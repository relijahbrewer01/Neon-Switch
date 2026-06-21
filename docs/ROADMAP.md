# Neon Switch — Living Development Roadmap

This is the project’s living checklist. Update it whenever work is completed, split, deferred, or expanded.

## Status Legend

- [x] Complete
- [ ] Planned
- **Next** — current development focus

## Current Focus

**Foundation Step 11 — Physical Android Device Validation**

The Android export foundation is now operational: the debug preset is committed, the setup and test instructions are documented, and GitHub Actions successfully produces an installable debug APK. The remaining work requires a real Android phone to verify touch feel, haptics, audio, cutouts, lifecycle behavior, and persistence.

Every playable update must increment the build version according to [`VERSIONING.md`](VERSIONING.md).

---

## Phase 0 — Prototype and Setup

- [x] Define the two-lane one-touch arcade concept.
- [x] Build a playable Godot prototype.
- [x] Add touch, mouse, Space, and Enter controls.
- [x] Add obstacles, pickups, scoring, and best-score persistence.
- [x] Add procedural visuals and generated sound effects.
- [x] Create the GitHub repository, README, license, and `.gitignore`.
- [x] Write the foundation plan and junior-developer brief.

---

## Phase 1 — Stable Game Foundation

Detailed instructions live in [`FOUNDATION_PLAN.md`](FOUNDATION_PLAN.md).

### Runtime and Architecture

- [x] **Step 1 — Runtime baseline**
  - [x] Headless import-and-parse CI.
  - [x] Core-loop smoke test.
  - [x] Ten restart cycles.
  - [x] Fresh-scene save persistence.

- [x] **Step 2 — Centralized balance**
  - [x] Add `game_balance.gd`.
  - [x] Centralize positions, timing, speed, scoring, and reaction values.
  - [x] Add the canonical build version and top-left version label.

- [x] **Step 3 — State transitions**
  - [x] Explicit ready, playing, and game-over entry methods.
  - [x] Duplicate collision and restart guards.
  - [x] Stale game-over UI protection.
  - [x] Mandatory version-bump CI.

- [x] **Step 4 — Wave generation**
  - [x] Add `wave_director.gd`.
  - [x] Introduction, rhythm, and pressure tiers.
  - [x] Mathematical reaction-window validation.
  - [x] Guaranteed survival route.

- [x] **Step 5 — Entity contracts**
  - [x] Narrow public player, obstacle, and pickup APIs.
  - [x] Idempotent cleanup and collection.
  - [x] Stable signal connections across restarts.

- [x] **Step 6 — Save service**
  - [x] Add `save_service.gd`.
  - [x] Handle missing, malformed, wrong-type, and negative values.
  - [x] Write only new best scores.
  - [x] Keep disk failures separate from gameplay state.

- [x] **Step 7 — Unified input**
  - [x] Add `primary_input.gd`.
  - [x] Route touch, mouse, Space, Enter, and keypad Enter through one path.
  - [x] Reject releases, repeats, secondary inputs, and unrelated keys.
  - [x] Keep decorative UI pointer-transparent.

### Presentation and Platform Readiness

- [x] **Step 8 — Portrait UI and safe areas**
  - [x] Add `portrait_layout.gd`.
  - [x] Support 9:16, 9:19.5, and 9:20.
  - [x] Fit six-digit score, best, and shard values.
  - [x] Keep panels and version text inside simulated cutout-safe areas.
  - [x] Extend the procedural background across tall screens.

- [x] **Step 9 — Audio and haptic contracts**
  - [x] Add `feedback_service.gd`.
  - [x] Reuse generated streams and players.
  - [x] Centralize start, switch, collect, and crash feedback.
  - [x] Separate feedback RNG from gameplay RNG.
  - [x] Guard desktop and headless haptic execution.

- [x] **Step 10 — Development diagnostics**
  - [x] Add `debug_overlay.gd` and an F3 toggle.
  - [x] Display state, seed, speed, spawn interval, elapsed time, lane, input source, and entity counts.
  - [x] Keep the panel inside the active safe area.
  - [x] Add project-setting and command-line deterministic seeds.
  - [x] Reset deterministic RNG at each run start.
  - [x] Replace temporary game-over timers with one owned cancellable timer.
  - [x] Eliminate headless audio playback leaks.
  - [x] Fail CI when Godot reports ObjectDB teardown leaks.

- [ ] **Step 11 — Android foundation validation** **Next**
  - [x] Change desktop portrait scaling to `keep_width` so the playfield stays centered on wide screens.
  - [x] Request a centered initial standalone desktop window position.
  - [x] Commit a secret-free Android debug export preset.
  - [x] Enable Android ETC2/ASTC texture imports.
  - [x] Document JDK, Android SDK, export-template, installation, and log-capture setup.
  - [x] Add a reproducible Android debug-build workflow.
  - [x] Export an arm64 debug APK successfully in CI.
  - [x] Record and verify the APK SHA-256 checksum.
  - [x] Add a reusable physical-device test report.
  - [ ] Install and launch the APK on physical Android hardware.
  - [ ] Test portrait orientation and touch response.
  - [ ] Test switch, collect, and crash haptics by feel.
  - [ ] Test generated audio through speakers and headphones.
  - [ ] Test suspend, resume, app switching, and screen locking.
  - [ ] Verify status-bar, camera-cutout, and gesture-navigation safe areas.
  - [ ] Verify best-score persistence after closing and reopening the app.
  - [ ] Record device model, Android version, results, and remaining defects.

**Phase 1 exit condition:** The core loop is stable, fair, testable, and validated on Android hardware.

---

## Phase 2 — Core Gameplay Polish

- [ ] Tune onboarding and the first 30 seconds.
- [ ] Tune long-run speed and spawn curves.
- [ ] Expand fair patterns without adding controls.
- [ ] Improve collision readability and death feedback.
- [ ] Add score milestones and escalating visual intensity.
- [ ] Define pause and interruption behavior.
- [ ] Add audio and haptic settings.
- [ ] Review accessibility for contrast, flashing, motion, and input comfort.
- [ ] Conduct external playtests.

---

## Phase 3 — Replayability and Progression

- [ ] Decide whether shards become persistent currency.
- [ ] Design lightweight cosmetic unlocks.
- [ ] Add orb colors or trail variants.
- [ ] Add missions or achievements.
- [ ] Evaluate daily seeded runs and leaderboards.
- [ ] Add player statistics.
- [ ] Add a minimal first-run tutorial.

---

## Phase 4 — Release Preparation

- [ ] Select the final package identifier.
- [ ] Create and secure release signing keys.
- [ ] Produce Android App Bundles.
- [ ] Prepare store assets and privacy information.
- [ ] Decide on monetization.
- [ ] Test on several Android device classes.
- [ ] Run closed testing and fix release blockers.
- [ ] Publish version 1.0.

### Later Platforms

- [ ] Web export.
- [ ] Windows and Linux releases.
- [ ] iOS export when macOS/Xcode access is available.

---

## Phase 5 — Post-Launch

- [ ] Monitor crashes and feedback.
- [ ] Publish stability fixes.
- [ ] Review privacy-safe retention data if analytics are added.
- [ ] Add only updates that strengthen the one-touch core.
- [ ] Maintain changelog and semantic version tags.

---

## Idea Inbox

- Alternate visual themes
- Seasonal palettes
- Near-miss scoring
- Shard combos
- Daily seeded runs
- Ghost replays
- Cosmetic trail editor
- Challenge modifiers
- Reduced-motion mode
- Colorblind palettes
