extends RefCounted
class_name PrimaryInput

## Normalizes every supported one-touch input into one primary-action press.
##
## Only initial presses are accepted. Releases, key-repeat echoes, secondary
## mouse buttons, unrelated keys, and secondary touch points are rejected.

enum Source {
    NONE,
    TOUCH,
    MOUSE,
    KEYBOARD,
}

static func source_for(event: InputEvent) -> int:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and touch.index == 0:
            return Source.TOUCH
        return Source.NONE

    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
            return Source.MOUSE
        return Source.NONE

    if event is InputEventKey:
        var key := event as InputEventKey
        if not key.pressed or key.echo:
            return Source.NONE
        if key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
            return Source.KEYBOARD
        return Source.NONE

    return Source.NONE

static func is_primary_press(event: InputEvent) -> bool:
    return source_for(event) != Source.NONE

static func source_name(source: int) -> String:
    match source:
        Source.TOUCH:
            return "touch"
        Source.MOUSE:
            return "mouse"
        Source.KEYBOARD:
            return "keyboard"
        _:
            return "none"
