extends Node2D

const OBSTACLE_SCENE := preload("res://scenes/obstacle.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const SAVE_PATH := "user://neon_switch_save.cfg"

enum GameState { READY, PLAYING, GAME_OVER }

@onready var background: NeonBackground = $Background
@onready var world: Node2D = $World
@onready var player: NeonPlayer = $World/Player
@onready var hud: NeonHUD = $HUD/HUDRoot

var state := GameState.READY
var rng := RandomNumberGenerator.new()
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
    player.hit_obstacle.connect(_on_player_hit)
    player.collected_pickup.connect(_on_player_collect)
    player.reset_player()
    hud.show_ready(best_score)

func _process(delta: float) -> void:
    if restart_lock > 0.0:
        restart_lock -= delta

    if screen_shake > 0.0:
        screen_shake -= delta
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
    var pressed := false
    if event is InputEventScreenTouch:
        pressed = event.pressed
    elif event is InputEventMouseButton:
        pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
    elif event is InputEventKey:
        pressed = event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)

    if not pressed:
        return

    match state:
        GameState.READY:
            _start_game()
        GameState.PLAYING:
            player.switch_lane()
            sfx_switch.play()
        GameState.GAME_OVER:
            if restart_lock <= 0.0:
                _reset_to_ready()
                _start_game()

func _start_game() -> void:
    _clear_spawned_objects()
    score_float = 0.0
    displayed_score = 0
    shards = 0
    elapsed = 0.0
    spawn_clock = GameBalance.INITIAL_SPAWN_CLOCK
    current_speed = GameBalance.START_SPEED
    spawn_interval = GameBalance.START_SPAWN_INTERVAL
    state = GameState.PLAYING
    player.reset_player()
    player.set_active(true)
    background.set_intensity(0.0)
    hud.show_playing()
    hud.update_stats(0, best_score, 0)
    sfx_start.play()

func _reset_to_ready() -> void:
    _clear_spawned_objects()
    state = GameState.READY
    player.reset_player()
    background.set_intensity(0.0)
    hud.show_ready(best_score)

func _spawn_wave() -> void:
    var blocked_lane := rng.randi_range(0, GameBalance.LANE_X.size() - 1)
    var obstacle := OBSTACLE_SCENE.instantiate() as NeonObstacle
    obstacle.position = Vector2(
        GameBalance.LANE_X[blocked_lane],
        GameBalance.OBSTACLE_SPAWN_Y
    )
    obstacle.speed = current_speed
    world.add_child(obstacle)

    # The collectible usually appears in the safe lane, creating a tiny risk/reward decision.
    if rng.randf() < GameBalance.PICKUP_SPAWN_CHANCE:
        var pickup := PICKUP_SCENE.instantiate() as EnergyPickup
        pickup.position = Vector2(
            GameBalance.LANE_X[1 - blocked_lane],
            GameBalance.PICKUP_BASE_SPAWN_Y - rng.randf_range(
                0.0,
                GameBalance.PICKUP_EXTRA_OFFSET_MAX
            )
        )
        pickup.speed = current_speed
        world.add_child(pickup)

    # Later in a run, occasional staggered barriers create a quick two-tap rhythm.
    if (
        elapsed > GameBalance.FOLLOWUP_UNLOCK_TIME
        and rng.randf() < GameBalance.followup_chance_at(elapsed)
    ):
        var followup := OBSTACLE_SCENE.instantiate() as NeonObstacle
        followup.position = Vector2(
            GameBalance.LANE_X[1 - blocked_lane],
            GameBalance.OBSTACLE_SPAWN_Y - current_speed * GameBalance.FOLLOWUP_SPACING_SECONDS
        )
        followup.speed = current_speed
        world.add_child(followup)

func _on_player_collect(pickup: EnergyPickup) -> void:
    if state != GameState.PLAYING or pickup.collected:
        return
    pickup.collect()
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
    if state != GameState.PLAYING:
        return

    state = GameState.GAME_OVER
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
    await get_tree().create_timer(GameBalance.GAME_OVER_PANEL_DELAY).timeout
    hud.show_game_over(displayed_score, best_score, shards, displayed_score > old_best)

    if OS.has_feature("mobile"):
        Input.vibrate_handheld(170)

func _clear_spawned_objects() -> void:
    for child in world.get_children():
        if child != player:
            if child is Area2D:
                (child as Area2D).monitoring = false
            world.remove_child(child)
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
