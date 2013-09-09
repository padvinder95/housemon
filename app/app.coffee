ng = angular.module 'myApp', [
  'ui.router'
  'ng-primus'
  'admin'
  'view1'
  'view2'
  'rf12demo'
  'rpc'
]
  
ng.config ($stateProvider, $urlRouterProvider, $locationProvider) ->
  $urlRouterProvider.otherwise '/'
  $locationProvider.html5Mode true

ng.directive 'appVersion', (version) ->
  (scope, elm, attrs) ->
    elm.text version
