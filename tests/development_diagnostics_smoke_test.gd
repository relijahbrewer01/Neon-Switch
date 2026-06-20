extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const TEST_SEED := 424242

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[diagnostics] Starting development diagnostics smoke test")

    _expect(
        int(ProjectSettings.get_setting("debug/neon_switch/deterministic_seed", -99)) == -1,
        "Project defaults to random gameplay seeding"
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

    var overlay := game.get("debug_overlay") as NeonDebugOverlay
    var player := game.get_node("World/Player") as NeonPlayer
    var world := game.get_node("World") as Node2D
    var panel_timer := game.get("game_over_panel_timer") as Timer
    var feedback := game.get("feedback") as NeonFeedback

    _expect(overlay != null, "Main owns a diagnostics overlay")
    _expect(overlay != null and not overlay.is_open(), "Diagnostics begin hidden")

    game.call("_unhandled_input", _make_key_event(KEY_F3, true, false))
    await process_frame
    _expect(overlay.is_open(), "F3 opens diagnostics")
    _expect(overlay.snapshot_text().contains("STATE      READY"), "Ready state appears in diagnostics")
    _expect(overlay.snapshot_text().contains("SPEED"), "Speed appears in diagnostics")
    _expect(overlay.snapshot_text().contains("SPAWN"), "Spawn interval appears in diagnostics")
    _expect(overlay.snapshot_text().contains("ELAPSED"), "Elapsed time appears in diagnostics")
    _expect(overlay.snapshot_text().contains("LANE"), "Lane appears in diagnostics")
    _expect(overlay.snapshot_text().contains("ENTITIES"), "Entity count appears in diagnostics")
    _expect(
        PortraitLayout.contains_rect(
            game.get_node("HUD/HUDRoot").current_safe_rect(),
            overlay.panel_rect()
        ),
        "Diagnostics panel stays inside the current safe area"
    )

    game.call("_unhandled_input", _make_key_event(KEY_F3, false, false))
    game.call("_unhandled_input", _make_key_event(KEY_F3, true, true))
    _expect(overlay.is_open(), "F3 release and repeat events are ignored")

    game.call("set_deterministic_seed", TEST_SEED)
    _expect(bool(game.call("uses_deterministic_seed")), "Deterministic mode can be enabled")
    _expect(int(game.call("deterministic_seed_value")) == TEST_SEED, "Configured seed is exposed")

    game.call("_unhandled_input", _make_key_event(KEY_SPACE, true, false))
    await process_frame
    _expect(int(game.get("state")) == 1, "Space starts a deterministic run")
    _expect(overlay.snapshot_text().contains("STATE      PLAYING"), "Playing state appears in diagnostics")
    _expect(overlay.snapshot_text().contains("SEED       %d" % TEST_SEED), "Active seed appears in diagnostics")

    var game_rng := game.get("rng") as RandomNumberGenerator
    var first_sequence: Array[int] = [game_rng.randi(), game_rng.randi(), game_rng.randi()]

    var obstacle := obstacle_scene.instantiate() as NeonObstacle
    obstacle.configure(0.0)
    obstacle.position = Vector2(GameBalance.LANE_X[0], 100.0)
    world.add_child(obstacle)

    var pickup := pickup_scene.instantiate() as EnergyPickup
    pickup.configure(0.0)
    pickup.position = Vector2(GameBalance.LANE_X[1], 100.0)
    world.add_child(pickup)
    await process_frame

    var snapshot := game.call("debug_snapshot") as Dictionary
    _expect(int(snapshot.get("obstacles", 0)) == 1, "Diagnostics count active obstacles")
    _expect(int(snapshot.get("pickups", 0)) == 1, "Diagnostics count active pickups")
    _expect(int(snapshot.get("entities", 0)) == 2, "Diagnostics report total active entities")

    game.call("_enter_game_over_state")
    await process_frame
    _expect(int(game.get("state")) == 2, "Forced crash enters GAME_OVER")
    _expect(not panel_timer.is_stopped(), "Owned game-over panel timer starts")
    _expect(overlay.snapshot_text().contains("STATE      GAME_OVER"), "Game-over state appears in diagnostics")

    game.set("restart_lock", 0.0)
    game.call("_handle_primary_action")
    await process_frame
    _expect(int(game.get("state")) == 1, "Restart returns to PLAYING")
    _expect(panel_timer.is_stopped(), "Restart cancels the owned game-over timer")

    var second_sequence: Array[int] = [game_rng.randi(), game_rng.randi(), game_rng.randi()]
    _expect(first_sequence == second_sequence, "The same debug seed reproduces the run RNG sequence")

    game.call("set_deterministic_seed", -1)
    _expect(not bool(game.call("uses_deterministic_seed")), "Negative seed restores random mode")

    game.call("_unhandled_input", _make_key_event(KEY_F3, true, false))
    await process_frame
    _expect(not overlay.is_open(), "F3 closes diagnostics")

    feedback.shutdown()
    await process_frame
    await process_frame
    game.queue_free()
    await process_frame
    await process_frame
    _finish()

func _make_key_event(keycode: Key, pressed: bool, echo: bool) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = keycode
    event.pressed = pressed
    event.echo = echo
    return event

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[diagnostics][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[diagnostics][FAIL] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[diagnostics] All development diagnostics tests passed")
        quit(0)
        return
    push_error("[diagnostics] %d test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
