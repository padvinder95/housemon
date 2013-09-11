stream = require 'stream'

class Decoder extends stream.Transform
  constructor: ->
    super objectMode: true
  _transform: (data, encoding, done) ->
    if data.type is 'rf12-2'
      out = @decode data
      if Array.isArray out
        for x in out
          data.msg = x
          @push data
      else if out?
        data.msg = out
        @push data
    done()

module.exports = (app, plugin) ->

  app.on 'setup', ->
    @register 'driver.testnode', class extends Decoder
      decode: (data) ->
        { batt: data.msg.readUInt16LE 5 }
    
    @register 'nodemap.rf12-2', 'testnode'
