function ScratchpadCtrl($scope, Data, $http){
  var editor = $scope.scratchpad,
      scriptsLoaded = false;

  $scope.aceChanged = function(e) {
    var text = $scope.scratchpad.getValue();
    var html = Opal.Asciidoctor.$render(text);
    document.querySelector('.scratchpad-preview').innerHTML = html;
  };

  // Because Asciidoctor.js and opal.js are so large, we will load them on demand
  $scope.loadScripts = function(callback) {
    if(scriptsLoaded) { return; } // only load once
    scriptsLoaded = true;

    // Load Opal /assets/vendor/opal.js
    loadJS('/assets/vendor/opal.js',function() {
      // console.log("Opload Loaded.");
    });

    loadJS('/assets/vendor/asciidoctor.js',function() {
      // console.log("Asciidoctor Loaded.");
      $http.get('/partials/asciidoc.html').then(function(res){
        var adoc = res.data.replace(/<br \/>/gi,'\n');
        $scope.scratchpad.getSession().setValue(adoc);
        $scope.aceChanged();
      });
    });

    // setup the editor
    $scope.scratchpad.setShowPrintMargin(false);
    $scope.scratchpad.setTheme("ace/theme/github");
    $scope.scratchpad.getSession().setMode("ace/mode/asciidoc");


    
    window.s =$scope.scratchpad;
    // $scope.scratchpad.edit("testing 123");
  }

  function loadJS(scriptPath, callback) {
      var scriptNode = document.createElement('script');
      scriptNode.type = 'text/javascript';
      scriptNode.src = scriptPath;

      var headNode = document.getElementsByTagName('head');
      if (headNode[0] != null)
          headNode[0].appendChild(scriptNode);

      if (callback != null) {
          scriptNode.onreadystagechange = callback;            
          scriptNode.onload = callback;
      }
  }
}