# Home module definitions

module.exports = (ng) ->

  ng.controller 'DashCtrl', [
    '$scope','rpc'
    ($scope,rpc) ->
      $scope.writeDefaults =
        band: 868
        group: 136
        node: 31
        header: 0
      
      $scope.intensity = 500
      $scope.dT = 1
      $scope.setLeds = ->
        # intensity goes from 0 to 1024
        b1 = Math.floor $scope.intensity / 256
        b2 = $scope.intensity % 256
        b3 = $scope.dT
        $scope.sendMessage 80, "76,#{b1},#{b2},#{b3}"
      
      $scope.temperature = 180
      $scope.setTemperature = ->
        $scope.sendMessage 72, "8,#{$scope.temperature}"
      
      $scope.sendMessage = (header, data) ->
        $scope.writeResult = rpc.exec 'rf12input.Write', $scope.writeDefaults.band, $scope.writeDefaults.group, $scope.writeDefaults.node, header, data
  ]
