extends Area2D
class_name NeonObstacle

## Moving hazard entity.
##
## Obstacles own their movement, procedural appearance, offscreen retirement,
## and idempotent cleanup. They never decide whether the run ends.

var _speed := GameBalance.START_SPEED
var _spin := 0.0
var _tint := Color("ff466b")
var _despawned := false

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    _spin = rng.randf_range(-0.65, 0.65)
    var palette: Array[Color] = [Color("ff466b"), Color("ff7847"), Color("e64cff")]
    _tint = palette[rng.randi_range(0, palette.size() - 1)]
    queue_redraw()

func configure(move_speed: float) -> bool:
    if _despawned:
        return false
    _speed = maxf(0.0, move_speed)
    return true

func movement_speed() -> float:
    return _speed

func is_despawned() -> bool:
    return _despawned

func despawn() -> bool:
    if _despawned:
        return false

    _despawned = true
    set_process(false)
    visible = false
    collision_layer = 0
    collision_mask = 0
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)
    queue_free()
    return true

func _process(delta: float) -> void:
    if _despawned:
        return

    position.y += _speed * delta
    rotation += _spin * delta
    if position.y > GameBalance.OBSTACLE_CLEANUP_Y:
        despawn()

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
    draw_colored_polygon(points, Color(_tint, 0.23))
    var outline := PackedVector2Array()
    for point in points:
        outline.append(point)
    outline.append(points[0])
    draw_polyline(outline, _tint, 5.0, true)
    draw_line(Vector2(-49.0, -13.0), Vector2(49.0, 13.0), Color(_tint, 0.76), 7.0)
    draw_line(Vector2(-49.0, 13.0), Vector2(49.0, -13.0), Color(_tint, 0.76), 7.0)
    draw_circle(Vector2.ZERO, 10.0, Color("fff4f7"))
