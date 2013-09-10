module.exports = (app, server, primus) ->
  console.log 'READY'

  primus.use 'verbose',
    server: (primus) ->
      ['connection', 'disconnection', 'initialised', 'close'].forEach (type) ->
        primus.on type, (socket) ->
          console.info "primus (#{type})", new Date
    client: (primus) ->
      # only report the first error, but do it very disruptively!
      primus.once 'error', alert

  primus.use 'tick',
    server: (primus) ->
      setInterval ->
        primus.write Date.now()
      , 5000
    client: (primus) ->
      primus.transform 'incoming', (packet) ->
        if typeof packet.data is 'number'
          console.log 'tick', packet.data

  false