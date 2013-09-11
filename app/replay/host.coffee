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

  _flush: (done) ->
    @push @pending  if @pending
    done()

# Replay a log file again as properly timed events, but for the current date
# Takes a log stream as feed, and turns it into a never-ending simulation
class Replayer extends stream.Transform
  constructor: ->
    super objectMode: true
    @history = []

  _transform: (message, encoding, done) ->
    @history.push message
    done()

  _flush: (done) ->
    # console.info "Replayer: #{@history.length} entries collected"
    MS_PER_DAY = 86400000

    findNext = (index, now) =>
      timeNow = now % MS_PER_DAY
      for i in [index...@history.length]
        if @history[i].time % MS_PER_DAY >= timeNow
          return i

    resumeFrom = (index) =>
      now = Date.now()
      index = findNext(index, now) ? 0
      entry = @history[index]
      delay = entry.time % MS_PER_DAY - now % MS_PER_DAY
      delay += MS_PER_DAY  if delay < 0
      setTimeout =>
        entry.replaying ?= entry.time
        entry.time = now - (now % MS_PER_DAY) + (entry.time % MS_PER_DAY)
        @push entry
        resumeFrom index + 1
      , delay

    resumeFrom 0

# Turn a function into a transform stream, can return multiple results as array
class Transformer extends stream.Transform
  constructor: (@proc) ->
    super objectMode: true

  _transform: (message, encoding, done) ->
    out = @proc message
    if Array.isArray out
      @push x  for x in out
    else
      @push out  if out?
    done()

# Take one log line and return it as packet, with timestamp and device info
logParser = (offset = 0) ->
  (line) ->
    t = /^L (\d\d):(\d\d):(\d\d)\.(\d\d\d) (\S+) (.+)/.exec line
    if t
      time: ((+t[1] * 60 + +t[2]) * 60 + +t[3]) * 1000 + +t[4] + offset
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

module.exports = (app, plugin) ->
  app.register 'pipe', 'splitter', Splitter
  app.register 'pipe', 'transformer', Transformer
  app.register 'pipe', 'replayer', Replayer
  app.register 'source', 'logstream', createLogStream
