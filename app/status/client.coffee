ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'status',
    url: '/status'
    templateUrl: 'status/view.html'
    controller: 'Status'
  navbarProvider.add '/status', 'Status', 61

ng.controller 'Status', ($scope, primus, host) ->
  info = {}

  host('status_driverinfo').then (result) ->
    info = result
    $scope.status = primus.live $scope, 'status'

  $scope.lookup = (row) ->
    info[row.type]?.out?[row.name] ? {}

ng.factory 'driverInfo', (host) ->
