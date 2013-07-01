/* Table grid hover directive */
aw.directive('gridhover',function(){
  return {
    restrict : "A",
    link : function(scope,elem,attrs){
      elem.bind('mouseenter',function(e){
        scope.data.gridHoverPoints.x = attrs.x;
        scope.data.gridHoverPoints.y = attrs.y;
        scope.$apply();
      });
    }
  };
});