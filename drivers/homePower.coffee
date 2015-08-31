module.exports =

  announcer: 16

  descriptions:
    c1:
      title: 'Counter'
      unit: 'kWh'
      factor: 1
      scale: 3
      min: 0
      max: 66 # 65536 x 1Wh rollover
    p1:
      title: 'Usage'
      unit: 'W'
      scale: 1
      min: 0
      max: 10000

  feed: 'rf12.packet'

  decode: (raw, cb) ->
    ints = (raw.readUInt16LE(1+2*i, true) for i in [0..1])
    # only report values that have changed
    result = {}
    @prev ?= []
    if ints[0] isnt @prev[0]
      result.c1 = ints[0]
      result.p1 = time2watt ints[1]
    @prev = ints
    cb result

time2watt = (t) ->
  if t > 60000
    t = 1000 * (t - 60000)
  2*18000000 / t | 0  if t > 0
