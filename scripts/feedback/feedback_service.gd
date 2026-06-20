extends Node
class_name NeonFeedback

## Reusable audio and haptic feedback service.
##
## All generated streams and AudioStreamPlayer nodes are created once during
## startup. Gameplay calls semantic methods such as play_switch() and never
## allocates audio resources or invokes platform vibration APIs directly.

enum FeedbackEvent {
    START,
    SWITCH,
    COLLECT,
    CRASH,
}

const SAMPLE_RATE := 22050
const SWITCH_HAPTIC_MS := 18
const COLLECT_HAPTIC_MS := 28
const CRASH_HAPTIC_MS := 170
const COLLECT_PITCH_MIN := 0.96
const COLLECT_PITCH_MAX := 1.08

var _players: Dictionary = {}
var _streams: Dictionary = {}
var _play_counts: Dictionary = {}
var _last_pitch: Dictionary = {}
var _audio_playback_supported := true
var _haptics_supported := false
var _haptic_request_count := 0
var _haptic_emit_count := 0
var _built := false
var _pitch_rng := RandomNumberGenerator.new()
var _noise_rng := RandomNumberGenerator.new()

func _ready() -> void:
    initialize()

func _exit_tree() -> void:
    shutdown()

func initialize() -> void:
    if _built:
        return
    _pitch_rng.seed = 94051
    _noise_rng.seed = 61417
    _audio_playback_supported = DisplayServer.get_name().to_lower() != "headless"
    _haptics_supported = OS.has_feature("mobile")
    _build_resources()

func shutdown() -> void:
    # AudioServer may retain AudioStreamPlayback objects briefly after a player
    # leaves the tree. Stop playback and detach streams explicitly so tests and
    # application shutdown release every playback resource.
    for player_value in _players.values():
        var audio_player := player_value as AudioStreamPlayer
        if audio_player == null:
            continue
        audio_player.stop()
        audio_player.stream = null

    _streams.clear()
    _players.clear()
    _built = false

func play_start() -> bool:
    return _play_feedback(FeedbackEvent.START, 1.0)

func play_switch() -> bool:
    var played := _play_feedback(FeedbackEvent.SWITCH, 1.0)
    _request_haptic(SWITCH_HAPTIC_MS)
    return played

func play_collect() -> bool:
    var pitch := _pitch_rng.randf_range(COLLECT_PITCH_MIN, COLLECT_PITCH_MAX)
    var played := _play_feedback(FeedbackEvent.COLLECT, pitch)
    _request_haptic(COLLECT_HAPTIC_MS)
    return played

func play_crash() -> bool:
    var played := _play_feedback(FeedbackEvent.CRASH, 1.0)
    _request_haptic(CRASH_HAPTIC_MS)
    return played

func is_built() -> bool:
    return _built

func audio_playback_supported() -> bool:
    return _audio_playback_supported

func haptics_supported() -> bool:
    return _haptics_supported

func audio_player_count() -> int:
    return _players.size()

func generated_stream_count() -> int:
    return _streams.size()

func play_count(event: int) -> int:
    return int(_play_counts.get(event, 0))

func last_pitch(event: int) -> float:
    return float(_last_pitch.get(event, 1.0))

func stream_instance_id(event: int) -> int:
    var stream := _streams.get(event) as AudioStream
    return 0 if stream == null else stream.get_instance_id()

func player_instance_id(event: int) -> int:
    var audio_player := _players.get(event) as AudioStreamPlayer
    return 0 if audio_player == null else audio_player.get_instance_id()

func haptic_request_count() -> int:
    return _haptic_request_count

func haptic_emit_count() -> int:
    return _haptic_emit_count

func _build_resources() -> void:
    if _built:
        return

    _register_feedback(
        FeedbackEvent.START,
        "Start",
        _make_tone(330.0, 0.22, 0.32, 440.0),
        -7.0
    )
    _register_feedback(
        FeedbackEvent.SWITCH,
        "Switch",
        _make_tone(620.0, 0.075, 0.34, 180.0),
        -9.0
    )
    _register_feedback(
        FeedbackEvent.COLLECT,
        "Collect",
        _make_tone(880.0, 0.16, 0.38, 520.0),
        -5.0
    )
    _register_feedback(
        FeedbackEvent.CRASH,
        "Crash",
        _make_noise_burst(0.24, 0.42),
        -3.0
    )
    _built = true

func _register_feedback(
    event: int,
    player_name: String,
    stream: AudioStream,
    volume_db: float
) -> void:
    var audio_player := AudioStreamPlayer.new()
    audio_player.name = "%sAudio" % player_name
    audio_player.stream = stream
    audio_player.volume_db = volume_db
    add_child(audio_player)

    _players[event] = audio_player
    _streams[event] = stream
    _play_counts[event] = 0
    _last_pitch[event] = 1.0

func _play_feedback(event: int, pitch: float) -> bool:
    if not _built:
        return false

    var audio_player := _players.get(event) as AudioStreamPlayer
    if audio_player == null or audio_player.stream == null:
        return false

    audio_player.pitch_scale = clampf(pitch, 0.01, 4.0)
    if _audio_playback_supported:
        audio_player.play()
    _play_counts[event] = play_count(event) + 1
    _last_pitch[event] = audio_player.pitch_scale
    return true

func _request_haptic(duration_ms: int) -> bool:
    if duration_ms <= 0:
        return false

    _haptic_request_count += 1
    if not _haptics_supported:
        return false

    Input.vibrate_handheld(duration_ms)
    _haptic_emit_count += 1
    return true

func _make_tone(
    start_hz: float,
    duration: float,
    amplitude: float,
    end_hz: float = -1.0
) -> AudioStreamWAV:
    var sample_count := maxi(1, int(duration * SAMPLE_RATE))
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    var phase := 0.0
    var final_hz := start_hz if end_hz < 0.0 else end_hz

    for i in range(sample_count):
        var progress := float(i) / float(sample_count)
        var frequency := lerpf(start_hz, final_hz, progress)
        phase += TAU * frequency / float(SAMPLE_RATE)
        var envelope := sin(PI * progress)
        var sample := int(
            clampf(sin(phase) * amplitude * envelope, -1.0, 1.0) * 32767.0
        )
        data.encode_s16(i * 2, sample)

    return _make_wav(data)

func _make_noise_burst(duration: float, amplitude: float) -> AudioStreamWAV:
    var sample_count := maxi(1, int(duration * SAMPLE_RATE))
    var data := PackedByteArray()
    data.resize(sample_count * 2)

    for i in range(sample_count):
        var progress := float(i) / float(sample_count)
        var envelope := pow(1.0 - progress, 2.0)
        var sample := int(
            _noise_rng.randf_range(-1.0, 1.0)
            * amplitude
            * envelope
            * 32767.0
        )
        data.encode_s16(i * 2, sample)

    return _make_wav(data)

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = data
    return stream
