extends Control
class_name NeonHUD

var version_label: Label
var score_label: Label
var best_label: Label
var shard_label: Label
var title_label: Label
var subtitle_label: Label
var hint_label: Label
var footer_label: Label
var panel: PanelContainer
var flash: ColorRect
var top_bar: HBoxContainer
var safe_container: MarginContainer
var layout: VBoxContainer

var _safe_rect := Rect2(Vector2.ZERO, PortraitLayout.DESIGN_SIZE)
var _content_rect := Rect2(Vector2.ZERO, PortraitLayout.DESIGN_SIZE)

func _ready() -> void:
    _build_ui()
    _apply_input_passthrough(self)

    var viewport := get_viewport()
    var resize_callable := Callable(self, "_refresh_layout")
    if viewport and not viewport.size_changed.is_connected(resize_callable):
        viewport.size_changed.connect(resize_callable)

    _refresh_layout()
    show_ready(0)

func _build_ui() -> void:
    flash = ColorRect.new()
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(1.0, 0.2, 0.35, 0.0)
    add_child(flash)

    safe_container = MarginContainer.new()
    safe_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
    add_child(safe_container)

    layout = VBoxContainer.new()
    layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    safe_container.add_child(layout)

    top_bar = HBoxContainer.new()
    top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
    top_bar.add_theme_constant_override("separation", 10)
    layout.add_child(top_bar)

    score_label = _make_label("0", 50, Color("f4fbff"), HORIZONTAL_ALIGNMENT_LEFT)
    score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    score_label.custom_minimum_size.x = 150.0
    top_bar.add_child(score_label)

    shard_label = _make_label("◆ 0", 24, Color("65f7c3"), HORIZONTAL_ALIGNMENT_CENTER)
    shard_label.custom_minimum_size.x = 136.0
    top_bar.add_child(shard_label)

    best_label = _make_label("BEST 0", 23, Color("8db3d9"), HORIZONTAL_ALIGNMENT_RIGHT)
    best_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    best_label.custom_minimum_size.x = 170.0
    top_bar.add_child(best_label)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(spacer)

    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(0.0, 350.0)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.025, 0.055, 0.13, 0.93)
    panel_style.border_color = Color(0.18, 0.72, 1.0, 0.62)
    panel_style.set_border_width_all(3)
    panel_style.set_corner_radius_all(30)
    panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
    panel_style.shadow_size = 18
    panel.add_theme_stylebox_override("panel", panel_style)
    layout.add_child(panel)

    var panel_margin := MarginContainer.new()
    panel_margin.add_theme_constant_override("margin_left", 34)
    panel_margin.add_theme_constant_override("margin_top", 34)
    panel_margin.add_theme_constant_override("margin_right", 34)
    panel_margin.add_theme_constant_override("margin_bottom", 34)
    panel.add_child(panel_margin)

    var panel_box := VBoxContainer.new()
    panel_box.alignment = BoxContainer.ALIGNMENT_CENTER
    panel_box.add_theme_constant_override("separation", 14)
    panel_margin.add_child(panel_box)

    title_label = _make_label("NEON SWITCH", 56, Color("62ddff"), HORIZONTAL_ALIGNMENT_CENTER)
    panel_box.add_child(title_label)

    subtitle_label = _make_label("Dodge the barriers. Collect the light.", 25, Color("d9ebff"), HORIZONTAL_ALIGNMENT_CENTER)
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel_box.add_child(subtitle_label)

    hint_label = _make_label("TAP ANYWHERE TO BEGIN\nTap again to switch lanes", 27, Color("67f4c3"), HORIZONTAL_ALIGNMENT_CENTER)
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel_box.add_child(hint_label)

    footer_label = _make_label("SPACE / CLICK / ENTER ALSO WORK", 17, Color(0.52, 0.65, 0.78, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
    layout.add_child(footer_label)

    # Read the canonical build version from project.godot so screenshots and
    # bug reports identify the exact build without duplicating version strings.
    var app_version := str(ProjectSettings.get_setting("application/config/version", "0.0.0-dev"))
    version_label = _make_label("v%s" % app_version, 13, Color(0.52, 0.65, 0.78, 0.72), HORIZONTAL_ALIGNMENT_LEFT)
    add_child(version_label)

func _refresh_layout() -> void:
    var viewport_size := get_viewport_rect().size
    var safe_rect := PortraitLayout.runtime_safe_rect(viewport_size)
    apply_layout(viewport_size, safe_rect)

func apply_layout(viewport_size: Vector2, safe_rect: Rect2) -> void:
    _safe_rect = PortraitLayout.clamp_rect_to_viewport(safe_rect, viewport_size)
    _content_rect = PortraitLayout.content_rect(_safe_rect)

    safe_container.position = _content_rect.position
    safe_container.size = _content_rect.size

    version_label.position = _safe_rect.position + Vector2(8.0, 4.0)
    version_label.size = Vector2(minf(220.0, _safe_rect.size.x - 16.0), 20.0)

    safe_container.queue_sort()
    layout.queue_sort()
    top_bar.queue_sort()

func current_safe_rect() -> Rect2:
    return _safe_rect

func current_content_rect() -> Rect2:
    return _content_rect

func layout_is_inside_safe_area() -> bool:
    if not PortraitLayout.contains_rect(_safe_rect, Rect2(safe_container.position, safe_container.size)):
        return false
    if not PortraitLayout.contains_rect(_safe_rect, version_label.get_global_rect()):
        return false
    if panel.visible and not PortraitLayout.contains_rect(_safe_rect, panel.get_global_rect()):
        return false
    return true

func stats_fit_current_layout() -> bool:
    var required_width := (
        score_label.get_combined_minimum_size().x
        + shard_label.get_combined_minimum_size().x
        + best_label.get_combined_minimum_size().x
        + float(top_bar.get_theme_constant("separation")) * 2.0
    )
    return (
        required_width <= top_bar.size.x + 0.5
        and top_bar.size.x <= _content_rect.size.x + 0.5
    )

func _apply_input_passthrough(node: Node) -> void:
    if node is Control:
        var control := node as Control
        control.mouse_filter = Control.MOUSE_FILTER_IGNORE
        control.focus_mode = Control.FOCUS_NONE

    for child in node.get_children():
        _apply_input_passthrough(child)

func is_input_passthrough() -> bool:
    return _is_input_passthrough_recursive(self)

func _is_input_passthrough_recursive(node: Node) -> bool:
    if node is Control:
        var control := node as Control
        if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
            return false
        if control.focus_mode != Control.FOCUS_NONE:
            return false

    for child in node.get_children():
        if not _is_input_passthrough_recursive(child):
            return false
    return true

func _make_label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
    var label := Label.new()
    label.text = text_value
    label.horizontal_alignment = alignment
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.58))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 3)
    return label

