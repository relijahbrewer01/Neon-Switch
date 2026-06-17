extends Area2D
class_name NeonPlayer

signal hit_obstacle(obstacle: NeonObstacle)
signal collected_pickup(pickup: EnergyPickup)

var lane_index: int = GameBalance.PLAYER_START_LANE
var active: bool = false
var move_tween: Tween
var pulse_time: float = 0.0
var trail_direction: float = 1.0

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    queue_redraw()

func _process(delta: float) -> void:
    pulse_time += delta
    queue_redraw()

func reset_player() -> void:
    active = false
    lane_index = GameBalance.PLAYER_START_LANE
    position = Vector2(GameBalance.LANE_X[lane_index], GameBalance.PLAYER_Y)
    scale = Vector2.ONE
    rotation = 0.0
    modulate = Color.WHITE
    monitoring = true
    if move_tween and move_tween.is_running():
        move_tween.kill()
    queue_redraw()

func set_active(value: bool) -> void:
    active = value

func switch_lane() -> void:
    if not active:
        return

    lane_index = 1 - lane_index
    var old_x: float = position.x
    var target_x: float = GameBalance.LANE_X[lane_index]
    trail_direction = signf(target_x - old_x)

    if move_tween and move_tween.is_running():
        move_tween.kill()

    move_tween = create_tween()
    move_tween.set_trans(Tween.TRANS_BACK)
    move_tween.set_ease(Tween.EASE_OUT)
    move_tween.tween_property(self, "position:x", target_x, GameBalance.PLAYER_SWITCH_TIME)

    var squash := create_tween()
    squash.tween_property(self, "scale", Vector2(1.24, 0.82), 0.055)
    squash.tween_property(self, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK)

    if OS.has_feature("mobile"):
        Input.vibrate_handheld(18)

func crash() -> void:
    active = false
    # Physics monitoring cannot be changed synchronously from an area-entered
    # callback. Defer the property update so the current physics step can end.
    set_deferred("monitoring", false)
    if move_tween and move_tween.is_running():
        move_tween.kill()
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.16).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(self, "modulate:a", 0.0, 0.18)
    tween.tween_property(self, "rotation", rotation + PI * 0.75, 0.18)

func celebrate_pickup() -> void:
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.055)
    tween.tween_property(self, "scale", Vector2.ONE, 0.085)

func _on_area_entered(area: Area2D) -> void:
    if not active:
        return
    if area is NeonObstacle:
        hit_obstacle.emit(area as NeonObstacle)
    elif area is EnergyPickup:
        collected_pickup.emit(area as EnergyPickup)

func _draw() -> void:
    var pulse := (sin(pulse_time * 6.0) + 1.0) * 0.5

    # Motion trail, aimed back toward the lane just left.
    for i in range(4):
        var offset := Vector2(-trail_direction * (38.0 + i * 22.0), 0.0)
        draw_circle(offset, 18.0 - i * 3.2, Color(0.18, 0.74, 1.0, 0.14 - i * 0.025))

    draw_circle(Vector2.ZERO, 51.0 + pulse * 4.0, Color(0.10, 0.65, 1.0, 0.10))
    draw_circle(Vector2.ZERO, 42.0, Color("102c62"))
    draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 48, Color("54d9ff"), 5.0)
    draw_circle(Vector2.ZERO, 28.0, Color("24a8ff"))
    draw_circle(Vector2(-8.0, -10.0), 8.0, Color(0.85, 0.97, 1.0, 0.92))
    draw_circle(Vector2.ZERO, 9.0 + pulse * 2.0, Color("ffffff"))
