/* Center overlays vertically directive */
aw.directive('center',function($window){
  return {
    restrict : "A",
    link : function(scope,elem,attrs){
      
      var resize = function() {
        var winHeight = $window.innerHeight - 90,
            overlayHeight = elem[0].offsetHeight,
            diff = (winHeight - overlayHeight) / 2;
            elem.css('top',diff+"px");
      };

      var watchForChange = function() {
        return scope.$parent.data.overlaytype;
      }
      scope.$watch(watchForChange,function() {
        $window.setTimeout(function() {
          resize();
        }, 1);
      })

      angular.element($window).bind('resize',function(e){
        resize();
      });
    }
  };
});