exports.info =
  name: 'status'
  description: 'Collect and show the current status'
  menus: [
    title: 'Status'
  ]
  connections:
    feeds:
      'readings': 'collection'
    results:
      'status': 'collection'
  
state = require '../server/state'
_ = require 'underscore'

models = state.models

adjustValue = (value, info) ->
  if info.factor
    value *= info.factor
  if info.scale < 0
    value *= Math.pow 10, -info.scale
  else if info.scale >= 0
    value /= Math.pow 10, info.scale
    value = value.toFixed info.scale
  value

updateStatus = (obj, loc, info, param, value) ->
  key = "#{loc.title} - #{info.title}"
  tag = obj.key.split '.'
  adj = adjustValue value, info

  state.store 'status',
    key: key
    location: loc.title
    parameter: info.title
    value: adj
    unit: info.unit
    time: obj.time
    origin: tag[0]
    type: tag[1]
    name: param
    origval: value
    factor: info.factor
    scale: info.scale

# TODO linear search, should be replaced by hash index
# TODO location and driver lookup depend on timestamp of the reading
findKey = (collection, key) ->
  for k,v of collection
    if key is v.key
      return v

splitReading = (obj, handler) ->
  [locName, other..., drvName] = obj.key.split '.'

  loc = findKey models.locations, locName
  unless loc
    loc = findKey models.locations, drvName
    unless loc
      loc = findKey models.locations, drvName?.replace /-.*/, ''
  drv = findKey models.drivers, drvName
  unless drv
    drv = findKey models.drivers, drvName?.replace /-.*/, ''

  if loc and drv
    for param, value of _.omit obj, 'id','key','time'
      info = drv[param]
      # weed out NaN and other things than don't fit in a 32-bit signed int
      if info and value? and -2147483648 <= value < 2147483648
        handler obj, loc, info, param, value
      else
        console.info 'ignored value', locName, drvName, param, value

processReading = (obj, oldObj) ->
  if obj
    splitReading obj, updateStatus

reprocessor = (reading) ->
  splitReading reading, (obj, loc, info, param, value) ->
    key = "#{loc.title} - #{info.title}"
    state.emit 'reprocess.status', obj.time, key, value

exports.factory = class

  constructor: ->
    state.on 'set.readings', processReading
    state.on 'reprocess.reading', reprocessor

  destroy: ->
    state.off 'set.readings', processReading
    state.ofJSON.stringify readingf 'reprocess.reading', reprocessor
