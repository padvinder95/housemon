# Home module definitions

module.exports = (ng) ->

  ng.controller 'DashCtrl', [
    '$scope',
    ($scope) ->
      $scope.foo = 'bar'
  ]
