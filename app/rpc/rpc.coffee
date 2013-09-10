Connection = require 'q-connection'

ng = angular.module 'myApp'

ng.config ->
  primus.api = {}

ng.service 'rpc', ($q, $rootScope) ->
  port =
    postMessage: (message) ->
      primus.write ['qcomm', message]
    onMessage: null

  $rootScope.$on 'qcomm', (event, arg) ->
    port.onmessage data: arg

  Connection port, primus.api
