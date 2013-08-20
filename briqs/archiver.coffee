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
fs = require 'fs'
async = require 'async'
_ = require 'underscore'

SLOTSIZE_MIN = 60 # each archive slot holds 60 minutes of aggregated values
SLOTSIZE_MS = SLOTSIZE_MIN * 60 * 1000 # archive slot size in milliseconds

FILESIZE = 1024 # number of slots per archive file
BYTES_PER_SLOT = 20 # each slot stores five 32-bit values

ARCHIVE_PATH = './archive'
ARCHREQ_PATH = '../archive'
ARCHMAP_PATH = './archive/index.json'

if fs.existsSync ARCHMAP_PATH
  archMap = require ARCHREQ_PATH
  console.info 'archMap', archMap._
else
  archMap = _: 0 # sequence number

fs.mkdir ARCHIVE_PATH, -> # ignore mkdir errors (it probably already exists)

aggregated = {} # in-memory cache of aggregated values

occasionalMapSave = _.debounce ->
  fs.writeFile ARCHMAP_PATH, JSON.stringify archMap, null, 2
, 3000

# also aggregates all reprocessed values, collecting the results in memory
# TODO need to flush more often, since complete reprocess will fill up memory
#   perhaps track these slots and trigger on reprocess.{start,end} events?

archiveValue = (time, param, value) ->
  # locate (or create) the proper collector slot in the aggregation cache
  slot = time / SLOTSIZE_MS | 0
  collector = aggregated[slot] ?= {}
  collector.dirty = true # tag as being modified recently
  # lookup (or assign and store) the id of the named parameter
  unless archMap[param]?
    archMap[param] = ++archMap._
    occasionalMapSave()
  id = archMap[param]
  # aggregate the value by combining it with what's already there
  item = collector[id] ?= { cnt: 0 }
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

saveToFile = (seg, slots, id, cb) ->
  path = "#{ARCHIVE_PATH}/p#{seg}/p#{seg}-#{id}.dat"
  console.info 'save', path
  # TODO no need to read files, could just seek and write over existing slots
  fs.readFile path, (err, data) ->
    unless data?
      data = new Buffer(BYTES_PER_SLOT * FILESIZE)
      data.fill 0
    for slot in slots
      item = aggregated[slot]?[id]
      if item?.cnt
        pos = (slot % FILESIZE) * BYTES_PER_SLOT
        try
          data.writeUInt16LE item.cnt, pos
          data.writeInt32LE Math.round(item.mean), pos+4
          data.writeInt32LE item.min, pos+8
          data.writeInt32LE item.max, pos+12
          if item.cnt > 1
            sdev = Math.sqrt item.m2 / (item.cnt - 1)
            data.writeInt32LE Math.round(sdev), pos+16
        catch err
          console.error 'cannot save', slot, id, item
    fs.writeFile path, data, cb

cronTask = (minutes) ->
  if minutes % 3 is 0
    # a segment is a series of slots which is saved as a single file
    segments = {} # map of arrays with slots we need to save
    for hour, collector of aggregated
      if collector.dirty
        delete collector.dirty
      else
        seg = hour / FILESIZE | 0
        segments[seg] ?= []
        segments[seg].push hour
    # at this point, we know which segments and slots to save (if any)
    async.eachSeries _.keys(segments), (seg, done) ->
      fs.mkdir "#{ARCHIVE_PATH}/p#{seg}", ->
        slots = segments[seg]
        # skip "_" sequence number, avoids double save of last key
        async.eachSeries _.values(_.omit(archMap, '_')), (id, cb) ->
          saveToFile seg, slots, id, cb
        , -> # called once all id's in this segment have been saved
          delete aggregated[slot]  for slot in slots
          done()

exports.factory = class
  constructor: ->
    state.on 'set.status', storeValue
    state.on 'reprocess.status', archiveValue
    state.on 'minutes', cronTask
  destroy: ->
    state.off 'set.status', storeValue
    state.off 'reprocess.status', archiveValue
    state.off 'minutes', cronTask