func show_ready(best: int) -> void:
    panel.visible = true
    title_label.text = "NEON SWITCH"
    subtitle_label.text = "Dodge the barriers. Collect the light."
    hint_label.text = "TAP ANYWHERE TO BEGIN\nTap again to switch lanes"
    best_label.text = "BEST %d" % best
    score_label.text = "0"
    shard_label.text = "◆ 0"

func show_playing() -> void:
    panel.visible = false

func show_game_over(score: int, best: int, shards: int, is_new_best: bool) -> void:
    panel.visible = true
    title_label.text = "NEW BEST!" if is_new_best else "SIGNAL LOST"
    subtitle_label.text = "Score %d   •   Shards %d\nBest %d" % [score, shards, best]
    hint_label.text = "TAP TO RESTART"
    best_label.text = "BEST %d" % best

func update_stats(score: int, best: int, shards: int) -> void:
    score_label.text = str(score)
    best_label.text = "BEST %d" % best
    shard_label.text = "◆ %d" % shards

func pulse_score() -> void:
    var tween := create_tween()
    tween.tween_property(score_label, "scale", Vector2(1.10, 1.10), 0.05)
    tween.tween_property(score_label, "scale", Vector2.ONE, 0.09)

func flash_collect() -> void:
    flash.color = Color(0.25, 1.0, 0.72, 0.18)
    var tween := create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.16)

func flash_crash() -> void:
    flash.color = Color(1.0, 0.12, 0.25, 0.44)
    var tween := create_tween()
    tween.tween_property(flash, "color:a", 0.0, 0.42)
