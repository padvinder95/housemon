module.exports =

  announcer: 17

  descriptions:
    ['BATT']

  BATT:
    ping:
      title: 'Ping count'
      min: 0
    age:
      title: 'Estimated age'
      unit: 'days'
      min: 0
    vpre:
      title: 'Vcc before send'
      unit: 'V'
      factor: 2
      scale: 2
    vpost:
      title: 'Vcc after send'
      unit: 'V'
      factor: 2
      scale: 2

  feed: 'rf12.packet'

  decode: (raw, cb) ->
    count = raw.readUInt32LE(1)
    result =
      tag: 'BATT-0'
      ping: count
      age: count / (86400 / 64) | 0
    if raw.length >= 8
      result.tag = "BATT-#{raw[5]}"
      result.vpre = 50 + raw[6]
      result.vpost = 50 + raw[7] if raw[7]
    cb result
