ng = angular.module 'view2', []

ng.config [
  '$stateProvider',
  ($stateProvider) ->
    $stateProvider
      .state 'view2',
        url: '/view2'
        templateUrl: 'view2/view.html'
        controller: 'MyCtrl2'
]

ng.run [
  ->
    primus.api.twice = (x) -> 2 * x
]

ng.controller 'MyCtrl2', [
  '$q', '$scope', 'rpc',
  ($q, $scope, rpc) ->
    deferred = $q.defer()
    rpc.invoke('next')
      .then (res) ->
        deferred.resolve res
    $scope.counter = deferred.promise
]

ng.filter 'interpolate', [
  'version',
  (version) ->
    (text) ->
      String(text).replace '%VERSION%', version
]

ng.value 'version', '0.1'
