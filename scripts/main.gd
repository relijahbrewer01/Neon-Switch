extends Node2D

const OBSTACLE_SCENE := preload("res://scenes/obstacle.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const SAVE_PATH := "user://neon_switch_save.cfg"

enum GameState { READY, PLAYING, GAME_OVER }

@onready var background: NeonBackground = $Background
@onready var world: Node2D = $World
@onready var player: NeonPlayer = $World/Player
@onready var hud: NeonHUD = $HUD/HUDRoot

var state: int = GameState.READY
var state_transition_in_progress := false
var state_transition_serial := 0

var rng := RandomNumberGenerator.new()
var wave_director := WaveDirector.new()
var score_float := 0.0
var displayed_score := 0
var best_score := 0
var shards := 0
var elapsed := 0.0
var spawn_clock := 0.0
var current_speed := GameBalance.START_SPEED
var spawn_interval := GameBalance.START_SPAWN_INTERVAL
var restart_lock := 0.0
var screen_shake := 0.0
var sfx_switch: AudioStreamPlayer
var sfx_collect: AudioStreamPlayer
var sfx_crash: AudioStreamPlayer
var sfx_start: AudioStreamPlayer

func _ready() -> void:
    rng.randomize()
    _load_best_score()
    _build_audio_players()
    _connect_player_signals()
    _enter_ready_state(true)

func _connect_player_signals() -> void:
    var hit_callable := Callable(self, "_on_player_hit")
    if not player.hit_obstacle.is_connected(hit_callable):
        player.hit_obstacle.connect(hit_callable)

    var pickup_callable := Callable(self, "_on_player_collect")
    if not player.collected_pickup.is_connected(pickup_callable):
        player.collected_pickup.connect(pickup_callable)

func _process(delta: float) -> void:
    if restart_lock > 0.0:
        restart_lock = maxf(0.0, restart_lock - delta)

    if screen_shake > 0.0:
        screen_shake = maxf(0.0, screen_shake - delta)
        world.position = Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-7.0, 7.0)) * (
            screen_shake / GameBalance.SCREEN_SHAKE_DURATION
        )
    else:
        world.position = Vector2.ZERO

    if state != GameState.PLAYING:
        return

    elapsed += delta
    score_float += delta * GameBalance.score_rate_at(elapsed)
    current_speed = GameBalance.speed_at(elapsed)
    spawn_interval = GameBalance.spawn_interval_at(elapsed)
    background.set_intensity(
        inverse_lerp(GameBalance.START_SPEED, GameBalance.MAX_SPEED, current_speed)
    )

    spawn_clock += delta
    if spawn_clock >= spawn_interval:
        spawn_clock -= spawn_interval
        _spawn_wave()

    var new_score := int(score_float)
    if new_score != displayed_score:
        displayed_score = new_score
        hud.update_stats(displayed_score, best_score, shards)

func _input(event: InputEvent) -> void:
    if _is_primary_action_pressed(event):
        _handle_primary_action()

func _is_primary_action_pressed(event: InputEvent) -> bool:
    if event is InputEventScreenTouch:
        return event.pressed
    if event is InputEventMouseButton:
        return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
    if event is InputEventKey:
        return (
            event.pressed
            and not event.echo
            and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)
        )
    return false

func _handle_primary_action() -> void:
    # A state change remains locked through the current frame. This prevents a
    # burst of duplicate touch events from starting a run and immediately
    # switching lanes, or restarting more than once.
    if state_transition_in_progress:
        return

    match state:
        GameState.READY:
            _enter_playing_state()
        GameState.PLAYING:
            _request_lane_switch()
        GameState.GAME_OVER:
            _request_restart()

func _request_lane_switch() -> void:
    if state != GameState.PLAYING or state_transition_in_progress:
        return
    if player.switch_lane():
        sfx_switch.play()

func _request_restart() -> void:
    if state != GameState.GAME_OVER:
        return
    if restart_lock > 0.0 or state_transition_in_progress:
        return
    _enter_playing_state()

