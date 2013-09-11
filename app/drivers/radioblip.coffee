module.exports = (app) ->

  # announcer: 17
  #
  # in: 'Buffer'
  #
  # out:
  #   ['BATT']
  #
  # BATT:
  #   ping:
  #     title: 'Ping count', min: 0
  #   age:
  #     title: 'Estimated age', unit: 'days', min: 0
  #   vpre:
  #     title: 'Vcc before send', unit: 'V', min: 0, factor: 2, scale: 2
  #   vpost:
  #     title: 'Vcc after send', unit: 'V', min: 0, factor: 2, scale: 2
  #   vbatt:
  #     title: 'Battery in', unit: 'V', min: 0, factor: 2, scale: 2

  app.register 'driver.radioblip',
    decode: (data) ->
      raw = data.msg
      count = raw.readUInt32LE(1)
      result =
        tag: 'BATT-0'
        ping: count
        age: count / (86400 / 64) | 0
      if raw.length >= 8
        result.tag = "BATT-#{raw[5]&0x7F}"
        result.vpre = 50 + raw[6]
        if raw[5] & 0x80
          # if high bit of id is set, this is a boost node reporting its battery
          # this is ratiometric (proportional) w.r.t. the "vpre" just measured
          result.vbatt = result.vpre * raw[7] / 255 | 0
        else
          # in the non-boost case, the second value is vcc after last transmit
          # this is always set, except in the first transmission after power-up
          result.vpost = 50 + raw[7] if raw[7]
      result
