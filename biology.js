(function() {
  var Ship, Substance;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
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
      opts.fillStyle = "#c1f3ff";
      opts.direction = new wolf.Vector(0, -1);
      Ship.__super__.constructor.call(this, opts);
    }
    Ship.prototype.thrust = function() {
      var impulse;
      impulse = this.direction.scale(0.8);
      console.log("applying impulse " + impulse);
      return this.applyImpulse(impulse);
    };
    Ship.prototype.starboard = function() {
      return this.turn(-1);
    };
    Ship.prototype.port = function() {
      return this.turn(1);
    };
    Ship.prototype.turn = function(orientation) {
      var doTurn, magnitude;
      magnitude = 20;
      doTurn = __bind(function() {
        var degrees, turn;
        turn = 5;
        if (0 < magnitude) {
          degrees = turn * orientation;
          this.rotate(degrees);
          this.direction = this.direction.rotate(degrees);
          setTimeout(doTurn, 40);
        }
        return magnitude -= turn;
      }, this);
      return doTurn();
    };
    return Ship;
  })();
  Substance = (function() {
    __extends(Substance, wolf.Circle);
    function Substance(opts) {
      var defaults, subSubstances;
      if (opts == null) {
        opts = {};
      }
      defaults = subSubstances = [];
      Substance.__super__.constructor.call(this, wolf.defaults(opts, defaults));
    }
    return Substance;
  })();
  $(document).ready(function() {
    var commands, createSubstance, engine, ship;
    engine = new wolf.Engine("canvas");
    engine.environment.gravitationalConstant = 0;
    ship = new Ship({
      x: 200,
      y: 200,
      speed: 0
    });
    commands = {
      38: function() {
        return ship.thrust();
      },
      37: function() {
        return ship.starboard();
      },
      39: function() {
        return ship.port();
      },
      32: function() {
        var bullet;
        bullet = ship.shootBullet();
        return engine.add(bullet);
      },
      80: function() {
        return engine.logStatusReport();
      }
    };
    $(document).keydown(function(event) {
      var callback, key;
      key = event.which || event.keyCode;
      console.log(key);
      callback = commands[key];
      if (callback) {
        return callback();
      }
    });
    engine.add(ship);
    engine.start();
    createSubstance = function() {
      var substance;
      console.log("creating substance");
      substance = new Substance({
        x: wolf.random(0, 800),
        y: wolf.random(0, 500),
        speed: 0.1,
        direction: new wolf.Vector(wolf.random(-1, 1), wolf.random(-1, 1)).normalize(),
        radius: 20,
        dragCoefficient: 0
      });
      if (engine.isRunning) {
        engine.add(substance);
        return setTimeout(function() {
          return createSubstance();
        }, 2000);
      }
    };
    return createSubstance();
  });
}).call(this);
