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
    out = info[row.type]?.out
    # If out is an array, the we must use the tag (without optional '-' suffix)
    if out? and Array.isArray out
      out = info[row.type]?[row.tag.replace /-.*/, '']
    out?[row.name] ? {}

  $scope.niceValue = (row) ->
    {scale,factor} = info[row.type]?.out?[row.name] ? {}

    value = row.value
    if factor
      value *= factor
    if scale < 0
      value *= Math.pow 10, -scale
    else if scale >= 0
      value /= Math.pow 10, scale
      value = value.toFixed scale
    value

ng.factory 'driverInfo', (host) ->
