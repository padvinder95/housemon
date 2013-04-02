exports.info =
  name: 'reprocess'
  description: 'Reprocess raw data from logfiles'
  rpcs: ['scanLogs','reprocessLog']
  menus: [
    title: 'Reprocess'
    controller: 'ReprocessCtrl'
  ]

fs = require 'fs'
async = require 'async'

LOGGER_PATH = './logger'

exports.scanLogs = (cb) ->
  fs.readdir LOGGER_PATH, (err, dirs) ->
    if err
      cb err
    else
      logFiles = {}
      async.eachSeries dirs, (dir, done) ->
        dirPath = "#{LOGGER_PATH}/#{dir}"
        fs.stat dirPath, (err, stats) ->
          if not err and stats.isDirectory()
            fs.readdir dirPath, (err, files) ->
              unless err
                logFiles[dir] = _.filter files, (name) ->
                  dir is name.slice 0, 4
              done err
      , (err) ->
        cb err, logFiles

exports.reprocessLog = (name, cb) ->
  console.info 'reprocessing', name
  cb()
