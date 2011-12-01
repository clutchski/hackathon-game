#
# The code for the biology game.
#

class Ship extends wolf.Polygon

    constructor : (opts = {}) ->
        shape  = [[0, 0], [-15, -35], [-30, 0]]
        opts.vertices = (new wolf.Point(a+opts.x, b+opts.y) for [a, b] in shape)
        super(opts)
        @fillColor = "#aaa"

$(document).ready () ->


    # Initialize the engine.
    engine = new wolf.Engine("canvas")
    engine.environment.gravitationalConstant = 0

    ship = new Ship({x: 200, y: 200, speed: 0})

    engine.add(ship)
    engine.start()
