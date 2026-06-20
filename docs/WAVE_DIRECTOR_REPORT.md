# Neon Switch — Wave Director Report

## Status

**Foundation Step 4 is complete and validated.**

This milestone was prepared as build `0.1.0-dev.4` and merged together with the Step 5 entity-contract work in build:

```text
0.1.0-dev.5
```

## Objective

Wave construction has been removed from `main.gd` and placed in:

```text
scripts/game/wave_director.gd
```

The director decides what should spawn but never instantiates scenes or touches the scene tree. `main.gd` remains responsible for converting returned definitions into gameplay entities.

## Wave Entry Contract

Each entry is a dictionary containing:

```gdscript
{
    "type": "obstacle" or "pickup",
    "lane": lane_index,
    "offset_y": vertical_offset_from_primary_spawn,
}
```

## Pattern Tiers

### Introduction

- Begins at run start.
- Contains one obstacle.
- May include a pickup in the safe lane.
- Never includes a follow-up obstacle.

### Rhythm

- Begins at `FOLLOWUP_UNLOCK_TIME`.
- May add a staggered obstacle in the opposite lane.
- Follow-up probability increases according to the existing curve.

### Pressure

- Begins at `PRESSURE_TIER_START_TIME`.
- Uses the mature follow-up probability.
- Keeps the same readable pattern grammar rather than introducing impossible geometry.

## Fairness Contract

The minimum deliberate lane-change window is:

```text
PLAYER_SWITCH_TIME + MIN_REACTION_TIME
0.115 + 0.320 = 0.435 seconds
```

Follow-up spacing is clamped to the greater of the configured spacing and this minimum response window. Vertical distance is then derived from current speed:

```gdscript
vertical_spacing = speed * safe_spacing_seconds
```

This keeps available reaction time stable as world speed increases.

## Route Validation

`WaveDirector.is_wave_fair()` groups obstacles by arrival position and tracks reachable lanes. It rejects:

- Simultaneous full-lane blocks
- Opposite-lane hazards with insufficient switch time
- Invalid lane indices
- Empty hazard definitions

Every generated wave is asserted against the same validator during development.

## Behavior Preservation

The established random-call order remains:

1. Select blocked lane.
2. Roll pickup chance.
3. Roll pickup offset only when a pickup exists.
4. Roll follow-up chance only after follow-ups unlock.

The only intentional gameplay correction is increasing unsafe follow-up spacing to the configured minimum reaction window.

## Validation

The Godot 4.6.3 baseline workflow passed after integration. Tests cover:

- Tier boundaries
- Minimum switch-window calculation
- Rejection of a deliberately impossible pattern
- Acceptance at the exact safe threshold
- 1,440 seeded generated-wave samples across three elapsed-time and three speed values
- Known entry types and valid lane indices
- One-obstacle introduction patterns
- Follow-up generation in rhythm and pressure tiers
- At least one valid survival route in every sample
- Main-loop instantiation of director entries

## Result

```text
Project import and parsing: PASS
WaveDirector registration: PASS
Tier boundaries: PASS
Impossible-pattern rejection: PASS
Safe-threshold acceptance: PASS
Generated-wave fairness: PASS
Main integration: PASS
Godot runtime errors: NONE OBSERVED
```

## Decision

Wave construction is stable and isolated. Future obstacle grammars should be added to `WaveDirector`, then validated through the same route-safety contract before reaching the scene tree.
