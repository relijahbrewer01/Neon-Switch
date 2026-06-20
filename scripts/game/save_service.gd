extends RefCounted
class_name SaveService

## Resilient best-score persistence service.
##
## The service owns file format, validation, and write policy. Gameplay code may
## update its in-memory best score regardless of disk availability; persistence
## failures are reported through return values and never interrupt the run.

enum LoadStatus {
    NOT_LOADED,
    MISSING,
    LOADED,
    MALFORMED,
    INVALID_VALUE,
}

const DEFAULT_SAVE_PATH := "user://neon_switch_save.cfg"
const SCORE_SECTION := "score"
const BEST_SCORE_KEY := "best"
const META_SECTION := "meta"
const FORMAT_VERSION_KEY := "format_version"
const SAVE_FORMAT_VERSION := 1

var _save_path: String
var _best_score := 0
var _has_loaded := false
var _last_load_status: int = LoadStatus.NOT_LOADED
var _last_save_error: Error = OK

func _init(save_path: String = DEFAULT_SAVE_PATH) -> void:
    _save_path = save_path

func load_best_score() -> int:
    _best_score = 0
    _has_loaded = true
    _last_save_error = OK

    if not FileAccess.file_exists(_save_path):
        _last_load_status = LoadStatus.MISSING
        return _best_score

    var config := ConfigFile.new()
    var load_error := config.load(_save_path)
    if load_error != OK:
        _last_load_status = LoadStatus.MALFORMED
        return _best_score

    var raw_value: Variant = config.get_value(
        SCORE_SECTION,
        BEST_SCORE_KEY,
        0
    )
    if typeof(raw_value) != TYPE_INT or int(raw_value) < 0:
        _last_load_status = LoadStatus.INVALID_VALUE
        return _best_score

    _best_score = int(raw_value)
    _last_load_status = LoadStatus.LOADED
    return _best_score

func save_if_new_best(candidate_score: int) -> bool:
    if not _has_loaded:
        load_best_score()

    if candidate_score < 0 or candidate_score <= _best_score:
        return false

    var config := ConfigFile.new()
    config.set_value(META_SECTION, FORMAT_VERSION_KEY, SAVE_FORMAT_VERSION)
    config.set_value(SCORE_SECTION, BEST_SCORE_KEY, candidate_score)

    _last_save_error = config.save(_save_path)
    if _last_save_error != OK:
        return false

    _best_score = candidate_score
    _last_load_status = LoadStatus.LOADED
    return true

func best_score() -> int:
    return _best_score

func has_loaded() -> bool:
    return _has_loaded

func last_load_status() -> int:
    return _last_load_status

func last_save_error() -> Error:
    return _last_save_error

func save_path() -> String:
    return _save_path
