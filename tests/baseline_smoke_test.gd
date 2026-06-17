extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const SAVE_PATH := "user://neon_switch_save.cfg"

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[baseline] Starting Neon Switch smoke test")
    _remove_test_save()

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

    _expect(int(game.get("state")) == 0, "Game begins in READY state")
    _expect(int(game.get("best_score")) == 0, "Missing save defaults best score to zero")

    var player = game.get_node("World/Player")
    var world = game.get_node("World")
    var hud = game.get_node("HUD/HUDRoot")

    _expect(player != null, "Player node exists")
    _expect(world != null, "World node exists")
    _expect(hud != null, "HUD node exists")

    game.call("_input", _make_key_event(KEY_SPACE))

    _expect(int(game.get("state")) == 1, "Space starts a run")
    _expect(bool(player.get("active")), "Player activates when a run starts")
    _expect(int(game.get("displayed_score")) == 0, "Run begins with zero displayed score")

    await process_frame

    game.call("_input", _make_mouse_event())
    await create_timer(0.20).timeout

    _expect(int(player.get("lane_index")) == 1, "Mouse input switches exactly one lane")
    _expect(absf(float(player.position.x) - 510.0) < 1.0, "Player reaches the opposite lane")

    game.call("_input", _make_touch_event())
    await create_timer(0.20).timeout

    _expect(int(player.get("lane_index")) == 0, "Touch input uses the same lane-switch action")
    _expect(absf(float(player.position.x) - 210.0) < 1.0, "Touch returns player to the first lane")

    var pickup = pickup_scene.instantiate()
    pickup.position = player.position
    world.add_child(pickup)
    await physics_frame
    await physics_frame

    _expect(int(game.get("shards")) == 1, "Pickup collision increments shard count once")
    _expect(int(game.get("displayed_score")) >= 25, "Pickup collision awards bonus score")

    game.set("displayed_score", 123)
    game.set("score_float", 123.0)

    var obstacle = obstacle_scene.instantiate()
    obstacle.position = player.position
    world.add_child(obstacle)
    await physics_frame
    await physics_frame

    _expect(int(game.get("state")) == 2, "Obstacle collision enters GAME_OVER once")
    _expect(not bool(player.get("active")), "Player deactivates after collision")

    await create_timer(0.40).timeout

    _expect(int(game.get("best_score")) == 123, "A new best score is recorded")
    _expect(FileAccess.file_exists(SAVE_PATH), "Best score creates a save file")

    var panel = hud.get("panel")
    _expect(panel != null and bool(panel.visible), "Game-over panel becomes visible")

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
        reloaded_game.call("_start_game")
        await process_frame

        _expect(int(reloaded_game.get("state")) == 1, "Restart cycle %d enters PLAYING" % (run_index + 1))
        _expect(bool(reloaded_player.get("active")), "Restart cycle %d activates player" % (run_index + 1))

        var cycle_obstacle = obstacle_scene.instantiate()
        reloaded_game.get_node("World").add_child(cycle_obstacle)
        reloaded_game.call("_on_player_hit", cycle_obstacle)
        await create_timer(0.38).timeout

        _expect(int(reloaded_game.get("state")) == 2, "Restart cycle %d reaches GAME_OVER" % (run_index + 1))
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
