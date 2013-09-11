module.exports = (app) ->

  # announcer: 13
  #
  # in: 'Buffer'
  #
  # out:
  #   acw:
  #     title: 'PV power AC', unit: 'W', min: 0, max: 6000
  #   dcv1:
  #     title: 'PV level east', unit: 'V', scale: 2, min: 0, max: 250
  #   dcv2:
  #     title: 'PV level west', unit: 'V', scale: 2, min: 0, max: 250
  #   dcw1:
  #     title: 'PV power east', unit: 'W', min: 0, max: 4000
  #   dcw2:
  #     title: 'PV power west', unit: 'W', min: 0, max: 4000
  #   total:
  #     title: 'PV total', unit: 'MWh', scale: 3, min: 0
  #   yield:
  #     title: 'PV daily yield', unit: 'kWh', scale: 3, min: 0, max: 50

  app.register 'driver.smarelay',
    decode: (data) ->
      vec = (data.msg.readUInt16LE(1+2*i, true) for i in [0..6])
      result =
        acw: vec[2]
        dcv1: vec[3]
        dcv2: vec[4]
      # only report aggragated values when they actually change
      @prev ?= []
      result.yield = vec[0]  if vec[0] isnt @prev[0]
      result.total = vec[1]  if vec[1] isnt @prev[1]
      if vec[2]
        result.dcw1 = vec[5]
        result.dcw2 = vec[6]
      @prev = vec
      result
