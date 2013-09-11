# stream = require 'stream'
# 
# class TestNode extends stream.Transform
#   constructor:
#     super()
#   
#   _transform: (message, encoding, done) ->
#     message.line = { batt: bytes[6] * 256 + bytes[5] }
#     @push message
#     done()
# 
# module.exports = (app, plugin) ->
#   app.register 'driver', 'testnode', TestNode

stream = require 'stream'

class Decoder extends stream.Transform
  constructor: ->
    super objectMode: true
  _transform: (data, encoding, done) ->
    if data.type is 'rf12-2'
      out = @decode data
      if Array.isArray out
        for x in out
          data.line = x
          @push data
      else
        data.line = out
        @push data
    done()

module.exports = (app, plugin) ->

  app.on 'start', ->
    @register 'driver', 'testnode', class extends Decoder
      decode: (data) ->
        { batt: data.line[6] * 256 + data.line[5] }
    
    @register 'node', 'rf12-2', 'testnode'
