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
            console.log(winHeight,overlayHeight,diff);
      };
      resize();

      angular.element($window).bind('resize',function(e){
        // console.log('resafsdf');
        // console.log(elem.css('top'));
        resize();
      });
      // elem.bind('mouseenter',function(e){
      //   scope.data.gridHoverPoints.x = attrs.x;
      //   scope.data.gridHoverPoints.y = attrs.y;
      //   scope.$apply();
      // });
    }
  };
});