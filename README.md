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
├── scenes/
│   ├── main.tscn
│   ├── obstacle.tscn
│   ├── pickup.tscn
│   └── player.tscn
└── scripts/
    ├── background.gd
    ├── hud.gd
    ├── main.gd
    ├── obstacle.gd
    ├── pickup.gd
    └── player.gd
```

## Architecture

- `main.gd` owns the game state, spawning, difficulty curve, scoring, generated audio, and save data.
- `player.gd` owns lane switching, collision signals, animation, and mobile vibration.
- `obstacle.gd` and `pickup.gd` are lightweight moving entities.
- `background.gd` draws and animates the entire playfield procedurally.
- `hud.gd` constructs the responsive interface at runtime.
- Best score is stored locally through `ConfigFile` at `user://neon_switch_save.cfg`.

## Easy Tuning Points

In `scripts/main.gd`:

- Starting speed: `current_speed = 650.0`
- Maximum speed: `1120.0`
- Starting spawn interval: `0.92`
- Minimum spawn interval: `0.48`
- Shard reward: `25.0`

In `scripts/player.gd`:

- Lane-switch duration: `MOVE_TIME = 0.115`

## License

The project code, vector icon, and generated sound effects are released under the MIT License. You may modify, publish, and sell your version.
