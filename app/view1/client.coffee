ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider) ->
  $stateProvider.state 'view1',
    url: '/'
    templateUrl: 'view1/view.html'
    controller: 'View1Ctrl'
  navbarProvider.add '/', 'View1', 11
  
  primus.rpc.view1_twice = (x) ->
    2 * x

ng.controller 'View1Ctrl', ->
