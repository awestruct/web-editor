aw.factory('Repo', function($http) {
  // Repo is a class which we can use for retrieving and 
  // updating data on the server
  var Repo = function(data) {
    angular.extend(this, data);
  };

  // a static method to retrieve Repo by ID
  Repo.prototype.get = function(repo) {
    return $http.get('/repo/' + repo).then(function(response) {
      return new Repo(response);
    });
  };

  Repo.prototype.getFile = function(path) {
    return $http.get(path).then(function(response) {
      return response;
    });
  }

  // an instance method to create a new Repo
  // Repo.prototype.create = function() {
  //   var book = this;
  //   return $http.post('/Book/', book).then(function(response) {
  //     book.id = response.data.id;
  //     return book;
  //   });
  // };

  return Repo;
});