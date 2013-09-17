ng = angular.module 'myApp'

ng.config ($stateProvider) ->
  $stateProvider.state 'admin',
    url: '/admin'
    templateUrl: 'admin/view.html'
    controller: 'AdminCtrl'

ng.controller 'AdminCtrl', ($scope, host) ->
  $scope.hello = host 'admin_dbinfo'
