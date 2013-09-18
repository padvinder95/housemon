ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'status',
    url: '/status'
    templateUrl: 'status/view.html'
    controller: 'Status'
  navbarProvider.add '/status', 'Status', 61

ng.controller 'Status', ($scope, primus) ->
  $scope.status = {}

  primus.write ['live', 'status']
  $scope.$on 'live.status', (event, type, value) ->
    switch type
      when 'put'
        $scope.status[value.key] = value
      when 'del'
        delete $scope.status[value]
