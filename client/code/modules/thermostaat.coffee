module.exports = (ng) ->
  
  ng.controller 'ThermostaatCtrl', [
    '$scope',
    ($scope) ->
      $scope.$on 'ss-thermostaat', (event,value) ->
        $scope.temperature_setpoint = value
  ]
