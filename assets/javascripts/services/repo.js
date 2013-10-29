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
    path = path.replace('./',''); // fix root level files
    return $http.post(path,{content:content});
  };

  Repo.prototype.getImages = function(repo) {
    return $http.get('/repo/' + repo + '?allow=jpg').then(function(response) {
      return new Repo(response);
    });
  };

  Repo.prototype.saveImage = function(path,file, callback) {
    // Using XHR request as angular's databinding isn't great for image uploads
    var fd = new FormData(),
        xhr = new XMLHttpRequest();
    
    fd.append("content", file);
    fd.append("binary", true);


    // Set auth headers, we usually do this on $http, but since we are
    // stepping outside $http, we need to do it here
    var token = window.token,
        time = new Date().getTime().toString().substring(0,8)
        shaObj = new jsSHA(token + "" + time, "TEXT"),
        hash = shaObj.getHash("SHA-512", "HEX");

    xhr.open("POST", path);
    xhr.setRequestHeader("token", hash);
    xhr.setRequestHeader("time",time);
    xhr.addEventListener("load", callback, false);
    xhr.send(fd);
  };


  return Repo;
});