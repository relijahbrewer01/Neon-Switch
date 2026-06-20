# Neon Switch — Development Diagnostics Report

## Status

**Foundation Step 10 is complete and validated.**

The playable build version is:

```text
0.1.0-dev.10
```

## Objective

This milestone adds a development-only view into the live game without coupling the interface to gameplay internals.

The implementation includes:

- An F3 diagnostics overlay
- State and timing visibility
- Active entity counts
- Input-source visibility
- Optional deterministic run seeds
- Owned game-over delay timing
- Automated rejection of ObjectDB teardown leaks

## F3 Overlay

The overlay lives in:

```text
scripts/debug/debug_overlay.gd
```

Pressing F3 toggles it without entering the normal one-touch gameplay action path.

The panel displays:

```text
Current game state
Deterministic seed or RANDOM
Current movement speed
Current spawn interval
Elapsed run time
Current player lane
Obstacle count
Pickup count
Total active entity count
Last accepted primary input source
```

The overlay is pointer-transparent, non-focusable, and positioned inside the current mobile safe area.

## Snapshot Contract

`main.gd` exposes a compact diagnostic snapshot rather than allowing the overlay to inspect controller fields directly.

```gdscript
debug_snapshot() -> Dictionary
```

`NeonDebugOverlay` only formats and displays that snapshot. It does not make gameplay decisions.

## Deterministic Seeds

Random mode remains the default:

```text
debug/neon_switch/deterministic_seed=-1
```

A non-negative value enables deterministic mode. The gameplay RNG resets to that value at the beginning of every run, so restarts reproduce the same random sequence.

The seed may be supplied through `project.godot` or through a user command-line argument:

```text
godot --path . -- --seed=424242
```

Random behavior may be restored with:

```text
--seed=random
```

Feedback audio owns separate random generators, so collect pitch and crash noise do not disturb deterministic obstacle generation.

## Owned Game-Over Timer

The old delayed panel callback used `SceneTree.create_timer()`. Rapid restart stress tests could leave temporary timers alive when the test process exited.

`main.gd` now owns one persistent `Timer`:

```text
GameOverPanelTimer
```

The timer:

- Starts when the run enters game over
- Stores the transition serial and new-best result
- Stops when the player restarts or returns to ready
- Cannot display stale game-over UI over a new run
- Is freed with the game controller

## Audio Teardown Investigation

Verbose CI logs showed that the remaining ObjectDB warning came from `AudioStreamPlaybackWAV` objects created during headless tests.

The feedback service now:

- Skips physical playback when Godot uses the headless display server
- Continues to execute semantic feedback routing and counters
- Explicitly stops players and detaches streams during shutdown
- Releases test resources before the process exits

Normal desktop and mobile builds still play audio. Only headless validation avoids creating playback objects that have no audible destination.

## Automated Validation

A dedicated suite now runs at:

```text
tests/development_diagnostics_smoke_test.gd
```

It validates:

- Diagnostics begin hidden
- F3 opens and closes the overlay
- F3 release and echo events are ignored
- Required diagnostic fields are present
- The panel remains inside the safe area
- Deterministic mode can be enabled and disabled
- The active seed appears in the overlay
- Identical seeds reproduce the same run RNG sequence
- Obstacle, pickup, and total entity counts are correct
- Ready, playing, and game-over states appear correctly
- The owned game-over timer starts and cancels correctly

The workflow also scans every Godot test log for:

```text
ObjectDB instances leaked at exit
```

Any recurrence now fails CI instead of becoming background noise.

## Result

```text
Godot version: 4.6.3 stable
Project import and parsing: PASS
Core integration baseline: PASS
Save-service suite: PASS
Input-contract suite: PASS
Portrait-layout suite: PASS
Feedback-contract suite: PASS
Development-diagnostics suite: PASS
Deterministic run replay: PASS
Owned timer cancellation: PASS
Safe-area overlay placement: PASS
ObjectDB teardown leak gate: PASS
Version Guard: PASS
```

## Decision

Development visibility and deterministic testing are stable enough to proceed to:

**Foundation Step 11 — Complete Android Foundation Validation**
