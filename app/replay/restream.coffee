stream = require 'stream'
fs = require 'fs'
path = require 'path'
zlib = require 'zlib'

# A stream to transform arbitrary text into a stream of line strings
class Splitter extends stream.Transform
  constructor: ->
    super()
    @pending = ''

  _transform: (data, encoding, done) ->
    lines = (@pending + data).split /\r?\n/
    @pending = lines.pop()
    for x in lines
      @push x
    done()

  _flush: ->
    @push @pending  if @pending

# Turn a function into a transform stream, can return multiple results as array
class Transformer extends stream.Transform
  constructor: (@proc) ->
    super objectMode: true

  _transform: (data, encoding, done) ->
    data = data.toString() # TODO: why is thie needed?
    out = @proc data
    if Array.isArray out
      for x in out
        @push x
    else if out?
      @push out
    done()

# Take one log line and returns a packet, including timestamp and device info
logParser = (offset = 0) ->
  (line) ->
    t = /^L (\d\d):(\d\d):(\d\d)\.(\d\d\d) (\S+) (.+)/.exec line
    if t
      time = ((parseInt(t[1], 10) * 60 +
               parseInt(t[2], 10)) * 60 +
               parseInt(t[3], 10)) * 1000 +
               parseInt(t[4], 10)
      time: time + offset
      device: t[5]
      line: t[6]

createLogStream = (fileName) ->
  t = /^(\d\d\d\d)(\d\d)(\d\d)\./.exec path.basename(fileName)
  startTime = Date.parse "#{t[1]}-#{t[2]}-#{t[3]}"  if t
  stream = fs.createReadStream fileName
  if path.extname(fileName) is '.gz'
    stream = stream.pipe zlib.createGunzip()
  stream
    .pipe(new Splitter)
    .pipe(new Transformer logParser(startTime))

module.exports = { Splitter, Transformer, createLogStream }
