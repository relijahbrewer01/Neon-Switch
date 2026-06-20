# Neon Switch

A complete, self-contained one-touch mobile arcade game built with **Godot 4.6.x** and GDScript.

## The Game

Your signal orb races down one of two neon lanes. Tap anywhere to switch lanes, dodge incoming barriers, and collect green energy shards. The run gradually accelerates, and later waves introduce staggered barriers that demand quick double-switches.

There are no external art dependencies. Every visual is drawn in code, and the sound effects are generated at runtime from GDScript, so the repository contains no external media dependencies.

## Controls

- **Android / iOS:** tap anywhere
- **Desktop testing:** left click, Space, or Enter

## Open and Run

1. Install Godot 4.6.3 or a compatible newer Godot 4.x release.
2. Clone or download this repository.
3. In Godot, click **Import** and select `project.godot`.
4. Open the project and press **F6/F5** or click Play.

The project is configured for a 720×1280 portrait viewport and scales to different phone screens.

A small version string appears in the top-left corner. It is read from `application/config/version` in `project.godot`, so screenshots and bug reports identify the exact build being tested.

## Versioning

Every playable game update must increment the development build number in `project.godot`.

Current development format:

```text
0.1.0-dev.N
```

The repository includes a pull-request Version Guard that fails when runtime files change without a version bump. Full instructions live in `docs/VERSIONING.md`.

## Android Export

Godot's current Android export workflow requires OpenJDK 17 and the Android SDK. In Godot, configure both under **Editor Settings → Export → Android**, install the Android export templates, then create an Android preset under **Project → Export**.

Recommended first package name:

```text
com.elijah.neonswitch
```

For Play Store release, create and securely store a release keystore, switch to an Android App Bundle (`.aab`), and replace the placeholder package identifier with one you own.

## iOS Export

An iOS build requires macOS with Xcode. Install Godot's export templates, add an iOS export preset, provide your Apple bundle identifier and signing team, then export the generated Xcode project.

## Project Structure

```text
Neon-Switch/
├── project.godot
├── icon.svg
├── README.md
├── docs/
│   ├── BALANCE_REPORT.md
│   ├── BASELINE_REPORT.md
│   ├── ENTITY_CONTRACTS_REPORT.md
│   ├── FOUNDATION_PLAN.md
│   ├── ROADMAP.md
│   ├── SAVE_SERVICE_REPORT.md
│   ├── STATE_TRANSITIONS_REPORT.md
│   ├── VERSIONING.md
│   └── WAVE_DIRECTOR_REPORT.md
├── scenes/
│   ├── main.tscn
│   ├── obstacle.tscn
│   ├── pickup.tscn
│   └── player.tscn
├── scripts/
│   ├── config/
│   │   └── game_balance.gd
│   ├── game/
│   │   ├── save_service.gd
│   │   └── wave_director.gd
│   ├── background.gd
│   ├── hud.gd
│   ├── main.gd
│   ├── obstacle.gd
│   ├── pickup.gd
│   └── player.gd
└── tests/
    ├── baseline_smoke_test.gd
    └── save_service_smoke_test.gd
```

## Architecture

- `game_balance.gd` is the central authority for gameplay-critical timing, positioning, scoring, speed, and spawn values.
- `wave_director.gd` builds tiered, mathematically validated wave definitions without instantiating scenes.
- `save_service.gd` owns best-score file format, validation, load status, and new-record write policy.
- `main.gd` owns the guarded game-state machine, turns wave definitions into entities, tracks scoring, generates audio, and delegates persistence to `SaveService`.
- `player.gd` owns lane state, collision signals, player-only animation, and mobile vibration through a small public contract.
- `obstacle.gd` owns hazard movement, configuration, offscreen retirement, and idempotent cleanup.
- `pickup.gd` owns movement, one-time collection state, collection animation, and idempotent cleanup.
- `background.gd` draws and animates the entire playfield procedurally.
- `hud.gd` constructs the responsive interface and debug version label at runtime.

## Save Data

Best score is stored through `SaveService` at:

```text
user://neon_switch_save.cfg
```

The service safely handles:

- Missing save files
- Malformed configuration files
- Wrong-type score values
- Negative stored scores
- Equal or lower score attempts

A missing or invalid save falls back to zero without blocking startup. Only a score greater than the currently loaded best is written. Disk failure does not roll back the in-memory record or interrupt game-over flow.

## Entity Contracts

Gameplay entities expose narrow public APIs rather than allowing the game controller to edit their internal state directly.

- Player: `reset_for_run()`, `activate()`, `switch_lane()`, `crash()`, and read-only state methods.
- Obstacle: `configure()`, `movement_speed()`, `despawn()`, and `is_despawned()`.
- Pickup: `configure()`, `collect()`, `despawn()`, and read-only collection/lifecycle methods.

Main coordinates scoring and state. Each entity owns its movement, feedback, collision shutdown, and final cleanup.

## Wave Fairness

The director separates pattern choice from scene creation and validates every generated wave against the configured response window:

```text
PLAYER_SWITCH_TIME + MIN_REACTION_TIME
```

Introduction waves contain one obstacle. Rhythm and pressure tiers may add an opposite-lane follow-up only when vertical spacing provides enough travel time for a deliberate lane change. Simultaneous full-lane blocks and under-spaced lane changes are rejected.

## Balance and Tuning

Gameplay-critical values live in:

```text
scripts/config/game_balance.gd
```

This includes:

- Lane positions and player start position
- Lane-switch duration
- Starting and maximum speed
- Spawn-interval curve
- Score-rate curve and pickup reward
- Obstacle and pickup spawn/cleanup positions
- Wave-tier timing and follow-up probability
- Restart and game-over timing
- Minimum reaction-time policy

Change tuning values there rather than scattering new numeric literals through gameplay scripts.

## Automated Validation

GitHub Actions imports and parses the project with Godot 4.6.3, then runs both smoke-test suites:

```text
res://tests/baseline_smoke_test.gd
res://tests/save_service_smoke_test.gd
```

Coverage includes the core loop, guarded state transitions, entity public contracts, idempotent collection and cleanup, stable signal connections, input paths, collisions, restart stress, SaveService integration, missing/malformed/invalid persistence data, new-best-only writes, centralized balance values, tier boundaries, generated-wave fairness, and displayed build version.

## License

The project code, vector icon, and generated sound effects are released under the MIT License. You may modify, publish, and sell your version.
