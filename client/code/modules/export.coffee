# Sandbox module definitions

module.exports = (ng) ->

  ng.controller 'ExportCtrl', [
    '$scope',
    ($scope) ->

      $scope.setSelection = (key) ->
        $scope.selection = key

  ]
