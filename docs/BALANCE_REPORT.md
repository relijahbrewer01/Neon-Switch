# Neon Switch — Balance Centralization Report

## Status

**Foundation Step 2 is complete.**

Gameplay-critical tuning now has one authoritative owner:

```text
scripts/config/game_balance.gd
```

The development build version for this milestone is:

```text
0.1.0-dev.2
```

That version is stored in `project.godot` and displayed as a small label in the top-left corner of the game.

## Objective

This step moved gameplay tuning out of operational scripts without intentionally changing the game’s behavior.

Before this pass, values such as lane positions, player placement, speed, spawn timing, pickup rewards, and restart timing were repeated or embedded directly in `main.gd`, `player.gd`, `background.gd`, `obstacle.gd`, and `pickup.gd`.

The refactor gives those values one home and gives gameplay scripts named contracts instead of unexplained numeric literals.

## Centralized Values

`GameBalance` now owns:

- Viewport size
- Lane positions
- Player starting lane and vertical position
- Lane-switch duration
- Starting and maximum speed
- Speed gain per second
- Starting and minimum spawn intervals
- Spawn-interval reduction
- Initial spawn-clock offset
- Base score rate and score acceleration
- Pickup score reward
- Obstacle spawn and cleanup positions
- Pickup spawn, random offset, cleanup, and probability values
- Follow-up-wave unlock time, probability, and spacing
- Minimum reaction-time policy for the future wave director
- Restart lock, game-over panel delay, and screen-shake duration

## Centralized Curves

The configuration also exposes named functions:

```gdscript
GameBalance.speed_at(elapsed_seconds)
GameBalance.spawn_interval_at(elapsed_seconds)
GameBalance.score_rate_at(elapsed_seconds)
GameBalance.followup_chance_at(elapsed_seconds)
```

This keeps the mathematical shape of progression beside the values that control it.

## Runtime Integration

The following scripts now read from `GameBalance`:

- `main.gd`
- `player.gd`
- `background.gd`
- `obstacle.gd`
- `pickup.gd`

The duplicated player position was removed from `main.tscn`; `player.gd` now establishes the authoritative reset position through `GameBalance`.

## Version Label

`project.godot` now defines:

```text
application/config/version="0.1.0-dev.2"
```

`hud.gd` reads that value at runtime and displays:

```text
v0.1.0-dev.2
```

The label is intentionally small, low-contrast, and positioned at the extreme top-left so it remains useful for debugging without competing with the score HUD.

The version string is not duplicated inside the HUD script. Updating `project.godot` updates the displayed label automatically.

## Behavior Preservation

The existing numerical values and formulas were preserved.

One subtle preservation detail was handled explicitly: before follow-up waves unlock, the game still avoids consuming an extra random-number roll. This preserves the pre-refactor random sequence behavior rather than merely preserving the probability distribution.

No intentional changes were made to:

- Player speed
- Lane-switch timing
- Spawn frequency
- Pickup probability
- Pickup score value
- Difficulty progression
- Follow-up-wave behavior
- Restart timing

## Automated Validation

The baseline smoke test was expanded to verify:

- Canonical version value
- Version-label creation and text
- Viewport configuration
- Lane positions
- Starting and maximum speed
- Starting and minimum spawn interval
- Pickup reward
- Initial speed and spawn curve outputs
- Follow-up unlock threshold
- Player starting lane and position
- Initial run speed and spawn interval
- Configured lane-switch timing
- Configured pickup reward
- Configured restart-lock window
- Existing collision, save, and ten-restart behavior

## Test Result

Godot 4.6.3 CI completed successfully after the refactor.

```text
Project import: PASS
Script and resource parsing: PASS
GameBalance registration: PASS
Canonical version: PASS
Version HUD label: PASS
Configured player placement: PASS
Configured speed and spawn values: PASS
Keyboard, mouse, and touch paths: PASS
Pickup scoring: PASS
Game-over timing window: PASS
Best-score persistence: PASS
Ten restart cycles: PASS
Repeated runtime errors: NONE OBSERVED
```

An interim test compared the restart-lock timer to its starting value after multiple frames had already elapsed. The game was behaving correctly; the assertion was too strict. The test now validates that the timer remains inside the configured active window instead of pretending time stood still for the test runner.

## Deferred Fairness Enforcement

`GameBalance.MIN_REACTION_TIME` is now defined, but it is not yet enforced by the current inline wave generator.

That is intentional. Mathematical pattern validation belongs to **Foundation Step 4: Extract Wave Generation**, where wave construction will move into a dedicated director.

Centralizing the policy now prepares that work without silently changing the current game during this refactor.

## Decision

The balance-centralization step is stable and complete.

The project is ready for **Foundation Step 3: Formalize Game-State Transitions**.
