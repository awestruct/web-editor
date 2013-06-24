var aw = angular.module('aw',['ui.ace', 'angular-underscore']);

aw.factory('Editor',function() {
  return {};
});

// Mock data until we get the backend hooked up
aw.factory('Files', function() {
  return {
  "sha": "master",
  "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/trees/master",
  "tree": [{"mode": "100644", "type": "blob", "sha": "e1eba573a6ef99f28464f7e7a19a9691279b824b", "path": "index.html", "size": 553, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/e1eba573a6ef99f28464f7e7a19a9691279b824b"}, {"mode": "040000", "type": "tree", "sha": "e503dd32ff70ced237d59a64a599555eaf7eefb7", "path": "js", "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/trees/e503dd32ff70ced237d59a64a599555eaf7eefb7"}, {"mode": "100644", "type": "blob", "sha": "30775691bfdc4f33332a158d8e967463504a1c7a", "path": "js/jquery.event.drag-2.0.js", "size": 12830, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/30775691bfdc4f33332a158d8e967463504a1c7a"}, {"mode": "100644", "type": "blob", "sha": "f3cb29be1b0adbe2005be1ef7c6f3128f7a3e479", "path": "readme", "size": 3, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/f3cb29be1b0adbe2005be1ef7c6f3128f7a3e479"}, {"mode": "100644", "type": "blob", "sha": "55f53c148abb9e448cd3b55b5a3fe5d0e436603e", "path": "scripts.coffee", "size": 1274, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/55f53c148abb9e448cd3b55b5a3fe5d0e436603e"}, {"mode": "100644", "type": "blob", "sha": "58ac95b87eeb28d05b2b3290d8fc4a4711ca33d8", "path": "scripts.js", "size": 1363, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/58ac95b87eeb28d05b2b3290d8fc4a4711ca33d8"}, {"mode": "100644", "type": "blob", "sha": "5384f273859cd1af155bb7ceb772c30c039eda48", "path": "server.js", "size": 298, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/5384f273859cd1af155bb7ceb772c30c039eda48"}, {"mode": "100644", "type": "blob", "sha": "ecb9266044a05bb0b7211713324ce0a2dbc1a29a", "path": "style.css", "size": 1093, "url": "https://api.github.com/repos/wesbos/websocket-canvas-draw/git/blobs/ecb9266044a05bb0b7211713324ce0a2dbc1a29a"} ] };
});

aw.config(function($routeProvider, $locationProvider){

  $routeProvider
    .when('/',{
      templateUrl: "partials/layout.html",
      controller : "AwCtrl"
    })
    .when('/edit/:fileName',{
      templateUrl: "partials/layout.html",
      controller : "AwCtrl"
    })
    .otherwise({
      template : "Error"
    });
});




function AwCtrl($scope, $routeParams, Files, Editor) {

    $scope.currentFile = false;
    $scope.ace = {};
    $scope.openEditors = {};
    $scope.ace.EditSession = require("ace/edit_session").EditSession;

    
    // Initialize
    $scope.init = function() {
      // go out and get a list of files
      $scope.files = Files;
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
    };

}

