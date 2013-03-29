module.exports =

  announcer: 13

  descriptions:
    acw:
      title: 'PV power AC'
      unit: 'W'
      min: 0
      max: 6000
    dcv1:
      title: 'PV level east'
      unit: 'V'
      scale: 2
      min: 0
      max: 250
    dcv2:
      title: 'PV level west'
      unit: 'V'
      scale: 2
      min: 0
      max: 250
    dcw1:
      title: 'PV power east'
      unit: 'W'
      min: 0
      max: 4000
    dcw2:
      title: 'PV power west'
      unit: 'W'
      min: 0
      max: 4000
    total:
      title: 'PV total'
      unit: 'MWh'
      scale: 3
      min: 0
    yield:
      title: 'PV daily yield'
      unit: 'kWh'
      scale: 3
      min: 0
      max: 50

  feed: 'rf12.packet'

  decode: (raw, cb) ->
    ints = (raw.readUInt16LE(1+2*i, true) for i in [0..6])
    result =
      acw: ints[2]
      dcv1: ints[3]
      dcv2: ints[4]
    # only report aggragated values when they actually change
    @prev ?= []
    result.yield = ints[0]  if ints[0] isnt @prev[0]
    result.total = ints[1]  if ints[1] isnt @prev[1]
    if ints[2]
      result.dcw1 = ints[5]
      result.dcw2 = ints[6]
    @prev = ints
    cb result
