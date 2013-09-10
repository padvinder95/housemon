ng = angular.module 'myApp'

ng.factory 'rpc', ($q, $rootScope) ->
  port =
    postMessage: (message) ->
      primus.write ['rpc', message]
    onMessage: null

  $rootScope.$on 'rpc', (event, arg) ->
    port.onmessage data: arg

  Connection = require 'q-connection'
  Connection port, primus.api
