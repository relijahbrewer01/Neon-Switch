# Neon Switch — Audio and Haptic Feedback Report

## Status

**Foundation Step 9 is complete and validated.**

The playable build version is:

```text
0.1.0-dev.9
```

## Objective

Audio generation and mobile vibration policy have been removed from gameplay entities and centralized in:

```text
scripts/feedback/feedback_service.gd
```

The service exposes semantic feedback methods:

```gdscript
play_start() -> bool
play_switch() -> bool
play_collect() -> bool
play_crash() -> bool
```

Gameplay code now reports what happened. The feedback service decides which sound, pitch, volume, and vibration duration represent that event.

## Resource Lifetime

At startup, `NeonFeedback` creates exactly:

```text
4 generated AudioStreamWAV resources
4 persistent AudioStreamPlayer nodes
```

One stream and player are assigned to each event:

- Start
- Switch
- Collect
- Crash

Repeated playback reuses those same object instances. Gameplay-time calls do not regenerate sample buffers or add audio nodes to the scene tree.

## Generated Audio

The existing prototype sound character is preserved:

- Start: rising tone
- Switch: short falling tone
- Collect: bright falling tone with slight pitch variation
- Crash: decaying noise burst

Audio remains generated from GDScript and requires no external media files.

## Randomness Isolation

The old implementation used the game controller's random-number generator for collect pitch and crash-noise construction. That meant presentation could alter later wave-selection randomness.

`NeonFeedback` now owns two deterministic generators:

```text
pitch RNG
noise RNG
```

Audio variation can no longer consume or reorder gameplay RNG calls.

## Haptic Policy

Haptic durations remain equivalent to the prototype:

```text
Switch:  18 ms
Collect: 28 ms
Crash:   170 ms
```

Start feedback is audio-only.

Only `NeonFeedback` may call `Input.vibrate_handheld()`. The player and main controller no longer invoke the platform API directly.

The service evaluates mobile support once during initialization. On desktop and headless builds, haptic requests return safely without calling the vibration API.

## Ownership Changes

### Main Controller

`main.gd` owns one `NeonFeedback` child and calls semantic methods after successful game events.

### Player

`player.gd` continues to own lane state, collision sensing, and player animation. It no longer owns device vibration.

This prevents one entity from silently coupling movement code to a specific platform feature.

## Automated Validation

A dedicated suite now runs at:

```text
tests/feedback_contract_smoke_test.gd
```

It validates:

- Exactly four generated streams
- Exactly four persistent audio players
- Forty repeated plays of every feedback event
- Stable stream instance IDs across repeated playback
- Stable player instance IDs across repeated playback
- No additional audio nodes during play
- Collect pitch remains within the configured range
- Switch, collect, and crash request haptics
- Desktop/headless execution emits no platform vibration
- Main owns an initialized feedback service
- Start, switch, collect, and crash events route correctly
- Duplicate crash reporting cannot replay crash feedback
- Feedback randomness does not consume gameplay RNG

The general integration baseline was also shortened so specialized suites own their respective detailed contracts while the baseline remains focused on the complete ready-to-restart loop.

## Result

```text
Godot version: 4.6.3 stable
Project import and parsing: PASS
Core integration baseline: PASS
Save-service suite: PASS
Input-contract suite: PASS
Portrait-layout suite: PASS
Feedback-contract suite: PASS
Version Guard: PASS
Desktop haptic errors: NONE OBSERVED
Gameplay RNG interference: NONE OBSERVED
```

## Remaining Physical Validation

Headless CI proves that desktop execution is guarded and error-free, but it cannot judge whether vibration feels pleasant on a real phone.

Foundation Step 11 still owns:

- Physical Android vibration testing
- Device-specific vibration strength review
- Audio playback through phone speakers
- Suspend/resume behavior during active audio

## Decision

The feedback contract is stable enough to proceed to:

**Foundation Step 10 — Add Development Diagnostics**
