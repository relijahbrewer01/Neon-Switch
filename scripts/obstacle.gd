extends Area2D
class_name NeonObstacle

var speed := 650.0
var spin := 0.0
var tint := Color("ff466b")
var passed_player := false

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    spin = rng.randf_range(-0.65, 0.65)
    var palette: Array[Color] = [Color("ff466b"), Color("ff7847"), Color("e64cff")]
    tint = palette[rng.randi_range(0, palette.size() - 1)]
    queue_redraw()

func _process(delta: float) -> void:
    position.y += speed * delta
    rotation += spin * delta
    if position.y > 1380.0:
        queue_free()

func _draw() -> void:
    var points := PackedVector2Array([
        Vector2(-85.0, -23.0),
        Vector2(-61.0, -36.0),
        Vector2(61.0, -36.0),
        Vector2(85.0, -23.0),
        Vector2(85.0, 23.0),
        Vector2(61.0, 36.0),
        Vector2(-61.0, 36.0),
        Vector2(-85.0, 23.0)
    ])
    draw_colored_polygon(points, Color(tint, 0.23))
    var outline := PackedVector2Array()
    for point in points:
        outline.append(point)
    outline.append(points[0])
    draw_polyline(outline, tint, 5.0, true)
    draw_line(Vector2(-49.0, -13.0), Vector2(49.0, 13.0), Color(tint, 0.76), 7.0)
    draw_line(Vector2(-49.0, 13.0), Vector2(49.0, -13.0), Color(tint, 0.76), 7.0)
    draw_circle(Vector2.ZERO, 10.0, Color("fff4f7"))
