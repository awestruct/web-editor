aw.factory('Data',function() {
  /* We use this data service to share data between the controllers */
  return {
    hovering : false,
    messages : [],
    gridHoverPoints : {
      x : 0,
      y : 0
    }
  };
});