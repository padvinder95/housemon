Connection = require 'q-connection'

module.exports = (primus) ->

  primus.api = {}

  primus.on 'connection', (spark) ->

    port =
      postMessage: (message) ->
        spark.write ['qcomm', message]
      onmessage: null

    spark.on 'qcomm', (arg) ->
      port.onmessage data: arg

    spark.remote = Connection port, primus.api

    spark.remote.invoke('twice', 123)
      .then (res) -> console.log 'double', res
