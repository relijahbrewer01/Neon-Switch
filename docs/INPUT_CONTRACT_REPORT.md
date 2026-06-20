# Neon Switch — Input Contract Report

## Status

**Foundation Step 7 is complete and validated.**

The playable build version is:

```text
0.1.0-dev.7
```

## Objective

All supported controls now pass through one normalization layer before reaching gameplay:

```text
scripts/input/primary_input.gd
```

`main.gd` no longer interprets raw device events itself. It receives only accepted primary-action presses through `_unhandled_input()` and forwards them to the existing state-aware action handler.

## Accepted Inputs

The normalized action accepts:

- Primary touch index `0` on press
- Left mouse button on press
- Space on initial press
- Enter on initial press
- Keypad Enter on initial press

## Rejected Inputs

The contract rejects:

- Touch releases
- Secondary touch points
- Mouse releases
- Right and other mouse buttons
- Keyboard releases
- Keyboard echo/repeat events
- Unrelated keys

Rejected events do not change state, switch lanes, or replace the last accepted input-source diagnostic.

## Delivery Path

The runtime path is:

```text
Viewport input dispatch
    → Control GUI filtering
    → Main._unhandled_input()
    → PrimaryInput.source_for()
    → Main._handle_primary_action()
```

Using `_unhandled_input()` allows future interactive UI controls to consume intentional clicks. Decorative UI must therefore remain transparent to pointer input.

## HUD Pass-Through Contract

`NeonHUD` recursively applies these settings to every generated `Control`:

```gdscript
mouse_filter = Control.MOUSE_FILTER_IGNORE
focus_mode = Control.FOCUS_NONE
```

This includes labels, panels, margins, containers, overlays, score displays, and the version label.

The HUD exposes `is_input_passthrough()` for automated verification. A future button or menu control must explicitly opt into interaction rather than accidentally inheriting it.

## Input Source Diagnostics

`main.gd` stores the most recent accepted normalized source:

```gdscript
last_primary_input_source
```

Possible values come from `PrimaryInput.Source`:

```text
NONE
TOUCH
MOUSE
KEYBOARD
```

This is lightweight diagnostic state and does not affect gameplay decisions.

## Automated Validation

A dedicated suite now runs at:

```text
tests/input_contract_smoke_test.gd
```

It verifies:

- Classification of every accepted input form
- Rejection of releases, repeats, secondary buttons, secondary touches, and unrelated keys
- Stable debug names for normalized sources
- Recursive HUD pointer and focus pass-through
- A real left-click pushed through the Viewport at the visible ready panel
- Ready-to-playing transition through that click
- No action from a batch of rejected events
- Touch lane switching
- Space lane switching
- Enter lane switching
- Keypad Enter lane switching
- Correct normalized source tracking

The existing gameplay baseline was also updated to call `_unhandled_input()` rather than the removed raw `_input()` path.

## Result

Godot 4.6.3 validation completed successfully in workflow run **#104**. The Version Guard completed successfully in run **#12**.

```text
Project import and parsing: PASS
PrimaryInput registration: PASS
Accepted-event classification: PASS
Rejected-event filtering: PASS
HUD pass-through: PASS
Viewport delivery through ready panel: PASS
Touch, mouse, Space, Enter, keypad Enter: PASS
Existing gameplay regression: PASS
Save-service regression: PASS
Version Guard: PASS
Godot runtime errors: NONE OBSERVED
```

## Decision

Input handling is stable enough to proceed to:

**Foundation Step 8 — Complete the Portrait UI and Safe-Area Pass**
