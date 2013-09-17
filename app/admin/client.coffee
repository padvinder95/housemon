ng = angular.module 'myApp'

ng.config ($stateProvider) ->
  $stateProvider
    .state 'admin',
      url: '/admin'
      templateUrl: 'admin/view.html'
      controller: 'AdminCtrl'

ng.controller 'AdminCtrl', ($scope, rpc) ->
  $scope.hello = rpc 'admin_dbinfo'
