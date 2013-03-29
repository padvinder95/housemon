exports.info =
  name: 'jeemon-log'
  description: 'Parser for JeeMon-formatted text logfiles'
  inputs: [
    name: 'Logfile path'
    default: 'abc...' # TODO: server-side file/directory selection
  ]
  # dependencies:
  #   'lazy': '*'

events = require 'events'
fs = require 'fs'
zlib = require 'zlib'
state = require '../server/state'

# L 01:02:03.537 usb-A40117UK OK 9 25 54 66 235 61 139 183 235 210 226 33 19

class JeeMonLogParser extends events.EventEmitter
  
  info = {}

  parse: (line) ->
    words = line.split ' '
    if words[0] is 'L'
      t = /(\d\d):(\d\d):(\d\d)\.(\d\d\d)/.exec words[1]
      if words[3] is 'OK'
        time = ((parseInt(t[1], 10) * 60 +
                 parseInt(t[2], 10)) * 60 +
                 parseInt(t[3], 10)) * 1000 +
                 parseInt(t[4], 10)
        info =
          time: time
          device: words[2]
          id: words[4] & 0x1F
          buffer: new Buffer(words.slice 4)
        @emit 'packet', info
      else
        @emit 'other', line.substring 28
  
  parseFile: (filename, cb) ->
    stream = fs.createReadStream filename
    if filename.slice -3 is '.gz'
      stream = stream.pipe zlib.createGunzip()
    @parseStream stream, cb

  parseStream: (stream, cb) ->
    all = []
    stream.on 'data', (data) ->
      all.push data.toString()
    stream.on 'end', () =>
      for line in all.join('').split '\n'
        @parse line
      cb()

exports.factory = JeeMonLogParser
