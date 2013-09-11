module.exports = (app) ->

  app.register 'driver.testnode',
    in: 'Buffer'
    out:
      batt:
        title: 'Battery status', unit: 'V', scale: 3, min: 0, max: 5

    decode: (data) ->
      { batt: data.msg.readUInt16LE 5 }
