ng = angular.module 'myApp'

ng.factory 'host', ($q, $rootScope, primus) ->
  port =
    postMessage: (message) ->
      primus.write ['rpc', message]
    onMessage: null

  $rootScope.$on 'rpc', (event, arg) ->
    port.onmessage data: arg

  Connection = require 'q-connection'
  qc = Connection port, primus.client
  
  (args...) ->
    q = $q.defer()
    # silly glue to convert from q-connection's "q" to Angular's "$q"
    qc.invoke(args...)
      .then (res) ->
        q.resolve res
      .fail (err) ->
        console.log 'fail', fail
        q.catch err
    q.promise
