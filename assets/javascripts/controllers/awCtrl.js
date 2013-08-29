function AwCtrl($scope, $routeParams, $route,Data, Repo, $resource, $http, $window, Token) {
    
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
    $scope.data.progress = 10;
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
      // First check if we have a token already, if we do, skip it all and setup
      if(window.token) {
        console.log("Token already acquired, no need for a new one.");
        $scope.getSettings();
        return;
      }

      // Then, try and get a token without auth
      $http.get('/token', {})
        .success(function(data, status, headers, config){
          console.log("Got token without auth - ", data);
          window.token = headers().base_token;
          // check and get the settings
          $scope.getSettings();
        })
        .error(function() {
            // We don't have a token yet, so lets login and get one
            console.log("Error getting token");
            $scope.toggleOverlay('login');
        });
    };

    $scope.getSettings = function(){
      $http.get('/settings')
        .success(function(data, status, headers, config){
          console.log("get /settings Successful!");
          // Check if we have a repo
          if(data.repo) {
            $scope.settings = data;
            if(!$routeParams.repo) { // if we dont have any route params, route them!
              window.location = "/#/" + data.repo.split('/').pop();
            }
            // Setup the repo
             repo = new Repo();
             repo.get($scope.data.repo).then(function(res) {
             $scope.files = res.data;
             // trigger a route change to load file if they have come via a permalink
             $scope.handleRouteChange();
            });
          }
          else {
            // $scope.toggleOverlay('settings');
            console.log("There are no settings returned, clone the repo?");
            $scope.toggleOverlay('settings');
          }
        })
        .error(function(data, status, headers, config) {
          // There was an error getting /settings, we must not have a token.. 
          console.log("There was an error getting /settings")
          $scope.toggleOverlay('login');
        });
    }

    $scope.getToken = function(settings) {
      if(settings) {
        var config = {headers:  {
                'Authorization': 'Basic '+btoa(settings.username + ":" + settings.password)  // Base64
            }
        };
      }
      else {
        settings = {};
      }

      $http.get('/token',config)
        .success(function(data, status, headers, config){
          $scope.data.waiting = false;
          $scope.data.overlay = false;
          window.token = headers().base_token;
          console.log("Token returned "+window.token);
          // Try it again, now with the token in place
          $scope.init();
        })
        .error(function(data, status, headers, config) {
          // Find the error code
          alert('Oops, there has been an error. Please check your credentials and try again');
          $scope.data.waiting = false;
        });
    }

    $scope.toggleOverlay = function(overlaytype) {
      $scope.data.overlaytype = overlaytype;
      if(!!overlaytype) {
        $scope.data.overlay = true;
      }
      else {
       $scope.data.progress = 0;
       $scope.data.waiting = false;
       $scope.data.overlay = false; 
      }

    }

    $scope.syncFiles = function(cb) {
      repo.get($scope.data.repo).then(function(res) {
       $scope.files = res.data;
       cb();
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

    $scope.popupMessage = function(message){
      $scope.data.popupmessage = message;
      $scope.toggleOverlay('popupmessage');
    }

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
        $scope.currentSession = session;
        openSession(session,file);
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
              var before = session.dirty;
              session.dirty = true;
              if(!before) {
                $scope.$apply();
              }

            });

            $scope.currentSession = session;
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
              $scope.$apply();
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

      if($scope.repo) {
        var method = "post";
      }
      else {
        var method = "put"
        $scope.data.repo = settings.repo.split('/').pop();
        console.log($scope.data.repo);
      }

      // PUT on init, POST on settings update
      $http[method]('/settings',settings)
        .success(function(response){
          /* Switch Branches */
          console.log("Setting PUT is successfull");
            $scope.change_set(function() {
              $scope.data.waiting = false;
              $scope.data.overlay = false;
              window.location.reload();
            });
        })
        .error(function(data, status, headers, config) {
          // Find the error code
          if(data.length < 140) {
            alert('Oops, there was an error: ' + data);
          }
          else {
            alert('Oops, there has been an error. Please check your credentials and try again');
          }
          $scope.data.waiting = false;
        });
    }

    $scope.commit = function(commitdata) {
  
      $scope.data.waiting = true;
      $http.post('/repo/' + $scope.data.repo + '/commit', commitdata)
        .success(function(data) {
          $scope.data.waiting = false;
          $scope.toggleOverlay('push');
          $scope.data.commitdata = {};
        })
        .error(function(data){
          // console.log(data);
          alert("Oops, there was an error, make sure you have saved changes to commit first.");
          $scope.data.waiting = false;
        });
    }

    $scope.pullLatest = function(overwrite) {
      var data = {};
      data.overwrite = !!overwrite;

      $scope.data.popupmessage = 'Pulling latest from Github...';
      $scope.toggleOverlay('popupmessage');

      $http.post('/repo/' + $scope.data.repo + '/pull_latest', data)
        .success(function(data, headers){
          console.log("Success!", data, headers);
          $scope.data.popupmessage += '<br>&#10003; Successfully pulled and merged latest';
          $scope.data.popupmessage += '<br>Refreshing file list...';
          $scope.toggleOverlay('popupmessage');
          $scope.syncFiles(function() {
            $scope.data.popupmessage += '<br>&#10003; File list refreshed. <br> Finished!';
          });
        })
        .error(function() {
          if(confirm("There are merge conflicts. Press Okay to overwrite any local changes. Press Cancel to return to editing.")) {
            $scope.pullLatest(true);
          }
        })
    }

    $scope.push = function(pushdata) {
      /* Perform commit, push and pull request */
      $scope.data.waiting = true;
      $scope.data.progress = 50;
      /* Start with the commit */
      $http.post('/repo/' + $scope.data.repo + '/commit', { message : pushdata.message })
        .success(function(data) {
          console.log("Commit was successfull")

          /* Move onto the push and pull req */
          $http.post('/repo/' + $scope.data.repo + '/push', pushdata)
            .success(function(data){
              // console.log(data);

              /* Start a fresh branch */
              $scope.change_set(function() {
                $scope.data.progress = 100;
                $scope.data.waiting = false;
                $scope.popupMessage("Success! Your pull request is accessible at <a target='_blank' href='"+data+"'>"+data+"</a>");
              });
            })
            .error(function(data){
              console.log(data);
              $scope.data.waiting = false;
              alert("Error");
            });
        })
        .error(function(data){
          // console.log(data);
          alert("Oops, there was an error commiting your data, make sure you have saved changes to commit first.");
          $scope.data.waiting = false;
        });
  
    }

    $scope.change_set = function(callback){
      var dateObj = new Date()
          , month = dateObj.getUTCMonth()
          , day = dateObj.getUTCDate()
          , year = dateObj.getUTCFullYear()
          , timestamp = dateObj.getTime();

      var name = "changeset-"+ year + "-" + month + "-" + day + "-" + timestamp;

      $http.post('/repo/' + $scope.data.repo + '/change_set', { name : name })
        .success(function(data){
          console.log("Changed Branch!");
          callback();
        })
        .error(function(data){
          alert("Error, unable to change to changeset branch "+ name);
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
        console.log("Editing File...");
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
}