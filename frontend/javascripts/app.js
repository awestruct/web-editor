var aw = angular.module('aw',['ui.ace']);


aw.directive('filespane',function() {
    return  {
        restrict : 'E',
        templateUrl : "partials/filespane.html"
    };
});


// Mock data until we get the backend hooked up

aw.factory('Files', function() {
  return ["one.html","two.html","three.js", "four.js","five.md"];
});

aw.config(function($routeProvider){
  $routeProvider
    .when('/',{
      templateUrl: "partials/layout.html",
      controller : "AwCtrl"
    })
    .when('/edit',{
      template : "Edit!",
      controller : "AwCtrl"
    })
    .otherwise({
      template : "Error"
    });
});




function AwCtrl($scope, Files) {
    
    $scope.currentFile = false;
    
    // Initialize
    $scope.init = function() {
      // go out and get a list of files
      $scope.files = Files;
    };


    $scope.edit = function(file) {
      $scope.currentFile = file;
    };


}