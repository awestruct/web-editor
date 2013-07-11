aw.factory('Repo', function($http) {

  // Repo is a class which we can use for retrieving and 
  // updating data on the server
  var Repo = function(data) {
    angular.extend(this, data);
  };

  // an instance method to retrieve Repo by ID
  Repo.prototype.get = function(repo) {
    return $http.get('/repo/' + repo).then(function(response) {
      return new Repo(response);
    });
  };

  Repo.prototype.getFile = function(path) {
    return $http.get(path).then(function(response) {
      return response;
    });
  };

  Repo.prototype.saveFile = function(path,content) {
    return $http.post(path,{content:content});
  };

  Repo.prototype.saveImage = function(path,file, callback) {
    // Using XHR request as angular's databinding isn't great for image uplods
    var fd = new FormData(),
        xhr = new XMLHttpRequest();
    
    fd.append("content", file);
    fd.append("binary", true);

    xhr.addEventListener("load", callback, false);
    xhr.open("POST", path);
    xhr.send(fd);
  };


  return Repo;
});