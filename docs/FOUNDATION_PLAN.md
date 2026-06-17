# Neon Switch — Foundation Plan and Junior Developer Brief

## 1. Purpose

This document defines the **foundation phase** for Neon Switch.

The current repository already contains a playable prototype: the player can switch between two lanes, obstacles and pickups spawn, score increases, best score is saved, and the game supports touch, mouse, and keyboard input.

The purpose of this phase is **not** to add a shop, cosmetics, power-ups, achievements, ads, multiplayer, or content variety.

The purpose is to turn the prototype into a dependable base that future features can safely build on.

A foundation is considered successful when:

- The game launches without parser or runtime errors.
- The core loop is stable and repeatable.
- Input behaves consistently on desktop and mobile.
- Difficulty is fair and understandable.
- Game state transitions cannot overlap or become stuck.
- The project structure is clear enough that another developer can navigate it quickly.
- Tuning values are centralized rather than scattered through gameplay code.
- Save data is resilient to missing or malformed files.
- The project can be exported to Android without architectural changes.

The rule for this phase is simple:

> Stabilize the machine before adding more gears.

---

## 2. Product Summary

Neon Switch is a portrait-oriented, one-touch arcade survival game.

The player controls a glowing signal orb traveling down one of two lanes. A tap switches the player to the opposite lane. The player must avoid barriers and may collect energy shards for bonus score. The game becomes faster and more demanding over time.

### Core Loop

```text
READY
  ↓ tap
PLAYING
  ↓ survive, switch lanes, collect shards
COLLISION
  ↓
GAME OVER
  ↓ tap
PLAYING AGAIN
```

### Player Promise

The game should feel:

- Immediate
- Responsive
- Fair
- Easy to understand
- Difficult to master
- Suitable for very short mobile sessions

### Core Design Pillars

1. **One-touch clarity**  
   Every meaningful gameplay action must be possible with a single tap.

2. **Readable danger**  
   The player should understand why they failed.

3. **Fast restart**  
   Death should return the player to gameplay quickly.

4. **Short-session replayability**  
   A full attempt may last seconds or minutes, but restarting should always feel tempting.

5. **Mobile-first behavior**  
   Desktop input exists for development and accessibility, but the game is designed around portrait touch play.

---

## 3. Current Baseline

The repository currently contains:

```text
project.godot
icon.svg
LICENSE
README.md

scenes/
├── main.tscn
├── obstacle.tscn
├── pickup.tscn
└── player.tscn

scripts/
├── background.gd
├── hud.gd
├── main.gd
├── obstacle.gd
├── pickup.gd
└── player.gd
```

### Existing Responsibilities

- `main.gd`
  - Owns game state
  - Spawns obstacles and pickups
  - Tracks score, speed, and difficulty
  - Saves best score
  - Handles high-level input
  - Generates and plays sound effects

- `player.gd`
  - Owns lane switching
  - Detects obstacle and pickup collisions
  - Handles player animation and vibration

- `obstacle.gd`
  - Moves obstacles downward
  - Draws obstacle visuals

- `pickup.gd`
  - Moves pickups downward
  - Draws pickup visuals
  - Handles collection animation

- `background.gd`
  - Draws and animates the procedural background

- `hud.gd`
  - Builds the interface at runtime
  - Displays score, best score, shards, ready state, and game-over state

This baseline is useful, but several responsibilities are concentrated in `main.gd`, tuning values are embedded directly in scripts, and the spawning logic needs a formal fairness contract before the game grows.

---

## 4. Foundation Goals

The foundation phase has seven goals.

### Goal A — Runtime Stability

The project must parse, launch, restart, and exit cleanly without errors or warnings that indicate broken logic.

### Goal B — Predictable Game State

Only one state may be active at a time:

```gdscript
enum GameState {
    READY,
    PLAYING,
    GAME_OVER
}
```

Every transition must happen through a named method rather than scattered variable changes.

### Goal C — Fair Spawning

Every obstacle wave must leave the player a valid response window.

The generator must never create a pattern that is technically impossible because the next obstacle arrives before the lane-switch tween and human reaction time allow a response.

### Goal D — Centralized Balance

Speed, spawn timing, score rates, pickup reward, lane positions, reaction windows, and difficulty thresholds should be defined in one place.

