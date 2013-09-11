module.exports = (app) ->

  # announcer: 16
  #
  # in: 'Buffer'
  #
  # out:
  #   c1:
  #     title: 'Counter stove', unit: 'kWh'
  #     factor: 0.5, scale: 3, min: 0, max: 33
  #   c2:
  #     title: 'Counter solar', unit: 'kWh'
  #     factor: 0.5, scale: 3, min: 0, max: 33
  #   c3:
  #     title: 'Counter house', unit: 'kWh'
  #     factor: 0.5, scale: 3, min: 0, max: 33
  #   p1:
  #     title: 'Usage stove', unit: 'W', scale: 1, min: 0, max: 10000
  #   p2:
  #     title: 'Production solar', unit: 'W', scale: 1, min: 0, max: 10000
  #   p3:
  #     title: 'Usage house', unit: 'W', scale: 1, min: 0, max: 10000

  app.register 'driver.homepower',
    decode: (data) ->
      raw = data.msg
      vec = (raw.readUInt16LE(1+2*i) for i in [0..5])
      # only report values which have changed
      result = {}
      @prev ?= []
      if vec[0] isnt @prev[0]
        result.c1 = vec[0]
        result.p1 = time2watt vec[1]
      if vec[2] isnt @prev[2]
        result.c2 = vec[2]
        result.p2 = time2watt vec[3]
      if vec[4] isnt @prev[4]
        result.c3 = vec[4]
        result.p3 = time2watt vec[5]
      @prev = vec
      result

time2watt = (t) ->
  if t > 60000
    t = 1000 * (t - 60000)
  18000000 / t | 0  if t > 0
