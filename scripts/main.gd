extends Node2D

const OBSTACLE_SCENE := preload("res://scenes/obstacle.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")

enum GameState { READY, PLAYING, GAME_OVER }

@onready var background: NeonBackground = $Background
@onready var world: Node2D = $World
@onready var player: NeonPlayer = $World/Player
@onready var hud: NeonHUD = $HUD/HUDRoot

var state: int = GameState.READY
var state_transition_in_progress := false
var state_transition_serial := 0
var last_primary_input_source: int = PrimaryInput.Source.NONE

var rng := RandomNumberGenerator.new()
var wave_director := WaveDirector.new()
var save_service := SaveService.new()
var feedback := NeonFeedback.new()
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

func _ready() -> void:
    feedback.name = "Feedback"
    add_child(feedback)
    feedback.initialize()

    rng.randomize()
    best_score = save_service.load_best_score()
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

func _unhandled_input(event: InputEvent) -> void:
    var input_source := PrimaryInput.source_for(event)
    if input_source == PrimaryInput.Source.NONE:
        return

    last_primary_input_source = input_source
    get_viewport().set_input_as_handled()
    _handle_primary_action()

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
        feedback.play_switch()

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
    feedback.play_start()
    return true

func _enter_game_over_state() -> bool:
    if not _begin_state_transition(GameState.GAME_OVER):
        return false

    player.crash()
    screen_shake = GameBalance.SCREEN_SHAKE_DURATION
    restart_lock = GameBalance.RESTART_LOCK_TIME
    feedback.play_crash()
    hud.flash_crash()

    var old_best := best_score
    if displayed_score > best_score:
        best_score = displayed_score
        # Disk failure must never roll back the in-memory record or interrupt
        # the game-over flow. The service will retry on a later higher score.
        save_service.save_if_new_best(best_score)

    hud.update_stats(displayed_score, best_score, shards)

    var transition_serial := state_transition_serial
    _show_game_over_panel_after_delay(
        transition_serial,
        displayed_score > old_best
    )
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
    feedback.play_collect()

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
