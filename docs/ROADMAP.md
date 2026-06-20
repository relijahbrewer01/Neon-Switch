# Neon Switch — Living Development Roadmap

This document is the project’s living checklist. Update it whenever a milestone is completed, split, deferred, or expanded.

## Status Legend

- [x] Complete
- [ ] Planned or not yet complete
- **In progress** — active branch or current development focus
- **Deferred** — intentionally postponed, not forgotten

## Current Focus

**Foundation Phase — Step 10: Add Development Diagnostics**

The audio and haptic feedback milestone is complete and documented in [`FEEDBACK_CONTRACT_REPORT.md`](FEEDBACK_CONTRACT_REPORT.md). The next implementation branch should add a toggleable runtime diagnostic overlay, deterministic testing controls, and cleanup visibility for development builds.

Every playable update must increment the build version according to [`VERSIONING.md`](VERSIONING.md).

---

## Phase 0 — Prototype and Project Setup

- [x] Define the two-lane, one-touch arcade concept.
- [x] Build a playable Godot prototype.
- [x] Add touch, mouse, Space, and Enter controls.
- [x] Add obstacles, pickups, scoring, and persistent best score.
- [x] Add procedural visuals and generated sound effects.
- [x] Create the GitHub repository.
- [x] Add README, license, and `.gitignore`.
- [x] Write the detailed foundation plan and junior-developer brief.

**Exit condition:** The prototype exists in source control and has a documented path toward a stable MVP.

---

## Phase 1 — Stable Game Foundation

Detailed instructions live in [`FOUNDATION_PLAN.md`](FOUNDATION_PLAN.md).

### Runtime and Architecture

- [x] **Step 1 — Establish a clean runtime baseline.**
  - [x] Add a headless Godot import-and-parse CI job.
  - [x] Add an automated baseline smoke test.
  - [x] Confirm CI passes on Godot 4.6.3.
  - [x] Confirm ready → play → collect → crash → restart loop.
  - [x] Confirm ten consecutive restart cycles.
  - [x] Confirm best-score persistence across a fresh scene instance.
  - [x] Record the finalized baseline report.

- [x] **Step 2 — Centralize balance values.**
  - [x] Add `scripts/config/game_balance.gd`.
  - [x] Move lane positions, player position, speeds, spawn timing, score values, and reaction timing into named constants.
  - [x] Preserve existing gameplay feel during the refactor.
  - [x] Add a canonical development version in `project.godot`.
  - [x] Display the canonical version as a tiny top-left debug label.
  - [x] Record the finalized balance-centralization report.

- [x] **Step 3 — Formalize game-state transitions.**
  - [x] Add explicit ready, playing, and game-over entry methods.
  - [x] Route input through a single primary-action handler.
  - [x] Guard against duplicate collision and restart events.
  - [x] Protect delayed game-over UI from stale callbacks.
  - [x] Add mandatory version-bump policy and CI guard.
  - [x] Record the finalized state-transition report.

- [x] **Step 4 — Extract wave generation.**
  - [x] Add `scripts/game/wave_director.gd`.
  - [x] Define introductory, rhythm, and pressure pattern tiers.
  - [x] Enforce a mathematical minimum reaction window.
  - [x] Guarantee at least one valid survival route per wave.
  - [x] Preserve the established random-call order.
  - [x] Add generated-wave stress validation.
  - [x] Record the wave-director report.

- [x] **Step 5 — Clarify entity contracts.**
  - [x] Confirm player ownership and signals.
  - [x] Confirm obstacle movement and cleanup responsibilities.
  - [x] Confirm pickup movement, collection, and cleanup responsibilities.
  - [x] Verify signal connections do not duplicate across restarts.
  - [x] Replace direct entity-field access with public methods.
  - [x] Add idempotent entity cleanup and collection tests.
  - [x] Record the entity-contract report.

- [x] **Step 6 — Isolate save handling.**
  - [x] Add `scripts/game/save_service.gd`.
  - [x] Handle missing and malformed save data safely.
  - [x] Reject wrong-type and negative stored score values.
  - [x] Save only when a new best score is achieved.
  - [x] Keep disk failures separate from in-memory gameplay state.
  - [x] Add dedicated persistence smoke tests.
  - [x] Record the save-service report.

- [x] **Step 7 — Unify input behavior.**
  - [x] Add `scripts/input/primary_input.gd`.
  - [x] Route touch, mouse, Space, Enter, and keypad Enter through one action path.
  - [x] Ignore release, repeat, unrelated-key, secondary-button, and secondary-touch events.
  - [x] Move gameplay handling to `_unhandled_input()`.
  - [x] Ensure every decorative HUD control passes pointer input through.
  - [x] Add dedicated Viewport and input-filter smoke tests.
  - [x] Record the input-contract report.

### Presentation and Platform Readiness

