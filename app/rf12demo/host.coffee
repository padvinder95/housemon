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
        part = { time: Date.now(), dev: dev, msg: part }
      emitter.emit type, part
    origParser { emit }, buffer

class Parser extends stream.Transform
  constructor: ->
    super objectMode: true
    @config = null

  _transform: (data, encoding, done) ->
    msg = data.msg
    if msg.length < 300
      tokens = msg.split ' '
      if tokens.shift() is 'OK'
        nodeId = tokens[0] & 0x1F
        prefix = if @config then "#{@config.band}:#{@config.group}:" else ''
        @push { type: "rf12-#{prefix}#{nodeId}", msg: Buffer(tokens) }
      else if match = /^ \w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/.exec msg
        @config = { recvid: +match[1], group: +match[2], band: +match[3] }
        console.info 'RF12 config:', msg
      else
        # unrecognized input, usually a "?" msg
        @push { type: 'unknown', msg, @config }
    done()

class Decoder extends stream.Transform
  constructor: ->
    super objectMode: true

  _transform: (data, encoding, done) ->
    {type, msg, config} = data
    driver = require '../drivers/' + type
    out = driver.decode msg, config
    if Array.isArray out
      @push x  for x in out
    else
      @push out  if out
    done()

module.exports = (app, plugin) ->
  app.register 'interface.serial', Serial
  app.register 'pipe.parser', Parser
  app.register 'pipe.decoder', Decoder
