# Neon Switch — Entity Contracts Report

## Status

**Foundation Step 5 is complete and validated.**

The playable build version is:

```text
0.1.0-dev.5
```

## Objective

The player, obstacles, and pickups now have explicit ownership boundaries and narrow public APIs.

The governing rule is:

> Main coordinates the run; entities own their own state and lifecycle.

## Player Contract

`NeonPlayer` owns:

- Current lane
- Active/inactive state
- Lane-switch animation
- Pickup feedback animation
- Crash animation
- Collision sensing
- Switch haptics
- Contact reporting through typed signals

Public API:

```gdscript
reset_for_run() -> void
activate() -> bool
is_active() -> bool
current_lane() -> int
switch_lane() -> bool
crash() -> bool
celebrate_pickup() -> bool
```

Player-owned tweens are killed during reset so animation from a previous run cannot leak into the next one.

## Obstacle Contract

`NeonObstacle` owns:

- Movement speed
- Downward movement
- Procedural tint and spin
- Offscreen retirement
- Collision shutdown
- Final cleanup

Public API:

```gdscript
configure(move_speed: float) -> bool
movement_speed() -> float
is_despawned() -> bool
despawn() -> bool
```

Calling `despawn()` more than once is safe. The first call performs shutdown; later calls return `false` and do nothing.

## Pickup Contract

`EnergyPickup` owns:

- Movement speed
- Downward movement
- One-time collection state
- Collection animation
- Offscreen retirement
- Collision shutdown
- Final cleanup

Public API:

```gdscript
configure(move_speed: float) -> bool
movement_speed() -> float
is_collected() -> bool
is_despawned() -> bool
collect() -> bool
despawn() -> bool
```

`collect()` returns `true` exactly once. `main.gd` awards shards and score only after a successful return, preventing duplicate overlap events from duplicating rewards.

## Main Controller Changes

`main.gd` now:

- Connects player signals through `_connect_player_signals()`.
- Checks whether each signal is already connected.
- Calls `configure()` instead of assigning entity speed fields.
- Awards pickup rewards only when `collect()` succeeds.
- Calls entity `despawn()` methods during run cleanup.
- Plays the switch sound only when `player.switch_lane()` succeeds.

Main still owns game state, score, HUD coordination, audio coordination, scene instantiation, and—until Step 6—save handling.

## Signal Safety

The player-to-main connections are:

```text
hit_obstacle     → _on_player_hit
collected_pickup → _on_player_collect
```

Repeated setup calls do not add subscribers. Connection counts remain stable across ten restart cycles.

## Cleanup Contract

Obstacles and pickups perform their own shutdown sequence:

1. Mark themselves despawned.
2. Stop processing.
3. Hide immediately.
4. Disable collision participation.
5. Queue themselves for deletion.

Offscreen retirement and run-reset cleanup use the same `despawn()` path. The persistent player is never removed from the World node.

## Validation

The Godot 4.6.3 baseline workflow passed after integration. Tests cover:

- Player inactive/active state through public methods
- Player lane state through `current_lane()`
- Exactly one main-game subscriber per player signal
- Duplicate signal-setup protection
- Stable signal counts across ten restarts
- Obstacle and pickup speed configuration
- Main-owned orchestration through public entity methods
- Obstacle idempotent cleanup
- Pickup idempotent collection and cleanup
- Automatic offscreen retirement
- Duplicate pickup reward prevention
- Entity-owned run cleanup leaving only the persistent player
- Existing wave, state, save, collision, and restart regressions

## Result

```text
Project import and parsing: PASS
Player contract: PASS
Obstacle contract: PASS
Pickup contract: PASS
Signal stability: PASS
Duplicate reward protection: PASS
Idempotent cleanup: PASS
Offscreen retirement: PASS
Ten restart cycles: PASS
Version Guard: PASS
Godot runtime errors: NONE OBSERVED
```

## Decision

Entity ownership is stable enough to proceed to:

**Foundation Step 6 — Isolate Save Handling**

That step will move persistence out of `main.gd`, safely handle missing or malformed data, and keep save failures from affecting the gameplay loop.