### Goal E — Clear Contracts Between Scripts

Each script should have one main responsibility and communicate through typed methods or signals.

### Goal F — Mobile Readiness

Touch input, safe-area layout, portrait scaling, haptics, and Android export assumptions must be tested early.

### Goal G — Easy Future Expansion

The architecture should support later additions such as:

- Alternate obstacle patterns
- Cosmetic player skins
- Daily challenges
- Power-ups
- Missions
- Leaderboards
- Ads or paid unlocks

These features are not part of this phase, but the foundation should not make them painful to add later.

---

## 5. Non-Goals

Do not implement any of the following during the foundation phase:

- Shops
- Currency beyond the current run shard count
- Unlockable skins
- Achievements
- Online leaderboards
- Advertisements
- Analytics SDKs
- Cloud saves
- Multiple game modes
- Boss encounters
- Story or lore systems
- New art pipelines
- Major visual redesigns
- Music systems
- Localization

Do not widen the scope because a feature seems small. Small features have a habit of arriving with luggage.

---

## 6. Proposed Foundation Structure

The target structure should remain simple.

```text
Neon-Switch/
├── project.godot
├── README.md
├── LICENSE
├── icon.svg
│
├── docs/
│   └── FOUNDATION_PLAN.md
│
├── scenes/
│   ├── main.tscn
│   ├── player.tscn
│   ├── obstacle.tscn
│   └── pickup.tscn
│
└── scripts/
    ├── config/
    │   └── game_balance.gd
    │
    ├── game/
    │   ├── main.gd
    │   ├── wave_director.gd
    │   └── save_service.gd
    │
    ├── entities/
    │   ├── player.gd
    │   ├── obstacle.gd
    │   └── pickup.gd
    │
    └── presentation/
        ├── background.gd
        └── hud.gd
```

This reorganization is recommended, but it should only be performed after the current project is confirmed to run.

### Why This Structure

- `config/` holds tunable values.
- `game/` holds orchestration and systems.
- `entities/` holds gameplay objects.
- `presentation/` holds visuals and interface.

The point is not folder elegance for its own sake. The point is reducing the amount of searching required to answer, “Where does this behavior live?”

---

## 7. Junior Developer Instructions

## Step 0 — Read Before Editing

Before changing any file:

1. Read this entire document.
2. Read `README.md`.
3. Open every `.gd` file and identify its current responsibility.
4. Run the project once in Godot.
5. Record all parser errors, runtime errors, warnings, and obvious gameplay problems.
6. Do not begin refactoring until the current runtime state is understood.

### Deliverable

Create a short audit note in the pull request description containing:

- Godot version used
- Whether the project launches
- Any parser errors
- Any runtime errors
- Any visual or input defects observed

---

## Step 1 — Establish a Clean Runtime Baseline

### Objective

Confirm the current game runs before restructuring it.

### Tasks

1. Open `project.godot` in Godot 4.6.x.
2. Allow Godot to import the project.
3. Run the main scene.
4. Test:
   - Ready screen
   - Starting a run
   - Lane switching
   - Collecting a shard
   - Hitting an obstacle
   - Restarting
   - Best-score persistence after closing and reopening the game
5. Fix only blocking parser or runtime errors.
6. Avoid gameplay redesign during this step.

### Coding Rules

- Use explicit types when inference is ambiguous.
- Typed arrays must use syntax such as:

```gdscript
const LANE_X: Array[float] = [210.0, 510.0]
```

- Do not use `:=` when the expression may resolve to `Variant`.
- Do not suppress errors without understanding them.
- Do not replace working systems simply because another approach looks cleaner.

### Acceptance Criteria

- The project launches without parser errors.
- A full run can begin and end.
- Restarting works at least ten consecutive times.
- The debugger does not fill with repeated errors.

---

## Step 2 — Centralize Balance Values

### Objective

Move gameplay tuning out of operational code.

### Create

```text
scripts/config/game_balance.gd
```

### Recommended Shape

