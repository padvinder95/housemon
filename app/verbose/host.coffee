module.exports = (app, plugin) ->

  plugin.server = (primus) ->
    ['connection', 'disconnection', 'initialised', 'close'].forEach (type) ->
      primus.on type, (socket) ->
        console.info "primus (#{type})", new Date

  plugin.client = (primus) ->
    # only report the first error, but do it very disruptively!
    primus.once 'error', alert
