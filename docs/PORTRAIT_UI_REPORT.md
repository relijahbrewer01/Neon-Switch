# Neon Switch — Portrait UI and Safe-Area Report

## Status

**Foundation Step 8 is complete and validated.**

The playable build version is:

```text
0.1.0-dev.8
```

## Objective

The interface now adapts to modern portrait displays instead of assuming that every device exposes an unobstructed 720×1280 rectangle.

This milestone adds:

- Expanded portrait aspect scaling
- Logical safe-area mapping
- Runtime HUD relayout
- Cutout-aware version-label placement
- Six-digit stat support
- Tall-viewport procedural background rendering
- Deterministic layout tests for common phone proportions

## Portrait Scaling

`project.godot` now uses:

```text
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

The 720×1280 design width remains stable while taller displays receive additional logical vertical space rather than black bars or nonuniform stretching.

## Safe-Area Service

Safe-area calculations live in:

```text
scripts/ui/portrait_layout.gd
```

On Android and iOS, the service reads the physical display safe area and maps it into the logical Godot viewport.

The mapping accounts for the difference between physical display pixels and logical canvas units:

```text
logical inset = physical inset × logical viewport / physical display size
```

Invalid, empty, or unavailable display data safely falls back to the full logical viewport.

Mapped rectangles are clamped to visible viewport bounds before the HUD uses them.

## HUD Layout

`NeonHUD` now builds its interface inside two runtime rectangles:

```text
safe rectangle
    → content rectangle with presentation gutters
        → top bar, spacer, status panel, footer
```

The safe rectangle avoids display cutouts and system-obscured edges. The content rectangle adds ordinary visual breathing room without assuming fixed device insets.

The tiny build-version label is positioned relative to the safe rectangle, so it remains visible without sitting beneath a camera cutout.

The HUD automatically recalculates layout when the viewport size changes.

## Large Stat Values

The top bar was rebalanced to support:

```text
Score:  999999
Best:   999999
Shards: 999999
```

The score, shard, and best-score regions have explicit minimum widths and responsive expansion. Automated tests compare their combined minimum width against the available safe content width.

## Background Coverage

`NeonBackground` no longer draws only to the original design height.

It now:

- Reads the active logical viewport size
- Redraws after viewport-size changes
- Uses normalized star positions
- Extends horizon bands and the central divider across tall displays
- Exposes deterministic canvas sizing for automated tests

This prevents the lower portion of 19.5:9 and 20:9 screens from becoming an empty unrendered strip.

## Validated Layouts

The dedicated portrait suite validates:

### 9:16

```text
Logical viewport: 720×1280
Safe area: full viewport
```

### 9:19.5

```text
Logical viewport: 720×1560
Simulated safe area: 60 units from top and bottom
```

### 9:20

```text
Logical viewport: 720×1600
Simulated safe area:
- 18 units left and right
- 80 units top and bottom
```

For each case, tests confirm:

- Safe rectangle preservation
- Content containment
- Ready panel containment
- Game-over panel containment
- Version-label containment
- Six-digit stat fit
- Full-height background coverage
- Continued HUD input pass-through

## Automated Validation

The Godot workflow now runs:

```text
tests/portrait_layout_smoke_test.gd
```

alongside the gameplay, save-service, and input-contract suites.

Final pull-request validation:

```text
Godot version: 4.6.3 stable
Project import and parsing: PASS
Gameplay baseline: PASS
Save-service regression: PASS
Input-contract regression: PASS
Portrait-layout suite: PASS
Version Guard: PASS
```

The portrait suite completed without script errors or failed assertions. The broader baseline process continues to emit its previously observed ObjectDB teardown warning after all assertions pass; this is a test-process cleanup warning rather than a portrait-layout failure.

## Remaining Physical Validation

Headless tests can validate layout mathematics and Control geometry, but they cannot reproduce every manufacturer’s status bar, gesture region, or camera shape.

The following remain assigned to Foundation Step 11:

- Physical Android cutout validation
- Gesture-navigation inset review
- Status-bar behavior
- Rotation/orientation enforcement
- Screenshot review on real 19.5:9 and 20:9 hardware

## Decision

The portrait interface is stable enough to proceed to:

**Foundation Step 9 — Finalize Audio and Haptic Contracts**