```gdscript
extends RefCounted
class_name GameBalance

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
const LANE_X: Array[float] = [210.0, 510.0]
const PLAYER_Y := 1050.0

const START_SPEED := 650.0
const MAX_SPEED := 1120.0
const SPEED_GAIN_PER_SECOND := 13.0

const START_SPAWN_INTERVAL := 0.92
const MIN_SPAWN_INTERVAL := 0.48
const SPAWN_INTERVAL_REDUCTION_PER_SECOND := 0.0075

const BASE_SCORE_PER_SECOND := 11.0
const SCORE_ACCELERATION := 0.055
const PICKUP_SCORE := 25.0

const LANE_SWITCH_TIME := 0.115
const RESTART_LOCK_TIME := 0.48
const MIN_REACTION_TIME := 0.32
```

The exact values may remain unchanged initially. This step is about location and ownership, not rebalancing.

### Tasks

1. Add `game_balance.gd`.
2. Replace duplicated lane positions and player position values with `GameBalance` references.
3. Replace hard-coded speed, spawn, score, and timing values with named constants.
4. Keep purely visual values inside presentation scripts unless they affect gameplay fairness.

### Acceptance Criteria

- Gameplay behaves the same as before the refactor.
- No gameplay-critical number is duplicated across multiple scripts.
- A designer can find the major balance values in one file.

---

## Step 3 — Harden Game-State Transitions

### Objective

Make state changes explicit and impossible to overlap.

### Required Methods

`main.gd` should expose private transition methods similar to:

```gdscript
func _enter_ready_state() -> void:
    pass

func _enter_playing_state() -> void:
    pass

func _enter_game_over_state() -> void:
    pass
```

### Rules

- Do not assign `state` from unrelated methods.
- Do not start a run by manually changing several variables in `_input()`.
- State-entry methods own reset behavior, UI visibility, player activation, and timers.
- Inputs should request transitions; they should not perform the entire transition inline.

### Required Transition Table

| Current State | Input/Event | Next State |
|---|---|---|
| READY | Tap | PLAYING |
| PLAYING | Tap | PLAYING, switch lane |
| PLAYING | Obstacle collision | GAME_OVER |
| GAME_OVER | Tap after restart lock | PLAYING |

### Edge Cases to Test

- Rapidly tap during the ready-to-playing transition.
- Tap repeatedly during a crash.
- Tap before the restart lock expires.
- Trigger two collision signals on the same frame.
- Restart ten times without reloading the scene.

### Acceptance Criteria

- Only one death event is processed per run.
- The player cannot switch lanes after death.
- The game cannot start two runs simultaneously.
- Restart always begins from the same clean state.

---

## Step 4 — Extract Wave Generation

### Objective

Separate spawning and pattern fairness from the main game loop.

### Create

```text
scripts/game/wave_director.gd
```

### Responsibility

`wave_director.gd` should decide:

- Which lane is blocked
- Whether a pickup appears
- Whether a follow-up obstacle appears
- How much spacing exists between hazards
- Whether a pattern is allowed at the current elapsed time

It should not:

- Update score
- Own the player
- Draw UI
- Save data
- Play audio

### Suggested Contract

```gdscript
extends RefCounted
class_name WaveDirector

func build_wave(elapsed: float, speed: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
    return []
```

A wave entry may look like:

```gdscript
{
    "type": "obstacle",
    "lane": 0,
    "offset_y": 0.0
}
```

### Fairness Rule

For every sequential hazard that requires another lane switch:

```text
travel time between hazards
must be greater than or equal to
lane-switch time + minimum reaction time
```

Approximate travel time:

```gdscript
var travel_time := vertical_spacing / current_speed
```

A follow-up pattern is valid only when:

```gdscript
travel_time >= GameBalance.LANE_SWITCH_TIME + GameBalance.MIN_REACTION_TIME
```

### Pattern Tiers

#### Tier 1 — Introduction

Available immediately:

- One obstacle in either lane
- Optional pickup in the safe lane

#### Tier 2 — Rhythm

Unlock after roughly 15–20 seconds:

- Obstacle followed by an obstacle in the opposite lane
- Spacing must satisfy the fairness rule

#### Tier 3 — Pressure

Unlock later:

- Shorter safe windows
- Higher speed
- More frequent pickups positioned to tempt quick switches

Do not add more than these three tiers during the foundation phase.

### Acceptance Criteria

- `main.gd` requests a wave rather than inventing one inline.
- Every generated wave contains at least one valid survival route.
- The director does not instantiate scenes directly unless clearly documented.
- Impossible patterns are prevented mathematically, not merely considered unlikely.

