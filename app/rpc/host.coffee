Q = require 'q'
Connection = require 'q-connection'

module.exports = (app, plugin) ->
  app.rpc = {}

  # can't use "app.on 'setup'" here because that would be too late
  plugin.server = (primus) ->
    primus.on 'connection', (spark) ->

      port =
        postMessage: (message) ->
          spark.write ['rpc', message]
        onmessage: null

      spark.on 'rpc', (arg) ->
        port.onmessage data: arg

      qc = Connection port, app.rpc
      spark.rpc = (args...) ->
        qc.invoke args...

  plugin.client = (primus) ->
    primus.rpc = {}
