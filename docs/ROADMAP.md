# Neon Switch — Living Development Roadmap

This document is the project’s living checklist. Update it whenever a milestone is completed, split, deferred, or expanded.

## Status Legend

- [x] Complete
- [ ] Planned or not yet complete
- **In progress** — active branch or current development focus
- **Deferred** — intentionally postponed, not forgotten

## Current Focus

**Foundation Phase — Step 3: Formalize Game-State Transitions**

The balance-centralization milestone is complete and documented in [`BALANCE_REPORT.md`](BALANCE_REPORT.md). The next implementation branch should make state changes explicit, route primary input through one action handler, and guard transitions against overlap.

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

- [ ] **Step 3 — Formalize game-state transitions.** **Next**
  - [ ] Add explicit ready, playing, and game-over entry methods.
  - [ ] Route input through a single primary-action handler.
  - [ ] Guard against duplicate collision and restart events.

- [ ] **Step 4 — Extract wave generation.**
  - [ ] Add `scripts/game/wave_director.gd`.
  - [ ] Define introductory, rhythm, and pressure pattern tiers.
  - [ ] Enforce a mathematical minimum reaction window.
  - [ ] Guarantee at least one valid survival route per wave.

- [ ] **Step 5 — Clarify entity contracts.**
  - [ ] Confirm player ownership and signals.
  - [ ] Confirm obstacle movement and cleanup responsibilities.
  - [ ] Confirm pickup movement, collection, and cleanup responsibilities.
  - [ ] Verify signal connections do not duplicate across restarts.

- [ ] **Step 6 — Isolate save handling.**
  - [ ] Add `scripts/game/save_service.gd`.
  - [ ] Handle missing and malformed save data safely.
  - [ ] Save only when a new best score is achieved.

- [ ] **Step 7 — Unify input behavior.**
  - [ ] Verify touch, mouse, Space, and Enter use the same action path.
  - [ ] Ignore repeat and release events.
  - [ ] Ensure decorative UI never consumes gameplay taps.

### Presentation and Platform Readiness

- [ ] **Step 8 — Complete the portrait UI and safe-area pass.**
  - [ ] Test 9:16, 9:19.5, and 9:20 layouts.
  - [ ] Verify six-digit scores fit.
  - [ ] Verify panels remain visible on tall screens and cutout devices.

- [ ] **Step 9 — Finalize audio and haptic contracts.**
  - [ ] Reuse generated audio streams without allocations during play.
  - [ ] Verify switch, collect, start, and crash feedback.
  - [ ] Confirm desktop execution produces no haptic errors.

- [ ] **Step 10 — Add development diagnostics.**
  - [ ] Add an F3 debug overlay.
  - [ ] Display game state, speed, spawn interval, elapsed time, lane, and active entity counts.
  - [ ] Add an optional deterministic RNG seed.

- [ ] **Step 11 — Complete Android foundation validation.**
  - [ ] Create an Android debug export preset.
  - [ ] Export and install a debug APK.
  - [ ] Test orientation, touch, haptics, audio, suspend/resume, and UI margins on physical hardware.

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
5. Keep finished items visible so the roadmap remains a history as well as a forecast.
