# Neon Switch

A self-contained one-touch mobile arcade game built with **Godot 4.6.x** and GDScript.

## The Game

Guide a signal orb between two neon lanes. Tap to switch lanes, avoid barriers, collect energy shards, and survive an accelerating run.

Visuals are drawn in code and sound effects are generated at runtime, so the project has no external art or audio dependency.

## Controls

- **Mobile:** primary touch anywhere
- **Desktop:** left click, Space, Enter, or keypad Enter

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
│   ├── FOUNDATION_PLAN.md
│   ├── ROADMAP.md
│   ├── INPUT_CONTRACT_REPORT.md
│   ├── PORTRAIT_UI_REPORT.md
│   ├── SAVE_SERVICE_REPORT.md
│   └── WAVE_DIRECTOR_REPORT.md
├── scenes/
├── scripts/
│   ├── config/game_balance.gd
│   ├── game/save_service.gd
│   ├── game/wave_director.gd
│   ├── input/primary_input.gd
│   ├── ui/portrait_layout.gd
│   ├── background.gd
│   ├── hud.gd
│   └── main.gd
└── tests/
    ├── baseline_smoke_test.gd
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
- `main.gd` coordinates game state, scoring, entities, audio, saves, and normalized input.
- `background.gd` renders across the active logical viewport.
- `hud.gd` builds the interface inside safe and content rectangles.

## Portrait Layout

The project uses `canvas_items` scaling with the `expand` aspect mode.

Validated logical layouts:

- 720×1280 — 9:16
- 720×1560 — 9:19.5
- 720×1600 — 9:20

The HUD keeps score information, status panels, footer text, and the build version inside the calculated safe area. Six-digit score, best-score, and shard values are covered by automated tests.

## Automated Validation

GitHub Actions imports and parses the project with Godot 4.6.3, then runs:

```text
res://tests/baseline_smoke_test.gd
res://tests/save_service_smoke_test.gd
res://tests/input_contract_smoke_test.gd
res://tests/portrait_layout_smoke_test.gd
```

Coverage includes gameplay state, entity contracts, input routing, save resilience, restart stress, wave fairness, portrait geometry, safe-area containment, tall background coverage, and the displayed build version.

## License

The project is released under the MIT License.
