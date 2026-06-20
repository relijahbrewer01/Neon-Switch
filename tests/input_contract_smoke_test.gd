extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SAVE_PATH := SaveService.DEFAULT_SAVE_PATH

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[input-contract] Starting primary-input smoke test")
    _remove_test_save()
    _validate_classifier()

    var main_scene := load(MAIN_SCENE_PATH) as PackedScene
    _expect(main_scene != null, "Main scene loads for input validation")
    if main_scene == null:
        _finish()
        return

    var game = main_scene.instantiate()
    get_root().add_child(game)
    await process_frame
    await process_frame

    var player := game.get_node("World/Player") as NeonPlayer
    var hud := game.get_node("HUD/HUDRoot") as NeonHUD

    _expect(hud != null and hud.is_input_passthrough(), "Every decorative HUD control ignores pointer input")
    _expect(int(game.get("state")) == 0, "Input test begins in READY")

    # Push a click through the real Viewport input pipeline at the center of the
    # visible ready panel. The HUD must not consume it before _unhandled_input.
    get_root().push_input(_make_mouse_event(MOUSE_BUTTON_LEFT, true))
    await process_frame

    _expect(int(game.get("state")) == 1, "Click through the ready panel reaches the gameplay action")
    _expect(player.is_active(), "Click starts the run")
    _expect(
        int(game.get("last_primary_input_source")) == PrimaryInput.Source.MOUSE,
        "Main records mouse as the normalized source"
    )

    var starting_lane := player.current_lane()
    _push_rejected_events()
    await process_frame

    _expect(player.current_lane() == starting_lane, "Release, repeat, secondary, and unrelated events do nothing")
    _expect(
        int(game.get("last_primary_input_source")) == PrimaryInput.Source.MOUSE,
        "Rejected events do not replace the last accepted source"
    )

    get_root().push_input(_make_touch_event(0, true))
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(player.current_lane() == 1 - starting_lane, "Primary touch switches one lane")
    _expect(
        int(game.get("last_primary_input_source")) == PrimaryInput.Source.TOUCH,
        "Touch uses the normalized primary-action path"
    )

    get_root().push_input(_make_key_event(KEY_SPACE, true, false))
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(player.current_lane() == starting_lane, "Space switches through the same action path")
    _expect(
        int(game.get("last_primary_input_source")) == PrimaryInput.Source.KEYBOARD,
        "Space records keyboard as the normalized source"
    )

    get_root().push_input(_make_key_event(KEY_ENTER, true, false))
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(player.current_lane() == 1 - starting_lane, "Enter switches through the same action path")

    get_root().push_input(_make_key_event(KEY_KP_ENTER, true, false))
    await create_timer(GameBalance.PLAYER_SWITCH_TIME + 0.09).timeout
    _expect(player.current_lane() == starting_lane, "Keypad Enter shares the Enter contract")

    game.queue_free()
    await process_frame
    _remove_test_save()
    _finish()

func _validate_classifier() -> void:
    _expect(
        PrimaryInput.source_for(_make_touch_event(0, true)) == PrimaryInput.Source.TOUCH,
        "Primary touch press is accepted"
    )
    _expect(
        PrimaryInput.source_for(_make_touch_event(0, false)) == PrimaryInput.Source.NONE,
        "Touch release is rejected"
    )
    _expect(
        PrimaryInput.source_for(_make_touch_event(1, true)) == PrimaryInput.Source.NONE,
        "Secondary touch is rejected"
    )
    _expect(
        PrimaryInput.source_for(_make_mouse_event(MOUSE_BUTTON_LEFT, true)) == PrimaryInput.Source.MOUSE,
        "Left mouse press is accepted"
    )
    _expect(
        PrimaryInput.source_for(_make_mouse_event(MOUSE_BUTTON_LEFT, false)) == PrimaryInput.Source.NONE,
        "Mouse release is rejected"
    )
    _expect(
        PrimaryInput.source_for(_make_mouse_event(MOUSE_BUTTON_RIGHT, true)) == PrimaryInput.Source.NONE,
        "Secondary mouse button is rejected"
    )
    _expect(
        PrimaryInput.source_for(_make_key_event(KEY_SPACE, true, false)) == PrimaryInput.Source.KEYBOARD,
        "Space press is accepted"
    )
    _expect(
        PrimaryInput.source_for(_make_key_event(KEY_ENTER, true, false)) == PrimaryInput.Source.KEYBOARD,
        "Enter press is accepted"
    )
    _expect(
        PrimaryInput.source_for(_make_key_event(KEY_KP_ENTER, true, false)) == PrimaryInput.Source.KEYBOARD,
        "Keypad Enter press is accepted"
    )
    _expect(
        PrimaryInput.source_for(_make_key_event(KEY_SPACE, false, false)) == PrimaryInput.Source.NONE,
        "Key release is rejected"
    )
    _expect(
        PrimaryInput.source_for(_make_key_event(KEY_SPACE, true, true)) == PrimaryInput.Source.NONE,
        "Keyboard echo is rejected"
    )
    _expect(
        PrimaryInput.source_for(_make_key_event(KEY_A, true, false)) == PrimaryInput.Source.NONE,
        "Unrelated key is rejected"
    )
    _expect(PrimaryInput.source_name(PrimaryInput.Source.TOUCH) == "touch", "Touch source has a stable debug name")
    _expect(PrimaryInput.source_name(PrimaryInput.Source.MOUSE) == "mouse", "Mouse source has a stable debug name")
    _expect(PrimaryInput.source_name(PrimaryInput.Source.KEYBOARD) == "keyboard", "Keyboard source has a stable debug name")

func _push_rejected_events() -> void:
    get_root().push_input(_make_touch_event(0, false))
    get_root().push_input(_make_touch_event(1, true))
    get_root().push_input(_make_mouse_event(MOUSE_BUTTON_LEFT, false))
    get_root().push_input(_make_mouse_event(MOUSE_BUTTON_RIGHT, true))
    get_root().push_input(_make_key_event(KEY_SPACE, false, false))
    get_root().push_input(_make_key_event(KEY_SPACE, true, true))
    get_root().push_input(_make_key_event(KEY_A, true, false))

func _make_touch_event(index: int, pressed: bool) -> InputEventScreenTouch:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.pressed = pressed
    event.position = Vector2(360.0, 640.0)
    return event

func _make_mouse_event(button: MouseButton, pressed: bool) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = button
    event.pressed = pressed
    event.position = Vector2(360.0, 640.0)
    event.global_position = event.position
    return event

func _make_key_event(keycode: Key, pressed: bool, echo: bool) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = keycode
    event.pressed = pressed
    event.echo = echo
    return event

func _remove_test_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
    var error := DirAccess.remove_absolute(absolute_path)
    if error != OK:
        failures.append("Could not remove gameplay test save")
        push_error("[input-contract][FAIL] Could not remove gameplay test save (error %d)" % error)

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[input-contract][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[input-contract][FAIL] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[input-contract] All input tests passed")
        quit(0)
        return
    push_error("[input-contract] %d test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
