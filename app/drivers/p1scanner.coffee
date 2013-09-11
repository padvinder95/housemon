module.exports = (app) ->

  # announcer: 15
  #
  # in: 'Buffer'
  #
  # out:
  #   use1:
  #     title: 'Elec usage - low', unit: 'kWh', scale: 3, min: 0
  #   use2:
  #     title: 'Elec usage - high', unit: 'kWh', scale: 3, min: 0
  #   gen1:
  #     title: 'Elec return - low', unit: 'kWh', scale: 3, min: 0
  #   gen2:
  #     title: 'Elec return - high', unit: 'kWh', scale: 3, min: 0
  #   mode:
  #     title: 'Elec tariff'
  #   usew:
  #     title: 'Elec usage now', unit: 'W', scale: -1, min: 0, max: 15000
  #   genw:
  #     title: 'Elec return now', unit: 'W', scale: -1, min: 0, max: 10000
  #   gas:
  #     title: 'Gas total', unit: 'm3', scale: 3, min: 0

  app.register 'driver.p1scanner',
    decode: (data) ->
      raw = data.msg
      # see http://jeelabs.org/2012/12/01/extracting-data-from-p1-packets/
      vec = []
      v = 0
      for i in [1...raw.length]
        b = raw[i]
        v = (v << 7) + (b & 0x7F)
        if b & 0x80
          vec.push v
          v = 0
      if vec[0] is 1
        # only report values which have actually changed
        # for usew and genw, we only need to report the one that is active
        result = {}
        @prev ?= []
        result.use1 = vec[1]  if vec[1] isnt @prev[1]
        result.use2 = vec[2]  if vec[2] isnt @prev[2]
        result.gen1 = vec[3]  if vec[3] isnt @prev[3]
        result.gen2 = vec[4]  if vec[4] isnt @prev[4]
        result.mode = vec[5]  if vec[5] isnt @prev[5]
        result.usew = vec[6]  if vec[6] isnt @prev[6] or vec[6]
        result.genw = vec[7]  if vec[7] isnt @prev[7] or vec[7]
        result.gas = vec[9]  if vec[9] isnt @prev[9]
        @prev = vec
        result
