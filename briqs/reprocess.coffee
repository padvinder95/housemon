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
logParser = require './jeemon-log-parser'
nodeMap = require './nodeMap'
state = require '../server/state'

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
  if name.length is 4
    fs.readdir "#{LOGGER_PATH}/#{name}", (err, files) ->
      return cb err  if err
      async.eachSeries files, (file, done) ->
        processOne file, done
      , cb
  else
    processOne name, cb

processOne = (name, cb) ->
  parse = /^(\d\d\d\d)(\d\d)(\d\d)\./.exec name
  return cb()  unless parse

  basetime = Date.UTC parse[1], parse[2]-1, parse[3]
  filename = "#{LOGGER_PATH}/#{parse[1]}/#{name}"
  console.info 'reprocessing', filename

  rf12info = null

  parser = new logParser.factory

  state.emit 'reprocess.start', name
  parser.parseFile filename, ->
    state.emit 'reprocess.end', name
    cb() # TODO it's confusing to have both events and a callack

  parser.on 'other', (data) ->
    # TODO this RF12-specific stuff doesn't belong here
    if /RF12demo/.test data
      match = /\w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/.exec data
      if match
        rf12info =
          recvid: parseInt(match[1])
          group: parseInt(match[2])
          band: parseInt(match[3])
        console.info 'reprocess rf12info', rf12info

  parser.on 'packet', (packet) ->
    _.defaults packet, rf12info, nodeMap.rf12default
    packet.time += basetime
    state.emit 'reprocess.packet', packet
