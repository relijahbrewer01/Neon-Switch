extends Area2D
class_name NeonPlayer

## Persistent player entity.
##
## The player owns lane state, collision sensing, and player-only animation. It
## reports contacts through signals but never changes score, game state, spawn
## timing, save data, audio, or platform haptics.

signal hit_obstacle(obstacle: NeonObstacle)
signal collected_pickup(pickup: EnergyPickup)

var _lane_index: int = GameBalance.PLAYER_START_LANE
var _active := false
var _move_tween: Tween
var _feedback_tween: Tween
var _crash_tween: Tween
var _pulse_time := 0.0
var _trail_direction := 1.0

func _ready() -> void:
    var contact_callable := Callable(self, "_on_area_entered")
    if not area_entered.is_connected(contact_callable):
        area_entered.connect(contact_callable)
    queue_redraw()

func _process(delta: float) -> void:
    _pulse_time += delta
    queue_redraw()

func reset_for_run() -> void:
    _active = false
    _lane_index = GameBalance.PLAYER_START_LANE
    _kill_owned_tweens()

    position = Vector2(GameBalance.LANE_X[_lane_index], GameBalance.PLAYER_Y)
    scale = Vector2.ONE
    rotation = 0.0
    modulate = Color.WHITE
    visible = true

    collision_layer = 1
    collision_mask = 6
    monitoring = true
    monitorable = true
    queue_redraw()

func activate() -> bool:
    if _active:
        return false
    _active = true
    monitoring = true
    monitorable = true
    return true

func is_active() -> bool:
    return _active

func current_lane() -> int:
    return _lane_index

func switch_lane() -> bool:
    if not _active:
        return false

    _lane_index = 1 - _lane_index
    var old_x: float = position.x
    var target_x: float = GameBalance.LANE_X[_lane_index]
    _trail_direction = signf(target_x - old_x)

    if _move_tween and _move_tween.is_running():
        _move_tween.kill()

    _move_tween = create_tween()
    _move_tween.set_trans(Tween.TRANS_BACK)
    _move_tween.set_ease(Tween.EASE_OUT)
    _move_tween.tween_property(
        self,
        "position:x",
        target_x,
        GameBalance.PLAYER_SWITCH_TIME
    )

    _start_scale_feedback(Vector2(1.24, 0.82), 0.055, 0.09)
    return true

func crash() -> bool:
    if not _active:
        return false

    _active = false
    # Contact callbacks run during physics processing. Defer monitor changes so
    # the current overlap query can finish without Godot rejecting the update.
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)

    if _move_tween and _move_tween.is_running():
        _move_tween.kill()
    if _feedback_tween and _feedback_tween.is_running():
        _feedback_tween.kill()
    if _crash_tween and _crash_tween.is_running():
        _crash_tween.kill()

    _crash_tween = create_tween()
    _crash_tween.set_parallel(true)
    _crash_tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.16).set_trans(Tween.TRANS_QUAD)
    _crash_tween.tween_property(self, "modulate:a", 0.0, 0.18)
    _crash_tween.tween_property(self, "rotation", rotation + PI * 0.75, 0.18)
    return true

func celebrate_pickup() -> bool:
    if not _active:
        return false
    _start_scale_feedback(Vector2(1.18, 1.18), 0.055, 0.085)
    return true

func _start_scale_feedback(target_scale: Vector2, out_time: float, return_time: float) -> void:
    if _feedback_tween and _feedback_tween.is_running():
        _feedback_tween.kill()

    _feedback_tween = create_tween()
    _feedback_tween.tween_property(self, "scale", target_scale, out_time)
    _feedback_tween.tween_property(self, "scale", Vector2.ONE, return_time).set_trans(Tween.TRANS_BACK)

func _kill_owned_tweens() -> void:
    for tween in [_move_tween, _feedback_tween, _crash_tween]:
        if tween and tween.is_running():
            tween.kill()
    _move_tween = null
    _feedback_tween = null
    _crash_tween = null

func _on_area_entered(area: Area2D) -> void:
    if not _active:
        return
    if area is NeonObstacle:
        hit_obstacle.emit(area as NeonObstacle)
    elif area is EnergyPickup:
        collected_pickup.emit(area as EnergyPickup)

func _draw() -> void:
    var pulse := (sin(_pulse_time * 6.0) + 1.0) * 0.5

    # Motion trail, aimed back toward the lane just left.
    for i in range(4):
        var offset := Vector2(-_trail_direction * (38.0 + i * 22.0), 0.0)
        draw_circle(offset, 18.0 - i * 3.2, Color(0.18, 0.74, 1.0, 0.14 - i * 0.025))

    draw_circle(Vector2.ZERO, 51.0 + pulse * 4.0, Color(0.10, 0.65, 1.0, 0.10))
    draw_circle(Vector2.ZERO, 42.0, Color("102c62"))
    draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 48, Color("54d9ff"), 5.0)
    draw_circle(Vector2.ZERO, 28.0, Color("24a8ff"))
    draw_circle(Vector2(-8.0, -10.0), 8.0, Color(0.85, 0.97, 1.0, 0.92))
    draw_circle(Vector2.ZERO, 9.0 + pulse * 2.0, Color("ffffff"))
