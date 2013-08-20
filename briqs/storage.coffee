exports.info =
  name: 'storage'
  description: 'Permanent data storage'
  
state = require '../server/state'
level = require 'level'

db = level './storage', {}, (err) ->
  throw err  if err
  if true
    console.log 'db opened'
    console.log db.db.getProperty 'leveldb.stats'
    db.db.approximateSize 'reading~', 'reading~~', (err, size) ->
      throw err  if err
      console.log 'reading size ~ %db', size

processValue = (obj, oldObj) ->
  # console.log obj
  dbkey = "reading~#{obj.key}~#{obj.time}"
  db.put dbkey, obj.value, (err) ->
    throw err  if err

exports.factory = class
  constructor: ->
    state.on 'set.status', processValue
  destroy: ->
    state.off 'set.status', processValue
