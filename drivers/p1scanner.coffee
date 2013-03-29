module.exports =

  announcer: 15

  descriptions:
    use1:
      title: 'Elec usage - low'
      unit: 'kWh'
      scale: 3
      min: 0
    use2:
      title: 'Elec usage - high'
      unit: 'kWh'
      scale: 3
      min: 0
    gen1:
      title: 'Elec return - low'
      unit: 'kWh'
      scale: 3
      min: 0
    gen2:
      title: 'Elec return - high'
      unit: 'kWh'
      scale: 3
      min: 0
    mode:
      title: 'Elec tariff'
    usew:
      title: 'Elec usage now'
      unit: 'W'
      scale: -1
      min: 0
      max: 15000
    genw:
      title: 'Elec return now'
      unit: 'W'
      scale: -1
      min: 0
      max: 10000
    gas:
      title: 'Gas total'
      unit: 'm3'
      scale: 3
      min: 0

  feed: 'rf12.packet'

  decode: (raw, cb) ->
    # see http://jeelabs.org/2012/12/01/extracting-data-from-p1-packets/
    ints = []
    v = 0
    for i in [1...raw.length]
      b = raw[i]
      v = (v << 7) + (b & 0x7F)
      if b & 0x80
        ints.push v
        v = 0
    if ints[0] is 1
      # only report values which have actually changed
      # for usew and genw, we only need to report the one that is active
      result = {}
      @prev ?= []
      result.use1 = ints[1]  if ints[1] isnt @prev[1]
      result.use2 = ints[2]  if ints[2] isnt @prev[2]
      result.gen1 = ints[3]  if ints[3] isnt @prev[3]
      result.gen2 = ints[4]  if ints[4] isnt @prev[4]
      result.mode = ints[5]  if ints[5] isnt @prev[5]
      result.usew = ints[6]  if ints[6] isnt @prev[6] or ints[6]
      result.genw = ints[7]  if ints[7] isnt @prev[7] or ints[7]
      result.gas = ints[9]  if ints[9] isnt @prev[9]
      @prev = ints
      cb result