func _enter_ready_state(force: bool = false) -> bool:
    if not _begin_state_transition(GameState.READY, force):
        return false

    _clear_spawned_objects()
    _reset_run_values()
    player.reset_for_run()
    background.set_intensity(0.0)
    hud.show_ready(best_score)
    return true

func _enter_playing_state() -> bool:
    if state == GameState.GAME_OVER and restart_lock > 0.0:
        return false
    if not _begin_state_transition(GameState.PLAYING):
        return false

    _clear_spawned_objects()
    _reset_run_values()
    restart_lock = 0.0
    screen_shake = 0.0
    world.position = Vector2.ZERO
    player.reset_for_run()
    player.activate()
    background.set_intensity(0.0)
    hud.show_playing()
    hud.update_stats(0, best_score, 0)
    sfx_start.play()
    return true

func _enter_game_over_state() -> bool:
    if not _begin_state_transition(GameState.GAME_OVER):
        return false

    player.crash()
    screen_shake = GameBalance.SCREEN_SHAKE_DURATION
    restart_lock = GameBalance.RESTART_LOCK_TIME
    sfx_crash.play()
    hud.flash_crash()

    var old_best := best_score
    if displayed_score > best_score:
        best_score = displayed_score
        _save_best_score()

    hud.update_stats(displayed_score, best_score, shards)

    var transition_serial := state_transition_serial
    _show_game_over_panel_after_delay(
        transition_serial,
        displayed_score > old_best
    )

    if OS.has_feature("mobile"):
        Input.vibrate_handheld(170)
    return true

func _begin_state_transition(next_state: int, force: bool = false) -> bool:
    if state_transition_in_progress:
        return false
    if not force and not _is_transition_allowed(state, next_state):
        return false

    state_transition_in_progress = true
    state = next_state
    state_transition_serial += 1
    call_deferred("_release_state_transition", state_transition_serial)
    return true

func _release_state_transition(serial: int) -> void:
    if serial == state_transition_serial:
        state_transition_in_progress = false

func _is_transition_allowed(from_state: int, to_state: int) -> bool:
    match from_state:
        GameState.READY:
            return to_state == GameState.PLAYING
        GameState.PLAYING:
            return to_state == GameState.GAME_OVER
        GameState.GAME_OVER:
            return to_state == GameState.PLAYING
    return false

func _show_game_over_panel_after_delay(
    transition_serial: int,
    is_new_best: bool
) -> void:
    await get_tree().create_timer(GameBalance.GAME_OVER_PANEL_DELAY).timeout

    # Ignore an old delayed callback if another state transition has already
    # happened. This prevents stale game-over UI from appearing over a new run.
    if state != GameState.GAME_OVER:
        return
    if transition_serial != state_transition_serial:
        return

    hud.show_game_over(displayed_score, best_score, shards, is_new_best)

func _reset_run_values() -> void:
    score_float = 0.0
    displayed_score = 0
    shards = 0
    elapsed = 0.0
    spawn_clock = GameBalance.INITIAL_SPAWN_CLOCK
    current_speed = GameBalance.START_SPEED
    spawn_interval = GameBalance.START_SPAWN_INTERVAL

func _spawn_wave() -> void:
    var entries := wave_director.build_wave(elapsed, current_speed, rng)

    for entry in entries:
        var entry_type := str(entry.get("type", ""))
        var lane := int(entry.get("lane", -1))
        var offset_y := float(entry.get("offset_y", 0.0))

        if lane < 0 or lane >= GameBalance.LANE_X.size():
            push_error("WaveDirector returned an invalid lane index: %d" % lane)
            continue

        if entry_type == WaveDirector.ENTRY_OBSTACLE:
            var obstacle := OBSTACLE_SCENE.instantiate() as NeonObstacle
            obstacle.position = Vector2(
                GameBalance.LANE_X[lane],
                GameBalance.OBSTACLE_SPAWN_Y + offset_y
            )
            obstacle.configure(current_speed)
            world.add_child(obstacle)
        elif entry_type == WaveDirector.ENTRY_PICKUP:
            var pickup := PICKUP_SCENE.instantiate() as EnergyPickup
            pickup.position = Vector2(
                GameBalance.LANE_X[lane],
                GameBalance.OBSTACLE_SPAWN_Y + offset_y
            )
            pickup.configure(current_speed)
            world.add_child(pickup)
        else:
            push_error("WaveDirector returned an unknown entry type: %s" % entry_type)

