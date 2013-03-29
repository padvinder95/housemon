# Peek module definitions

module.exports = (ng) ->

  ng.controller 'PeekCtrl', [
    '$scope',
    ($scope) ->
      $scope.$on 'ss-peek', (event, args...) ->
        console.log 'peek', args...
  ]
