function AwCtrl($scope, $routeParams, Data, Repo, $resource) {
    window.Repo = Repo;
    $scope.data = Data;
    $scope.currentFile = false;
    $scope.ace = {};
    $scope.openEditors = {};
    $scope.ace.EditSession = require("ace/edit_session").EditSession;

    $scope.data.repo = $routeParams.repo;
    
    // Initialize
    $scope.init = function() {

      // to retrieve a book
       var repo = new Repo();
       repo.get('awestruct.org').then(function(res) {
        $scope.files = res.data;
       });
    };

    $scope.toggleOpen = function(child){
      child.open = !child.open;
      console.log(child.open);
    };

    $scope.addMessage = function(text, type) {
      var message = {text:text, type:type};
      $scope.data.messages.push(message);
    };

    $scope.removeMessage = function(el){
      $scope.data.messages.splice(el.$index,1);
    };

    $scope.edit = function(file) {
      var session;
      // check if new session needs to be created
      if(!!$scope.openEditors[file.path]) {
        session = $scope.openEditors[file.path];
      }
      else {
        session = new $scope.ace.EditSession(file.path);
        $scope.openEditors[file.path] = session;
      }

      $scope.editor.setSession(session);
      $scope.currentFile = file.path;
      $scope.editor.getSession().setMode("ace/mode/markdown");
      $scope.editor.setTheme("ace/theme/github");
      $scope.editor.setShowPrintMargin(false);
    };


    /* Resources */


}
