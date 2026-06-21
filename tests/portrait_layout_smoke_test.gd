extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[portrait-layout] Starting portrait and safe-area smoke test")

    _expect(
        str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "keep_width",
        "Project keeps portrait width fixed, centers wide screens, and expands vertically"
    )

    var mapped_safe_area := PortraitLayout.map_display_safe_area(
        Vector2(720.0, 1600.0),
        Vector2i(1080, 2400),
        Rect2i(0, 120, 1080, 2160)
    )
    _expect(
        _rects_equal(mapped_safe_area, Rect2(0.0, 80.0, 720.0, 1440.0)),
        "Physical display insets map into logical viewport coordinates"
    )

    var fallback_safe_area := PortraitLayout.map_display_safe_area(
        Vector2(720.0, 1600.0),
        Vector2i.ZERO,
        Rect2i()
    )
    _expect(
        _rects_equal(fallback_safe_area, Rect2(0.0, 0.0, 720.0, 1600.0)),
        "Invalid display data falls back to the full logical viewport"
    )

    var clamped_safe_area := PortraitLayout.clamp_rect_to_viewport(
        Rect2(-20.0, -30.0, 780.0, 1680.0),
        Vector2(720.0, 1600.0)
    )
    _expect(
        _rects_equal(clamped_safe_area, Rect2(0.0, 0.0, 720.0, 1600.0)),
        "Safe rectangles are clamped to visible viewport bounds"
    )

    var main_scene := load(MAIN_SCENE_PATH) as PackedScene
    _expect(main_scene != null, "Main scene loads for portrait validation")
    if main_scene == null:
        _finish()
        return

    var game = main_scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var hud := game.get_node("HUD/HUDRoot") as NeonHUD
    var background := game.get_node("Background") as NeonBackground
    _expect(hud != null, "HUD exists for portrait validation")
    _expect(background != null, "Background exists for portrait validation")

    var layout_cases: Array[Dictionary] = [
        {
            "name": "9:16",
            "viewport": Vector2(720.0, 1280.0),
            "safe": Rect2(0.0, 0.0, 720.0, 1280.0),
        },
        {
            "name": "9:19.5",
            "viewport": Vector2(720.0, 1560.0),
            "safe": Rect2(0.0, 60.0, 720.0, 1440.0),
        },
        {
            "name": "9:20 with side and camera insets",
            "viewport": Vector2(720.0, 1600.0),
            "safe": Rect2(18.0, 80.0, 684.0, 1440.0),
        },
    ]

    for layout_case in layout_cases:
        var case_name := str(layout_case["name"])
        var viewport_size: Vector2 = layout_case["viewport"]
        var safe_rect: Rect2 = layout_case["safe"]

        hud.apply_layout(viewport_size, safe_rect)
        background.apply_canvas_size(viewport_size)
        hud.show_ready(999999)
        hud.update_stats(999999, 999999, 999999)
        await process_frame
        await process_frame

        _expect(
            _rects_equal(hud.current_safe_rect(), safe_rect),
            "%s preserves the expected safe rectangle" % case_name
        )
        _expect(
            PortraitLayout.contains_rect(
                safe_rect,
                hud.current_content_rect()
            ),
            "%s keeps the content rectangle inside the safe area" % case_name
        )
        _expect(
            hud.layout_is_inside_safe_area(),
            "%s keeps visible ready-state UI inside the safe area" % case_name
        )
        _expect(
            hud.stats_fit_current_layout(),
            "%s fits six-digit score, best, and shard values" % case_name
        )
        _expect(
            background.canvas_size().is_equal_approx(viewport_size),
            "%s expands the procedural background across the viewport" % case_name
        )

        hud.show_game_over(999999, 999999, 999999, true)
        await process_frame
        await process_frame
        _expect(
            hud.layout_is_inside_safe_area(),
            "%s keeps the game-over panel inside the safe area" % case_name
        )

    _expect(hud.is_input_passthrough(), "Responsive HUD remains pointer-transparent")

    game.queue_free()
    await process_frame
    _finish()

func _rects_equal(a: Rect2, b: Rect2, epsilon: float = 0.01) -> bool:
    return (
        absf(a.position.x - b.position.x) <= epsilon
        and absf(a.position.y - b.position.y) <= epsilon
        and absf(a.size.x - b.size.x) <= epsilon
        and absf(a.size.y - b.size.y) <= epsilon
    )

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[portrait-layout][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[portrait-layout][FAIL] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[portrait-layout] All portrait layout tests passed")
        quit(0)
        return
    push_error("[portrait-layout] %d test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
