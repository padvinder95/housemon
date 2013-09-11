module.exports = (app) ->

  app.register 'driver.ookrelay',
    announcer: 12
    in: 'Buffer'
    out:
      ['DCF77', 'EMX', 'KS300', 'S300']
  
    DCF77:
      date:
        title: 'Date'
      tod:
        title: 'Time'
      dst:
        title: 'Summer'
  
    EMX:
      seq:
        title: 'Seq number'
      avg:
        title: 'Average power', unit: 'W', min: 0, max: 4000, factor: 12
      max:
        title: 'Maximum power', unit: 'W', min: 0, max: 4000, factor: 12
      tot:
        title: 'Total consumption', unit: 'Wh', min: 0
  
    KS300:
      temp:
        title: 'Temperature', unit: '°C', scale: 1
      humi:
        title: 'Relative humidity', unit: '%'
      rain:
        title: 'Precipitation'
      rnow:
        title: 'Raining'
      wind:
        title: 'Wind speed', unit: 'km/h', scale: 1
  
    S300:
      temp:
        title: 'Temperature', unit: '°C', scale: 1
      humi:
        title: 'Relative humidity', unit: '%', scale: 1

    decode: (data) ->
      raw = data.msg
      out = []
      offset = 1
      while offset < raw.length
        type = raw[offset] & 0x0F
        size = raw[offset] >> 4
        name = ookDecoderType[type]
        offset += 1
        seg = raw.slice(offset, offset+size)
        offset += size
        if ookDecoders[name]
          ookDecoders[name] seg, (result) -> out.push result
        else
          out.push tag: name, hex: seg.toString('hex').toUpperCase()
      out

ookDecoderType = [ 'dcf', 'viso', 'emx', 'ksx', 'fsx',
                   'orsc', 'cres', 'kaku', 'xrf', 'hez', 'elro' ]

getBits = (raw, bitpos, count) ->
  (raw.readUInt32LE(bitpos>>3, true) >> (bitpos&7)) & ((1 << count) - 1)
  
ookDecoders =

  dcf: (raw, push) ->
    bytes = (raw[i] for i in [0..5])
    push
      tag: 'DCF77'
      date: ((2000 + bytes[0]) * 100 + bytes[1]) * 100 + bytes[2]
      tod: bytes[3] * 100 + bytes[4]
      dst: bytes[5]
    
  ksx: (raw, push) ->
    s = getBits(raw, 0, 4)
    switch s
      when 1
        v = (getBits(raw, i*5, 4) for i in [0..7])
        t = 100 * v[4] + 10 * v[3] + v[2]
        push
          tag: "S300-#{v[1]&7}"
          temp: if v[1] & 8 then -t else t
          humi: 100 * v[7] + 10 * v[6] + v[5]
      when 7
        v = (getBits(raw, i*5, 4) for i in [0..12])
        t = 100 * v[4] + 10 * v[3] + v[2]
        push
          tag: 'KS300'
          temp: if v[1] & 0x08 then -t else t
          humi: 10 * v[6] + v[5]
          wind: 100 * v[9] + 10 * v[8] + v[7]
          rain: 256 * v[12] + 16 * v[11] + v[10]
          rnow: (v[1] >> 1) & 0x01
      else
        push
          tag: "KSX-#{s}"
          hex: raw.toString('hex').toUpperCase()
          
  emx: (raw, push) ->
    v = (getBits(raw, i*9, 8) for i in [0..8])
    push
      tag: "EMX-#{v[0]}:#{v[1]}"
      seq: v[2]
      avg: 256 * v[6] + v[5]
      max: 256 * v[8] + v[7]
      tot: 256 * v[4] + v[3]
      
  fsx: (raw, push) ->
    # TODO decoding looks like it's still a bit off
    v = (getBits(raw, i*9, 8) for i in [0..4])
    # console.log 'fsx',v
    house = 256 * v[1] + v[0]
    addr = 2 * v[2] + (v[3] >> 7)
    if v[3] & 32
      push
        tag: "FS20X-#{house}:#{addr}"
        cmd: v[3] & 31
        ext: v[4]
    else
      push
        tag: "FS20-#{house}:#{addr}"
        cmd: v[3] & 31
