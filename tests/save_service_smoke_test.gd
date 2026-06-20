extends SceneTree

const TEST_SAVE_PATH := "user://neon_switch_save_service_test.cfg"

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[save-service] Starting persistence smoke test")
    _remove_file(TEST_SAVE_PATH)

    var missing_service := SaveService.new(TEST_SAVE_PATH)
    _expect(missing_service.load_best_score() == 0, "Missing save defaults to zero")
    _expect(missing_service.has_loaded(), "Missing save still completes load state")
    _expect(
        missing_service.last_load_status() == SaveService.LoadStatus.MISSING,
        "Missing save reports MISSING status"
    )
    _expect(not FileAccess.file_exists(TEST_SAVE_PATH), "Loading a missing save does not create a file")
    _expect(not missing_service.save_if_new_best(-1), "Negative scores are rejected")
    _expect(not FileAccess.file_exists(TEST_SAVE_PATH), "Rejected scores do not create a file")

    _expect(missing_service.save_if_new_best(40), "First positive best score is saved")
    _expect(missing_service.best_score() == 40, "Service caches the persisted best score")
    _expect(missing_service.last_save_error() == OK, "Successful save reports OK")
    _expect(FileAccess.file_exists(TEST_SAVE_PATH), "Successful save creates a file")
    _expect(not missing_service.save_if_new_best(40), "Equal score does not rewrite the save")
    _expect(not missing_service.save_if_new_best(12), "Lower score does not rewrite the save")

    var stored_config := ConfigFile.new()
    _expect(stored_config.load(TEST_SAVE_PATH) == OK, "Written save can be loaded as ConfigFile")
    _expect(
        int(stored_config.get_value(SaveService.SCORE_SECTION, SaveService.BEST_SCORE_KEY, -1)) == 40,
        "No-op save attempts preserve the stored best score"
    )
    _expect(
        int(stored_config.get_value(SaveService.META_SECTION, SaveService.FORMAT_VERSION_KEY, -1))
            == SaveService.SAVE_FORMAT_VERSION,
        "Save file records the current format version"
    )

    _expect(missing_service.save_if_new_best(75), "Higher score replaces the stored best")
    var reloaded_service := SaveService.new(TEST_SAVE_PATH)
    _expect(reloaded_service.load_best_score() == 75, "Fresh service reloads the higher score")
    _expect(
        reloaded_service.last_load_status() == SaveService.LoadStatus.LOADED,
        "Valid save reports LOADED status"
    )

    _write_raw(TEST_SAVE_PATH, "[score\nbest=broken")
    var malformed_service := SaveService.new(TEST_SAVE_PATH)
    _expect(malformed_service.load_best_score() == 0, "Malformed save falls back to zero")
    _expect(
        malformed_service.last_load_status() == SaveService.LoadStatus.MALFORMED,
        "Malformed save reports MALFORMED status"
    )
    _expect(malformed_service.save_if_new_best(10), "A new best repairs a malformed save")
    var repaired_service := SaveService.new(TEST_SAVE_PATH)
    _expect(repaired_service.load_best_score() == 10, "Repaired save reloads normally")

    var wrong_type_config := ConfigFile.new()
    wrong_type_config.set_value(SaveService.SCORE_SECTION, SaveService.BEST_SCORE_KEY, "forty")
    _expect(wrong_type_config.save(TEST_SAVE_PATH) == OK, "Wrong-type fixture writes successfully")
    var wrong_type_service := SaveService.new(TEST_SAVE_PATH)
    _expect(wrong_type_service.load_best_score() == 0, "Wrong-type score falls back to zero")
    _expect(
        wrong_type_service.last_load_status() == SaveService.LoadStatus.INVALID_VALUE,
        "Wrong-type score reports INVALID_VALUE"
    )

    var negative_config := ConfigFile.new()
    negative_config.set_value(SaveService.SCORE_SECTION, SaveService.BEST_SCORE_KEY, -25)
    _expect(negative_config.save(TEST_SAVE_PATH) == OK, "Negative fixture writes successfully")
    var negative_service := SaveService.new(TEST_SAVE_PATH)
    _expect(negative_service.load_best_score() == 0, "Negative stored score falls back to zero")
    _expect(
        negative_service.last_load_status() == SaveService.LoadStatus.INVALID_VALUE,
        "Negative stored score reports INVALID_VALUE"
    )

    _remove_file(TEST_SAVE_PATH)
    _finish()

func _write_raw(path: String, contents: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    _expect(file != null, "Malformed fixture file opens for writing")
    if file == null:
        return
    file.store_string(contents)
    file.close()

func _remove_file(path: String) -> void:
    if not FileAccess.file_exists(path):
        return
    var absolute_path := ProjectSettings.globalize_path(path)
    var error := DirAccess.remove_absolute(absolute_path)
    if error != OK:
        failures.append("Could not remove test file at %s" % absolute_path)
        push_error("[save-service][FAIL] Could not remove test file at %s (error %d)" % [absolute_path, error])

func _expect(condition: bool, message: String) -> void:
    if condition:
        print("[save-service][PASS] %s" % message)
        return
    failures.append(message)
    push_error("[save-service][FAIL] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[save-service] All persistence tests passed")
        quit(0)
        return
    push_error("[save-service] %d test(s) failed" % failures.size())
    for failure in failures:
        push_error(" - %s" % failure)
    quit(1)
