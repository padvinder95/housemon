ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider
    .state 'readings',
      url: '/readings'
      templateUrl: 'readings/view.html'
      controller: 'ReadingsCtrl'
  navbarProvider.add '/readings', 'Readings', 60

ng.controller 'ReadingsCtrl', ->
