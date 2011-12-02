#
# The code for the biology game.
#

logger = new wolf.Logger('biology')

class Ship extends wolf.Polygon

    constructor : (opts = {}) ->
        shape  = [[0, 0], [-15, -35], [-30, 0]]
        opts.vertices = (new wolf.Point(a+opts.x, b+opts.y) for [a, b] in shape)
        opts.fillStyle = "#c1f3ff"
        opts.direction = new wolf.Vector(0, -1)
        super(opts)
        @image = @images.static
        @static = false
        @inventory = {}

    addSubstance : (substance) ->
        @inventory[substance.symbol] ?= []
        @inventory[substance.symbol].push(substance)
        logger.info("added substance #{substance.symbol}")
        @trigger('inventory', @)

    render:  (context) ->
        rads = @direction.getRotation()
        c = @getCenter()
        context.translate(c.x, c.y)
        context.rotate(rads + Math.PI / 2)
        context.drawImage(@image, -30.5, -30)

    # Apply the shift's thrusters.
    thrust : () ->
        return if @static
        @thrustIterations = 30
        impulse = @direction.scale(0.8)
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
        return new Bullet(@fireOptions())

    # Elapse.
    elapse : (ms, iteration) ->
        @thrustIterations = Math.max(@thrustIterations - 1, 0)
        @image = if not @thrustIterations
            @images.static
        else
            @images.thrust

    jump : (position) ->
        @setPosition(position)

    tractorBeam : () ->
        @static = true
        @speed = @speed / 3
        setTimeout () =>
            @static = false
        , 400
        opts = @fireOptions()
        opts.ship = @
        return new TractorBeam(opts)

    fireOptions : () ->
        position = @direction.scale(20).add(@vertices[1])
        return {
            x: position.x
            y: position.y
            direction: @direction.copy()
        }




class TractorBeam extends wolf.Circle

    constructor : (opts={}) ->
        opts.radius = 7
        opts.speed = 1.5
        opts.dragCoefficient = 0
        opts.fillStyle = "#A5FF75"
        super(opts)
        @pastPositions = []
        @element = null

    render : (context) ->
        context.fillStyle = @fillStyle
        if not @element
            @pastPositions.push(@getPosition())
            for p in @pastPositions
                context.beginPath()
                context.arc(p.x, p.y, @radius, 0, Math.PI *2)
                context.fill()
        else
            context.beginPath()
            p = @getPosition()
            context.arc(p.x, p.y, @radius, 0, Math.PI *2)
            context.fill()
            context.lineWidth = 2

            context.beginPath()
            context.strokeStyle = "#ccc"
            context.arc(p.x, p.y, @radius, 0, Math.PI *2)
            context.stroke()

    elapse : (ms, iteration) ->
        colors = [
            "#727F4A"
            "#ACBF6F"
            "#E6FF94"
            "#394025"
            "#CFE585"
            "#CDFFA9"
            "#CDFFA9"
            "#9ABF7F"
        ]

        @fillStyle = colors[Math.floor(wolf.random(0, colors.length))]
        if not @element
            @radius += wolf.random(-2, 0.5)
            @radius = Math.max(@radius, 1)

        if @element
            sp = @ship.getPosition()
            tp = @getPosition()

            tp.x = if sp.x > tp.x then tp.x + 0.4 else tp.x - 0.4
            tp.y = if sp.y > tp.y then tp.y + 0.4 else tp.y - 0.4
            @setPosition(tp)

            @radius = @element.radius + wolf.random(-5, 5)

        if not @element and @pastPositions.length > 50
            @destroy()

    lockOn : (element) ->
        @element = element
        @radius = element.radius
        @speed = 0



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
            speed: 0.1
            mass: 10000
            direction: new wolf.Vector(wolf.random(-1, 1), wolf.random(-1, 1)).normalize()
            radius: 35
            dragCoefficient: 0
            fillStyle: "#abcdef"
            symbol: "A"

        super(wolf.defaults(opts, defaults))
        @lastMove = new Date()
        @directionPeriod = 100

    elapse : (ms, iteration) ->
        now = new Date()
        if now - @lastMove > @directionPeriod
            v = wolf.random(-1, 1)
            if Math.random() > 0.5
                @direction = new wolf.Vector(@direction.x, v).normalize()
            else
                @direction = new wolf.Vector(v, @direction.y).normalize()
            @lastMove = now
            @directionPeriod = wolf.random(200, 1200)
        @fillStyle = @colors[Math.floor(wolf.random(0, @colors.length-1))]

    render : (context) ->
        context.lineWidth = 5
        context.strokeStyle = "#ddd"
        context.beginPath()
        context.arc(@x, @y, @radius, 0, Math.PI *2)
        context.stroke()

        super(context)
        context.fillStyle = "black"
        context.font = "bold 30px Calibri"
        context.textAlign = "center"
        context.textBaseline = "middle"
        context.fillText(@symbol, @x, @y)

    # Destroy the substance and return it's composed substances.
    split : (direction) ->
        @destroy()
        d = @direction
        p = @getPosition()
        explode = (s) ->
            np = new wolf.Point(p.x + wolf.random(-15, 15), p.y + wolf.random(-15, 15))
            s.setPosition(np)
            s.direction = d.add(direction).normalize()
            return s

        return (explode(s) for s in @subSubstances)

    isElement : () ->
        return @subSubstances.length == 0

