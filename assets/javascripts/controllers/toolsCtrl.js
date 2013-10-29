function ToolsCtrl($scope, Data){
  
  /* Handle Images */
  $scope.handleImages = function(files){
    for (var i = files.length - 1; i >= 0; i--) {

      var name = files[i].name,
          type = files[i].type,
          isValid = type.match(/(?:jpe?g|png|gif)/gi),
          formdata = {};

      if(!isValid) {
        $scope.addMessage("Cannot upload <strong>"+name+"</strong>. Only .jpg, .png, and .gif allowed","alert");
        continue;
      }

      // Put the image placeholder up
      $scope.format('upload-image', name);
      

      var path = $scope.data.repoUrl + "/images/"+name,
          releativePath = "/images/"+name;

      repo.saveImage(path,files[i],function(response){
        console.log(response);
      });

      $scope.$apply();

      $scope.editor.replace('!['+name+']('+encodeURI(releativePath)+')', {
        needle : "![uploading "+name+". . .]()"
      });
      
      $scope.editor.clearSelection();
      

    }
  };

  // Pick an existing Image
  $scope.pickImage = function() {
    repo.getImages($scope.data.repo).then(function(data){
      console.log(data.data.images);
    });
  };
  /* Markdown Editing tools */
  $scope.format = function(method, name, opts) {
    var editor = $scope.editor,
        session = editor.getSession(),
        selection = session.getSelection(),
        range = editor.getSelectionRange(),
        cursor = editor.getCursorPosition(),
        blank = !editor.session.getTextRange(range).length,
        style = markdownMethods[method],
        text = editor.session.getTextRange(range) || style.textDefault,
        newText = name || text,
        diff; // difference between new and original text


    window.editor = editor;

    if(style.search) {
      newText = text.replace(style.search,style.replace);
    }
    else if (style.append) {
     newText = text + style.append;
    }
    else if (method == 'table') {
      newText = text + style.exec(name, opts); // rowCount, colCount
    }
    else if (style.exec) {
      newText = style.exec(text,blank,name);
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


  //  Regex patterns adapted from https://github.com/gollum/gollum/blob/master/lib/gollum/public/gollum/javascript/editor/langs/markdown.js
  var markdownMethods = $scope.markdownMethods = {

    'bold' : {
      search: /([^\n]+)([\n\s]*)/g,
      replace: "**$1**$2",
      textDefault: "bolded text"
    },

    'italic' : {
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
      textDefault : "code block",
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

    'upload-image' : {
      exec: function(text, blank, name) {
        var text = text || "";
        return text+"\n![uploading "+name+". . .]()\n";
      },
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
      replace: "= $1$2",
      blockLevel : true,
      textDefault : "Heading level 1"
    },

    'h2' : {
      search: /(.+)([\n]?)/g,
      replace: "== $1$2",
      blockLevel : true,
      textDefault : "Heading level 2"
    },

    'h3' : {
      search: /(.+)([\n]?)/g,
      replace: "=== $1$2",
      blockLevel : true,
      textDefault : "Heading level 3"
    },

    'h4' : {
      search: /(.+)([\n]?)/g,
      replace: "==== $1$2",
      blockLevel : true,
      textDefault : "Heading level 4"
    },

    'h5' : {
      search: /(.+)([\n]?)/g,
      replace: "===== $1$2",
      blockLevel : true,
      textDefault : "Heading level 5"
    },

    'h6' : {
      search: /(.+)([\n]?)/g,
      replace: "====== $1$2",
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

    'table' : {
      exec : function(rowCount,colCount) {
        // rowCount = 10; colCount = 4;
        // start the table
        var output = "\n|==============================================\n";
        // append the table headings
        for(var x=0; x<colCount;x++){
          output+= "| Col"+parseInt(x+1)+"\t\t";
        }
        // append all the rows
        var rows = new Array(rowCount);
        for(var i=0;i<rowCount;i++) {
          console.log("wat");
          output+= "\n"; // new line
          for(x=0; x<colCount;x++){
            output+= "| \t\t\t";
          }
        }
        // end the table
        output+= "\n|==============================================\n";
        return output;
      },
      textDefault : ""
    }
  };
}