stream = require 'stream'
serialport = require 'serialport'

class Serial extends serialport.SerialPort
  constructor: (dev, baudrate = 57600) ->
    path = dev.replace /^usb-/, '/dev/tty.usbserial-'
    parser = lineEventParser dev
    super path, { baudrate, parser }

lineEventParser = (dev) ->
  origParser = serialport.parsers.readline /\r?\n/
  (emitter, buffer) ->
    emit = (type, part) ->
      if type is 'data' # probably always true
        part = { time: Date.now(), device: dev, line: part }
      emitter.emit type, part
    origParser { emit }, buffer

class Parser extends stream.Transform
  constructor: ->
    super objectMode: true
    @config = {}

  _transform: (packet, encoding, done) ->
    data = packet.line
    if data.length < 300
      tokens = data.split ' '
      if tokens.shift() is 'OK'
        bytes = (+x for x in tokens) # convert to ints
        nodeId = bytes[0] & 0x1F
        @push { type: "rf12-#{nodeId}", bytes, @config }
      else if match = /^ \w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/.exec data
        @config.recvid = +match[1]
        @config.group = +match[2]
        @config.band = +match[3]
        console.info 'RF12 config:', data
      else
        # unrecognized input, usually a "?" line
        @push { type: 'unknown', bytes: data, @config }
    done()

class Decoder extends stream.Transform
  constructor: ->
    super objectMode: true

  _transform: (data, encoding, done) ->
    {type, bytes, info} = data
    driver = require '../drivers/' + type
    driver.decode bytes, info, @push.bind @
    done()

module.exports = { Serial, Parser, Decoder }
