extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const SAVE_PATH := SaveService.DEFAULT_SAVE_PATH
const EXPECTED_VERSION := "0.1.0-dev.6"

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
    _expect(GameBalance.LANE_X == [210.0, 510.0], "Balance config preserves lane positions")
    _expect(is_equal_approx(GameBalance.START_SPEED, 650.0), "Balance config preserves starting speed")
    _expect(is_equal_approx(GameBalance.PICKUP_SCORE, 25.0), "Balance config preserves pickup reward")

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

    await _validate_entity_contracts(obstacle_scene, pickup_scene)

    var game = main_scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var player := game.get_node("World/Player") as NeonPlayer
    var world := game.get_node("World") as Node2D
    var hud = game.get_node("HUD/HUDRoot")
    var save_service := game.get("save_service") as SaveService

    _expect(int(game.get("state")) == 0, "Game begins in READY state")
    _expect(not bool(game.get("state_transition_in_progress")), "Initial READY transition unlocks")
    _expect(int(game.get("best_score")) == 0, "Missing save defaults best score to zero")
    _expect(player != null and world != null and hud != null, "Required runtime nodes exist")
    _expect(game.get("wave_director") != null, "Main owns a WaveDirector service")
    _expect(save_service != null, "Main owns a SaveService")
    _expect(
        save_service != null and save_service.last_load_status() == SaveService.LoadStatus.MISSING,
        "Main receives missing-save status without failing startup"
    )
    _expect(player.current_lane() == GameBalance.PLAYER_START_LANE, "Player begins in configured lane")
    _expect(not player.is_active(), "Player begins inactive in READY")

    var version_label = hud.get("version_label")
    _expect(version_label != null, "HUD creates a version label")
    _expect(
        version_label != null and version_label.text == "v%s" % EXPECTED_VERSION,
        "HUD displays the canonical project version"
    )

    var hit_connections := player.get_signal_connection_list(&"hit_obstacle").size()
    var pickup_connections := player.get_signal_connection_list(&"collected_pickup").size()
    _expect(hit_connections == 1, "Player has exactly one obstacle subscriber")
    _expect(pickup_connections == 1, "Player has exactly one pickup subscriber")
    game.call("_connect_player_signals")
    game.call("_connect_player_signals")
    _expect(
        player.get_signal_connection_list(&"hit_obstacle").size() == hit_connections,
        "Repeated signal setup does not duplicate obstacle connections"
    )
    _expect(
        player.get_signal_connection_list(&"collected_pickup").size() == pickup_connections,
        "Repeated signal setup does not duplicate pickup connections"
    )

    game.call("_input", _make_key_event(KEY_SPACE))
    _expect(int(game.get("state")) == 1, "Space begins a run")
    _expect(player.is_active(), "Player activates when a run starts")

    game.call("_input", _make_mouse_event())
    _expect(
        player.current_lane() == GameBalance.PLAYER_START_LANE,
        "Same-frame duplicate input cannot switch immediately after starting"
    )

    await process_frame

    var children_before_wave := world.get_child_count()
    game.set("elapsed", 0.0)
    game.set("current_speed", GameBalance.START_SPEED)
    var game_rng := game.get("rng") as RandomNumberGenerator
    game_rng.seed = 44221
    game.call("_spawn_wave")
    _expect(world.get_child_count() > children_before_wave, "Main instantiates WaveDirector entries")

    var spawned_entities: Array[Node] = []
    for child in world.get_children():
        if child == player:
            continue
        spawned_entities.append(child)
        if child is NeonObstacle:
            _expect(
                is_equal_approx((child as NeonObstacle).movement_speed(), GameBalance.START_SPEED),
                "Main configures obstacle speed through its public contract"
            )
        elif child is EnergyPickup:
            _expect(
                is_equal_approx((child as EnergyPickup).movement_speed(), GameBalance.START_SPEED),
                "Main configures pickup speed through its public contract"
            )

    game.call("_clear_spawned_objects")
    for entity in spawned_entities:
        if entity is NeonObstacle:
            _expect((entity as NeonObstacle).is_despawned(), "Main requests obstacle cleanup through despawn()")
        elif entity is EnergyPickup:
            _expect((entity as EnergyPickup).is_despawned(), "Main requests pickup cleanup through despawn()")
    await process_frame
    await process_frame
    _expect(world.get_child_count() == 1, "Entity-owned cleanup leaves only the player")

    game.call("_input", _make_mouse_event())
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(player.current_lane() == 1, "Mouse input switches exactly one lane")

    game.call("_input", _make_touch_event())
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(player.current_lane() == GameBalance.PLAYER_START_LANE, "Touch uses the same action path")

    var pickup := pickup_scene.instantiate() as EnergyPickup
    pickup.configure(GameBalance.START_SPEED)
    pickup.position = player.position
    world.add_child(pickup)
    await physics_frame
    await physics_frame

    _expect(int(game.get("shards")) == 1, "Pickup collision increments shard count once")
    _expect(float(game.get("score_float")) >= GameBalance.PICKUP_SCORE, "Pickup awards configured score")
    _expect(pickup.is_collected(), "Pickup owns one-time collection state")
    game.call("_on_player_collect", pickup)
    _expect(int(game.get("shards")) == 1, "Repeated pickup reporting cannot award twice")

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
    _expect(int(game.get("state_transition_serial")) == playing_serial + 1, "Collision records one transition")
    _expect(not player.is_active(), "Player owns inactive crash state")

    var game_over_serial := int(game.get("state_transition_serial"))
    game.call("_on_player_hit", obstacle)
    _expect(
        int(game.get("state_transition_serial")) == game_over_serial,
        "Duplicate collision cannot trigger another transition"
    )

    game.call("_handle_primary_action")
    _expect(int(game.get("state")) == 2, "Restart is blocked during the restart window")

    await process_frame
    game.set("restart_lock", 0.0)
    game.call("_handle_primary_action")
    game.call("_handle_primary_action")
    _expect(int(game.get("state")) == 1, "Unlocked restart enters PLAYING")
    _expect(
        int(game.get("state_transition_serial")) == game_over_serial + 1,
        "Double restart input records one transition"
    )
    _expect(
        player.current_lane() == GameBalance.PLAYER_START_LANE,
        "Second restart input cannot become an immediate switch"
    )

    await create_timer(GameBalance.GAME_OVER_PANEL_DELAY + 0.06).timeout
    var panel = hud.get("panel")
    _expect(panel != null and not bool(panel.visible), "Stale game-over UI cannot cover a restarted run")
    _expect(int(game.get("best_score")) == 123, "A new best score is recorded")
    _expect(save_service != null and save_service.best_score() == 123, "SaveService records the new best")
    _expect(FileAccess.file_exists(SAVE_PATH), "Best score creates a save file")

    game.queue_free()
    await process_frame
    await process_frame

    var reloaded_game = main_scene.instantiate()
    get_root().add_child(reloaded_game)
    await process_frame
    await process_frame

    _expect(int(reloaded_game.get("best_score")) == 123, "Best score persists across a fresh scene")
    var reloaded_service := reloaded_game.get("save_service") as SaveService
    _expect(
        reloaded_service != null and reloaded_service.last_load_status() == SaveService.LoadStatus.LOADED,
        "Fresh game reports a valid loaded save"
    )

    var reloaded_player := reloaded_game.get_node("World/Player") as NeonPlayer
    var reloaded_world := reloaded_game.get_node("World") as Node2D
    var stable_hit_connections := reloaded_player.get_signal_connection_list(&"hit_obstacle").size()
    var stable_pickup_connections := reloaded_player.get_signal_connection_list(&"collected_pickup").size()

    for run_index in range(10):
        if int(reloaded_game.get("state")) == 0:
            reloaded_game.call("_handle_primary_action")
        elif int(reloaded_game.get("state")) == 2:
            reloaded_game.set("restart_lock", 0.0)
            reloaded_game.call("_handle_primary_action")
        await process_frame

        _expect(int(reloaded_game.get("state")) == 1, "Restart cycle %d enters PLAYING" % (run_index + 1))
        _expect(reloaded_player.is_active(), "Restart cycle %d activates player" % (run_index + 1))
        _expect(
            reloaded_player.get_signal_connection_list(&"hit_obstacle").size() == stable_hit_connections,
            "Restart cycle %d preserves obstacle connection count" % (run_index + 1)
        )
        _expect(
            reloaded_player.get_signal_connection_list(&"collected_pickup").size() == stable_pickup_connections,
            "Restart cycle %d preserves pickup connection count" % (run_index + 1)
        )

        var cycle_serial := int(reloaded_game.get("state_transition_serial"))
        var cycle_obstacle := obstacle_scene.instantiate() as NeonObstacle
        cycle_obstacle.configure(GameBalance.START_SPEED)
        reloaded_world.add_child(cycle_obstacle)
        reloaded_game.call("_on_player_hit", cycle_obstacle)
        reloaded_game.call("_on_player_hit", cycle_obstacle)
        await process_frame

        _expect(int(reloaded_game.get("state")) == 2, "Restart cycle %d reaches GAME_OVER" % (run_index + 1))
        _expect(
            int(reloaded_game.get("state_transition_serial")) == cycle_serial + 1,
            "Restart cycle %d processes one collision transition" % (run_index + 1)
        )
        _expect(not reloaded_player.is_active(), "Restart cycle %d deactivates player" % (run_index + 1))

    reloaded_game.queue_free()
    await process_frame
    _remove_test_save()
    _finish()

