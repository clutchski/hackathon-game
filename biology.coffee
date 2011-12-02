#
# The code for the biology game.
#

class Ship extends wolf.Polygon

    constructor : (opts = {}) ->
        shape  = [[0, 0], [-15, -35], [-30, 0]]
        opts.vertices = (new wolf.Point(a+opts.x, b+opts.y) for [a, b] in shape)
        opts.fillStyle = "#c1f3ff"
        opts.direction = new wolf.Vector(0, -1)
        super(opts)

    render:  (context) ->
        rads = @direction.getRotation()
        c = @getCenter()
        context.translate(c.x, c.y)
        context.rotate(rads + Math.PI / 2)
        context.drawImage(@image, -30.5, -30.5)

    # Apply the shift's thrusters.
    thrust : () ->
        impulse = @direction.scale(0.8)
        console.log("applying impulse #{impulse}")
        @applyImpulse(impulse)

    # Turn the ship to the starboard side.
    starboard : () ->
        @turn(-1)

    # Turn the ship to the port side.
    port : () ->
        @turn(1)

    # Turn the ship in the given direction.
    turn : (orientation) ->
        magnitude = 20

        doTurn = () =>
            turn = 5
            if 0 < magnitude
                degrees = turn * orientation
                @rotate(degrees)
                @direction = @direction.rotate(degrees)
                setTimeout(doTurn, 40)
            magnitude -= turn

        doTurn()

    # Return a bullet fired by the ship.
    shootBullet : () ->
        position = @direction.scale(10).add(@vertices[1])
        bullet = new Bullet(
            x: position.x
            y: position.y
            direction: @direction.copy()
        )

# Bullets kill things!
class Bullet extends wolf.Circle

    constructor : (opts={}) ->
        opts.radius = 3
        opts.speed = 1.5
        opts.dragCoefficient = 0
        opts.fillStyle = "#ccc"
        super(opts)

class Substance extends wolf.Circle

    constructor : (opts = {}) ->
        defaults =
            subSubstances : []
            x: wolf.random(100, 700)
            y: wolf.random(100, 400)
            speed: 0.2
            mass: 10000
            direction: new wolf.Vector(wolf.random(-1, 1), wolf.random(-1, 1)).normalize()
            radius: wolf.random(30, 45)
            dragCoefficient: 0
            fillStyle: "#abcdef"

        super(wolf.defaults(opts, defaults))
        @lastMove = new Date()
        @directionPeriod = 100

    elapse : () ->
        now = new Date()
        if now - @lastMove > @directionPeriod
            v = wolf.random(-1, 1)
            if Math.random() > 0.5
                @direction = new wolf.Vector(@direction.x, v).normalize()
            else
                @direction = new wolf.Vector(v, @direction.y).normalize()
            @lastMove = now
            @directionPeriod = wolf.random(200, 1200)

    # Destroy the substance and return it's composed substances.
    split : (direction) ->
        @destroy()
        d = @direction
        p = @getPosition()
        explode = (s) ->
            s.setPosition(p)
            s.direction = d.add(direction).normalize()
            return s

        return (explode(s) for s in @subSubstances)

class Water extends Substance

    constructor : (opts = {}) ->
        opts.subSubstances = [
            new Oxygen()
            new Hydrogen()
            new Hydrogen()
        ]
        opts.fillStyle = "blue"
        super(opts)

class Hydrogen extends Substance

    constructor : (opts = {}) ->
        opts.fillStyle = "red"
        super(opts)

class Oxygen extends Substance

    constructor : (opts = {}) ->
        opts.fillStyle = "white"
        super(opts)


initialize = (images) ->

    # Initialize the engine.
    engine = new wolf.Engine("canvas")
    engine.environment.gravitationalConstant = 0

    ship = new Ship({x: 200, y: 200, speed: 0, image: images.ship})
    wall = new wolf.Rectangle({x:0, y:0, height: 10, width: 800, mass:100000})

    # Map key presses to behaviours.
    commands =
        38 : () ->
            ship.thrust()
        37 : () ->
            ship.starboard()
        39 : () ->
            ship.port()
        32 : () ->
            bullet = ship.shootBullet()
            engine.add(bullet)
        80 : () ->
            engine.logStatusReport()
        81 : () ->
            engine.toggle()

    # Attach behaviours.
    $(document).keydown (event) ->
        key = event.which || event.keyCode
        console.log(key)
        callback = commands[key]
        callback() if callback

    engine.add(ship)
    engine.add(wall)
    engine.start()

    addSubstance = (substance) ->
        engine.add(substance)
        substance.bind 'collided', (c, other) ->
            if other instanceof Bullet
                children = substance.split(other.direction)
                (addSubstance(c) for c in children)
                other.destroy()
            else
                c.resolve() # let them float

    createSubstance = () ->
        console.log("creating substance")
        if engine.isRunning
            substance = new Water()
            addSubstance(substance)
        setTimeout( () ->
            createSubstance()
        , 4000)

    createSubstance()

$(document).ready () ->
    shipImage = new Image()
    shipImage.onload = () ->
        images =
            ship: shipImage
        initialize(images)
    shipImage.src = 'ship.png'
