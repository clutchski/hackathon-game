(function() {
  var Ship;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Ship = (function() {
    __extends(Ship, wolf.Polygon);
    function Ship(opts) {
      var a, b, shape;
      if (opts == null) {
        opts = {};
      }
      shape = [[0, 0], [-15, -35], [-30, 0]];
      opts.vertices = (function() {
        var _i, _len, _ref, _results;
        _results = [];
        for (_i = 0, _len = shape.length; _i < _len; _i++) {
          _ref = shape[_i], a = _ref[0], b = _ref[1];
          _results.push(new wolf.Point(a + opts.x, b + opts.y));
        }
        return _results;
      })();
      Ship.__super__.constructor.call(this, opts);
      this.fillColor = "#aaa";
    }
    return Ship;
  })();
  $(document).ready(function() {
    var engine, ship;
    engine = new wolf.Engine("canvas");
    engine.environment.gravitationalConstant = 0;
    ship = new Ship({
      x: 200,
      y: 200,
      speed: 0
    });
    engine.add(ship);
    return engine.start();
  });
}).call(this);
