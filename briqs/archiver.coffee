exports.info =
  name: 'archiver'
  description: 'Archival data storage'
  connections:
    feeds:
      'status': 'collection'
      'reprocess.status': 'event'
      'minutes': 'event'
    results:
      'archive': 'dir'
  downloads:
    '/archive': './archive'
  
state = require '../server/state'

MIN_PER_SLOT = 60 # each archive slot holds 60 minutes of aggregated values

db = state.db

aggregated = {} # in-memory cache of aggregated values

# also aggregates all reprocessed values, collecting the results in memory
# TODO need to flush more often, since complete reprocess will fill up memory
#   perhaps track these slots and trigger on reprocess.{start,end} events?

archiveValue = (time, param, value) ->
  # locate (or create) the proper collector slot in the aggregation cache
  slot = time / (MIN_PER_SLOT * 60000) | 0
  collector = aggregated[slot] ?= {}
  collector.dirty = true # tag as being modified recently
  # aggregate the value by combining it with what's already there
  item = collector[param] ?= { cnt: 0 }
  # see http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
  if item.cnt is 0
    item.mean = item.m2 = 0
    item.min = item.max = value
  else
    item.min = Math.min value, item.min
    item.max = Math.max value, item.max
  # this is based on Welford's algorithm to reduce round-off errors
  delta = value - item.mean
  item.mean += delta / ++item.cnt
  item.m2 += delta * (value - item.mean)

storeValue = (obj, oldObj) ->
  if obj? #therwise error on resetStatus
    archiveValue obj.time, obj.key, obj.origval

flushSlots = () ->
  cutoff = Date.now() / (MIN_PER_SLOT * 60000) | 0
  count = 0
  data = new Buffer(18)
  for slot, collector of aggregated
    if slot < cutoff
      if collector.dirty
        collector.dirty = false
      else
        for param, item of collector
          data.writeUInt16LE item.cnt, 0, true
          data.writeInt32LE Math.round(item.mean), 2, true
          data.writeInt32LE item.min, 6, true
          data.writeInt32LE item.max, 10, true
          if item.cnt > 1
            sdev = Math.sqrt item.m2 / (item.cnt - 1)
            data.writeInt32LE Math.round(sdev), 14, true
          db.put "archive~#{param}~#{slot}", data, valueEncoding: 'binary'
        count += Object.keys(aggregated[slot]).length
        delete aggregated[slot]
  console.info 'archive cleanup', count  if count

cronTask = (minutes) ->
  flushSlots()

exports.factory = class
  constructor: ->
    state.on 'set.status', storeValue
    state.on 'reprocess.status', archiveValue
    state.on 'reprocess.end', flushSlots
    state.on 'minutes', cronTask
  destroy: ->
    state.off 'set.status', storeValue
    state.off 'reprocess.status', archiveValue
    state.off 'reprocess.end', flushSlots
    state.off 'minutes', cronTask