function ToolsCtrl($scope, Files){
  
  $scope.format = function(method) {
    var editor = $scope.editor,
        session = editor.getSession(),
        selection = session.getSelection(),
        range = editor.getSelectionRange(),
        cursor = editor.getCursorPosition(),
        blank = !editor.session.getTextRange(range).length,
        style = markdownMethods[method],
        text = editor.session.getTextRange(range) || style.textDefault,
        newText = text,
        diff; // difference between new and original text


    window.editor = editor;
    if(style.search) {
      newText = text.replace(style.search,style.replace);
    }
    else if (style.append) {
     console.info("Appending...");
     newText = text + style.append;
    }
    else if (style.exec) {
      console.info("Custom function...");
      newText = style.exec(text,blank);
    }
    else {
      throw "Formatting method '"+method+"'is not defined!";
    }

    // Some elements should start on a new line when they aren't
    if(blank && style.blockLevel && cursor.column) {
      newText = "\n" + newText;
    }

    // Replace the text
    editor.session.replace(range,newText);
    editor.focus();

    // Select what we just did
    if(blank) {
      editor.findPrevious(style.textDefault);
    }
    else {
      editor.findPrevious(text);
    }
  };


  //  Regex patterns modifed from https://github.com/gollum/gollum/blob/master/lib/gollum/public/gollum/javascript/editor/langs/markdown.js
  var markdownMethods = $scope.markdownMethods = {
    'strong' : {
      search: /([^\n]+)([\n\s]*)/g,
      replace: "**$1**$2",
      textDefault: "bolded text"
    },

    'emphasis' : {
      search: /([^\n]+)([\n\s]*)/g,
      replace: "_$1_$2",
      textDefault : "This text has emphasis"
    },

    'code-inline' : {
      search: /([^\n]+)([\n\s]*)/g,
      replace: "`$1`$2",
      textDefault : "code goes here"
    },

    'code-block' : {
      search: /([^\n]+)([\n\s]*)/g,
      replace: "```\n$1$2\n```\n",
      textDefault : "java",
      blockLevel : true
    },

    'hr' : {
      append: "\n***\n",
      textDefault : "",
      blockLevel: true
    },

    'ul' : {
      search: /(.+)([\n]?)/g,
      replace: "* $1$2",
      textDefault : "unordered list",
      blockLevel : true
    },

    'ol' : {
      exec: function(text, blank) {
        var count = 1;
        // split into lines
        var repText = '';
        var lines = text.split("\n") || " ";
        var hasContent = /[\w]+/;
        for ( var i = 0; i < lines.length; i++ ) {
          if ( hasContent.test(lines[i]) ) {
            repText += (i + 1).toString() + '. ' +
            lines[i] + "\n";
          }
          else {
            // bank string, start a new list
            repText += (i + 1).toString() + ". ";
          }
        }
        return repText;
      },
      textDefault : "ordered list",
      blockLevel : true
    },

    'blockquote' : {
      search: /(.+)([\n]?)/g,
      replace: "> $1$2",
      blockLevel : true,
      textDefault : "quote"
    },

    'h1' : {
      search: /(.+)([\n]?)/g,
      replace: "# $1$2",
      blockLevel : true,
      textDefault : "Heading level 1"
    },

    'h2' : {
      search: /(.+)([\n]?)/g,
      replace: "## $1$2",
      blockLevel : true,
      textDefault : "Heading level 2"
    },

    'h3' : {
      search: /(.+)([\n]?)/g,
      replace: "### $1$2",
      blockLevel : true,
      textDefault : "Heading level 3"
    },

    'h4' : {
      search: /(.+)([\n]?)/g,
      replace: "#### $1$2",
      blockLevel : true,
      textDefault : "Heading level 4"
    },

    'h5' : {
      search: /(.+)([\n]?)/g,
      replace: "##### $1$2",
      blockLevel : true,
      textDefault : "Heading level 5"
    },

    'h6' : {
      search: /(.+)([\n]?)/g,
      replace: "###### $1$2",
      blockLevel : true,
      textDefault : "Heading level 6"
    },

    'link' : {
      exec : function(text,blank) {
        url = text;
        if(blank) {
          text = "link title";
          url = "http://";
        }
        return "["+text +"]("+url+")";
      },
      textDefault : "http://"
    },

    'image'      :   {
      exec: function( txt, selText, $field ) {
        var results = null;
        $.GollumEditor.Dialog.init({
          title: 'Insert Image',
          fields: [
          {
            id: 'url',
            name: 'Image URL',
            type: 'text'
          },
          {
            id: 'alt',
            name: 'Alt Text',
            type: 'text'
          }
          ],
          OK: function( res ) {
            var rep = '';
            if ( res['url'] && res['alt'] ) {
              rep = '![' + res['alt'] + ']' +
              '(' + res['url'] + ')';
            }
            $.GollumEditor.replaceSelection( rep );
          }
        });
      }
    }
  

  };

}