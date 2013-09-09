ng = angular.module 'rf12demo', []

ng.config ($stateProvider) ->
  $stateProvider
    .state 'rf12demo',
      url: '/rf12demo'
      templateUrl: 'rf12demo/view.html'
      controller: 'rf12demoCtrl'

ng.controller 'rf12demoCtrl', ->