class Water extends Substance

    constructor : (opts = {}) ->
        opts.subSubstances = [
            new Oxygen()
            new Hydrogen()
            new Hydrogen()
        ]
        opts.colors = ["#3299CC", "#33A1DE"]
        opts.symbol = "H \u00B2 0"
        super(opts)

class Hydrogen extends Substance

    constructor : (opts = {}) ->
        opts.colors = ["blue", "red", "white", "black", "green"]
        opts.symbol = "H"
        super(opts)

class Oxygen extends Substance

    constructor : (opts = {}) ->
        opts.colors = ["blue", "blue"]
        opts.symbol = "O"
        super(opts)


updateInventory = (currentShip) ->

    # Update the intenvotry counts.
    for symbol, substances of currentShip.inventory
        console.log("#{symbol} #{substances.length}")
        s = $("#substance#{symbol}")
        s.html(substances.length)


initialize = (images) ->

    shipimages = {
        static : images['images/ship.png']
        thrust : images['images/ship.thrust.png']
    }

    # Initialize the engine.
    engine = new wolf.Engine("canvas")
    engine.environment.gravitationalConstant = 0

    ship = new Ship({x: 200, y: 200, speed: 0, images: shipimages})

    ship.bind 'inventory', () ->
        logger.info "updating ui"
        updateInventory(ship)
    # Map key presses to behaviours.
    commands =
        38 : () ->
            ship.thrust()
        37 : () ->
            ship.starboard()
        39 : () ->
            ship.port()
        83 : () ->
            bullet = ship.shootBullet()
            engine.add(bullet)
        80 : () ->
            engine.logStatusReport()
        81 : () ->
            engine.toggle()
        68 : () ->
            p = new wolf.Point(wolf.random(0, 800), wolf.random(0, 500))
            ship.jump(p)
        65 : () ->
            logger.info("traaactor")
            beam = ship.tractorBeam()
            beam.bind 'collided', (c, other) ->
                if other instanceof Substance and not beam.element
                    if other.isElement()
                        beam.lockOn(other)
                        other.destroy()
                    else
                        beam.destroy()
                else if other == ship
                    beam.destroy()
                    ship.addSubstance(beam.element) if beam.element
                c.resolve()
            engine.add(beam)


    # Attach behaviours.
    $(document).keydown (event) ->
        key = event.which || event.keyCode
        callback = commands[key]
        logger.debug("keypress #{key}")
        callback() if callback

    engine.add(ship)
    engine.start()

    addSubstance = (substance) ->
        engine.add(substance)
        substance.bind 'collided', (c, other) ->
            if other instanceof Bullet
                children = substance.split(other.direction)
                (addSubstance(c) for c in children)
                other.destroy()
            else if other == ship
                engine.destroy()
                $('body').css('background-color', 'red')
                setTimeout( () ->
                    window.location = window.location
                , 1000)
            else
                c.resolve() # let them float

    createSubstance = () ->
        if engine.isRunning
            substance = new Water()
            while substance.intersects(ship)
                substance = new Water()
            addSubstance(substance)
        setTimeout( () ->
            createSubstance()
        , 4000)

    createSubstance()


#
# Load the images and start the game.
#

$(document).ready () ->
    urls = [
        'images/ship.png'
        'images/ship.thrust.png'
    ]
    images = {}
    loaded = 0
    for url in urls
        image = new Image()
        images[url] = image
        image.onload = () ->
            loaded += 1
            if loaded == urls.length
                initialize(images)
        image.src = url
