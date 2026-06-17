extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const SAVE_PATH := "user://neon_switch_save.cfg"
const EXPECTED_VERSION := "0.1.0-dev.3"

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[baseline] Starting Neon Switch smoke test")
    _remove_test_save()

    _expect(
        str(ProjectSettings.get_setting("application/config/version", "")) == EXPECTED_VERSION,
        "Project exposes the expected canonical version"
    )
    _expect(GameBalance.VIEWPORT_SIZE == Vector2(720.0, 1280.0), "Balance config owns viewport size")
    _expect(GameBalance.LANE_X == [210.0, 510.0], "Balance config preserves lane positions")
    _expect(is_equal_approx(GameBalance.START_SPEED, 650.0), "Balance config preserves starting speed")
    _expect(is_equal_approx(GameBalance.MAX_SPEED, 1120.0), "Balance config preserves maximum speed")
    _expect(is_equal_approx(GameBalance.START_SPAWN_INTERVAL, 0.92), "Balance config preserves starting spawn interval")
    _expect(is_equal_approx(GameBalance.MIN_SPAWN_INTERVAL, 0.48), "Balance config preserves minimum spawn interval")
    _expect(is_equal_approx(GameBalance.PICKUP_SCORE, 25.0), "Balance config preserves pickup reward")

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

    var player = game.get_node("World/Player")
    var world = game.get_node("World")
    var hud = game.get_node("HUD/HUDRoot")

    _expect(int(game.get("state")) == 0, "Game begins in READY state")
    _expect(not bool(game.get("state_transition_in_progress")), "Initial READY transition unlocks")
    _expect(int(game.get("best_score")) == 0, "Missing save defaults best score to zero")
    _expect(player != null and world != null and hud != null, "Required runtime nodes exist")
    _expect(int(player.get("lane_index")) == GameBalance.PLAYER_START_LANE, "Player begins in configured lane")

    var version_label = hud.get("version_label")
    _expect(version_label != null, "HUD creates a version label")
    _expect(version_label != null and version_label.text == "v%s" % EXPECTED_VERSION, "HUD displays the canonical project version")

    var ready_serial := int(game.get("state_transition_serial"))
    game.call("_input", _make_key_event(KEY_SPACE))

    _expect(int(game.get("state")) == 1, "Space routes through the primary action and enters PLAYING")
    _expect(bool(game.get("state_transition_in_progress")), "State transition remains locked through the current frame")
    _expect(int(game.get("state_transition_serial")) == ready_serial + 1, "READY to PLAYING records one transition")
    _expect(bool(player.get("active")), "Player activates when a run starts")

    game.call("_input", _make_mouse_event())
    _expect(int(player.get("lane_index")) == GameBalance.PLAYER_START_LANE, "Duplicate same-frame input cannot switch immediately after starting")
    _expect(not bool(game.call("_enter_playing_state")), "Entering the active state twice is rejected")

    await process_frame
    _expect(not bool(game.get("state_transition_in_progress")), "PLAYING transition unlocks on the next frame")

    game.call("_input", _make_mouse_event())
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(int(player.get("lane_index")) == 1, "Mouse input switches exactly one lane")

    game.call("_input", _make_touch_event())
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(int(player.get("lane_index")) == GameBalance.PLAYER_START_LANE, "Touch uses the same primary action path")

    var pickup = pickup_scene.instantiate()
    pickup.position = player.position
    world.add_child(pickup)
    await physics_frame
    await physics_frame

    _expect(int(game.get("shards")) == 1, "Pickup collision increments shard count once")
    _expect(float(game.get("score_float")) >= GameBalance.PICKUP_SCORE, "Pickup collision awards configured score")

    game.set("displayed_score", 123)
    game.set("score_float", 123.0)

    var obstacle = obstacle_scene.instantiate()
    obstacle.position = player.position
    world.add_child(obstacle)
    var playing_serial := int(game.get("state_transition_serial"))
    await physics_frame
    await physics_frame

    _expect(int(game.get("state")) == 2, "Obstacle collision enters GAME_OVER")
    _expect(int(game.get("state_transition_serial")) == playing_serial + 1, "Collision records one GAME_OVER transition")
    _expect(not bool(player.get("active")), "Player deactivates after collision")

    var game_over_serial := int(game.get("state_transition_serial"))
    game.call("_on_player_hit", obstacle)
    _expect(int(game.get("state_transition_serial")) == game_over_serial, "Duplicate collision cannot trigger another game-over transition")

    game.call("_handle_primary_action")
    _expect(int(game.get("state")) == 2, "Restart input is ignored while the transition and restart lock are active")

    await process_frame
    game.set("restart_lock", 0.0)
    game.call("_handle_primary_action")
    game.call("_handle_primary_action")

    _expect(int(game.get("state")) == 1, "Unlocked restart enters PLAYING directly")
    _expect(int(game.get("state_transition_serial")) == game_over_serial + 1, "Double restart input records only one transition")
    _expect(int(player.get("lane_index")) == GameBalance.PLAYER_START_LANE, "Second restart input cannot become an immediate lane switch")

    await create_timer(GameBalance.GAME_OVER_PANEL_DELAY + 0.06).timeout
    var panel = hud.get("panel")
    _expect(panel != null and not bool(panel.visible), "Stale delayed game-over UI cannot cover a restarted run")
    _expect(int(game.get("best_score")) == 123, "A new best score is recorded")
    _expect(FileAccess.file_exists(SAVE_PATH), "Best score creates a save file")

    await process_frame
    var second_obstacle = obstacle_scene.instantiate()
    game.call("_on_player_hit", second_obstacle)
    await create_timer(GameBalance.GAME_OVER_PANEL_DELAY + 0.06).timeout
    _expect(int(game.get("state")) == 2, "A later run can still enter GAME_OVER")
    _expect(panel != null and bool(panel.visible), "Current game-over transition displays its panel")

    game.queue_free()
    await process_frame
    await process_frame

    var reloaded_game = main_scene.instantiate()
    get_root().add_child(reloaded_game)
    await process_frame
    await process_frame

    _expect(int(reloaded_game.get("best_score")) == 123, "Best score persists across a fresh scene instance")

    var reloaded_player = reloaded_game.get_node("World/Player")
    for run_index in range(10):
        if int(reloaded_game.get("state")) == 0:
            reloaded_game.call("_handle_primary_action")
        elif int(reloaded_game.get("state")) == 2:
            reloaded_game.set("restart_lock", 0.0)
            reloaded_game.call("_handle_primary_action")
        await process_frame

        _expect(int(reloaded_game.get("state")) == 1, "Restart cycle %d enters PLAYING" % (run_index + 1))
        _expect(bool(reloaded_player.get("active")), "Restart cycle %d activates player" % (run_index + 1))

        var cycle_serial := int(reloaded_game.get("state_transition_serial"))
        var cycle_obstacle = obstacle_scene.instantiate()
        reloaded_game.call("_on_player_hit", cycle_obstacle)
        reloaded_game.call("_on_player_hit", cycle_obstacle)
        await process_frame

        _expect(int(reloaded_game.get("state")) == 2, "Restart cycle %d reaches GAME_OVER" % (run_index + 1))
        _expect(int(reloaded_game.get("state_transition_serial")) == cycle_serial + 1, "Restart cycle %d processes one collision transition" % (run_index + 1))
        _expect(not bool(reloaded_player.get("active")), "Restart cycle %d deactivates player" % (run_index + 1))

    reloaded_game.queue_free()
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

func _make_touch_event() -> InputEventScreenTouch:
    var event := InputEventScreenTouch.new()
    event.index = 0
    event.pressed = true
    event.position = Vector2(360.0, 640.0)
    return event

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[baseline][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[baseline][FAIL] %s" % message)

func _remove_test_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
        var error := DirAccess.remove_absolute(absolute_path)
        if error != OK:
            push_warning("[baseline] Could not remove test save at %s (error %d)" % [absolute_path, error])

func _finish() -> void:
    if failures.is_empty():
        print("[baseline] All smoke tests passed")
        quit(0)
        return
    push_error("[baseline] %d smoke test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
