# ReprocesS module definitions 
module.exports = (ng) ->

  ng.controller 'ReprocessCtrl', [
    '$scope','rpc',
    ($scope, rpc) ->
      
      $scope.logFiles = rpc.exec 'host.api', 'scanLogs'
      
      $scope.reprocess = (name) ->
        rpc.exec 'host.api', 'reprocessLog', name
  ]
