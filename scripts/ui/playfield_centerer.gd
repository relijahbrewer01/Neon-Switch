extends Node
class_name PlayfieldCenterer

## Applies the horizontal offset required to keep the fixed 720-wide gameplay
## column centered when stretch/aspect="expand" exposes extra desktop width.
##
## Main owns screen shake and writes World.position first. This node runs later
## in the frame, preserves that small shake value, and adds the layout offset.

@onready var world: Node2D = get_node("../World") as Node2D

var _offset_x := 0.0

func _ready() -> void:
    process_priority = 100
    _refresh_offset()

    var viewport := get_viewport()
    var resize_callable := Callable(self, "_refresh_offset")
    if viewport and not viewport.size_changed.is_connected(resize_callable):
        viewport.size_changed.connect(resize_callable)

func _process(_delta: float) -> void:
    if world == null:
        return

    # Main's shake never exceeds eight logical pixels. Clamping protects this
    # late layout pass from accidentally accumulating its own previous offset.
    var shake_x := clampf(world.position.x, -8.0, 8.0)
    world.position.x = _offset_x + shake_x

func offset_x() -> float:
    return _offset_x

func apply_viewport_size(viewport_size: Vector2) -> void:
    _offset_x = PortraitLayout.playfield_offset_x(viewport_size)
    if world != null:
        var shake_x := clampf(world.position.x, -8.0, 8.0)
        world.position.x = _offset_x + shake_x

func _refresh_offset() -> void:
    apply_viewport_size(get_viewport().get_visible_rect().size)
