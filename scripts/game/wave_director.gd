extends RefCounted
class_name WaveDirector

## Pure wave-construction service.
##
## The director decides what should spawn, but it never instantiates scenes or
## touches the world tree. Main remains responsible for turning these entries
## into gameplay entities.

enum Tier {
    INTRODUCTION,
    RHYTHM,
    PRESSURE,
}

const TIER_INTRODUCTION := Tier.INTRODUCTION
const TIER_RHYTHM := Tier.RHYTHM
const TIER_PRESSURE := Tier.PRESSURE

const ENTRY_OBSTACLE := "obstacle"
const ENTRY_PICKUP := "pickup"
const OFFSET_EPSILON := 0.001

func tier_at(elapsed_seconds: float) -> int:
    if elapsed_seconds < GameBalance.FOLLOWUP_UNLOCK_TIME:
        return Tier.INTRODUCTION
    if elapsed_seconds < GameBalance.PRESSURE_TIER_START_TIME:
        return Tier.RHYTHM
    return Tier.PRESSURE

func tier_name(tier: int) -> String:
    match tier:
        Tier.INTRODUCTION:
            return "introduction"
        Tier.RHYTHM:
            return "rhythm"
        Tier.PRESSURE:
            return "pressure"
        _:
            return "unknown"

func build_wave(
    elapsed_seconds: float,
    speed: float,
    rng: RandomNumberGenerator
) -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    var blocked_lane := rng.randi_range(0, GameBalance.LANE_X.size() - 1)
    var safe_lane := 1 - blocked_lane

    entries.append(_make_entry(ENTRY_OBSTACLE, blocked_lane, 0.0))

    # Preserve the prototype's random-call order and pickup placement. The
    # pickup trails the first obstacle in its safe lane, creating temptation
    # without closing the survival route.
    if rng.randf() < GameBalance.PICKUP_SPAWN_CHANCE:
        var pickup_offset := (
            GameBalance.PICKUP_BASE_SPAWN_Y
            - GameBalance.OBSTACLE_SPAWN_Y
            - rng.randf_range(0.0, GameBalance.PICKUP_EXTRA_OFFSET_MAX)
        )
        entries.append(_make_entry(ENTRY_PICKUP, safe_lane, pickup_offset))

    var tier := tier_at(elapsed_seconds)
    if (
        tier != Tier.INTRODUCTION
        and elapsed_seconds > GameBalance.FOLLOWUP_UNLOCK_TIME
        and rng.randf() < GameBalance.followup_chance_at(elapsed_seconds)
    ):
        var spacing_seconds := maxf(
            GameBalance.FOLLOWUP_SPACING_SECONDS,
            minimum_switch_window()
        )
        entries.append(_make_entry(
            ENTRY_OBSTACLE,
            safe_lane,
            -speed * spacing_seconds
        ))

    assert(
        is_wave_fair(entries, speed),
        "WaveDirector generated a wave without a valid survival route."
    )
    return entries

func minimum_switch_window() -> float:
    return GameBalance.PLAYER_SWITCH_TIME + GameBalance.MIN_REACTION_TIME

func is_wave_fair(entries: Array[Dictionary], speed: float) -> bool:
    if speed <= 0.0 or GameBalance.LANE_X.is_empty():
        return false

    var hazards: Array[Dictionary] = []
    for entry in entries:
        if str(entry.get("type", "")) != ENTRY_OBSTACLE:
            continue

        var lane := int(entry.get("lane", -1))
        if lane < 0 or lane >= GameBalance.LANE_X.size():
            return false
        hazards.append(entry)

    if hazards.is_empty():
        return false

    hazards.sort_custom(Callable(self, "_sort_by_offset_descending"))

    var reachable_lanes: Array[bool] = []
    for lane_index in range(GameBalance.LANE_X.size()):
        reachable_lanes.append(true)

    var hazard_index := 0
    var previous_offset := 0.0
    var has_previous_group := false

    while hazard_index < hazards.size():
        var group_offset := float(hazards[hazard_index].get("offset_y", 0.0))

        if has_previous_group:
            var travel_time := absf(previous_offset - group_offset) / speed
            if travel_time + OFFSET_EPSILON >= minimum_switch_window():
                # Enough time has passed to deliberately choose either lane.
                for lane_index in range(reachable_lanes.size()):
                    reachable_lanes[lane_index] = true

        var blocked_lanes: Array[bool] = []
        for lane_index in range(GameBalance.LANE_X.size()):
            blocked_lanes.append(false)

        while hazard_index < hazards.size():
            var candidate_offset := float(hazards[hazard_index].get("offset_y", 0.0))
            if absf(candidate_offset - group_offset) > OFFSET_EPSILON:
                break
            var blocked_lane := int(hazards[hazard_index].get("lane", -1))
            blocked_lanes[blocked_lane] = true
            hazard_index += 1

        var route_remains := false
        for lane_index in range(reachable_lanes.size()):
            if blocked_lanes[lane_index]:
                reachable_lanes[lane_index] = false
            if reachable_lanes[lane_index]:
                route_remains = true

        if not route_remains:
            return false

        previous_offset = group_offset
        has_previous_group = true

    return true

func _make_entry(entry_type: String, lane: int, offset_y: float) -> Dictionary:
    return {
        "type": entry_type,
        "lane": lane,
        "offset_y": offset_y,
    }

func _sort_by_offset_descending(a: Dictionary, b: Dictionary) -> bool:
    return float(a.get("offset_y", 0.0)) > float(b.get("offset_y", 0.0))
