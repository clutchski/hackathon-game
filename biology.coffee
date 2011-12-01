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


class Substance extends wolf.Circle

    constructor : (opts = {}) ->
        defaults =
            subSubstances = []
        super(wolf.defaults(opts, defaults))


$(document).ready () ->

    # Initialize the engine.
    engine = new wolf.Engine("canvas")
    engine.environment.gravitationalConstant = 0

    ship = new Ship({x: 200, y: 200, speed: 0})

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

    # Attach behaviours.
    $(document).keydown (event) ->
        key = event.which || event.keyCode
        console.log(key)

        callback = commands[key]
        callback() if callback

    engine.add(ship)
    engine.start()

    createSubstance = () ->
        console.log("creating substance")
        substance = new Substance({
            x: wolf.random(0, 800)
            y: wolf.random(0, 500)
            speed: 0.1
            direction: new wolf.Vector(wolf.random(-1, 1), wolf.random(-1, 1)).normalize()
            radius: 20
            dragCoefficient: 0
        })
        if engine.isRunning
            engine.add(substance)
            setTimeout( () ->
                createSubstance()
            , 2000)

    createSubstance()
