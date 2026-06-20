# Neon Switch — Save Service Report

## Status

**Foundation Step 6 is complete and validated.**

The playable build version is:

```text
0.1.0-dev.6
```

## Objective

Best-score persistence has been removed from `main.gd` and isolated in:

```text
scripts/game/save_service.gd
```

The service owns save-file format, validation, load status, and the rule that only a strictly higher best score may be written.

## Public Contract

```gdscript
load_best_score() -> int
save_if_new_best(candidate_score: int) -> bool
best_score() -> int
has_loaded() -> bool
last_load_status() -> int
last_save_error() -> Error
save_path() -> String
```

A custom path may be supplied through the constructor, allowing persistence logic to be tested without touching the real game save.

## Load Statuses

`SaveService.LoadStatus` reports:

```text
NOT_LOADED
MISSING
LOADED
MALFORMED
INVALID_VALUE
```

This lets callers and tests distinguish a normal first launch from a damaged or invalid save while still receiving a safe score value.

## Safe Loading

The service returns `0` when:

- The save file does not exist.
- The configuration file cannot be parsed.
- The saved score is not an integer.
- The saved score is negative.

These conditions do not throw gameplay errors and do not prevent the ready screen from loading.

## Write Policy

`save_if_new_best()` writes only when:

```text
candidate score > currently loaded best score
```

Equal, lower, and negative scores return `false` without rewriting the file.

Successful files include:

```text
[meta]
format_version=1

[score]
best=<integer>
```

The format-version field creates a stable place for future save migration logic.

## Failure Isolation

`main.gd` updates its in-memory best score before asking the service to persist it.

If disk writing fails:

- The game-over flow continues.
- The HUD still shows the earned record for the current session.
- No state transition is interrupted.
- The service retains the previous persisted value and can retry on a later higher score.

Persistence is therefore important, but it is not allowed to become a gameplay dependency.

## Main Integration

`main.gd` now owns:

```gdscript
var save_service := SaveService.new()
```

Startup uses:

```gdscript
best_score = save_service.load_best_score()
```

New records use:

```gdscript
save_service.save_if_new_best(best_score)
```

The old `SAVE_PATH`, `_load_best_score()`, and `_save_best_score()` implementation has been removed from the game controller.

## Automated Validation

The Godot workflow now runs:

```text
tests/baseline_smoke_test.gd
tests/save_service_smoke_test.gd
```

Persistence coverage includes:

- Missing save returns zero.
- Missing save reports `MISSING`.
- Loading does not create a file.
- Negative candidates are rejected.
- First positive record writes successfully.
- Equal and lower scores do not rewrite.
- Higher score replaces the previous record.
- Fresh service instances reload persisted data.
- Malformed files fall back to zero.
- A new record repairs a malformed file.
- Wrong-type values report `INVALID_VALUE`.
- Negative stored values report `INVALID_VALUE`.
- Save files include the expected format version.
- Main owns and uses a `SaveService` instance.
- Main startup and fresh-scene persistence still work.

## Result

```text
Project import and parsing: PASS
SaveService registration: PASS
Missing-file fallback: PASS
Malformed-file fallback: PASS
Invalid-value fallback: PASS
New-best-only write policy: PASS
Malformed-save recovery: PASS
Format-version metadata: PASS
Main integration: PASS
Fresh-scene persistence: PASS
Version Guard: PASS
Godot runtime errors: NONE OBSERVED
```

## Decision

Persistence is isolated and resilient enough to proceed to:

**Foundation Step 7 — Unify Input Behavior**

That step will finish the primary-input contract by testing press/release filtering, key-repeat rejection, all supported devices, and decorative UI pass-through behavior.
