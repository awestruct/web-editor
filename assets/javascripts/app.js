var aw = angular.module('aw',['ui.ace', 'angular-underscore', 'ngResource']);


aw.config(function($routeProvider, $locationProvider){
  $routeProvider
    .when('/',{
      templateUrl: "partials/layout.html",
      controller : "AwCtrl"
    })
    .when('/:repo',{
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