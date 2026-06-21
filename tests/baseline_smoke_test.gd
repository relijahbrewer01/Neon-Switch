extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const SAVE_PATH := SaveService.DEFAULT_SAVE_PATH
const EXPECTED_VERSION := "0.1.0-dev.10"

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
    _expect(GameBalance.LANE_X == [210.0, 510.0], "Balance config preserves lane positions")
    _expect(is_equal_approx(GameBalance.START_SPEED, 650.0), "Balance config preserves starting speed")

    _validate_wave_director()

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
    var save_service := game.get("save_service") as SaveService
    var feedback := game.get("feedback") as NeonFeedback

    _expect(int(game.get("state")) == 0, "Game begins in READY")
    _expect(not bool(game.get("state_transition_in_progress")), "Initial transition unlocks")
    _expect(player != null and world != null and hud != null, "Required runtime nodes exist")
    _expect(save_service != null, "Main owns SaveService")
    _expect(feedback != null and feedback.is_built(), "Main owns initialized NeonFeedback")
    _expect(player.current_lane() == GameBalance.PLAYER_START_LANE, "Player begins in configured lane")
    _expect(not player.is_active(), "Player begins inactive")
    _expect(hud.version_label.text == "v%s" % EXPECTED_VERSION, "HUD displays canonical version")

    var hit_connections := player.get_signal_connection_list(&"hit_obstacle").size()
    var pickup_connections := player.get_signal_connection_list(&"collected_pickup").size()
    game.call("_connect_player_signals")
    game.call("_connect_player_signals")
    _expect(
        player.get_signal_connection_list(&"hit_obstacle").size() == hit_connections,
        "Obstacle signal connection remains unique"
    )
    _expect(
        player.get_signal_connection_list(&"collected_pickup").size() == pickup_connections,
        "Pickup signal connection remains unique"
    )

    game.call("_unhandled_input", _make_key_event(KEY_SPACE))
    _expect(int(game.get("state")) == 1, "Space begins a run")
    _expect(player.is_active(), "Player activates at run start")
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.START) == 1,
        "Run start triggers feedback once"
    )

    game.call("_unhandled_input", _make_mouse_event())
    _expect(
        player.current_lane() == GameBalance.PLAYER_START_LANE,
        "Same-frame duplicate input cannot switch lanes"
    )
    await process_frame

    game.call("_unhandled_input", _make_mouse_event())
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.05).timeout
    _expect(player.current_lane() == 1, "Mouse input switches one lane")
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.SWITCH) == 1,
        "Successful switch triggers feedback once"
    )

    var child_count_before := world.get_child_count()
    var game_rng := game.get("rng") as RandomNumberGenerator
    game_rng.seed = 44221
    game.call("_spawn_wave")
    _expect(world.get_child_count() > child_count_before, "Main instantiates a generated wave")
    game.call("_clear_spawned_objects")
    await process_frame
    await process_frame
    _expect(world.get_child_count() == 1, "Run cleanup leaves only the player")

    var pickup := pickup_scene.instantiate() as EnergyPickup
    pickup.configure(GameBalance.START_SPEED)
    pickup.position = player.position
    world.add_child(pickup)
    await physics_frame
    await physics_frame
    _expect(int(game.get("shards")) == 1, "Pickup increments shard count once")
    _expect(float(game.get("score_float")) >= GameBalance.PICKUP_SCORE, "Pickup awards score")
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.COLLECT) == 1,
        "Pickup triggers collect feedback once"
    )
    game.call("_on_player_collect", pickup)
    _expect(int(game.get("shards")) == 1, "Repeated pickup reporting awards nothing")

    game.set("displayed_score", 123)
    game.set("score_float", 123.0)
    var obstacle := obstacle_scene.instantiate() as NeonObstacle
    obstacle.configure(GameBalance.START_SPEED)
    obstacle.position = player.position
    world.add_child(obstacle)
    var playing_serial := int(game.get("state_transition_serial"))
    await physics_frame
    await physics_frame

    _expect(int(game.get("state")) == 2, "Obstacle collision enters GAME_OVER")
    _expect(
        int(game.get("state_transition_serial")) == playing_serial + 1,
        "Collision records one transition"
    )
    _expect(not player.is_active(), "Crash deactivates player")
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.CRASH) == 1,
        "Crash triggers feedback once"
    )

    var game_over_serial := int(game.get("state_transition_serial"))
    game.call("_on_player_hit", obstacle)
    _expect(
        int(game.get("state_transition_serial")) == game_over_serial,
        "Duplicate collision cannot transition again"
    )
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.CRASH) == 1,
        "Duplicate collision cannot replay crash feedback"
    )

    game.call("_handle_primary_action")
    _expect(int(game.get("state")) == 2, "Restart remains locked briefly")
    await process_frame
    game.set("restart_lock", 0.0)
    game.call("_handle_primary_action")
    game.call("_handle_primary_action")
    _expect(int(game.get("state")) == 1, "Unlocked restart returns to PLAYING")
    _expect(
        int(game.get("state_transition_serial")) == game_over_serial + 1,
        "Double restart input records one transition"
    )
    _expect(player.current_lane() == GameBalance.PLAYER_START_LANE, "Restart resets lane")

    await create_timer(GameBalance.GAME_OVER_PANEL_DELAY + 0.06).timeout
    _expect(not hud.panel.visible, "Stale game-over panel cannot cover restarted run")
    _expect(int(game.get("best_score")) == 123, "New best score is recorded")
    _expect(save_service.best_score() == 123, "SaveService receives new best")
    _expect(FileAccess.file_exists(SAVE_PATH), "New best creates save file")

    feedback.shutdown()
    await process_frame
    await process_frame
    game.queue_free()
    await process_frame
    await process_frame

    var reloaded_game = main_scene.instantiate()
    get_root().add_child(reloaded_game)
    await process_frame
    await process_frame
    _expect(int(reloaded_game.get("best_score")) == 123, "Best score reloads in a fresh scene")

    await _validate_restart_stress(reloaded_game, obstacle_scene)

    var reloaded_feedback := reloaded_game.get("feedback") as NeonFeedback
    reloaded_feedback.shutdown()
    await process_frame
    await process_frame
    reloaded_game.queue_free()
    await process_frame
    await process_frame
    _remove_test_save()
    _finish()

