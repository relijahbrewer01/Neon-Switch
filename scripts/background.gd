extends Node2D
class_name NeonBackground

const WIDTH := 720.0
const HEIGHT := 1280.0
const LANE_X: Array[float] = [210.0, 510.0]

var stars: Array[Dictionary] = []
var drift := 0.0
var intensity := 0.0

func _ready() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 88421
    for i in range(64):
        stars.append({
            "x": rng.randf_range(28.0, WIDTH - 28.0),
            "y": rng.randf_range(0.0, HEIGHT),
            "r": rng.randf_range(1.0, 3.2),
            "s": rng.randf_range(12.0, 42.0),
            "a": rng.randf_range(0.22, 0.78)
        })
    queue_redraw()

func _process(delta: float) -> void:
    drift = fmod(drift + delta * (38.0 + intensity * 32.0), HEIGHT)
    queue_redraw()

func set_intensity(value: float) -> void:
    intensity = clampf(value, 0.0, 1.0)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, HEIGHT)), Color("050816"))

    # Soft horizon bands.
    for i in range(9):
        var y := 180.0 + float(i) * 122.0
        var alpha := 0.018 + float(i % 2) * 0.012
        draw_rect(Rect2(0.0, y, WIDTH, 2.0), Color(0.25, 0.45, 0.95, alpha))

    # Starfield drifting toward the player.
    for star in stars:
        var y: float = fmod(float(star.y) + drift * float(star.s) / 24.0, HEIGHT)
        var radius: float = float(star.r) * (1.0 + intensity * 0.35)
        draw_circle(Vector2(float(star.x), y), radius, Color(0.58, 0.82, 1.0, float(star.a)))

    # The two neon rails.
    for x in LANE_X:
        draw_line(Vector2(x, 0.0), Vector2(x, HEIGHT), Color(0.08, 0.38, 0.68, 0.16), 18.0)
        draw_line(Vector2(x, 0.0), Vector2(x, HEIGHT), Color(0.25, 0.82, 1.0, 0.42), 3.0)

    # Central divider gives the eye a speed reference.
    for i in range(14):
        var y := fmod(float(i) * 108.0 + drift * 1.45, HEIGHT + 64.0) - 64.0
        draw_line(Vector2(360.0, y), Vector2(360.0, y + 42.0), Color(0.34, 0.38, 0.68, 0.16), 4.0)

    # Player-zone glow.
    for radius in [210.0, 155.0, 105.0]:
        draw_arc(Vector2(360.0, 1080.0), radius, PI, TAU, 48, Color(0.10, 0.65, 0.94, 0.035), 18.0)
