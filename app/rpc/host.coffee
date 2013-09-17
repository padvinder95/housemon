Q = require 'q'
Connection = require 'q-connection'

module.exports = (app, plugin) ->
  app.host = {}

  # can't use "app.on 'setup'" here because that would be too late
  plugin.server = (primus) ->
    primus.on 'connection', (spark) ->

      port =
        postMessage: (message) ->
          spark.write ['rpc', message]
        onmessage: null

      spark.on 'rpc', (arg) ->
        port.onmessage data: arg

      qc = Connection port, app.host
      spark.client = (args...) ->
        qc.invoke args...

  plugin.client = (primus) ->
    primus.client = {}