- [x] **Step 8 — Complete the portrait UI and safe-area pass.**
  - [x] Add `scripts/ui/portrait_layout.gd`.
  - [x] Enable expanded portrait aspect scaling.
  - [x] Map physical mobile safe areas into logical viewport coordinates.
  - [x] Test 9:16, 9:19.5, and 9:20 layouts.
  - [x] Verify six-digit score, best, and shard values fit.
  - [x] Keep ready, game-over, and version UI inside simulated cutout-safe areas.
  - [x] Extend the procedural background across tall logical viewports.
  - [x] Add dedicated portrait-layout smoke tests.
  - [x] Record the portrait UI report.

- [x] **Step 9 — Finalize audio and haptic contracts.**
  - [x] Add `scripts/feedback/feedback_service.gd`.
  - [x] Generate four reusable audio streams and players at startup.
  - [x] Route start, switch, collect, and crash feedback through semantic methods.
  - [x] Move platform vibration ownership out of gameplay entities.
  - [x] Guard desktop and headless execution from vibration calls.
  - [x] Separate feedback randomness from gameplay RNG.
  - [x] Add dedicated feedback reuse and integration tests.
  - [x] Record the audio and haptic feedback report.

- [ ] **Step 10 — Add development diagnostics.** **Next**
  - [ ] Add an F3 debug overlay.
  - [ ] Display game state, speed, spawn interval, elapsed time, lane, and active entity counts.
  - [ ] Add an optional deterministic RNG seed.
  - [ ] Investigate and eliminate the baseline test-process ObjectDB teardown warning.

- [ ] **Step 11 — Complete Android foundation validation.**
  - [ ] Create an Android debug export preset.
  - [ ] Export and install a debug APK.
  - [ ] Test orientation, touch, haptics, audio, suspend/resume, and UI margins on physical hardware.
  - [ ] Verify camera cutouts and gesture-navigation safe areas on real devices.

**Phase 1 exit condition:** The core loop is stable, fair, testable, and Android-ready without requiring architectural rewrites.

---

## Phase 2 — Core Gameplay Polish

Do not begin this phase until Phase 1 is complete.

- [ ] Tune the first 30 seconds for clarity and onboarding.
- [ ] Tune long-run speed and spawn curves.
- [ ] Expand fair obstacle patterns without adding new controls.
- [ ] Improve collision readability and death feedback.
- [ ] Add subtle score milestones and escalating visual intensity.
- [ ] Add a pause/resume policy for mobile interruption.
- [ ] Add audio settings and haptic settings.
- [ ] Perform accessibility review for contrast, flashing, motion, and input comfort.
- [ ] Conduct external playtests and record player failure points.

**Phase 2 exit condition:** The game feels deliberate rather than merely functional, and new players understand failures without explanation.

---

## Phase 3 — Replayability and Progression

Scope this phase only after playtesting proves the core loop is worth extending.

- [ ] Decide whether shards become persistent currency or remain run-only score objects.
- [ ] Design a lightweight cosmetic unlock system.
- [ ] Add player-orb color or trail variants.
- [ ] Add missions or achievement-style goals.
- [ ] Evaluate daily challenge mode.
- [ ] Evaluate local and online leaderboards.
- [ ] Add basic player statistics.
- [ ] Add a first-run tutorial that preserves one-touch simplicity.

**Phase 3 exit condition:** Players have meaningful reasons to return without the progression systems overwhelming the arcade loop.

---

## Phase 4 — Release Preparation

- [ ] Select the final package identifier and application name.
- [ ] Create release signing keys and store them securely.
- [ ] Produce Android App Bundle builds.
- [ ] Prepare Google Play store listing, icon, screenshots, description, and privacy information.
- [ ] Decide on monetization: premium, ads, cosmetic purchase, or fully free.
- [ ] Add privacy policy and terms where required.
- [ ] Test on multiple low-, mid-, and high-range Android devices.
- [ ] Run closed testing.
- [ ] Fix release-blocking defects.
- [ ] Publish version 1.0.

### Later Platform Work

- [ ] Export and validate a web build.
- [ ] Prepare Linux and Windows desktop releases if useful.
- [ ] Prepare iOS export when macOS/Xcode access is available.

**Phase 4 exit condition:** A signed, tested version is publicly available and the repository matches the released source state.

---

## Phase 5 — Post-Launch

- [ ] Monitor crash reports and player feedback.
- [ ] Publish urgent stability fixes.
- [ ] Review retention and difficulty data only after privacy-safe analytics are intentionally designed.
- [ ] Add content updates only when they strengthen the one-touch core.
- [ ] Maintain changelog and semantic version tags.

---

## Idea Inbox

Ideas may be added here without becoming commitments.

- Alternate visual themes
- Seasonal color palettes
- Near-miss scoring
- Combo-based shard collection
- Daily seeded runs
- Ghost replay of the player’s best attempt
- Cosmetic trail editor
- Challenge modifiers
- Reduced-motion mode
- Colorblind palettes

When an idea is approved, move it into the appropriate phase with acceptance criteria. Until then, it lives here and behaves itself.

---

## Roadmap Update Rule

Whenever work is merged:

1. Check off completed items.
2. Add newly discovered work under the correct phase.
3. Record intentionally deferred work instead of silently dropping it.
4. Update **Current Focus** and identify exactly one next step.
5. Increment the build version for every playable game update.
6. Keep finished items visible so the roadmap remains a history as well as a forecast.
