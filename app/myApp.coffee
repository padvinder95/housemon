# Limited context during startup: Angular modules and Primus not yet loaded
console.log 'MYAPP'

ng = angular.module 'myApp', ['ui.router']

ng.value 'appInfo',
  name: 'HouseMon'
  version: '0.8.0'
  home: 'https://github.com/jcw/housemon'

ng.provider 'navbar', ->
  navs = []
  add: (route, title, weight = 50) ->
    navs.push { route, title, weight }
  del: (route) ->
    navs = navs.filter (x) -> x.route isnt route
  $get: ->
    navs.sort (a, b) -> a.weight - b.weight
  
ng.config ($urlRouterProvider, $locationProvider) ->
  $urlRouterProvider.otherwise '/'
  $locationProvider.html5Mode true
  
ng.run ($rootScope, appInfo) ->
  $rootScope.appInfo = appInfo
  
ng.controller 'NavCtrl', ($scope, navbar) ->
  $scope.navbar = navbar

ng.directive 'appVersion', (appInfo) ->
  (scope, elm, attrs) ->
    elm.text appInfo.version
