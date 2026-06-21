extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const SAVE_PATH := SaveService.DEFAULT_SAVE_PATH
const EXPECTED_VERSION := "0.1.0-dev.11"

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[baseline] Starting Neon Switch integration smoke test")
    _remove_test_save()

    _expect(
        str(ProjectSettings.get_setting("application/config/version", "")) == EXPECTED_VERSION,
        "Project exposes the expected canonical version"
    )
    _expect(
        str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand",
        "Expanded canvas remains enabled for tall phones and wide desktops"
    )
    _expect(
        int(ProjectSettings.get_setting("display/window/size/initial_position_type", -1)) == 1,
        "Standalone desktop window requests a centered initial position"
    )
    _expect(
        bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)),
        "Android ETC2 and ASTC texture imports are enabled"
    )

    var main_scene := load(MAIN_SCENE_PATH) as PackedScene
    var obstacle_scene := load(OBSTACLE_SCENE_PATH) as PackedScene
    var pickup_scene := load(PICKUP_SCENE_PATH) as PackedScene
    _expect(main_scene != null, "Main scene loads")
    _expect(obstacle_scene != null, "Obstacle scene loads")
    _expect(pickup_scene != null, "Pickup scene loads")
    if main_scene == null or obstacle_scene == null or pickup_scene == null:
        _finish()
        return

    var game = main_scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var player := game.get_node("World/Player") as NeonPlayer
    var world := game.get_node("World") as Node2D
    var hud := game.get_node("HUD/HUDRoot") as NeonHUD
    var background := game.get_node("Background") as NeonBackground
    var centerer := game.get_node("PlayfieldCenterer") as PlayfieldCenterer
    var feedback := game.get("feedback") as NeonFeedback

    _expect(int(game.get("state")) == 0, "Game begins in READY")
    _expect(player != null and world != null and hud != null, "Core runtime nodes exist")
    _expect(background != null and centerer != null, "Responsive playfield layout nodes exist")
    _expect(feedback != null and feedback.is_built(), "Feedback service initializes")
    _expect(hud.version_label.text == "v%s" % EXPECTED_VERSION, "HUD displays the build version")

    var wide_size := Vector2(1600.0, 900.0)
    var expected_offset := 440.0
    centerer.apply_viewport_size(wide_size)
    background.apply_canvas_size(wide_size)
    hud.apply_layout(wide_size, Rect2(Vector2.ZERO, wide_size))
    await process_frame

    _expect(is_equal_approx(centerer.offset_x(), expected_offset), "Wide desktop playfield offset is centered")
    _expect(is_equal_approx(background.playfield_offset_x(), expected_offset), "Background rails share the centered offset")
    _expect(
        is_equal_approx(hud.current_content_rect().get_center().x, wide_size.x * 0.5),
        "HUD content remains centered on a wide desktop canvas"
    )

    centerer.apply_viewport_size(PortraitLayout.DESIGN_SIZE)
    background.apply_canvas_size(PortraitLayout.DESIGN_SIZE)
    hud.apply_layout(PortraitLayout.DESIGN_SIZE, Rect2(Vector2.ZERO, PortraitLayout.DESIGN_SIZE))

    game.call("_unhandled_input", _make_key_event(KEY_SPACE))
    await process_frame
    _expect(int(game.get("state")) == 1, "Space begins a run")
    _expect(player.is_active(), "Player activates when the run starts")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.START) == 1, "Start feedback plays once")

    game.call("_unhandled_input", _make_mouse_event())
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.05).timeout
    _expect(player.current_lane() == 1, "Mouse input switches exactly one lane")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.SWITCH) == 1, "Switch feedback plays once")

    var pickup := pickup_scene.instantiate() as EnergyPickup
    pickup.configure(GameBalance.START_SPEED)
    pickup.position = player.position
    world.add_child(pickup)
    await physics_frame
    await physics_frame
    _expect(int(game.get("shards")) == 1, "Pickup increments shard count")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.COLLECT) == 1, "Collect feedback plays once")

    var obstacle := obstacle_scene.instantiate() as NeonObstacle
    obstacle.configure(GameBalance.START_SPEED)
    obstacle.position = player.position
    world.add_child(obstacle)
    await physics_frame
    await physics_frame
    _expect(int(game.get("state")) == 2, "Obstacle collision enters GAME_OVER")
    _expect(not player.is_active(), "Crash deactivates the player")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.CRASH) == 1, "Crash feedback plays once")

    game.set("restart_lock", 0.0)
    game.call("_handle_primary_action")
    await process_frame
    _expect(int(game.get("state")) == 1, "Unlocked input restarts the run")
    _expect(player.current_lane() == GameBalance.PLAYER_START_LANE, "Restart restores the starting lane")

    feedback.shutdown()
    await process_frame
    game.queue_free()
    await process_frame
    await process_frame
    _remove_test_save()
    _finish()

func _make_key_event(keycode: Key) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = keycode
    event.pressed = true
    event.echo = false
    return event

func _make_mouse_event() -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    event.position = Vector2(360.0, 640.0)
    return event

func _remove_test_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
    var error := DirAccess.remove_absolute(absolute_path)
    if error != OK:
        push_warning("[baseline] Could not remove test save (error %d)" % error)

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[baseline][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[baseline][FAIL] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[baseline] All integration smoke tests passed")
        quit(0)
        return
    push_error("[baseline] %d smoke test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
