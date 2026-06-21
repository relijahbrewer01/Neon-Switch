extends RefCounted
class_name PortraitLayout

## Maps physical mobile safe-area data into the project's logical viewport and
## keeps the 720-wide gameplay column centered when expanded desktop windows
## expose additional horizontal canvas space.

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const CONTENT_GUTTER_X := 28.0
const CONTENT_GUTTER_TOP := 20.0
const CONTENT_GUTTER_BOTTOM := 24.0
const MIN_CONTENT_WIDTH := 480.0
const MIN_CONTENT_HEIGHT := 720.0

static func runtime_safe_rect(viewport_size: Vector2) -> Rect2:
    var full_rect := Rect2(Vector2.ZERO, _valid_viewport_size(viewport_size))
    if not OS.has_feature("mobile"):
        return full_rect

    var display_size := DisplayServer.screen_get_size()
    var display_safe_area := DisplayServer.get_display_safe_area()
    return map_display_safe_area(
        full_rect.size,
        display_size,
        display_safe_area
    )

static func map_display_safe_area(
    viewport_size: Vector2,
    display_size: Vector2i,
    display_safe_area: Rect2i
) -> Rect2:
    var valid_viewport_size := _valid_viewport_size(viewport_size)
    var full_rect := Rect2(Vector2.ZERO, valid_viewport_size)

    if display_size.x <= 0 or display_size.y <= 0:
        return full_rect
    if display_safe_area.size.x <= 0 or display_safe_area.size.y <= 0:
        return full_rect

    var scale := Vector2(
        valid_viewport_size.x / float(display_size.x),
        valid_viewport_size.y / float(display_size.y)
    )
    var mapped := Rect2(
        Vector2(display_safe_area.position) * scale,
        Vector2(display_safe_area.size) * scale
    )
    return clamp_rect_to_viewport(mapped, valid_viewport_size)

static func clamp_rect_to_viewport(rect: Rect2, viewport_size: Vector2) -> Rect2:
    var valid_viewport_size := _valid_viewport_size(viewport_size)
    var left := clampf(rect.position.x, 0.0, valid_viewport_size.x)
    var top := clampf(rect.position.y, 0.0, valid_viewport_size.y)
    var right := clampf(rect.end.x, left, valid_viewport_size.x)
    var bottom := clampf(rect.end.y, top, valid_viewport_size.y)

    if right - left < 1.0 or bottom - top < 1.0:
        return Rect2(Vector2.ZERO, valid_viewport_size)
    return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))

static func playfield_offset_x(viewport_size: Vector2) -> float:
    var valid_viewport_size := _valid_viewport_size(viewport_size)
    return maxf(0.0, (valid_viewport_size.x - DESIGN_SIZE.x) * 0.5)

static func centered_playfield_rect(rect: Rect2) -> Rect2:
    var width := minf(rect.size.x, DESIGN_SIZE.x)
    return Rect2(
        Vector2(rect.position.x + (rect.size.x - width) * 0.5, rect.position.y),
        Vector2(width, rect.size.y)
    )

static func content_rect(safe_rect: Rect2) -> Rect2:
    # Wide desktop windows expose additional horizontal canvas under `expand`.
    # Cap UI to the portrait design width and center that column instead of
    # allowing containers and gameplay information to cling to the left edge.
    var playfield_rect := centered_playfield_rect(safe_rect)
    var horizontal_gutter := minf(
        CONTENT_GUTTER_X,
        maxf(0.0, (playfield_rect.size.x - MIN_CONTENT_WIDTH) * 0.5)
    )
    var top_gutter := minf(
        CONTENT_GUTTER_TOP,
        maxf(0.0, playfield_rect.size.y - MIN_CONTENT_HEIGHT)
    )
    var bottom_gutter := minf(
        CONTENT_GUTTER_BOTTOM,
        maxf(0.0, playfield_rect.size.y - MIN_CONTENT_HEIGHT - top_gutter)
    )

    return Rect2(
        playfield_rect.position + Vector2(horizontal_gutter, top_gutter),
        Vector2(
            maxf(1.0, playfield_rect.size.x - horizontal_gutter * 2.0),
            maxf(1.0, playfield_rect.size.y - top_gutter - bottom_gutter)
        )
    )

static func contains_rect(outer: Rect2, inner: Rect2, epsilon: float = 0.5) -> bool:
    return (
        inner.position.x >= outer.position.x - epsilon
        and inner.position.y >= outer.position.y - epsilon
        and inner.end.x <= outer.end.x + epsilon
        and inner.end.y <= outer.end.y + epsilon
    )

static func _valid_viewport_size(viewport_size: Vector2) -> Vector2:
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return DESIGN_SIZE
    return viewport_size
