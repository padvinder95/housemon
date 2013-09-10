ng = angular.module 'myApp', [
  'ui.router'
  'ng-primus'
  'admin'
  'rpc'
]

ng.value 'version', '0.1'

ng.provider 'navbar', ->
  navs = []
  add: (title, route, weight = 50) ->
    navs.push { title, route, weight }
  $get: ->
    navs.sort (a, b) -> a.weight - b.weight
  
ng.config ($urlRouterProvider, $locationProvider) ->
  $urlRouterProvider.otherwise '/'
  $locationProvider.html5Mode true
  
ng.controller 'NavCtrl', ($scope, navbar) ->
  $scope.navbar = navbar

ng.directive 'appVersion', (version) ->
  (scope, elm, attrs) ->
    elm.text version
