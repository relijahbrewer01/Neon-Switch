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

The design baseline is 720×1280 portrait. `canvas_items` with `keep_width` keeps the portrait playfield centered on wide desktop windows and expands the logical height on taller phones.

The standalone desktop window also requests a centered initial position. The small top-left version label reads `application/config/version` from `project.godot`.

## Android Debug Build

The repository contains a secret-free **Android Debug** export preset and an automated GitHub Actions build.

```text
Package: com.elijah.neonswitch
Architecture: arm64-v8a
Output: build/android/neon-switch-debug.apk
```

The workflow installs OpenJDK 17, the Android SDK toolchain, Godot 4.6.3, matching export templates, and a disposable debug keystore before producing an installable APK and SHA-256 checksum.

Local setup, installation commands, and the hardware checklist are documented in:

```text
docs/ANDROID_VALIDATION.md
docs/ANDROID_DEVICE_TEST_REPORT.md
```

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
├── export_presets.cfg
├── README.md
├── .github/workflows/
│   ├── android-debug-build.yml
│   └── godot-baseline.yml
├── docs/
│   ├── ANDROID_DEVICE_TEST_REPORT.md
│   ├── ANDROID_VALIDATION.md
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

Press **F3** to toggle the runtime diagnostics panel. It displays state, seed mode, speed, spawn interval, elapsed time, lane, active entity counts, and the last accepted primary input source.

Random mode is the default. Set a non-negative seed in `project.godot` or launch with:

```text
godot --path . -- --seed=424242
```

Every run then resets the gameplay RNG to the same seed. Use `--seed=random` or `-1` in the project setting to restore random behavior.

## Audio and Haptics

`NeonFeedback` builds four streams and four `AudioStreamPlayer` nodes once at startup for start, switch, collect, and crash events.

Playback reuses those same objects. Feedback owns separate random generators, so presentation cannot alter obstacle-wave randomness. Desktop builds safely ignore haptic requests, and headless validation exercises routing without creating physical playback objects.

## Portrait Layout

The project uses `canvas_items` scaling with `keep_width`.

Validated logical layouts:

- 720×1280 — 9:16
- 720×1560 — 9:19.5
- 720×1600 — 9:20

The fixed logical width keeps both gameplay lanes centered on wide desktop displays. Taller portrait displays receive additional vertical canvas space. The HUD keeps score information, panels, diagnostics, and the build version inside the calculated safe area.

## Automated Validation

GitHub Actions imports and parses the project with Godot 4.6.3, runs all six Godot smoke-test suites, rejects ObjectDB teardown leaks, and exports the Android debug APK.

Coverage includes the complete run loop, entity contracts, input routing, save resilience, restart stress, wave fairness, portrait geometry, centered desktop scaling policy, safe-area containment, generated-audio reuse, deterministic seeds, diagnostics, timer cancellation, and build versioning.

## License

The project is released under the MIT License.
