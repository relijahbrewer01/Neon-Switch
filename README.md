# Neon Switch

A self-contained one-touch mobile arcade game built with **Godot 4.6.x** and GDScript.

## The Game

Guide a signal orb between two neon lanes. Tap to switch lanes, avoid barriers, collect energy shards, and survive an accelerating run.

Visuals are drawn in code and sound effects are generated at runtime, so the project has no external art or audio dependency.

## Controls

- **Mobile:** primary touch anywhere
- **Desktop:** left click, Space, Enter, or keypad Enter
- **Development diagnostics:** F3

Only initial presses count. Releases, repeated key events, unrelated keys, other mouse buttons, and secondary touches are ignored.

## Open and Run

1. Install Godot 4.6.3 or a compatible Godot 4.x release.
2. Clone or download the repository.
3. Import `project.godot` in Godot.
4. Press F6/F5 or click Play.

The design baseline is 720×1280 portrait. Expanded canvas scaling supports taller portrait displays without letterboxing.

The small top-left version label reads `application/config/version` from `project.godot`.

## Versioning

Every playable update increments:

```text
0.1.0-dev.N
```

The Version Guard workflow rejects playable changes that reuse the previous version.

## Project Structure

```text
Neon-Switch/
├── project.godot
├── README.md
├── docs/
│   ├── DEVELOPMENT_DIAGNOSTICS_REPORT.md
│   ├── FEEDBACK_CONTRACT_REPORT.md
│   ├── FOUNDATION_PLAN.md
│   ├── INPUT_CONTRACT_REPORT.md
│   ├── PORTRAIT_UI_REPORT.md
│   ├── ROADMAP.md
│   ├── SAVE_SERVICE_REPORT.md
│   └── WAVE_DIRECTOR_REPORT.md
├── scenes/
├── scripts/
│   ├── config/game_balance.gd
│   ├── debug/debug_overlay.gd
│   ├── feedback/feedback_service.gd
│   ├── game/save_service.gd
│   ├── game/wave_director.gd
│   ├── input/primary_input.gd
│   ├── ui/portrait_layout.gd
│   ├── background.gd
│   ├── hud.gd
│   └── main.gd
└── tests/
    ├── baseline_smoke_test.gd
    ├── development_diagnostics_smoke_test.gd
    ├── feedback_contract_smoke_test.gd
    ├── input_contract_smoke_test.gd
    ├── portrait_layout_smoke_test.gd
    └── save_service_smoke_test.gd
```

## Architecture

- `game_balance.gd` owns gameplay tuning.
- `wave_director.gd` builds validated wave definitions.
- `save_service.gd` owns best-score persistence.
- `primary_input.gd` normalizes supported controls.
- `portrait_layout.gd` maps mobile display safe areas into logical canvas coordinates.
- `feedback_service.gd` owns generated audio, event playback, pitch variation, and mobile vibration policy.
- `debug_overlay.gd` displays a read-only runtime snapshot supplied by the game controller.
- `main.gd` coordinates game state, scoring, entities, saves, normalized input, semantic feedback, diagnostics, and deterministic run seeding.
- `background.gd` renders across the active logical viewport.
- `hud.gd` builds the interface inside safe and content rectangles.

## Development Diagnostics

Press **F3** to toggle the runtime diagnostics panel. It displays:

- State
- Seed mode
- Speed
- Spawn interval
- Elapsed time
- Lane
- Obstacle, pickup, and total entity counts
- Last accepted primary input source

Random mode is the default. Set a non-negative seed in `project.godot`:

```text
debug/neon_switch/deterministic_seed=424242
```

or launch with a user argument:

```text
godot --path . -- --seed=424242
```

Every run then resets the gameplay RNG to the same seed. Use `--seed=random` or `-1` in the project setting to restore random behavior.

## Audio and Haptics

`NeonFeedback` builds four streams and four `AudioStreamPlayer` nodes once at startup:

- Start
- Switch
- Collect
- Crash

Playback reuses those same objects. Collect pitch variation and crash-noise generation use feedback-owned random generators, so presentation cannot alter obstacle-wave randomness.

Only the feedback service may call the platform vibration API. Desktop builds safely ignore haptic requests. Headless validation exercises feedback routing without creating physical playback objects, preventing meaningless audio-server teardown leaks.

## Portrait Layout

The project uses `canvas_items` scaling with the `expand` aspect mode.

Validated logical layouts:

- 720×1280 — 9:16
- 720×1560 — 9:19.5
- 720×1600 — 9:20

The HUD keeps score information, status panels, footer text, the diagnostics panel, and the build version inside the calculated safe area. Six-digit score, best-score, and shard values are covered by automated tests.

## Automated Validation

GitHub Actions imports and parses the project with Godot 4.6.3, then runs:

```text
res://tests/baseline_smoke_test.gd
res://tests/save_service_smoke_test.gd
res://tests/input_contract_smoke_test.gd
res://tests/portrait_layout_smoke_test.gd
res://tests/feedback_contract_smoke_test.gd
res://tests/development_diagnostics_smoke_test.gd
```

Coverage includes the complete run loop, entity contracts, input routing, save resilience, restart stress, wave fairness, portrait geometry, safe-area containment, generated-audio reuse, feedback routing, deterministic seeds, diagnostics fields, timer cancellation, desktop haptic safety, and the displayed build version.

CI also rejects any Godot log that reports `ObjectDB instances leaked at exit`.

## License

The project is released under the MIT License.
