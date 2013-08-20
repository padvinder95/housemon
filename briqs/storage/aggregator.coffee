_ = require 'underscore'

class Aggregator
  constructor: ->
    @count = @min = @max = 0
    @mean = @m2 = 0.0

  update: (value) ->
    # see http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
    @min = @max = value  if @count = 0
    @min = value  if value < @min
    @max = value  if value > @max
    # this is based on Welford's algorithm to reduce round-off errors
    delta = value - @mean
    @mean += delta / ++@count
    @m2 += delta * (value - @mean)

  extract: ->
    sdev = if @count > 1 then Math.sqrt @m2 / (@count - 1) else 0
    _.extend _.omit(@, 'm2'), {sdev}

create: () -> new Aggregator

pack: (item) ->
  data = new Buffer(18)
  # data.fill 0
  data.writeUInt16LE item.count, 0
  data.writeInt32LE Math.round(item.mean), 2
  data.writeInt32LE item.min, 6
  data.writeInt32LE item.max, 10
  data.writeInt32LE Math.round(item.sdev), 14
  data

unpack: (data) ->
  count: data.readUInt16LE 0
  mean: data.readUInt32LE 2
  min: data.readUInt32LE 6
  max: data.readUInt32LE 10
  sdev: data.readUInt32LE 14

module.exports = {create,pack,unpack}
