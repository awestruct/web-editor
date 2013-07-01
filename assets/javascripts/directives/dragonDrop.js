aw.directive("dropzone", function($parse) {
  return {
    restrict : "A",
    link: function (scope, elem, attrs) {

      /* Handle the drop */ 
      elem.bind('drop', function(e) {
        // e.stopPropagation();
        e.stopPropagation();
        e.preventDefault(); 
        scope.handleImages(e.dataTransfer.files);
        scope.data.hovering = false;
        scope.$apply();
      });

      /* Remove on drag leave */
      elem.bind('dragleave',function(e){
        e.stopPropagation();
        e.preventDefault(); 
        scope.data.hovering = false;
        scope.$apply();
      });
    }
  };
});

aw.directive('dropclass',function(){
  return {
    restrict : "A",
    link : function(scope,elem){
  
      elem.bind('dragover',function(e){
        e.preventDefault();
        e.stopPropagation();
        console.log("Hovering!");
        scope.data.hovering = true;
        scope.$apply();
      });
    }
  };
});
