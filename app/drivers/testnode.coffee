module.exports = (app) ->

  #   batt:
  #     title: 'Battery status', unit: 'V', scale: 3, min: 0, max: 5

  app.register 'driver.testnode',
    decode: (data) ->
      { batt: data.msg.readUInt16LE 5 }