func _on_player_collect(pickup: EnergyPickup) -> void:
    if state != GameState.PLAYING:
        return
    if not pickup.collect():
        return
    player.celebrate_pickup()
    shards += 1
    score_float += GameBalance.PICKUP_SCORE
    displayed_score = int(score_float)
    hud.update_stats(displayed_score, best_score, shards)
    hud.pulse_score()
    hud.flash_collect()
    sfx_collect.pitch_scale = rng.randf_range(0.96, 1.08)
    sfx_collect.play()
    if OS.has_feature("mobile"):
        Input.vibrate_handheld(28)

func _on_player_hit(_obstacle: NeonObstacle) -> void:
    _enter_game_over_state()

func _clear_spawned_objects() -> void:
    for child in world.get_children():
        if child == player:
            continue
        if child is NeonObstacle:
            (child as NeonObstacle).despawn()
        elif child is EnergyPickup:
            (child as EnergyPickup).despawn()
        else:
            child.queue_free()

func _build_audio_players() -> void:
    # Generate tiny retro sound effects at runtime so the repository remains
    # completely self-contained and avoids binary asset management.
    sfx_switch = _make_audio_player(_make_tone(620.0, 0.075, 0.34, 180.0), -9.0)
    sfx_collect = _make_audio_player(_make_tone(880.0, 0.16, 0.38, 520.0), -5.0)
    sfx_crash = _make_audio_player(_make_noise_burst(0.24, 0.42), -3.0)
    sfx_start = _make_audio_player(_make_tone(330.0, 0.22, 0.32, 440.0), -7.0)

func _make_audio_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
    var audio_player := AudioStreamPlayer.new()
    audio_player.stream = stream
    audio_player.volume_db = volume_db
    add_child(audio_player)
    return audio_player

func _make_tone(start_hz: float, duration: float, amplitude: float, end_hz: float = -1.0) -> AudioStreamWAV:
    var sample_rate := 22050
    var sample_count := maxi(1, int(duration * sample_rate))
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    var phase := 0.0
    var final_hz := start_hz if end_hz < 0.0 else end_hz

    for i in sample_count:
        var progress := float(i) / float(sample_count)
        var frequency := lerpf(start_hz, final_hz, progress)
        phase += TAU * frequency / float(sample_rate)
        var envelope := sin(PI * progress)
        var sample := int(clampf(sin(phase) * amplitude * envelope, -1.0, 1.0) * 32767.0)
        data.encode_s16(i * 2, sample)

    return _make_wav(data, sample_rate)

func _make_noise_burst(duration: float, amplitude: float) -> AudioStreamWAV:
    var sample_rate := 22050
    var sample_count := maxi(1, int(duration * sample_rate))
    var data := PackedByteArray()
    data.resize(sample_count * 2)

    for i in sample_count:
        var progress := float(i) / float(sample_count)
        var envelope := pow(1.0 - progress, 2.0)
        var sample := int(rng.randf_range(-1.0, 1.0) * amplitude * envelope * 32767.0)
        data.encode_s16(i * 2, sample)

    return _make_wav(data, sample_rate)

func _make_wav(data: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream

func _load_best_score() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) == OK:
        best_score = int(config.get_value("score", "best", 0))

func _save_best_score() -> void:
    var config := ConfigFile.new()
    config.set_value("score", "best", best_score)
    config.save(SAVE_PATH)
