# Neon Switch — Android Device Test Report

Use one copy of this report per physical device. Do not mark a check complete unless it was observed on hardware.

## Device Information

```text
Tester:
Date:
Game version: 0.1.0-dev.11
APK SHA-256:
Device manufacturer and model:
Android version:
Screen resolution:
Display aspect ratio:
Camera cutout type:
Navigation mode: gestures / three-button / other
Audio output tested: speaker / wired / Bluetooth
```

## Build and Installation

- [ ] CI or local debug APK exported successfully.
- [ ] APK installed without signing or package errors.
- [ ] App icon appears correctly.
- [ ] App name appears as Neon Switch.
- [ ] App launches without a crash or black screen.
- [ ] Top-left version reads `v0.1.0-dev.11`.

Notes:

```text

```

## Display and Safe Areas

- [ ] Portrait orientation is enforced.
- [ ] Playfield and two lanes are horizontally centered.
- [ ] Tall display space expands vertically rather than moving gameplay left.
- [ ] Background fills the visible portrait area.
- [ ] Score, shard, and best-score fields are fully visible.
- [ ] Ready panel is fully visible.
- [ ] Game-over panel is fully visible.
- [ ] Version label is not hidden by a cutout.
- [ ] Footer and restart prompt avoid gesture-navigation regions.
- [ ] Six-digit test values do not overlap.

Notes or screenshots:

```text

```

## Touch Input

- [ ] First tap starts the game once.
- [ ] Each later tap switches exactly one lane.
- [ ] Tap releases do not switch lanes.
- [ ] Long presses do not generate repeated switches.
- [ ] Rapid taps do not bypass state-transition guards.
- [ ] Edge taps remain responsive.
- [ ] Touch still works after app resume.

Notes:

```text

```

## Audio

- [ ] Start sound plays once.
- [ ] Switch sound plays once per successful switch.
- [ ] Collect sound plays once per pickup.
- [ ] Crash sound plays once per crash.
- [ ] Speaker output is clear.
- [ ] Headphone or Bluetooth output works.
- [ ] No duplicate or stuck sound appears after suspend/resume.

Notes:

```text

```

## Haptics

- [ ] Switch haptic is noticeable but light.
- [ ] Collect haptic is noticeable but light.
- [ ] Crash haptic is stronger than switch and collect.
- [ ] Haptics occur once per event.
- [ ] Haptics remain comfortable during repeated play.

Notes:

```text

```

## Lifecycle and Persistence

- [ ] App survives switching away and returning.
- [ ] App survives screen lock and unlock.
- [ ] App survives notification interruption.
- [ ] No impossible game state appears after resume.
- [ ] A completed best score survives closing the app.
- [ ] Best score survives reopening the app.
- [ ] Ten consecutive restart cycles complete successfully.
- [ ] Ten minutes of continuous play complete successfully.

Notes:

```text

```

## Performance

```text
Observed frame pacing:
Device temperature after ten minutes:
Battery behavior:
Visible stutter conditions:
Longest successful run:
```

## Defects

| ID | Severity | Reproduction steps | Expected | Actual | Evidence |
|---|---|---|---|---|---|
| AND-001 |  |  |  |  |  |

## Result

Choose one:

- [ ] PASS — Foundation Step 11 is validated on this device.
- [ ] PASS WITH FOLLOW-UP — Usable, with non-blocking defects recorded above.
- [ ] FAIL — A release-blocking Android defect remains.

Final notes:

```text

```
