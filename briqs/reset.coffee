exports.info =
  name: 'reset'
  description: 'Reset various data items (use with extreme care!)'
  menus: [
    title: 'Reset'
    controller: 'ResetCtrl'
  ]
  rpcs: [
    'resetStatus'
    'resetReadings'
    'resetHistory'
    'flushRedis'
    'deleteArchive'
    'restart'
    'reprocessLogs'
  ]
  
state = require '../server/state'
local = require '../local'
redis = require 'redis'
fs = require 'fs'
{exec} = require 'child_process'
async = require 'async'
logParser = require './jeemon-log-parser'

config = local.redisConfig
db = redis.createClient config.port, config.host, config
db.select config.db

LOGDIR = '../Reference/house-logs'

exports.factory = class
  constructor: ->

  destroy: ->

  @resetStatus: ->
    console.log 'resetStatus'
    state.reset 'status'

  @resetReadings: ->
    console.log 'resetReadings'
    state.reset 'readings'

  @resetHistory: ->
    console.log 'resetHistory'
    db.zrange 'hist:keys', 0, -1, 'withscores', (err, res) ->
      ids = []
      for i in [0...res.length] by 2
        ids.push parseInt res[i+1]
      async.eachSeries ids, (id, cb) ->
        db.del "hist:#{id}", -> cb() # ignore errors
      , ->
        db.del 'hist:keys', ->

  @flushRedis: ->
    console.log 'flushRedis'
    db.flushdb()

  @deleteArchive: ->
    console.log 'deleteArchive'
    exec 'rm -r ./archive/*'

  @restart: ->
    console.log 'restart'
    # force restart by assuming nodemon is running and watching
    exec 'touch ./package.json'

  @reprocessLogs: ->
    console.log 'reprocessLogs'
    fs.readdir LOGDIR, (err, dirs) ->
      console.log dirs
      offset = null
      counter = null
      parser = new logParser.factory
      parser.on 'packet', (info) ->
        ++counter
        # console.log info
        info.time += offset
        # FIXME hack, fixed values inserted into data stream for now
        info.group = 5
        info.band = 868
      for year in ['2012']
        do (year) ->
          files = fs.readdirSync "#{LOGDIR}/#{year}"
          # use async to serialise the scans and process them in sequence
          async.eachSeries files.sort().slice(-5), (path, cb) ->
            if path.slice(0, 4) is year
              console.log 'reprocessing', path
              mon = parseInt path.slice(4, 6), 10
              day = parseInt path.slice(6, 8), 10
              offset = Date.UTC year, mon-1, day
              counter = 0
              parser.parseFile "#{LOGDIR}/#{year}/#{path}", ->
                console.log '  count =', counter
                cb()
            else
              cb()
