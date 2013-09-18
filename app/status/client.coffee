ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'status',
    url: '/status'
    templateUrl: 'status/view.html'
    controller: 'Status'
  navbarProvider.add '/status', 'Status', 61

ng.controller 'Status', ($scope, primus, host) ->
  host('status_driverinfo').then (info) ->

    # FIXME: this may get called a bit too often, memoise?
    lookup = (row) ->
      out = info[row.type]?.out
      # If out is an array, then lookup via tag (without optional '-' suffix)
      if out? and Array.isArray out
        subtype = row.tag.replace /-.*/, ''
        out = info[row.type]?[subtype]
      out?[row.name] ? {}

    $scope.status = primus.live $scope, 'status', (row) ->
      rowInfo = lookup row

      row.title = rowInfo.title
      row.unit = rowInfo.unit
      row.origVal = row.value

      if rowInfo.factor
        row.value *= rowInfo.factor
      if rowInfo.scale < 0
        row.value *= Math.pow 10, -rowInfo.scale
      else if rowInfo.scale >= 0
        row.value /= Math.pow 10, rowInfo.scale
        row.value = row.value.toFixed rowInfo.scale

ng.directive 'highlightOnChange', ($animate) ->
  link: (scope, elem, attrs) ->
    attrs.$observe 'highlightOnChange', ->
      $animate.addClass elem, 'highlight', ->
        $animate.removeClass elem, 'highlight'