func _validate_restart_stress(game: Node, obstacle_scene: PackedScene) -> void:
    var player := game.get_node("World/Player") as NeonPlayer
    var world := game.get_node("World") as Node2D
    var hit_count := player.get_signal_connection_list(&"hit_obstacle").size()
    var pickup_count := player.get_signal_connection_list(&"collected_pickup").size()

    for cycle in range(10):
        if int(game.get("state")) == 0:
            game.call("_handle_primary_action")
        elif int(game.get("state")) == 2:
            game.set("restart_lock", 0.0)
            game.call("_handle_primary_action")
        await process_frame

        _expect(int(game.get("state")) == 1, "Restart cycle %d enters PLAYING" % (cycle + 1))
        _expect(player.is_active(), "Restart cycle %d activates player" % (cycle + 1))
        _expect(
            player.get_signal_connection_list(&"hit_obstacle").size() == hit_count,
            "Restart cycle %d preserves obstacle signal count" % (cycle + 1)
        )
        _expect(
            player.get_signal_connection_list(&"collected_pickup").size() == pickup_count,
            "Restart cycle %d preserves pickup signal count" % (cycle + 1)
        )

        var serial := int(game.get("state_transition_serial"))
        var obstacle := obstacle_scene.instantiate() as NeonObstacle
        obstacle.configure(GameBalance.START_SPEED)
        world.add_child(obstacle)
        game.call("_on_player_hit", obstacle)
        game.call("_on_player_hit", obstacle)
        await process_frame
        _expect(int(game.get("state")) == 2, "Restart cycle %d reaches GAME_OVER" % (cycle + 1))
        _expect(
            int(game.get("state_transition_serial")) == serial + 1,
            "Restart cycle %d processes one crash transition" % (cycle + 1)
        )

func _validate_wave_director() -> void:
    var director := WaveDirector.new()
    _expect(
        is_equal_approx(
            director.minimum_switch_window(),
            GameBalance.PLAYER_SWITCH_TIME + GameBalance.MIN_REACTION_TIME
        ),
        "WaveDirector uses configured response window"
    )

    var rng := RandomNumberGenerator.new()
    rng.seed = 784423
    var all_fair := true
    for elapsed_sample in [0.0, 24.0, 70.0]:
        for speed_sample in [GameBalance.START_SPEED, 900.0, GameBalance.MAX_SPEED]:
            for sample_index in range(80):
                var wave := director.build_wave(elapsed_sample, speed_sample, rng)
                if not director.is_wave_fair(wave, speed_sample):
                    all_fair = false
    _expect(all_fair, "Generated wave sample preserves a survival route")

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

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[baseline][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[baseline][FAIL] %s" % message)

func _remove_test_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
    var error := DirAccess.remove_absolute(absolute_path)
    if error != OK:
        push_warning("[baseline] Could not remove test save (error %d)" % error)

func _finish() -> void:
    if failures.is_empty():
        print("[baseline] All integration smoke tests passed")
        quit(0)
        return
    push_error("[baseline] %d smoke test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
