module.exports = (app, plugin) ->

  plugin.server = (primus) ->
    setInterval ->
      primus.write Date.now()
    , 5000

  plugin.client = (primus) ->
    primus.transform 'incoming', (packet) ->
      if typeof packet.data is 'number'
        console.log 'tick', packet.data