---

## Step 5 — Define Entity Contracts

### Objective

Make player, obstacle, and pickup behavior predictable.

### Player Contract

The player owns:

- Current lane index
- Lane-switch tween
- Collision detection
- Player visual response
- Optional haptic response

The player does not own:

- Score
- Spawn timing
- Save data
- Game-over UI
- Difficulty progression

### Obstacle Contract

An obstacle owns:

- Downward movement
- Its speed
- Its visual appearance
- Self-cleanup after leaving the screen

An obstacle does not decide whether the player dies.

### Pickup Contract

A pickup owns:

- Downward movement
- Its speed
- Collection animation
- Self-cleanup

A pickup does not award score directly.

### Signal Rules

Signals should be typed when possible:

```gdscript
signal hit_obstacle(obstacle: NeonObstacle)
signal collected_pickup(pickup: EnergyPickup)
```

Connections should be made once in `_ready()` and should not accumulate after restarts.

### Acceptance Criteria

- Restarting does not duplicate signals.
- A pickup can only be collected once.
- A collision can only end a run once.
- Entities clean themselves up after leaving the playfield.

---

## Step 6 — Extract Save Handling

### Objective

Keep persistence out of the game loop.

### Create

```text
scripts/game/save_service.gd
```

### Suggested Interface

```gdscript
extends RefCounted
class_name SaveService

const SAVE_PATH := "user://neon_switch_save.cfg"

static func load_best_score() -> int:
    return 0

static func save_best_score(value: int) -> Error:
    return OK
```

### Required Behavior

- Missing save files return a best score of `0`.
- Malformed values fall back safely to `0`.
- Negative best scores are rejected or clamped to `0`.
- Failure to save must not crash the game.
- Save only when a new best score is achieved.

### Acceptance Criteria

- Deleting the save file does not break startup.
- Corrupting the saved best-score value does not crash startup.
- A new best score remains after closing and reopening the game.

---

## Step 7 — Input Consistency

### Objective

Ensure every supported input path invokes the same gameplay action.

### Supported Input

- Touch press
- Left mouse press
- Space
- Enter

### Rules

- Ignore key-repeat events.
- Process only the initial press, not release.
- Do not allow UI controls to consume the global gameplay tap unexpectedly.
- Input should be ignored when the application is not in a state that accepts it.
- Input behavior must remain identical regardless of source.

### Recommended Refactor

Create one method:

```gdscript
func _handle_primary_action() -> void:
    match state:
        GameState.READY:
            _enter_playing_state()
        GameState.PLAYING:
            _request_lane_switch()
        GameState.GAME_OVER:
            _request_restart()
```

Every supported input should call that method.

### Acceptance Criteria

- Touch, mouse, Space, and Enter all behave identically.
- Holding Space does not cause repeated switching.
- Tapping during crash animation does not bypass the restart lock.

---

## Step 8 — UI and Screen-Safety Pass

### Objective

Make the HUD readable across portrait phones without redesigning it.

### Tasks

1. Verify the project at these approximate aspect ratios:
   - 9:16
   - 9:19.5
   - 9:20
2. Confirm top UI does not overlap common camera cutout areas.
3. Confirm the ready and game-over panels remain inside the visible viewport.
4. Confirm text does not clip when the score reaches at least six digits.
5. Confirm the entire screen remains a valid tap target during gameplay.
6. Keep `mouse_filter` configured so decorative UI does not swallow touch input.

### Safe-Area Guidance

Do not build a complicated device database. Use generous top and bottom margins and test on real hardware.

### Acceptance Criteria

- No HUD element is cut off at supported portrait ratios.
- Six-digit scores fit.
- The game remains playable when the device has a tall screen.
- Tapping on the menu panel starts or restarts the game.

---

## Step 9 — Audio and Haptics Contract

### Objective

Keep feedback reliable and non-blocking.

### Existing Feedback Events

- Start
- Lane switch
- Pickup collect
- Crash

### Rules

- Audio generation should happen once at startup, not every time a sound is played.
- Missing audio capability must not stop gameplay.
- Haptics should only run on mobile-capable platforms.
- Haptics should remain brief and proportional:
  - Switch: subtle
  - Collect: slightly stronger
  - Crash: strongest

### Acceptance Criteria

