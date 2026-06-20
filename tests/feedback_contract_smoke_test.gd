extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const OBSTACLE_SCENE_PATH := "res://scenes/obstacle.tscn"
const PICKUP_SCENE_PATH := "res://scenes/pickup.tscn"
const SAVE_PATH := SaveService.DEFAULT_SAVE_PATH

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[feedback] Starting audio and haptic contract smoke test")
    _remove_test_save()

    await _validate_service_reuse()
    await _validate_main_integration()

    _remove_test_save()
    _finish()

func _validate_service_reuse() -> void:
    var feedback := NeonFeedback.new()
    feedback.name = "FeedbackContractFixture"
    get_root().add_child(feedback)
    feedback.initialize()
    await process_frame

    _expect(feedback.is_built(), "Feedback service builds at startup")
    _expect(feedback.audio_player_count() == 4, "Service creates exactly four audio players")
    _expect(feedback.generated_stream_count() == 4, "Service creates exactly four generated streams")
    _expect(feedback.get_child_count() == 4, "Generated audio players are the only service children")

    var events: Array[int] = [
        NeonFeedback.FeedbackEvent.START,
        NeonFeedback.FeedbackEvent.SWITCH,
        NeonFeedback.FeedbackEvent.COLLECT,
        NeonFeedback.FeedbackEvent.CRASH,
    ]
    var original_stream_ids: Dictionary = {}
    var original_player_ids: Dictionary = {}

    for event in events:
        original_stream_ids[event] = feedback.stream_instance_id(event)
        original_player_ids[event] = feedback.player_instance_id(event)
        _expect(int(original_stream_ids[event]) != 0, "Feedback event %d owns a stream" % event)
        _expect(int(original_player_ids[event]) != 0, "Feedback event %d owns a player" % event)

    for iteration in range(40):
        _expect(feedback.play_start(), "Start feedback plays on iteration %d" % iteration)
        _expect(feedback.play_switch(), "Switch feedback plays on iteration %d" % iteration)
        _expect(feedback.play_collect(), "Collect feedback plays on iteration %d" % iteration)
        _expect(feedback.play_crash(), "Crash feedback plays on iteration %d" % iteration)

    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.START) == 40, "Start feedback count is tracked")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.SWITCH) == 40, "Switch feedback count is tracked")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.COLLECT) == 40, "Collect feedback count is tracked")
    _expect(feedback.play_count(NeonFeedback.FeedbackEvent.CRASH) == 40, "Crash feedback count is tracked")
    _expect(
        feedback.last_pitch(NeonFeedback.FeedbackEvent.COLLECT) >= NeonFeedback.COLLECT_PITCH_MIN
        and feedback.last_pitch(NeonFeedback.FeedbackEvent.COLLECT) <= NeonFeedback.COLLECT_PITCH_MAX,
        "Collect pitch remains inside its configured variation range"
    )

    for event in events:
        _expect(
            feedback.stream_instance_id(event) == int(original_stream_ids[event]),
            "Feedback event %d reuses its generated stream" % event
        )
        _expect(
            feedback.player_instance_id(event) == int(original_player_ids[event]),
            "Feedback event %d reuses its audio player" % event
        )

    _expect(feedback.get_child_count() == 4, "Repeated playback creates no additional audio nodes")
    _expect(feedback.haptic_request_count() == 120, "Switch, collect, and crash request haptics")

    if not feedback.haptics_supported():
        _expect(feedback.haptic_emit_count() == 0, "Desktop/headless execution emits no platform vibration")

    feedback.queue_free()
    await process_frame

func _validate_main_integration() -> void:
    var main_scene := load(MAIN_SCENE_PATH) as PackedScene
    var obstacle_scene := load(OBSTACLE_SCENE_PATH) as PackedScene
    var pickup_scene := load(PICKUP_SCENE_PATH) as PackedScene

    _expect(main_scene != null, "Main scene loads for feedback integration")
    _expect(obstacle_scene != null, "Obstacle scene loads for feedback integration")
    _expect(pickup_scene != null, "Pickup scene loads for feedback integration")
    if main_scene == null or obstacle_scene == null or pickup_scene == null:
        return

    var game = main_scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var feedback := game.get("feedback") as NeonFeedback
    var player := game.get_node("World/Player") as NeonPlayer
    var world := game.get_node("World") as Node2D

    _expect(feedback != null and feedback.is_built(), "Main owns an initialized feedback service")
    _expect(feedback != null and feedback.get_parent() == game, "Feedback service belongs to the game controller")

    game.call("_handle_primary_action")
    await process_frame
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.START) == 1,
        "Beginning a run triggers start feedback once"
    )

    game.call("_handle_primary_action")
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.03).timeout
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.SWITCH) == 1,
        "Successful lane switch triggers switch feedback once"
    )

    var gameplay_rng := game.get("rng") as RandomNumberGenerator
    gameplay_rng.seed = 112233
    var control_rng := RandomNumberGenerator.new()
    control_rng.seed = 112233
    feedback.play_collect()
    _expect(
        gameplay_rng.randi() == control_rng.randi(),
        "Feedback pitch and noise randomness do not consume gameplay RNG"
    )

    var collect_count_before := feedback.play_count(NeonFeedback.FeedbackEvent.COLLECT)
    var pickup := pickup_scene.instantiate() as EnergyPickup
    pickup.configure(GameBalance.START_SPEED)
    pickup.position = player.position
    world.add_child(pickup)
    await physics_frame
    await physics_frame
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.COLLECT) == collect_count_before + 1,
        "Pickup collection triggers collect feedback once"
    )

    var obstacle := obstacle_scene.instantiate() as NeonObstacle
    obstacle.configure(GameBalance.START_SPEED)
    obstacle.position = player.position
    world.add_child(obstacle)
    await physics_frame
    await physics_frame
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.CRASH) == 1,
        "Obstacle collision triggers crash feedback once"
    )

    var crash_count := feedback.play_count(NeonFeedback.FeedbackEvent.CRASH)
    game.call("_on_player_hit", obstacle)
    _expect(
        feedback.play_count(NeonFeedback.FeedbackEvent.CRASH) == crash_count,
        "Duplicate collision reporting cannot replay crash feedback"
    )

    if not feedback.haptics_supported():
        _expect(feedback.haptic_emit_count() == 0, "Main integration remains desktop-safe for haptics")

    game.queue_free()
    await process_frame
    await process_frame

func _remove_test_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
    var error := DirAccess.remove_absolute(absolute_path)
    if error != OK:
        failures.append("Could not remove feedback test save")
        push_error("[feedback][FAIL] Could not remove feedback test save (error %d)" % error)

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[feedback][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[feedback][FAIL] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[feedback] All audio and haptic tests passed")
        quit(0)
        return
    push_error("[feedback] %d test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
