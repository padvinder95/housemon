exports.info =
  name: 'rf12replay'
  description: 'RF12 test data generator'
  connections:
    results:
      'rf12.packet': 'event'
  # needs: ['jeemon-log-parser']

logParser = require '../jeemon-log-parser'
fs = require 'fs'
zlib = require 'zlib'
nodeMap = require '../nodeMap'
state = require '../../server/state'
_ = require 'underscore'

exports.factory = class
  
  constructor: ->
    logs = []
    @timer = null
    
    # trigger a simulated packet event, then delay and schedule the next on
    emitNext = (pos) =>
      packet = logs[pos]
      # add static info to the packet, if the device is listed in nodeMap
      _.extend packet, nodeMap.rf12devices?[packet.device]  unless packet.band
      state.emit 'rf12.packet', packet
      # careful with wrapping, reuse the same log every day
      nextTick = logs[++pos]?.time
      unless nextTick?
        pos = 0
        nextTick = logs[0].time + 86400000
      # TODO: adjust for exact timing, current logic will graduallly drift
      @timer = setTimeout (-> emitNext pos), nextTick - packet.time
    
    stream = fs.createReadStream("#{__dirname}/20121130.txt.gz")
                  .pipe(zlib.createGunzip())

    parser = new logParser.factory
    
    parser.on 'packet', (packet) ->
      logs.push packet

    parser.parseStream stream, ->
      console.info "#{logs.length} test packets loaded"
      # start the process by locating the next time slot to use
      times = _.pluck logs, 'time'
      pos = _.sortedIndex times, Date.now() % 86400000
      emitNext pos
    
  destroy: ->
    clearTimeout @timer
