module.exports = (app, plugin) ->

  plugin.server = (primus) ->
    ticker = ->
      primus.write Date.now()
      setTimeout ticker, 60000
    primus.once 'connection', ->
      setTimeout ticker, 1000 # TODO: why is this delay needed?

  plugin.client = (primus) ->
    primus.transform 'incoming', (packet) ->
      if typeof packet.data is 'number'
        console.log 'tick', packet.data
