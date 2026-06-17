extends Area2D
class_name EnergyPickup

var speed := GameBalance.START_SPEED
var life := 0.0
var collected := false

func _process(delta: float) -> void:
    life += delta
    if not collected:
        position.y += speed * delta
        rotation += delta * 2.4
        scale = Vector2.ONE * (1.0 + sin(life * 7.0) * 0.08)
        if position.y > GameBalance.PICKUP_CLEANUP_Y:
            queue_free()
    queue_redraw()

func collect() -> void:
    if collected:
        return
    collected = true
    # Collection is triggered from a physics overlap callback, so collision
    # state changes must wait until the current physics step has completed.
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector2(2.1, 2.1), 0.16).set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "modulate:a", 0.0, 0.16)
    tween.tween_property(self, "rotation", rotation + PI, 0.16)
    tween.chain().tween_callback(queue_free)

func _draw() -> void:
    var glow := 0.5 + (sin(life * 8.0) + 1.0) * 0.25
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
