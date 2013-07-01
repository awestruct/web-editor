var aw = angular.module('aw',['ui.ace', 'angular-underscore']);


aw.config(function($routeProvider, $locationProvider){
  $routeProvider
    .when('/',{
      templateUrl: "partials/layout.html",
      controller : "AwCtrl"
    })
    .when('/edit/:fileName',{
      templateUrl: "partials/layout.html",
      controller : "AwCtrl"
    })
    .otherwise({
      template : "Error"
    });
});