func _validate_entity_contracts(
    obstacle_scene: PackedScene,
    pickup_scene: PackedScene
) -> void:
    var obstacle := obstacle_scene.instantiate() as NeonObstacle
    get_root().add_child(obstacle)
    _expect(obstacle.configure(777.0), "Obstacle accepts speed through configure()")
    _expect(is_equal_approx(obstacle.movement_speed(), 777.0), "Obstacle exposes movement speed")
    _expect(obstacle.despawn(), "Obstacle despawn succeeds once")
    _expect(not obstacle.despawn(), "Obstacle despawn is idempotent")
    _expect(obstacle.is_despawned(), "Obstacle exposes despawned state")
    await process_frame
    await process_frame
    _expect(not is_instance_valid(obstacle), "Obstacle owns final queue-free cleanup")

    var offscreen_obstacle := obstacle_scene.instantiate() as NeonObstacle
    offscreen_obstacle.position.y = GameBalance.OBSTACLE_CLEANUP_Y + 1.0
    get_root().add_child(offscreen_obstacle)
    await process_frame
    await process_frame
    _expect(not is_instance_valid(offscreen_obstacle), "Obstacle owns offscreen retirement")

    var pickup := pickup_scene.instantiate() as EnergyPickup
    get_root().add_child(pickup)
    _expect(pickup.configure(812.0), "Pickup accepts speed through configure()")
    _expect(is_equal_approx(pickup.movement_speed(), 812.0), "Pickup exposes movement speed")
    _expect(pickup.collect(), "Pickup collection succeeds once")
    _expect(not pickup.collect(), "Pickup collection is idempotent")
    _expect(pickup.is_collected(), "Pickup exposes collected state")
    _expect(pickup.despawn(), "Pickup can cancel animation and despawn")
    _expect(not pickup.despawn(), "Pickup despawn is idempotent")
    await process_frame
    await process_frame
    _expect(not is_instance_valid(pickup), "Pickup owns final queue-free cleanup")

    var offscreen_pickup := pickup_scene.instantiate() as EnergyPickup
    offscreen_pickup.position.y = GameBalance.PICKUP_CLEANUP_Y + 1.0
    get_root().add_child(offscreen_pickup)
    await process_frame
    await process_frame
    _expect(not is_instance_valid(offscreen_pickup), "Pickup owns offscreen retirement")

