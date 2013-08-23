var aw = angular.module('aw',['ui.ace', 'angular-underscore', 'ngResource'],function($httpProvider) {
  
  // Custom headers for authentication 
  function getCookie(name) {
    var parts = document.cookie.split(name + "=");
    if (parts.length == 2) return parts.pop().split(";").shift();
  }

  $httpProvider.defaults.headers.common['token'] = function() {
    var token = getCookie('token'),
        time = new Date().toISOString(),
        shaObj = new jsSHA(token + "" + time, "TEXT");
    return shaObj.getHash("SHA-512", "HEX");
  }

  $httpProvider.defaults.headers.common['time'] = function() {
    return new Date().toISOString();
  };

  // Use x-www-form-urlencoded Content-Type
 $httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8';

 // Override $http service's default transformRequest
 $httpProvider.defaults.transformRequest = [function(data) {
   /**
    * The workhorse; converts an object to x-www-form-urlencoded serialization.
    * @param {Object} obj
    * @return {String}
    */ 
   var param = function(obj) {
     var query = '';
     var name, value, fullSubName, subName, subValue, innerObj, i;
     
     for(name in obj) {
       value = obj[name];
       
       if(value instanceof Array) {
         for(i=0; i<value.length; ++i) {
           subValue = value[i];
           fullSubName = name + '[' + i + ']';
           innerObj = {};
           innerObj[fullSubName] = subValue;
           query += param(innerObj) + '&';
         }
       }
       else if(value instanceof Object) {
         for(subName in value) {
           subValue = value[subName];
           fullSubName = name + '[' + subName + ']';
           innerObj = {};
           innerObj[fullSubName] = subValue;
           query += param(innerObj) + '&';
         }
       }
       else if(value !== undefined && value !== null) {
         query += encodeURIComponent(name) + '=' + encodeURIComponent(value) + '&';
       }
     }
     
     return query.length ? query.substr(0, query.length - 1) : query;
   };
   
   return angular.isObject(data) && String(data) !== '[object File]' ? param(data) : data;
 }];
});


aw.config(function($routeProvider, $locationProvider){
  
  $routeProvider
    .when('/',{
      templateUrl: "partials/layout.html",
      reloadOnSearch : false,
      controller : "AwCtrl"
    })
    .when('/preview',{
      template: "<div class='previewHolder'>Save a file to initialize preview</div>",
      reloadOnSearch : false
    })
    .when('/:repo',{
      templateUrl: "partials/layout.html",
      reloadOnSearch : false,
      controller : "AwCtrl"      
    })
    .when('/:repo/*filepath',{
      templateUrl: "partials/layout.html",
      reloadOnSearch : false,
      controller : "AwCtrl"      
    })
    .otherwise({
      template : "Error"
    });
});