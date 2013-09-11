module.exports = (app) ->

  # announcer: 19
  #
  # in: 'Buffer'
  #
  # descriptions:
  #   value:
  #     title: 'Light level'
  #     unit: '%'
  #     min: 0
  #     max: 255
  #     factor: 100 / 255
  #     scale: 0

  app.register 'driver.lightnode',
    decode: (data) ->
      { value: data.msg[1] }
