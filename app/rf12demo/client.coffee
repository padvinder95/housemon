ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'rf12demo',
      url: '/rf12demo'
      templateUrl: 'rf12demo/view.html'
      controller: 'RF12demoCtrl'
  navbarProvider.add '/rf12demo', 'RF12demo'

ng.controller 'RF12demoCtrl', ->
