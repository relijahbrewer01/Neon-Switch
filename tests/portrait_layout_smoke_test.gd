extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[portrait-layout] Starting portrait and safe-area smoke test")

    _expect(
        str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand",
        "Expanded canvas supports tall phones and wide desktop windows"
    )
    _expect(
        is_equal_approx(PortraitLayout.playfield_offset_x(Vector2(1600.0, 900.0)), 440.0),
        "A 1600-wide desktop canvas centers the 720-wide playfield"
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

    var main_scene := load(MAIN_SCENE_PATH) as PackedScene
    _expect(main_scene != null, "Main scene loads for layout validation")
    if main_scene == null:
        _finish()
        return

    var game = main_scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var hud := game.get_node("HUD/HUDRoot") as NeonHUD
    var background := game.get_node("Background") as NeonBackground
    var centerer := game.get_node("PlayfieldCenterer") as PlayfieldCenterer
    var world := game.get_node("World") as Node2D
    _expect(hud != null and background != null, "Responsive presentation nodes exist")
    _expect(centerer != null and world != null, "Gameplay centering nodes exist")

    var layout_cases: Array[Dictionary] = [
        {
            "name": "9:16",
            "viewport": Vector2(720.0, 1280.0),
            "safe": Rect2(0.0, 0.0, 720.0, 1280.0),
            "offset": 0.0,
        },
        {
            "name": "9:19.5",
            "viewport": Vector2(720.0, 1560.0),
            "safe": Rect2(0.0, 60.0, 720.0, 1440.0),
            "offset": 0.0,
        },
        {
            "name": "9:20 with cutout insets",
            "viewport": Vector2(720.0, 1600.0),
            "safe": Rect2(18.0, 80.0, 684.0, 1440.0),
            "offset": 0.0,
        },
        {
            "name": "16:9 desktop",
            "viewport": Vector2(1600.0, 900.0),
            "safe": Rect2(0.0, 0.0, 1600.0, 900.0),
            "offset": 440.0,
        },
    ]

    for layout_case in layout_cases:
        var case_name := str(layout_case["name"])
        var viewport_size: Vector2 = layout_case["viewport"]
        var safe_rect: Rect2 = layout_case["safe"]
        var expected_offset := float(layout_case["offset"])

        hud.apply_layout(viewport_size, safe_rect)
        background.apply_canvas_size(viewport_size)
        centerer.apply_viewport_size(viewport_size)
        hud.show_ready(999999)
        hud.update_stats(999999, 999999, 999999)
        await process_frame

        _expect(
            _rects_equal(hud.current_safe_rect(), safe_rect),
            "%s preserves the expected safe rectangle" % case_name
        )
        _expect(
            PortraitLayout.contains_rect(safe_rect, hud.current_content_rect()),
            "%s keeps UI content inside the safe area" % case_name
        )
        _expect(
            is_equal_approx(hud.current_content_rect().get_center().x, safe_rect.get_center().x),
            "%s centers the HUD content column" % case_name
        )
        _expect(hud.layout_is_inside_safe_area(), "%s keeps ready UI safe" % case_name)
        _expect(hud.stats_fit_current_layout(), "%s fits six-digit stats" % case_name)
        _expect(
            background.canvas_size().is_equal_approx(viewport_size),
            "%s fills the available background canvas" % case_name
        )
        _expect(
            is_equal_approx(background.playfield_offset_x(), expected_offset),
            "%s centers the background gameplay geometry" % case_name
        )
        _expect(
            is_equal_approx(centerer.offset_x(), expected_offset),
            "%s centers the gameplay world" % case_name
        )

        hud.show_game_over(999999, 999999, 999999, true)
        await process_frame
        _expect(hud.layout_is_inside_safe_area(), "%s keeps game-over UI safe" % case_name)

    _expect(hud.is_input_passthrough(), "Responsive HUD remains pointer-transparent")

    var feedback := game.get("feedback") as NeonFeedback
    feedback.shutdown()
    await process_frame
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
