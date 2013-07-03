/* Save directive */
aw.directive('keyboardshortcut',function(){
  return {
    restrict : "A",
    link : function(scope,elem,attrs){
      
      var lastkey;
      elem.bind('keydown',function(e){
        console.log(scope);
        if(lastkey == 91 && e.keyCode == 83) {
          console.log(scope.currentFile);
          e.preventDefault();
          // save(currentFile);
        }
        lastkey = e.keyCode;
      });
    }
  };
});