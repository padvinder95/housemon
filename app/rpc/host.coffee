Q = require 'q'
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

      spark.remote.invoke('view2_twice', 123)
        .then (res) ->
          console.log 'double', res
        .fail (err) ->
          console.log 'rpc twice fail', err

  plugin.client = (primus) ->
    primus.api = {}
