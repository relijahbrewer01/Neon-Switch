extends Area2D
class_name EnergyPickup

## Moving collectible entity.
##
## Pickups own movement, one-time collection state, collection animation, and
## idempotent cleanup. They report no score and know nothing about the HUD.

var _speed := GameBalance.START_SPEED
var _life := 0.0
var _collected := false
var _despawned := false
var _collection_tween: Tween

func configure(move_speed: float) -> bool:
    if _despawned:
        return false
    _speed = maxf(0.0, move_speed)
    return true

func movement_speed() -> float:
    return _speed

func is_collected() -> bool:
    return _collected

func is_despawned() -> bool:
    return _despawned

func collect() -> bool:
    if _collected or _despawned:
        return false

    _collected = true
    # Collection begins inside an overlap callback, so collision-state changes
    # wait until the current physics query has completed.
    set_deferred("collision_layer", 0)
    set_deferred("collision_mask", 0)
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)

    _collection_tween = create_tween()
    _collection_tween.set_parallel(true)
    _collection_tween.tween_property(self, "scale", Vector2(2.1, 2.1), 0.16).set_trans(Tween.TRANS_BACK)
    _collection_tween.tween_property(self, "modulate:a", 0.0, 0.16)
    _collection_tween.tween_property(self, "rotation", rotation + PI, 0.16)
    _collection_tween.chain().tween_callback(_finish_collection)
    return true

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

    if _collection_tween and _collection_tween.is_running():
        _collection_tween.kill()
    _collection_tween = null

    queue_free()
    return true

func _finish_collection() -> void:
    _collection_tween = null
    despawn()

func _process(delta: float) -> void:
    if _despawned:
        return

    _life += delta
    if not _collected:
        position.y += _speed * delta
        rotation += delta * 2.4
        scale = Vector2.ONE * (1.0 + sin(_life * 7.0) * 0.08)
        if position.y > GameBalance.PICKUP_CLEANUP_Y:
            despawn()
    queue_redraw()

func _draw() -> void:
    var glow := 0.5 + (sin(_life * 8.0) + 1.0) * 0.25
    draw_circle(Vector2.ZERO, 42.0, Color(0.30, 1.0, 0.76, 0.07 + glow * 0.06))

    var outer := PackedVector2Array()
    for i in range(8):
        var angle := -PI / 2.0 + float(i) * TAU / 8.0
        var radius := 29.0 if i % 2 == 0 else 13.0
        outer.append(Vector2(cos(angle), sin(angle)) * radius)
    draw_colored_polygon(outer, Color("47f7bc"))
    var outline := PackedVector2Array()
    for point in outer:
        outline.append(point)
    outline.append(outer[0])
    draw_polyline(outline, Color("d9fff2"), 3.0, true)
    draw_circle(Vector2.ZERO, 7.0, Color.WHITE)
