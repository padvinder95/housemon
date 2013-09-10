{Serial,Parser,Decoder} = require './lib'

module.exports = (app, primus) ->
  port = new Serial 'usb-A900ad5m'
  port.on 'open', ->
    port.pipe(new Parser).pipe(new Decoder).on 'data', (data) ->
      console.log 'RF12 out:', data
