function AwCtrl($scope, $routeParams, $route,Data, Repo, $resource, $http, $window) {
    
    // window.Repo = Repo;
    window.scope = $scope;

    window.onbeforeunload = function(e){
      var currPath = $scope.currentFile.links[0].url,
          currSession = $scope.openEditors[currPath];
      if (currSession.dirty) {
        return "You have unsaved changes, are you sure you want to leave?";
      }
    };

    $scope.data = Data;
    $scope.data.folderState = {}; // record folder open/closed state
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
          if(data.repo) {
            $scope.settings = data;

            if(!$routeParams.repo) { // if we dont have any route params, route them!
              window.location = "/#/" + data.repo.split('/').pop();
            }
          }
          else {
            $scope.toggleOverlay('settings');
          }
        })
        .error(function(data, status, headers, config) {
          // There was an error, lets show the init screen
          $scope.data.overlay = true;
        });

       repo = new Repo();
       repo.get($scope.data.repo).then(function(res) {
        $scope.files = res.data;
        // trigger a route change to load file if they have come via a permalink
        $scope.handleRouteChange();
       });

    };

    $scope.toggleOverlay = function(overlaytype) {
      $scope.data.overlaytype = overlaytype;
      $scope.data.overlay = !$scope.data.overlay;
    }

    $scope.syncFiles = function() {
      repo.get($scope.data.repo).then(function(res) {
       $scope.files = res.data;
      });      
    };

    $scope.toggleOpen = function(child){
      $scope.data.folderState[child.path] = !$scope.data.folderState[child.path];
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
          repo.saveFile(path, content)
            .success(function(response){            
              $scope.data.saving = false;
              session.dirty = false;
              if($scope.previewWindow) {
                $scope.previewWindow.document.write(response);
              }
          })
          .error(function(){
            // not really an error, this means it saved but has not
            // returned a compiled file for preview. 
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

      if(fileName) {
        repo.saveFile(path, "").always(function(response) {
            $scope.syncFiles();
        });
      }
    };

    $scope.saveSettings = function(settings) {
      $scope.data.waiting = true;
      // PUT on init, POST on settings update
      $http.put('/settings',settings)
        .success(function(response){
          $scope.data.waiting = false;
          $scope.overlay = false;
          window.location.reload();
        })
        .error(function(data, status, headers, config) {          
          // Find the error code
          alert('Oops, there has been an error. Please check your credentials and try again');
          $scope.data.waiting = false;
        });
    }

    $scope.commit = function(commitdata) {
  
      $scope.data.waiting = true;
      $http.post('/repo/' + $scope.data.repo + '/commit', commitdata)
        .success(function(data) {
          console.log(data);
          $scope.data.waiting = false;
          $scope.data.commitdata = {};
        })
        .error(function(data){
          // console.log(data);
          $scope.data.waiting = false;
        });
    }

    $scope.push = function(pushdata) {
      /* Perform push and pull request */
      console.log(pushdata);
      $http.post('/repo/' + $scope.data.repo + '/push', pushdata)
        .success(function(data){
          console.log(data);
          alert("Success, check the console for the message. This will not be an alert box for long");
        })
        .error(function(data){
          console.log(data);
          alert("error, check the console for the message. This will not be an alert box for long");
        })
    }

    $scope.handleRouteChange = function() {
    
      if(!$routeParams.path) {
        return; // no routes
      }
      var file = _.findDeep($scope.files,{path:$routeParams.path});

      if(!file) {
        // nothing found, try it as a top level file
        file = _.findDeep($scope.files,{path:"./"+$routeParams.path});
      }
      if(file){
        $scope.edit(file);
      }
    }

    $scope.preview = function() {
      if(!$scope.previewWindow) {
        $scope.previewWindow = window.open('/#/preview');
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
