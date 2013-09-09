ng = angular.module 'admin', []

ng.config ($stateProvider) ->
  $stateProvider
    .state 'admin',
      url: '/admin'
      templateUrl: 'admin/view.html'
      controller: 'AdminCtrl'

ng.controller 'AdminCtrl', ($scope) ->
  $scope.hello = 'bonjour'
