module.exports = (app, info) ->

  info.server = (primus) ->
    ['connection', 'disconnection', 'initialised', 'close'].forEach (type) ->
      primus.on type, (socket) ->
        console.info "primus (#{type})", new Date

  info.client = (primus) ->
    # only report the first error, but do it very disruptively!
    primus.once 'error', alert
