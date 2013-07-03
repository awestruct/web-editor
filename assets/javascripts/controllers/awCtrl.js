function AwCtrl($scope, $routeParams, Data, Repo, $resource, $http) {
    
    window.Repo = Repo;
    window.scope = $scope;
    $scope.data = Data;
    $scope.currentFile = false;
    $scope.ace = {};
    $scope.openEditors = {};
    $scope.ace.EditSession = require("ace/edit_session").EditSession;

    $scope.data.repo = $routeParams.repo;
    $scope.data.repoUrl= window.location.origin + "/repo/" + $routeParams.repo;
    
    // Initialize
    $scope.init = function() {
      // to retrieve a book
       repo = new Repo();
       repo.get($scope.data.repo).then(function(res) {
        $scope.files = res.data;
       });
    };

    $scope.syncFiles = function() {
      repo.get($scope.data.repo).then(function(res) {
       console.log(res);
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
      var file = JSON.parse(file),
          path = file.links[0].url,
          session;
      
      // check if new session needs to be created
      if(!!$scope.openEditors[path]) {
        session = $scope.openEditors[path];
        $scope.currentFile = file;
        openSession(session,file);
        console.log("Opening existing session");
      }
      else {
        // goahead and grab the file
        console.log("Creating new session");
        repo.getFile(path)
          .then(function(response, status, headers, config){
            // check for errors
            if(response.status != 200) {
              $scope.addMessage("Error","alert");
              return;
            }
            
            // go ahead and create the session
            content = response.data.content;
            session = new $scope.ace.EditSession(content);
            session.setUndoManager(new ace.UndoManager());
            $scope.openEditors[path] = session;
            
            //  bind to change events
            session.on("change",function() {
              session.dirty = true;
            });

            openSession(session,file);
          });
      }


    };

    $scope.save = function(currentFile) {
      var session = $scope.editor.getSession(),
          content = $scope.editor.getValue(),
          path = currentFile.links[0].url;
          $scope.data.saving = true;
          repo.saveFile(path, content).then(function(response){
            $scope.data.saving = false;
          });
    };

    $scope.showTools = function(currentMode) {
      return currentMode && !!currentMode.match(/markdown|asciidoc/gi);
    };

    $scope.addFile = function(child) {
      var fileName = prompt("Please enter the file name, including the extension"),
          path = $scope.data.repoUrl + "/" + child.path.replace("./","") + "/" + fileName;

          console.log(child.path);

      if(fileName) {
        repo.saveFile(path, "").then(function(response) {
          if(response) {
            $scope.syncFiles();
          }
        });
      }
    };

    $scope.path = function(child) {
      console.log(child);
    }

    openSession = function(session,file) {
      var mode = findMode(file.links[0].url);
      $scope.currentFile = file;
      $scope.currentMode = mode;
      $scope.editor.setSession(session);
      $scope.editor.getSession().setMode("ace/mode/"+mode);
      $scope.editor.setTheme("ace/theme/github");
      $scope.editor.setShowPrintMargin(false);
    };

    findMode = function(filename) {
      var extension = filename.split('.').pop(),
          mode = "text"; // default

      extensions = {
        'markdown' : /md|markdown$/gi,
        'asciidoc' : /ad|asciidoc|adoc$/gi,
        'image' : /jpe?g|png|gif|webm$/gi,
        'html' : /html?$/gi,
        'less' : /less$/gi,
        'sass' : /sass|scss$/gi,
        'css' : /css$/gi,
        'coffee' : /coffee$/gi,
        'javascript' : /js$/gi,
        'text' : /te?xt$/gi,
        'haml' : /haml$/gi,
        'stylus' : /stylus|slim$/gi,
        'diff' : /diff$/gi,
        'ruby' : /lock|rakefile|gemfile/gi
      };

      _.each(extensions,function(i,name) {
        if(extension.match(extensions[name])) {
          mode = name;
        }
        });
      return mode;
    };




    /* Resources */


}
