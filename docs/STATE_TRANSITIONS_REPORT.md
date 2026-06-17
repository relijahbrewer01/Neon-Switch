# Neon Switch — State Transition Report

## Status

**Foundation Step 3 is complete.**

The playable build version for this milestone is:

```text
0.1.0-dev.3
```

## Objective

This step replaced scattered state changes with a formal transition contract.

The game now enters READY, PLAYING, and GAME_OVER through named methods instead of assigning state and performing side effects from unrelated input or collision code.

## State Entry Methods

The main game controller now owns:

```gdscript
_enter_ready_state()
_enter_playing_state()
_enter_game_over_state()
```

Each method is responsible for the side effects of entering that state.

### READY

- Clears spawned entities
- Resets run values
- Resets the player
- Resets background intensity
- Displays the ready HUD

### PLAYING

- Clears entities from the prior run
- Resets score, shards, elapsed time, speed, and spawn timing
- Clears restart and screen-shake state
- Resets and activates the player
- Hides the menu panel
- Updates the HUD
- Plays the start sound

### GAME_OVER

- Deactivates and crashes the player
- Starts screen shake and restart lock
- Plays crash feedback
- Saves a new best score when necessary
- Updates the HUD
- Schedules the delayed game-over panel

## Allowed Transition Table

The controller explicitly allows only:

```text
READY     → PLAYING
PLAYING   → GAME_OVER
GAME_OVER → PLAYING
```

Invalid transitions return `false` and perform no side effects.

## Transition Guard

Two values enforce transition safety:

```gdscript
state_transition_in_progress
state_transition_serial
```

The transition lock remains active through the current frame. This prevents a burst of duplicate input events from:

- Starting a run and immediately switching lanes
- Entering PLAYING twice
- Processing the same death more than once
- Restarting twice
- Restarting and immediately switching lanes

The serial increases exactly once for each accepted transition.

## Unified Primary Action

All supported primary input paths now converge on:

```gdscript
_handle_primary_action()
```

The input parser recognizes touch, left mouse, Space, and Enter, then delegates behavior according to the current state.

```text
READY     → start run
PLAYING   → switch lane
GAME_OVER → request restart
```

This creates one behavioral doorway even though several physical input devices can knock on it.

## Restart Contract

Restart no longer performs a temporary GAME_OVER → READY → PLAYING chain.

Once the restart lock expires, the game transitions directly:

```text
GAME_OVER → PLAYING
```

The PLAYING entry method performs the complete clean-run reset.

## Stale Callback Protection

The game-over panel appears after a short delay. That delayed callback now captures the transition serial and verifies that the game is still in the same GAME_OVER transition before showing UI.

If a new run has already started, the old callback exits quietly. This prevents stale game-over UI from appearing over active gameplay.

## Version Enforcement

This milestone also formalized the rule that every playable update must receive a new build number.

Added:

```text
docs/VERSIONING.md
.github/workflows/version-guard.yml
.github/pull_request_template.md
```

The Version Guard compares the pull-request branch against the base branch. When runtime files change, the pull request fails if `application/config/version` has not changed.

The HUD continues to read the version directly from `project.godot`.

## Automated Validation

The smoke test now verifies:

- Initial READY transition completes and unlocks
- Space starts through the primary action handler
- READY → PLAYING increments the serial once
- Duplicate same-frame input cannot switch lanes after starting
- Re-entering PLAYING is rejected
- Mouse and touch share the primary action path
- Collision enters GAME_OVER once
- Duplicate collision signals do not create another transition
- Restart input is blocked during the restart window
- Double restart input records only one transition
- A second restart input cannot become an immediate lane switch
- Stale delayed game-over UI cannot cover a restarted run
- A current GAME_OVER transition still displays its panel
- Best-score persistence remains intact
- Ten consecutive guarded run/death/restart cycles succeed
- The displayed build version is `v0.1.0-dev.3`

## Test Result

Godot 4.6.3 validation passed.

```text
Project import and parsing: PASS
Version Guard: PASS
Canonical version: PASS
READY entry: PASS
PLAYING entry: PASS
GAME_OVER entry: PASS
Allowed transition contract: PASS
Same-frame input guard: PASS
Duplicate collision guard: PASS
Restart lock: PASS
Double restart guard: PASS
Stale callback protection: PASS
Best-score persistence: PASS
Ten guarded restart cycles: PASS
Repeated runtime errors: NONE OBSERVED
```

## Decision

The state machine is stable enough to proceed to:

**Foundation Step 4 — Extract Wave Generation**

That step will move pattern construction out of `main.gd`, introduce pattern tiers, and enforce the minimum reaction-time policy already defined in `GameBalance`.
