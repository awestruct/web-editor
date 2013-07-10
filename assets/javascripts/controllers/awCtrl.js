function AwCtrl($scope, $routeParams, $route,Data, Repo, $resource, $http, $window) {
    
    window.Repo = Repo;
    window.scope = $scope;

    window.onbeforeunload = function(e){
      var currPath = $scope.currentFile.links[0].url,
          currSession = $scope.openEditors[currPath];
      if (currSession.dirty) {
        return "You have unsaved changes, are you sure you want to leave?";
      }
    };

    $scope.data = Data;
    $scope.currentFile = false;
    $scope.ace = {};
    $scope.openEditors = {};
    $scope.ace.EditSession = require("ace/edit_session").EditSession;
    $scope.data.repo = $routeParams.repo;
    $scope.data.repoUrl= window.location.origin + "/repo/" + $routeParams.repo;

    /*
      Handle Location Changes
    */
    $scope.$on('$locationChangeSuccess', function(event) {
      $scope.handleRouteChange();
    });


    /*
      Initialize the repo
      Note: This is only called once per full page load
    */
    $scope.init = function() {
      // check and get the settings
      $http.get('/settings')
        .success(function(data, status, headers, config){
          console.log(data, status, headers, config);
        })
        .error(function(data, status, headers, config) {
          // There was an error, lets show the init screen
          // $scope.data.overlay = true;
        });

      // to retrieve a book
       repo = new Repo();
       repo.get($scope.data.repo).then(function(res) {
        $scope.files = res.data;
        // trigger a route change to load file if they have come via a permalink
        $scope.handleRouteChange();
       });

    };

    $scope.syncFiles = function() {
      repo.get($scope.data.repo).then(function(res) {
       $scope.files = res.data;
      });      
    };

    $scope.toggleOpen = function(child){
      child.open = !child.open;
    };

    $scope.addMessage = function(text, type) {
      var message = {text:text, type:type};
      $scope.data.messages.push(message);
    };

    $scope.removeMessage = function(el){
      $scope.data.messages.splice(el.$index,1);
    };

    $scope.edit = function(file) {
        var path = file.links[0].url,
        session;
      
      // Make sure we aren't abandoning the current changes
      if($scope.currentFile) {
        var currPath = $scope.currentFile.links[0].url,
            currSession = $scope.openEditors[currPath];
        if (currSession.dirty) {
          $scope.addMessage("Oops, You must save the current file to continue", "alert");
          return;
        }
      }

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
            console.log(response);
            $scope.data.saving = false;
            session.dirty = false;
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
          console.log(response);
          if(response) {
            $scope.syncFiles();
          }
        });
      }
    };

    $scope.saveSettings = function(settings) {
      console.log(settings);
      // PUT on init, POST on settings update
      $http.post('/settings',settings).then(function(response){
        console.log(response);
      });
    }

    $scope.handleRouteChange = function() {
      var file = _.findDeep($scope.files,{path:$routeParams.path});
      if(!file) {
        // nothing found, try it as a top level file
        file = _.findDeep($scope.files,{path:"./"+$routeParams.path});
      }
      if(file){
        $scope.edit(file);
      }
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
