ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'status',
    url: '/status'
    templateUrl: 'status/view.html'
    controller: 'Status'
  navbarProvider.add '/status', 'Status', 61

ng.controller 'Status', ($scope, primus) ->
  $scope.status = primus.live $scope, 'status'
