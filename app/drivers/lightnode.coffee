module.exports = (app) ->

  app.register 'driver.lightnode',
    announcer: 19
    in: 'Buffer'
    descriptions:
      value:
        title: 'Light level'
        unit: '%'
        min: 0
        max: 255
        factor: 100 / 255
        scale: 0

    decode: (data) ->
      { value: data.msg[1] }
