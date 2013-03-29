# Main app setup and controller, this all hooks into AngularJS

module.exports = (ng) ->

  ng.controller 'MainCtrl', [
    'routes','$scope',
    (routes, $scope) ->

      $scope.routes = routes

      # reload app for any add/del in the bobs collection, to update the menus
      $scope.$on 'set.bobs', (event, obj, oldObj) ->
        window.location.reload true  if not obj or not oldObj

      # pick up the 'ss-tick' events sent from server/launch
      $scope.tick = '?'
      $scope.$on 'ss-tick', (event, msg) ->
        $scope.tick = msg
  ]
