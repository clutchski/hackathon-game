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
        impulse = @direction.scale(0.6)
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

        if not @element and @pastPositions.length > 20
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
            speed: 0.05
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
        context.strokeStyle = "#444"
        if not @subSubstances.length
            context.lineWidth = new Date().getMilliseconds() % 15
            context.strokeStyle = "white"
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
        opts.colors = ["green", "green", "#6B8E23"]
        opts.symbol = "H"
        super(opts)

class Oxygen extends Substance

    constructor : (opts = {}) ->
        opts.colors = ["blue", "blue"]
        opts.symbol = "O"
        super(opts)

class Carbon extends Substance

    constructor : (opts = {}) ->
        opts.colors = ["#FFFFAA", "yellow", "yellow"]
        opts.symbol = "C"
        super(opts)

class Sodium extends Substance

    constructor : (opts = {}) ->
        opts.colors = ["#eee", "#ccc", "#ddd", "#ddd"]
        opts.symbol = "Na"
        super(opts)

class Chloride extends Substance

    constructor : (opts = {}) ->
        opts.colors = ["#008080"]
        opts.symbol = "Cl"
        super(opts)


class SodiumChloride extends Substance

    constructor : (opts = {}) ->
        opts.subSubstances = [
            new Sodium()
            new Chloride()
        ]

        opts.colors = ["#eee", "#ccc", "#ddd", "#ddd"]
        opts.symbol = "NaCl"
        super(opts)


class CarbonDioxide extends Substance

    constructor : (opts = {}) ->
        opts.subSubstances = [
            new Oxygen()
            new Oxygen()
            new Carbon()
        ]
        opts.colors = ["#3299CC", "#33A1DE"]
        opts.symbol = "CO\u00B2"
        super(opts)


updateInventory = (currentShip, curLevel) ->

    # Update the intenvotry counts.
    for symbol, [ok, max] of curLevel.substanceLevels

        s = $("#substance#{symbol}")
        subs = currentShip.inventory[symbol] || []
        length = subs.length
        text = ""
        i = 0
        while i  < length
            text += "="
            i += 1
        for j in [length..max-1]
            if j == ok
                text += '|'
            else
                text += '.'
        s.html(text)
    #3
    #for symbol, substances of currentShip.inventory
    #    console.log("#{symbol} #{substances.length}")
    #    s.html(substances.length)


class Level

    constructor : () ->
        $('#game').css('background-image', "url(#{@backgroundImage})")

    getLevels : (substance) ->
        gauges = @substanceLevels[substance]
        return gauges

    count : (inventory, substance) ->
        return inventory[substance].length

    didYouWin : (inventory) ->
        for symbol, substances of @substanceLevels
            subs = inventory[symbol] || []
            [ok, max] = @getLevels(symbol)
            if subs.length < ok
                return false
        return true

    didYouDie : (inventory) ->
        for symbol, substances of @substanceLevels
            subs = inventory[symbol] || []
            [ok, max] = @getLevels(symbol)
            console.log("count: #{subs.length} [#{ok}, #{max}]")
            if subs.length >= max
                return true
        return false

    spawn : () ->
        els = [Water, CarbonDioxide, SodiumChloride]
        c = wolf.randomElement(els)
        return new c


class SpaceLevel extends Level

    constructor : () ->
        @backgroundImage = "images/space.jpg"
        @message = """
            You're in space motherfucker! Collect six hydrogen to win! Four
            oxygen and you lose!
        """
        super()
        @substanceLevels = {
            'O' : [2, 10]
            'H' : [4, 10]
            'C' : [2, 6]
            'Na' : [2, 10]
            'Cl' : [3, 10]
        }

class WaterLevel extends Level

    constructor : () ->
        @backgroundImage = "images/underwater.jpg"
        @message = """
            Aaaaah! I'm drowning bitches!
        """
        super()
        @substanceLevels = {
            'O' : [2, 3]
            'H' : [2, 3]
            'C' : [2 ,3]
            'Na' : [2, 3]
            'Cl' : [2, 3]
        }


class WarOf1812Level extends Level

    constructor : () ->
        @backgroundImage = "images/1812.jpg"
        @message = """
            Aaaaah! I'm drowning bitches!
        """
        super()
        @substanceLevels = {
            'O' : [2, 3]
            'H' : [2, 5]
            'C' : [2 ,3]
            'Na' : [4, 6]
            'Cl' : [2, 3]
        }


engine = null


death = () ->
    engine.destroy()
    $('body').css('background-color', 'red')
    setTimeout( () ->
        window.location = window.location
    , 1000)


initializeLevel = (LevelClass, images) ->

    # kill old games
    if engine
        engine.destroy()
        engine = null

    level = new LevelClass()

    shipimages = {
        static : images['images/ship.png']
        thrust : images['images/ship.thrust.png']
    }

    # Initialize the engine.
    engine = new wolf.Engine("canvas")
    engine.environment.gravitationalConstant = 0


    ship = new Ship({x: 200, y: 200, speed: 0, images: shipimages})

    updateInventory(ship,level)
    ship.bind 'inventory', () ->
        logger.info "updating ui"
        updateInventory(ship, level)
        if level.didYouDie(ship.inventory)
            death()
            alert('death')
        else if level.didYouWin(ship.inventory)
            alert('glory!')
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
    $(document).unbind('keydown')
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
                death("Collision")
            else
                c.resolve() # let them float

    createSubstance = () ->
        if engine.isRunning
            s = level.spawn()
            while s.intersects(ship)
                s = level.spawn()
            addSubstance(s)
        setTimeout( () ->
            createSubstance()
        , 4000)

    createSubstance()


initialize = (images) ->

    levels =
        space: SpaceLevel
        water: WaterLevel
        1812: WarOf1812Level

    runLevel = () ->
        levelId = location.hash.split("#")[1]
        Level = levels[levelId] || levels.space
        initializeLevel(Level, images)

    window.onhashchange = runLevel
    runLevel()

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


    $('#levels ar').click (event) ->
        link = $(event.target)
        window.location = window.location + link.attr('href')