func _validate_wave_director() -> void:
    var director := WaveDirector.new()

    _expect(director.tier_at(0.0) == WaveDirector.TIER_INTRODUCTION, "WaveDirector begins in introduction")
    _expect(
        director.tier_at(GameBalance.FOLLOWUP_UNLOCK_TIME) == WaveDirector.TIER_RHYTHM,
        "WaveDirector unlocks rhythm at the configured time"
    )
    _expect(
        director.tier_at(GameBalance.PRESSURE_TIER_START_TIME) == WaveDirector.TIER_PRESSURE,
        "WaveDirector reaches pressure at the configured time"
    )
    _expect(
        is_equal_approx(
            director.minimum_switch_window(),
            GameBalance.PLAYER_SWITCH_TIME + GameBalance.MIN_REACTION_TIME
        ),
        "WaveDirector derives the minimum switch window from balance policy"
    )

    var impossible_wave: Array[Dictionary] = [
        {"type": WaveDirector.ENTRY_OBSTACLE, "lane": 0, "offset_y": 0.0},
        {
            "type": WaveDirector.ENTRY_OBSTACLE,
            "lane": 1,
            "offset_y": -GameBalance.START_SPEED * 0.10,
        },
    ]
    _expect(
        not director.is_wave_fair(impossible_wave, GameBalance.START_SPEED),
        "WaveDirector rejects insufficient reaction time"
    )

    var safe_wave: Array[Dictionary] = [
        {"type": WaveDirector.ENTRY_OBSTACLE, "lane": 0, "offset_y": 0.0},
        {
            "type": WaveDirector.ENTRY_OBSTACLE,
            "lane": 1,
            "offset_y": -GameBalance.START_SPEED * director.minimum_switch_window(),
        },
    ]
    _expect(
        director.is_wave_fair(safe_wave, GameBalance.START_SPEED),
        "WaveDirector accepts the minimum safe reaction window"
    )

    var rng := RandomNumberGenerator.new()
    rng.seed = 784423
    var all_fair := true
    var intro_single := true
    var found_rhythm_followup := false
    var found_pressure_followup := false
    var all_entries_valid := true

    var elapsed_samples: Array[float] = [0.0, 24.0, 70.0]
    var speed_samples: Array[float] = [GameBalance.START_SPEED, 900.0, GameBalance.MAX_SPEED]

    for elapsed_sample in elapsed_samples:
        for speed_sample in speed_samples:
            for sample_index in range(160):
                var wave := director.build_wave(elapsed_sample, speed_sample, rng)
                if not director.is_wave_fair(wave, speed_sample):
                    all_fair = false

                var obstacle_count := 0
                for entry in wave:
                    var entry_type := str(entry.get("type", ""))
                    var lane := int(entry.get("lane", -1))
                    if entry_type != WaveDirector.ENTRY_OBSTACLE and entry_type != WaveDirector.ENTRY_PICKUP:
                        all_entries_valid = false
                    if lane < 0 or lane >= GameBalance.LANE_X.size():
                        all_entries_valid = false
                    if entry_type == WaveDirector.ENTRY_OBSTACLE:
                        obstacle_count += 1

                if elapsed_sample < GameBalance.FOLLOWUP_UNLOCK_TIME and obstacle_count != 1:
                    intro_single = false
                elif elapsed_sample < GameBalance.PRESSURE_TIER_START_TIME and obstacle_count > 1:
                    found_rhythm_followup = true
                elif elapsed_sample >= GameBalance.PRESSURE_TIER_START_TIME and obstacle_count > 1:
                    found_pressure_followup = true

    _expect(all_entries_valid, "Generated waves contain known types and valid lanes")
    _expect(all_fair, "Generated waves preserve a survival route")
    _expect(intro_single, "Introduction waves remain one-obstacle patterns")
    _expect(found_rhythm_followup, "Rhythm tier can generate follow-up hazards")
    _expect(found_pressure_followup, "Pressure tier can generate follow-up hazards")

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
