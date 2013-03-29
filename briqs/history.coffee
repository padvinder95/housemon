exports.info =
  name: 'history'
  description: 'Historical data storage (full details of the last few days)'
  rpcs: ['rawRange']
  connections:
    feeds:
      'status': 'collection'
      'minutes': 'event'
    results:
      'hist': 'redis'
  
state = require '../server/state'
local = require '../local'
redis = require 'redis'
async = require 'async'

MAXHOURS = 50 # keep readings newer than 50 hours ago

keyMap = {}
lastId = 0

config = local.redisConfig
db = redis.createClient config.port, config.host, config
dbReady = false

db.select config.db, (err) ->
  throw err  if err
  # restore keyMap from last info in hist:keys
  db.zrange 'hist:keys', 0, -1, 'withscores', (err, res) ->
    throw err  if err
    for i in [0...res.length] by 2
      lastId = parseInt res[i+1]
      keyMap[res[i]] = lastId
    dbReady = true # ready to accept new results

storeValue = (obj, oldObj) ->
  if obj and dbReady
    key = obj.key
    # map each key to a unique id, and remeber that mapping
    unless keyMap[key]?
      keyMap[key] = ++lastId
      db.zadd 'hist:keys', lastId, key, ->
    db.zadd "hist:#{keyMap[key]}", obj.time, obj.origval, ->

# callable from client as rpc
exports.rawRange = (key, from, to, cb) ->
  now = Date.now()
  from += now  if from < 0
  to += now  if to <= 0
  id = keyMap[key]
  if id? and dbReady
    db.zrangebyscore "hist:#{id}", from, to, 'withscores', cb
  else
    cb null, []

cronTask = (minutes) ->
  if minutes is 35 # clean up once an hour
    console.info 'history cleanup started'
    db.zrange 'hist:keys', 0, -1, 'withscores', (err, res) ->
      throw err  if err
      cutoff = Date.now() - MAXHOURS * 3600 * 1000
      ids = (parseInt res[i+1] for i in [0...res.length] by 2)
      async.eachSeries ids, (id, cb) ->
        db.zremrangebyscore "hist:#{id}", '-inf', cutoff, cb

exports.factory = class
  constructor: ->
    state.on 'set.status', storeValue
    state.on 'minutes', cronTask
  destroy: ->
    state.off 'set.status', storeValue
    state.off 'minutes', cronTask
