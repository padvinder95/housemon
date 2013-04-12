module.exports =

  announcer: 11

  descriptions:
    humi:
      title: 'Relative humidity'
      unit: '%'
      min: 0
      max: 100
    light:
      title: 'Light intensity'
      min: 0
      max: 100
      factor: 100 / 255
      scale: 0
    moved:
      title: 'Motion'
      min: 0
      max: 1
    temp:
      title: 'Temperature'
      unit: '°C'
      scale: 1
      min: -50
      max: 50

  feed: 'rf12.packet'

  decode: (raw, cb) ->
    t = raw.readUInt16LE(3, true) & 0x3FF
    cb
      light: raw[1]
      humi: raw[2] >> 1
      moved: raw[2] & 1
      temp: if t < 0x200 then t else t - 0x400
      # temp from -512 (e.g. 51.2) --> +511 (e.g. 51.1) supported by roomNode sketch. NB 512 will be incorrectly reported!