- Rapid lane switches do not allocate new audio streams.
- Audio players are reused.
- Desktop testing does not emit haptic-related errors.
- Muted device audio does not affect game logic.

---

## Step 10 — Debug and Validation Support

### Objective

Make future balancing and bug reports easier.

### Add Development-Only Debug Information

A lightweight debug overlay may show:

- Current game state
- Current speed
- Spawn interval
- Elapsed run time
- Current lane
- Active obstacle count
- Active pickup count

The overlay should be disabled by default and toggled with a development key such as `F3`.

Do not show it in release exports unless a debug build is used.

### Optional Deterministic Seed

Add a development-only way to use a fixed RNG seed. This allows a pattern bug to be reproduced.

Example:

```gdscript
const DEBUG_FIXED_SEED := -1
```

When set to a non-negative number, the same wave sequence should repeat.

### Acceptance Criteria

- Debug UI is hidden by default.
- Debug UI does not intercept touch input.
- A fixed seed reproduces the same early wave sequence.

---

## Step 11 — Android Foundation Check

### Objective

Confirm the project can move to Android without gameplay rewrites.

### Tasks

1. Install the Godot Android export templates.
2. Configure OpenJDK 17 and the Android SDK.
3. Create a development Android export preset.
4. Use a temporary package identifier such as:

```text
com.elijah.neonswitch
```

5. Enable vibration permission only if required by the export settings.
6. Export a debug APK.
7. Install it on at least one physical Android device.
8. Test:
   - Orientation
   - Touch input
   - Restart flow
   - Haptics
   - Audio
   - UI margins
   - App suspend and resume

### Suspend/Resume Rule

If the application is suspended during a run, the initial foundation version may pause or continue according to Godot defaults, but the behavior must be documented and must not corrupt the run state.

### Acceptance Criteria

- Debug APK installs and launches.
- The app remains portrait-oriented.
- Touch controls work across the full screen.
- No desktop-only assumption blocks mobile play.

---

## 8. Coding Standards

The junior developer must follow these rules throughout the foundation phase.

### GDScript

- Use Godot 4.x syntax only.
- Prefer explicit types for public state and ambiguous expressions.
- Use typed arrays for shared numeric data.
- Use `snake_case` for variables and methods.
- Use `PascalCase` for `class_name` declarations.
- Use `UPPER_SNAKE_CASE` for constants.
- Keep methods focused and reasonably short.
- Add comments explaining **why**, not narrating obvious code.

### Architecture

- Do not access another script's internal variables directly when a method or signal is more appropriate.
- Do not add autoload singletons during this phase unless specifically approved.
- Do not introduce a plugin or third-party dependency.
- Do not create a generalized framework for hypothetical future games.
- Prefer simple, local solutions over abstract systems with no current use.

### Error Handling

- Check file-operation results.
- Guard against duplicate collision handling.
- Guard against invalid state transitions.
- Do not use empty `except`-style behavior or silent failure patterns.
- Print useful development errors only when action can be taken from them.

### Scope

- Do not add extra gameplay features.
- Do not redesign the art.
- Do not rebalance the game until architecture changes preserve the existing feel.
- Request clarification when a requirement conflicts with the current design.

---

## 9. Required Test Matrix

The developer must manually test all items below before considering the foundation complete.

### Startup

- [ ] Project imports without missing resources.
- [ ] Main scene launches.
- [ ] No parser errors appear.
- [ ] Ready screen displays correctly.

### Input

- [ ] Left click starts the game.
- [ ] Space starts the game.
- [ ] Enter starts the game.
- [ ] Touch starts the game on mobile.
- [ ] All supported inputs switch lanes during play.
- [ ] Key repeat does not spam lane switches.

### Core Loop

- [ ] Player begins in the expected lane.
- [ ] Player switches exactly one lane per action.
- [ ] Obstacles move correctly.
- [ ] Pickups move correctly.
- [ ] Pickup collection awards the expected score.
- [ ] Obstacle collision ends the run.
- [ ] Restart begins a clean run.

### State Safety

- [ ] Double collision does not trigger double game over.
- [ ] Repeated taps during death do not start overlapping runs.
- [ ] Ten consecutive restarts succeed.
- [ ] Old obstacles do not remain after restart.
- [ ] Old pickups do not remain after restart.

### Difficulty

