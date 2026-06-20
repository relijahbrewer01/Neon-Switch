extends Node2D
class_name NeonBackground

var stars: Array[Dictionary] = []
var drift := 0.0
var intensity := 0.0
var _canvas_size := GameBalance.VIEWPORT_SIZE

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 88421
    for i in range(64):
        stars.append({
            "x_ratio": rng.randf_range(0.04, 0.96),
            "y_ratio": rng.randf_range(0.0, 1.0),
            "r": rng.randf_range(1.0, 3.2),
            "s": rng.randf_range(12.0, 42.0),
            "a": rng.randf_range(0.22, 0.78)
        })

    var viewport := get_viewport()
    var resize_callable := Callable(self, "_refresh_canvas_size")
    if viewport and not viewport.size_changed.is_connected(resize_callable):
        viewport.size_changed.connect(resize_callable)

    _refresh_canvas_size()

func _process(delta: float) -> void:
    drift = fmod(
        drift + delta * (38.0 + intensity * 32.0),
        _canvas_size.y
    )
    queue_redraw()

func set_intensity(value: float) -> void:
    intensity = clampf(value, 0.0, 1.0)

func canvas_size() -> Vector2:
    return _canvas_size

func _refresh_canvas_size() -> void:
    var viewport_size := get_viewport_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = GameBalance.VIEWPORT_SIZE
    _canvas_size = viewport_size
    drift = fmod(drift, _canvas_size.y)
    queue_redraw()

func _draw() -> void:
    var width := _canvas_size.x
    var height := _canvas_size.y
    var center_x := width * 0.5

    draw_rect(Rect2(Vector2.ZERO, _canvas_size), Color("050816"))

    # Soft horizon bands continue across expanded tall-phone viewports.
    var band_count := ceili(height / 122.0) + 1
    for i in range(band_count):
        var y := 180.0 + float(i) * 122.0
        var alpha := 0.018 + float(i % 2) * 0.012
        draw_rect(Rect2(0.0, y, width, 2.0), Color(0.25, 0.45, 0.95, alpha))

    # Star positions are normalized so resizing does not leave the lower part
    # of a tall display empty.
    for star in stars:
        var star_x := float(star.x_ratio) * width
        var base_y := float(star.y_ratio) * height
        var y: float = fmod(base_y + drift * float(star.s) / 24.0, height)
        var radius: float = float(star.r) * (1.0 + intensity * 0.35)
        draw_circle(Vector2(star_x, y), radius, Color(0.58, 0.82, 1.0, float(star.a)))

    # The two neon rails.
    for x in GameBalance.LANE_X:
        draw_line(Vector2(x, 0.0), Vector2(x, height), Color(0.08, 0.38, 0.68, 0.16), 18.0)
        draw_line(Vector2(x, 0.0), Vector2(x, height), Color(0.25, 0.82, 1.0, 0.42), 3.0)

    # Central divider gives the eye a speed reference.
    var divider_count := ceili((height + 64.0) / 108.0) + 1
    for i in range(divider_count):
        var y := fmod(float(i) * 108.0 + drift * 1.45, height + 64.0) - 64.0
        draw_line(Vector2(center_x, y), Vector2(center_x, y + 42.0), Color(0.34, 0.38, 0.68, 0.16), 4.0)

    # Player-zone glow remains aligned with the gameplay player's fixed lane.
    for radius in [210.0, 155.0, 105.0]:
        draw_arc(
            Vector2(center_x, GameBalance.PLAYER_Y + 30.0),
            radius,
            PI,
            TAU,
            48,
            Color(0.10, 0.65, 0.94, 0.035),
            18.0
        )
