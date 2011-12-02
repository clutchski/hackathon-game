(function() {
  var Bullet, Carbon, CarbonDioxide, Chloride, Hydrogen, Level, Oxygen, Ship, Sodium, SodiumChloride, SpaceLevel, Substance, TractorBeam, WarOf1812Level, Water, WaterLevel, death, engine, initialize, initializeLevel, logger, updateInventory;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  logger = new wolf.Logger('biology');
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
      this.image = this.images.static;
      this.static = false;
      this.inventory = {};
    }
    Ship.prototype.addSubstance = function(substance) {
      var _base, _name, _ref;
      if ((_ref = (_base = this.inventory)[_name = substance.symbol]) == null) {
        _base[_name] = [];
      }
      this.inventory[substance.symbol].push(substance);
      logger.info("added substance " + substance.symbol);
      return this.trigger('inventory', this);
    };
    Ship.prototype.render = function(context) {
      var c, rads;
      rads = this.direction.getRotation();
      c = this.getCenter();
      context.translate(c.x, c.y);
      context.rotate(rads + Math.PI / 2);
      return context.drawImage(this.image, -30.5, -30);
    };
    Ship.prototype.thrust = function() {
      var impulse;
      if (this.static) {
        return;
      }
      this.thrustIterations = 30;
      impulse = this.direction.scale(0.6);
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
    Ship.prototype.shootBullet = function() {
      return new Bullet(this.fireOptions());
    };
    Ship.prototype.elapse = function(ms, iteration) {
      this.thrustIterations = Math.max(this.thrustIterations - 1, 0);
      return this.image = !this.thrustIterations ? this.images.static : this.images.thrust;
    };
    Ship.prototype.jump = function(position) {
      return this.setPosition(position);
    };
    Ship.prototype.tractorBeam = function() {
      var opts;
      this.static = true;
      this.speed = this.speed / 3;
      setTimeout(__bind(function() {
        return this.static = false;
      }, this), 400);
      opts = this.fireOptions();
      opts.ship = this;
      return new TractorBeam(opts);
    };
    Ship.prototype.fireOptions = function() {
      var position;
      position = this.direction.scale(20).add(this.vertices[1]);
      return {
        x: position.x,
        y: position.y,
        direction: this.direction.copy()
      };
    };
    return Ship;
  })();
  TractorBeam = (function() {
    __extends(TractorBeam, wolf.Circle);
    function TractorBeam(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.radius = 7;
      opts.speed = 1.5;
      opts.dragCoefficient = 0;
      opts.fillStyle = "#A5FF75";
      TractorBeam.__super__.constructor.call(this, opts);
      this.pastPositions = [];
      this.element = null;
    }
    TractorBeam.prototype.render = function(context) {
      var p, _i, _len, _ref, _results;
      context.fillStyle = this.fillStyle;
      if (!this.element) {
        this.pastPositions.push(this.getPosition());
        _ref = this.pastPositions;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          context.beginPath();
          context.arc(p.x, p.y, this.radius, 0, Math.PI * 2);
          _results.push(context.fill());
        }
        return _results;
      } else {
        context.beginPath();
        p = this.getPosition();
        context.arc(p.x, p.y, this.radius, 0, Math.PI * 2);
        context.fill();
        context.lineWidth = 2;
        context.beginPath();
        context.strokeStyle = "#ccc";
        context.arc(p.x, p.y, this.radius, 0, Math.PI * 2);
        return context.stroke();
      }
    };
    TractorBeam.prototype.elapse = function(ms, iteration) {
      var colors, sp, tp;
      colors = ["#727F4A", "#ACBF6F", "#E6FF94", "#394025", "#CFE585", "#CDFFA9", "#CDFFA9", "#9ABF7F"];
      this.fillStyle = colors[Math.floor(wolf.random(0, colors.length))];
      if (!this.element) {
        this.radius += wolf.random(-2, 0.5);
        this.radius = Math.max(this.radius, 1);
      }
      if (this.element) {
        sp = this.ship.getPosition();
        tp = this.getPosition();
        tp.x = sp.x > tp.x ? tp.x + 0.4 : tp.x - 0.4;
        tp.y = sp.y > tp.y ? tp.y + 0.4 : tp.y - 0.4;
        this.setPosition(tp);
        this.radius = this.element.radius + wolf.random(-5, 5);
      }
      if (!this.element && this.pastPositions.length > 20) {
        return this.destroy();
      }
    };
    TractorBeam.prototype.lockOn = function(element) {
      this.element = element;
      this.radius = element.radius;
      return this.speed = 0;
    };
    return TractorBeam;
  })();
  Bullet = (function() {
    __extends(Bullet, wolf.Circle);
    function Bullet(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.radius = 3;
      opts.speed = 1.5;
      opts.dragCoefficient = 0;
      opts.fillStyle = "#ccc";
      Bullet.__super__.constructor.call(this, opts);
    }
    return Bullet;
  })();
  Substance = (function() {
    __extends(Substance, wolf.Circle);
    function Substance(opts) {
      var defaults;
      if (opts == null) {
        opts = {};
      }
      defaults = {
        subSubstances: [],
        x: wolf.random(100, 700),
        y: wolf.random(100, 400),
        speed: 0.05,
        mass: 10000,
        direction: new wolf.Vector(wolf.random(-1, 1), wolf.random(-1, 1)).normalize(),
        radius: 35,
        dragCoefficient: 0,
        fillStyle: "#abcdef",
        symbol: "A"
      };
      Substance.__super__.constructor.call(this, wolf.defaults(opts, defaults));
      this.lastMove = new Date();
      this.directionPeriod = 100;
    }
    Substance.prototype.elapse = function(ms, iteration) {
      var now, v;
      now = new Date();
      if (now - this.lastMove > this.directionPeriod) {
        v = wolf.random(-1, 1);
        if (Math.random() > 0.5) {
          this.direction = new wolf.Vector(this.direction.x, v).normalize();
        } else {
          this.direction = new wolf.Vector(v, this.direction.y).normalize();
        }
        this.lastMove = now;
        this.directionPeriod = wolf.random(200, 1200);
      }
      return this.fillStyle = this.colors[Math.floor(wolf.random(0, this.colors.length - 1))];
    };
    Substance.prototype.render = function(context) {
      context.lineWidth = 5;
      context.strokeStyle = "#444";
      if (!this.subSubstances.length) {
        context.lineWidth = new Date().getMilliseconds() % 15;
        context.strokeStyle = "white";
      }
      context.beginPath();
      context.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
      context.stroke();
      Substance.__super__.render.call(this, context);
      context.fillStyle = "black";
      context.font = "bold 30px Calibri";
      context.textAlign = "center";
      context.textBaseline = "middle";
      return context.fillText(this.symbol, this.x, this.y);
    };
    Substance.prototype.split = function(direction) {
      var d, explode, p, s, _i, _len, _ref, _results;
      this.destroy();
      d = this.direction;
      p = this.getPosition();
      explode = function(s) {
        var np;
        np = new wolf.Point(p.x + wolf.random(-15, 15), p.y + wolf.random(-15, 15));
        s.setPosition(np);
        s.direction = d.add(direction).normalize();
        return s;
      };
      _ref = this.subSubstances;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        s = _ref[_i];
        _results.push(explode(s));
      }
      return _results;
    };
    Substance.prototype.isElement = function() {
      return this.subSubstances.length === 0;
    };
    return Substance;
  })();
  Water = (function() {
    __extends(Water, Substance);
    function Water(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.subSubstances = [new Oxygen(), new Hydrogen(), new Hydrogen()];
      opts.colors = ["#3299CC", "#33A1DE"];
      opts.symbol = "H \u00B2 0";
      Water.__super__.constructor.call(this, opts);
    }
    return Water;
  })();
  Hydrogen = (function() {
    __extends(Hydrogen, Substance);
    function Hydrogen(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.colors = ["green", "green", "#6B8E23"];
      opts.symbol = "H";
      Hydrogen.__super__.constructor.call(this, opts);
    }
    return Hydrogen;
  })();
  Oxygen = (function() {
    __extends(Oxygen, Substance);
    function Oxygen(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.colors = ["blue", "blue"];
      opts.symbol = "O";
      Oxygen.__super__.constructor.call(this, opts);
    }
    return Oxygen;
  })();
  Carbon = (function() {
    __extends(Carbon, Substance);
    function Carbon(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.colors = ["#FFFFAA", "yellow", "yellow"];
      opts.symbol = "C";
      Carbon.__super__.constructor.call(this, opts);
    }
    return Carbon;
  })();
  Sodium = (function() {
    __extends(Sodium, Substance);
    function Sodium(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.colors = ["#eee", "#ccc", "#ddd", "#ddd"];
      opts.symbol = "Na";
      Sodium.__super__.constructor.call(this, opts);
    }
    return Sodium;
  })();
  Chloride = (function() {
    __extends(Chloride, Substance);
    function Chloride(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.colors = ["#008080"];
      opts.symbol = "Cl";
      Chloride.__super__.constructor.call(this, opts);
    }
    return Chloride;
  })();
  SodiumChloride = (function() {
    __extends(SodiumChloride, Substance);
    function SodiumChloride(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.subSubstances = [new Sodium(), new Chloride()];
      opts.colors = ["#eee", "#ccc", "#ddd", "#ddd"];
      opts.symbol = "NaCl";
      SodiumChloride.__super__.constructor.call(this, opts);
    }
    return SodiumChloride;
  })();
  CarbonDioxide = (function() {
    __extends(CarbonDioxide, Substance);
    function CarbonDioxide(opts) {
      if (opts == null) {
        opts = {};
      }
      opts.subSubstances = [new Oxygen(), new Oxygen(), new Carbon()];
      opts.colors = ["#3299CC", "#33A1DE"];
      opts.symbol = "CO\u00B2";
      CarbonDioxide.__super__.constructor.call(this, opts);
    }
    return CarbonDioxide;
  })();
  updateInventory = function(currentShip, curLevel) {
    var i, j, length, max, ok, s, subs, symbol, text, _ref, _ref2, _ref3, _results;
    _ref = curLevel.substanceLevels;
    _results = [];
    for (symbol in _ref) {
      _ref2 = _ref[symbol], ok = _ref2[0], max = _ref2[1];
      s = $("#substance" + symbol);
      subs = currentShip.inventory[symbol] || [];
      length = subs.length;
      text = "";
      i = 0;
      while (i < length) {
        text += "=";
        i += 1;
      }
      for (j = length, _ref3 = max - 1; length <= _ref3 ? j <= _ref3 : j >= _ref3; length <= _ref3 ? j++ : j--) {
        if (j === ok) {
          text += '|';
        } else {
          text += '.';
        }
      }
      _results.push(s.html(text));
    }
    return _results;
  };
  Level = (function() {
    function Level() {
      $('#game').css('background-image', "url(" + this.backgroundImage + ")");
    }
    Level.prototype.getLevels = function(substance) {
      var gauges;
      gauges = this.substanceLevels[substance];
      return gauges;
    };
    Level.prototype.count = function(inventory, substance) {
      return inventory[substance].length;
    };
    Level.prototype.didYouWin = function(inventory) {
      var max, ok, subs, substances, symbol, _ref, _ref2;
      _ref = this.substanceLevels;
      for (symbol in _ref) {
        substances = _ref[symbol];
        subs = inventory[symbol] || [];
        _ref2 = this.getLevels(symbol), ok = _ref2[0], max = _ref2[1];
        if (subs.length < ok) {
          return false;
        }
      }
      return true;
    };
    Level.prototype.didYouDie = function(inventory) {
      var max, ok, subs, substances, symbol, _ref, _ref2;
      _ref = this.substanceLevels;
      for (symbol in _ref) {
        substances = _ref[symbol];
        subs = inventory[symbol] || [];
        _ref2 = this.getLevels(symbol), ok = _ref2[0], max = _ref2[1];
        console.log("count: " + subs.length + " [" + ok + ", " + max + "]");
        if (subs.length >= max) {
          return true;
        }
      }
      return false;
    };
    Level.prototype.spawn = function() {
      var c, els;
      els = [Water, CarbonDioxide, SodiumChloride];
      c = wolf.randomElement(els);
      return new c;
    };
    return Level;
  })();
  SpaceLevel = (function() {
    __extends(SpaceLevel, Level);
    function SpaceLevel() {
      this.backgroundImage = "images/space.jpg";
      this.message = "You're in space motherfucker! Collect six hydrogen to win! Four\noxygen and you lose!";
      SpaceLevel.__super__.constructor.call(this);
      this.substanceLevels = {
        'O': [2, 10],
        'H': [4, 10],
        'C': [2, 6],
        'Na': [2, 10],
        'Cl': [3, 10]
      };
    }
    return SpaceLevel;
  })();
  WaterLevel = (function() {
    __extends(WaterLevel, Level);
    function WaterLevel() {
      this.backgroundImage = "images/underwater.jpg";
      this.message = "Aaaaah! I'm drowning bitches!";
      WaterLevel.__super__.constructor.call(this);
      this.substanceLevels = {
        'O': [2, 3],
        'H': [2, 3],
        'C': [2, 3],
        'Na': [2, 3],
        'Cl': [2, 3]
      };
    }
    return WaterLevel;
  })();
  WarOf1812Level = (function() {
    __extends(WarOf1812Level, Level);
    function WarOf1812Level() {
      this.backgroundImage = "images/1812.jpg";
      this.message = "Aaaaah! I'm drowning bitches!";
      WarOf1812Level.__super__.constructor.call(this);
      this.substanceLevels = {
        'O': [2, 3],
        'H': [2, 5],
        'C': [2, 3],
        'Na': [4, 6],
        'Cl': [2, 3]
      };
    }
    return WarOf1812Level;
  })();
  engine = null;
  death = function() {
    engine.destroy();
    $('body').css('background-color', 'red');
    return setTimeout(function() {
      return window.location = window.location;
    }, 1000);
  };
  initializeLevel = function(LevelClass, images) {
    var addSubstance, commands, createSubstance, level, ship, shipimages;
    if (engine) {
      engine.destroy();
      engine = null;
    }
    level = new LevelClass();
    shipimages = {
      static: images['images/ship.png'],
      thrust: images['images/ship.thrust.png']
    };
    engine = new wolf.Engine("canvas");
    engine.environment.gravitationalConstant = 0;
    ship = new Ship({
      x: 200,
      y: 200,
      speed: 0,
      images: shipimages
    });
    updateInventory(ship, level);
    ship.bind('inventory', function() {
      logger.info("updating ui");
      updateInventory(ship, level);
      if (level.didYouDie(ship.inventory)) {
        death();
        return alert('death');
      } else if (level.didYouWin(ship.inventory)) {
        return alert('glory!');
      }
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
      83: function() {
        var bullet;
        bullet = ship.shootBullet();
        return engine.add(bullet);
      },
      80: function() {
        return engine.logStatusReport();
      },
      81: function() {
        return engine.toggle();
      },
      68: function() {
        var p;
        p = new wolf.Point(wolf.random(0, 800), wolf.random(0, 500));
        return ship.jump(p);
      },
      65: function() {
        var beam;
        logger.info("traaactor");
        beam = ship.tractorBeam();
        beam.bind('collided', function(c, other) {
          if (other instanceof Substance && !beam.element) {
            if (other.isElement()) {
              beam.lockOn(other);
              other.destroy();
            } else {
              beam.destroy();
            }
          } else if (other === ship) {
            beam.destroy();
            if (beam.element) {
              ship.addSubstance(beam.element);
            }
          }
          return c.resolve();
        });
        return engine.add(beam);
      }
    };
    $(document).unbind('keydown');
    $(document).keydown(function(event) {
      var callback, key;
      key = event.which || event.keyCode;
      callback = commands[key];
      logger.debug("keypress " + key);
      if (callback) {
        return callback();
      }
    });
    engine.add(ship);
    engine.start();
    addSubstance = function(substance) {
      engine.add(substance);
      return substance.bind('collided', function(c, other) {
        var children, _i, _len;
        if (other instanceof Bullet) {
          children = substance.split(other.direction);
          for (_i = 0, _len = children.length; _i < _len; _i++) {
            c = children[_i];
            addSubstance(c);
          }
          return other.destroy();
        } else if (other === ship) {
          return death("Collision");
        } else {
          return c.resolve();
        }
      });
    };
    createSubstance = function() {
      var s;
      if (engine.isRunning) {
        s = level.spawn();
        while (s.intersects(ship)) {
          s = level.spawn();
        }
        addSubstance(s);
      }
      return setTimeout(function() {
        return createSubstance();
      }, 4000);
    };
    return createSubstance();
  };
  initialize = function(images) {
    var levels, runLevel;
    levels = {
      space: SpaceLevel,
      water: WaterLevel,
      1812: WarOf1812Level
    };
    runLevel = function() {
      var levelId;
      levelId = location.hash.split("#")[1];
      Level = levels[levelId] || levels.space;
      return initializeLevel(Level, images);
    };
    window.onhashchange = runLevel;
    return runLevel();
  };
  $(document).ready(function() {
    var image, images, loaded, url, urls, _i, _len;
    urls = ['images/ship.png', 'images/ship.thrust.png'];
    images = {};
    loaded = 0;
    for (_i = 0, _len = urls.length; _i < _len; _i++) {
      url = urls[_i];
      image = new Image();
      images[url] = image;
      image.onload = function() {
        loaded += 1;
        if (loaded === urls.length) {
          return initialize(images);
        }
      };
      image.src = url;
    }
    return $('#levels ar').click(function(event) {
      var link;
      link = $(event.target);
      return window.location = window.location + link.attr('href');
    });
  });
}).call(this);
