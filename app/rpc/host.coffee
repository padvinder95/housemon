Connection = require 'q-connection'

module.exports = (app, plugin) ->
  app.api = {}

  plugin.server = (primus) ->
    primus.on 'connection', (spark) ->

      port =
        postMessage: (message) ->
          spark.write ['qcomm', message]
        onmessage: null

      spark.on 'qcomm', (arg) ->
        port.onmessage data: arg

      spark.remote = Connection port, app.api

      spark.remote.invoke('twice', 123)
        .then (res) -> console.log 'double', res

  plugin.client = (primus) ->
    primus.api = {}
