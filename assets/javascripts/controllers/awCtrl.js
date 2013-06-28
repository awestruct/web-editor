function AwCtrl($scope, $routeParams, Files, Data) {
    $scope.data = Data;
    $scope.currentFile = false;
    $scope.ace = {};
    $scope.openEditors = {};
    $scope.ace.EditSession = require("ace/edit_session").EditSession;

    
    // Initialize
    $scope.init = function() {
      // go out and get a list of files
      $scope.files = Files;
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

}
