Connection = require 'q-connection'

module.exports = (app, primus) ->

  app.api = {}

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
