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
│   ├── FOUNDATION_PLAN.md
│   └── ROADMAP.md
├── scenes/
│   ├── main.tscn
│   ├── obstacle.tscn
│   ├── pickup.tscn
│   └── player.tscn
├── scripts/
│   ├── config/
│   │   └── game_balance.gd
│   ├── background.gd
│   ├── hud.gd
│   ├── main.gd
│   ├── obstacle.gd
│   ├── pickup.gd
│   └── player.gd
└── tests/
    └── baseline_smoke_test.gd
```

## Architecture

- `game_balance.gd` is the central authority for gameplay-critical timing, positioning, scoring, speed, and spawn values.
- `main.gd` owns game state, spawning orchestration, scoring, generated audio, and save data.
- `player.gd` owns lane switching, collision signals, animation, and mobile vibration.
- `obstacle.gd` and `pickup.gd` are lightweight moving entities.
- `background.gd` draws and animates the entire playfield procedurally.
- `hud.gd` constructs the responsive interface and debug version label at runtime.
- Best score is stored locally through `ConfigFile` at `user://neon_switch_save.cfg`.

## Balance and Tuning

Gameplay-critical values now live in:

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
- Follow-up wave timing and probability
- Restart and game-over timing
- Minimum reaction-time policy for the later wave-director pass

Change tuning values there rather than scattering new numeric literals through gameplay scripts.

## Automated Validation

GitHub Actions imports and parses the project with Godot 4.6.3, then runs `tests/baseline_smoke_test.gd`. The smoke test covers the core loop, input paths, collisions, restart stress, save persistence, centralized balance values, and displayed build version.

## License

The project code, vector icon, and generated sound effects are released under the MIT License. You may modify, publish, and sell your version.
