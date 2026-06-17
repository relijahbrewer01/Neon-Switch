# Neon Switch — Runtime Baseline Report

## Status

**Foundation Step 1 is complete.**

The project imports, parses, and completes the automated core-loop smoke test under Godot **4.6.3 stable**.

Validation was completed through GitHub Actions run **#14** on the `foundation/runtime-baseline` branch.

## Scope

This step was intentionally limited to runtime stabilization and repeatable validation.

It did not change:

- Game balance
- Spawn probabilities
- Difficulty progression
- Visual design
- Scoring values
- Project folder architecture

## Implemented Validation

The repository now contains:

```text
.github/workflows/godot-baseline.yml
tests/baseline_smoke_test.gd
```

The workflow performs two checks:

1. Imports the project in headless Godot and parses project resources.
2. Runs the automated gameplay smoke test.

Validation logs are uploaded as a short-lived workflow artifact for debugging failed runs.

## Automated Test Coverage

The smoke test confirms:

- Main, obstacle, and pickup scenes load.
- The game begins in the READY state.
- A missing save file safely produces a best score of zero.
- Required player, world, and HUD nodes exist.
- Space begins a run.
- Mouse input switches lanes.
- Touch input uses the same lane-switch behavior.
- The player reaches the correct lane coordinates.
- Pickup collision increments the shard count once.
- Pickup collision awards bonus score.
- Obstacle collision enters GAME_OVER.
- The player deactivates after collision.
- A new best score is written to disk.
- Best score persists across a fresh main-scene instance.
- The game completes ten consecutive start-and-game-over cycles.

## Defect Found and Corrected

The first CI run exposed a real Godot physics error:

```text
Function blocked during in/out signal. Use set_deferred("monitoring", true/false).
```

### Cause

`player.gd` changed the player Area2D's `monitoring` property synchronously while handling an `area_entered` physics signal.

Godot blocks that property change while the physics engine is processing the overlap callback.

### Correction

The collision-state change is now deferred:

```gdscript
set_deferred("monitoring", false)
```

The pickup collection path was hardened in the same way by deferring both `monitoring` and `monitorable` changes.

The player's `active` flag still changes immediately, so duplicate gameplay effects remain blocked before the deferred physics property update occurs.

## Final Test Result

```text
Project import: PASS
Script/resource parsing: PASS
Ready state: PASS
Keyboard start input: PASS
Mouse lane switching: PASS
Touch lane switching: PASS
Pickup collision and scoring: PASS
Obstacle collision and game over: PASS
Best-score save creation: PASS
Best-score reload: PASS
Ten restart cycles: PASS
Repeated runtime errors: NONE OBSERVED
```

The final smoke-test output ended with:

```text
[baseline] All smoke tests passed
```

## Remaining Manual Validation

Headless CI validates logic and project integrity, but it does not replace human visual and physical-device testing.

The following remain intentionally scheduled for later foundation steps:

- Visual review at multiple portrait aspect ratios
- Audio quality review through speakers or headphones
- Physical touch responsiveness
- Device vibration strength
- Android suspend/resume behavior
- Camera-cutout and safe-area validation
- Debug APK installation on real hardware

These are tracked in Steps 8, 9, and 11 of [`ROADMAP.md`](ROADMAP.md).

## Baseline Decision

The current prototype is stable enough to proceed to **Foundation Step 2: Centralize Balance Values**.

The next step should move gameplay-critical constants into `scripts/config/game_balance.gd` while preserving the exact runtime behavior proven by this baseline test.
