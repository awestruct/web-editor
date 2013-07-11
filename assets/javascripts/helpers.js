_.mixin({
  findDeep: function(items, attrs) {
  var result;

  function match(value) {
    for (var key in attrs) {
      if (attrs[key] !== value[key]) {
        return false;
      }
    }
    return true;
  }

  function traverse(value) {
    _.forEach(value, function (val) {
      if (match(val)) {
        result = val;
        return false;
      }

      if (typeof val === 'object') {
        traverse(val);
      }

      if (result) {
        return false;
      }
    });
  }

  traverse(items);

  return result;
  }
});