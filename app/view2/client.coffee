ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'view2',
      url: '/view2'
      templateUrl: 'view2/view.html'
      controller: 'View2Ctrl'
  navbarProvider.add '/view2', 'View2', 12

ng.run ->
  primus.api.twice = (x) -> 2 * x

ng.controller 'View2Ctrl', ($q, $scope, rpc) ->
  deferred = $q.defer()
  rpc.invoke('next')
    .then (res) ->
      deferred.resolve res
  $scope.counter = deferred.promise

ng.filter 'interpolate', (appInfo) ->
  (text) ->
    String(text).replace '%VERSION%', appInfo.version
