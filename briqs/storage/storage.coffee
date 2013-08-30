state = require '../../server/state'
level = require 'level'

db = level './storage', {}, (err) ->
  throw err  if err
  if true
    console.log 'db opened', db.db.getProperty 'leveldb.stats'
    db.db.approximateSize ' ', '~', (err, size) ->
      throw err  if err
      console.log 'storage size ~ %d bytes', size

processValue = (obj, oldObj) ->
  dbkey = "reading~#{obj.key}~#{obj.time}"
  db.put dbkey, obj.origval, (err) ->
    throw err  if err

module.exports = class
  constructor: ->
    state.on 'set.status', processValue

  destroy: ->
    state.off 'set.status', processValue

  @rawRange: (key, from, to, cb) ->
    now = Date.now()
    from += now  if from < 0
    to += now  if to <= 0
    prefix = "reading~#{key}~"
    results = []
    s = db.createReadStream start: prefix + from, end: prefix + to
    s.on 'data', (data) ->
      results.push +data.value
      results.push +data.key.substr prefix.length
    s.on 'error', (err) ->
      cb err
    s.on 'end', ->
      cb null, results
