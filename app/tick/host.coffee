module.exports = (app, info) ->

  info.server = (primus) ->
    setInterval ->
      primus.write Date.now()
    , 5000

  info.client = (primus) ->
    primus.transform 'incoming', (packet) ->
      if typeof packet.data is 'number'
        console.log 'tick', packet.data
