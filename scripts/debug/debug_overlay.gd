extends Control
class_name NeonDebugOverlay

## Development-only runtime diagnostics panel.
##
## The overlay is always pointer-transparent and remains hidden until F3 toggles
## it. Main supplies a compact snapshot so the overlay does not reach into
## gameplay internals or become another controller.

const PANEL_WIDTH := 330.0
const PANEL_MARGIN := 12.0

var panel: PanelContainer
var text_label: Label
var _snapshot: Dictionary = {}
var _safe_rect := Rect2(Vector2.ZERO, PortraitLayout.DESIGN_SIZE)

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    focus_mode = Control.FOCUS_NONE
    z_index = 100
    _build_ui()
    set_open(false)

func _build_ui() -> void:
    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.focus_mode = Control.FOCUS_NONE

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.015, 0.025, 0.065, 0.92)
    panel_style.border_color = Color(0.30, 0.88, 1.0, 0.78)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(12)
    panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
    panel_style.shadow_size = 8
    panel.add_theme_stylebox_override("panel", panel_style)
    add_child(panel)

    var margin := MarginContainer.new()
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.focus_mode = Control.FOCUS_NONE
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    text_label = Label.new()
    text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_label.focus_mode = Control.FOCUS_NONE
    text_label.add_theme_font_size_override("font_size", 17)
    text_label.add_theme_color_override("font_color", Color("bfefff"))
    text_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
    text_label.add_theme_constant_override("shadow_offset_x", 1)
    text_label.add_theme_constant_override("shadow_offset_y", 2)
    margin.add_child(text_label)

func toggle() -> bool:
    set_open(not visible)
    return visible

func set_open(open: bool) -> void:
    visible = open
    if open:
        _apply_panel_position()

func is_open() -> bool:
    return visible

func apply_safe_rect(safe_rect: Rect2) -> void:
    _safe_rect = safe_rect
    _apply_panel_position()

func update_snapshot(snapshot: Dictionary) -> void:
    _snapshot = snapshot.duplicate(true)
    if text_label == null:
        return

    var seed_text := "RANDOM"
    if bool(snapshot.get("deterministic", false)):
        seed_text = str(int(snapshot.get("seed", -1)))

    text_label.text = (
        "F3  DEVELOPMENT DIAGNOSTICS\n"
        + "STATE      %s\n" % str(snapshot.get("state", "UNKNOWN"))
        + "SEED       %s\n" % seed_text
        + "SPEED      %.1f\n" % float(snapshot.get("speed", 0.0))
        + "SPAWN      %.3f s\n" % float(snapshot.get("spawn_interval", 0.0))
        + "ELAPSED    %.2f s\n" % float(snapshot.get("elapsed", 0.0))
        + "LANE       %d\n" % int(snapshot.get("lane", -1))
        + "OBSTACLES  %d\n" % int(snapshot.get("obstacles", 0))
        + "PICKUPS    %d\n" % int(snapshot.get("pickups", 0))
        + "ENTITIES   %d\n" % int(snapshot.get("entities", 0))
        + "INPUT      %s" % str(snapshot.get("input", "none"))
    )
    panel.reset_size()
    _apply_panel_position()

func current_snapshot() -> Dictionary:
    return _snapshot.duplicate(true)

func snapshot_text() -> String:
    return "" if text_label == null else text_label.text

func panel_rect() -> Rect2:
    return Rect2(panel.position, panel.size)

func _apply_panel_position() -> void:
    if panel == null:
        return

    var width := minf(PANEL_WIDTH, maxf(1.0, _safe_rect.size.x - PANEL_MARGIN * 2.0))
    panel.size.x = width
    panel.position = Vector2(
        _safe_rect.end.x - width - PANEL_MARGIN,
        _safe_rect.position.y + PANEL_MARGIN
    )
