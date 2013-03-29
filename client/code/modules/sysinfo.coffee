# SysInfo module definitions

module.exports = (ng) ->

  ng.controller 'SysInfoCtrl', [
    '$scope','rpc',
    ($scope, rpc) ->

      $scope.info = rpc.exec 'host.api', 'sysInfo'
  ]
