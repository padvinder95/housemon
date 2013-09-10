Connection = require 'q-connection'

module.exports = (app, plugin) ->
  app.api = {}

  plugin.server = (primus) ->
    primus.on 'connection', (spark) ->

      port =
        postMessage: (message) ->
          spark.write ['rpc', message]
        onmessage: null

      spark.on 'rpc', (arg) ->
        port.onmessage data: arg

      spark.remote = Connection port, app.api

      spark.remote.invoke('twice', 123) # defined in view2
        .then (res) -> console.log 'double', res

  plugin.client = (primus) ->
    primus.api = {}
