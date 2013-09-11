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

  _transform: (message, encoding, done) ->
    line = message.line
    if line.length < 300
      tokens = line.split ' '
      if tokens.shift() is 'OK'
        nodeId = tokens[0] & 0x1F
        @push { type: "rf12-#{nodeId}", line: Buffer(tokens), @config }
      else if match = /^ \w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/.exec line
        @config = { recvid: +match[1], group: +match[2], band: +match[3] }
        console.info 'RF12 config:', line
      else
        # unrecognized input, usually a "?" line
        @push { type: 'unknown', line, @config }
    done()

class Decoder extends stream.Transform
  constructor: ->
    super objectMode: true

  _transform: (message, encoding, done) ->
    {type, line, config} = message
    driver = require '../drivers/' + type
    out = driver.decode line, config
    if Array.isArray out
      @push x  for x in out
    else
      @push out  if out
    done()

module.exports = (app, plugin) ->
  app.register 'interface', 'serial', Serial
  app.register 'pipe', 'parser', Parser
  app.register 'pipe', 'decoder', Decoder