- [ ] The first ten seconds are understandable to a new player.
- [ ] Speed increases over time.
- [ ] Spawn interval decreases within its configured limits.
- [ ] Every observed wave has a valid survival path.
- [ ] Follow-up patterns provide the configured minimum reaction time.

### Save Data

- [ ] Best score saves after a new record.
- [ ] Best score loads after relaunch.
- [ ] Missing save file defaults to zero.
- [ ] Invalid save value does not crash the game.

### Presentation

- [ ] Score updates correctly.
- [ ] Shard count updates correctly.
- [ ] Best score updates correctly.
- [ ] Ready panel appears only in READY.
- [ ] Game-over panel appears only in GAME_OVER.
- [ ] Collection flash works.
- [ ] Crash flash works.
- [ ] Screen shake resets after a crash.

### Mobile

- [ ] Android build launches in portrait.
- [ ] Full-screen tapping works.
- [ ] Haptics do not cause errors.
- [ ] UI is not hidden by display cutouts.
- [ ] App can suspend and resume without corrupting save data.

---

## 10. Deliverables

The foundation phase is complete only when the junior developer provides:

1. Updated project files.
2. `game_balance.gd`.
3. `wave_director.gd`.
4. `save_service.gd`.
5. Reorganized scripts, if the reorganization is performed.
6. A brief testing report.
7. A list of any known issues intentionally deferred.
8. An Android debug APK test result, when the export environment is available.
9. Updated README architecture notes.

---

## 11. Definition of Done

The foundation is done when all of the following are true:

- The project launches cleanly in the target Godot version.
- The ready, playing, and game-over states transition reliably.
- Input is unified across touch, mouse, Space, and Enter.
- Gameplay values are centralized.
- Spawn patterns are generated by a dedicated director.
- Pattern fairness is enforced by timing calculations.
- Save handling is isolated and resilient.
- Entity responsibilities are clear.
- The HUD remains usable across common portrait aspect ratios.
- Ten consecutive runs can be started, ended, and restarted without errors.
- The project can be exported to and played on Android.
- No out-of-scope feature has been added.

The foundation should feel uneventful when it is finished. That is a compliment. Good foundations are quiet because everything above them gets to make the noise.

---

## 12. Recommended Commit Sequence

The junior developer should use small commits in this order:

### Commit 1

```text
fix: establish clean runtime baseline
```

Resolve parser and blocking runtime errors only.

### Commit 2

```text
refactor: centralize gameplay balance constants
```

Add `game_balance.gd` and replace duplicated tuning values.

### Commit 3

```text
refactor: formalize game state transitions
```

Create explicit state-entry methods and guard transitions.

### Commit 4

```text
refactor: extract wave generation and fairness rules
```

Add `wave_director.gd` and move pattern selection out of `main.gd`.

### Commit 5

```text
refactor: isolate save data handling
```

Add `save_service.gd` and remove save-file ownership from `main.gd`.

### Commit 6

```text
refactor: organize gameplay and presentation scripts
```

Move files into the agreed folder structure and repair scene paths.

### Commit 7

```text
feat: add development debug overlay
```

Add state and difficulty diagnostics, hidden by default.

### Commit 8

```text
test: complete mobile foundation validation
```

Document desktop and Android validation results.

Do not squash all work into one giant commit. A readable history is a map back out of the cave.

---

## 13. Pull Request Template for This Phase

Use the following format in the foundation pull request:

```markdown
## Summary

Briefly explain the foundation work completed.

## Architectural Changes

- Added:
- Moved:
- Removed:
- Preserved:

## Gameplay Behavior

Describe whether gameplay feel or balance changed.

## Validation

- Godot version:
- Desktop tested:
- Android tested:
- Restart stress test:
- Save persistence tested:
- Debugger errors:

## Known Issues

List deferred issues, or write `None known`.

## Out-of-Scope Confirmation

Confirm that no shop, cosmetics, ads, achievements, or unrelated features were added.
```

---

## 14. Final Instruction to the Junior Developer

Work in order. Keep the game playable after every commit. Do not begin the next step while the current step still produces errors.

When uncertain, choose the smallest implementation that satisfies the documented contract.

Neon Switch does not need an empire of systems. It needs a clean pulse, a fair challenge, and code sturdy enough to survive whatever we build above it.
