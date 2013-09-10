ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'rf12demo',
      url: '/rf12demo'
      templateUrl: 'rf12demo/view.html'
      controller: 'rf12demoCtrl'
  navbarProvider.add 'RF12demo', '/rf12demo'

ng.controller 'rf12demoCtrl', ->
