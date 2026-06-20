extends RefCounted
class_name GameBalance

## Central authority for gameplay-critical tuning values.
##
## Presentation-only values should remain in their presentation scripts. Values
## that affect timing, scoring, positioning, spawning, or fairness belong here.

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
const LANE_X: Array[float] = [210.0, 510.0]
const PLAYER_START_LANE := 0
const PLAYER_Y := 1050.0
const PLAYER_SWITCH_TIME := 0.115

const START_SPEED := 650.0
const MAX_SPEED := 1120.0
const SPEED_GAIN_PER_SECOND := 13.0

const START_SPAWN_INTERVAL := 0.92
const MIN_SPAWN_INTERVAL := 0.48
const SPAWN_INTERVAL_REDUCTION_PER_SECOND := 0.0075
const INITIAL_SPAWN_CLOCK := 0.25

const BASE_SCORE_PER_SECOND := 11.0
const SCORE_ACCELERATION_PER_SECOND := 0.055
const PICKUP_SCORE := 25.0

const OBSTACLE_SPAWN_Y := -90.0
const OBSTACLE_CLEANUP_Y := 1380.0

const PICKUP_BASE_SPAWN_Y := -205.0
const PICKUP_EXTRA_OFFSET_MAX := 70.0
const PICKUP_CLEANUP_Y := 1360.0
const PICKUP_SPAWN_CHANCE := 0.64

# Wave tiers:
# - Introduction: one readable obstacle and optional pickup.
# - Rhythm: staggered opposite-lane follow-ups begin appearing.
# - Pressure: the follow-up probability has reached its configured ceiling.
const FOLLOWUP_UNLOCK_TIME := 18.0
const FOLLOWUP_MAX_CHANCE := 0.28
const FOLLOWUP_CHANCE_RAMP_SECONDS := 180.0
const PRESSURE_TIER_START_TIME := 50.4
const FOLLOWUP_SPACING_SECONDS := 0.28

# The director rejects any lane-changing hazard sequence that provides less
# than switch animation time plus this deliberate human response window.
const MIN_REACTION_TIME := 0.32

const RESTART_LOCK_TIME := 0.48
const GAME_OVER_PANEL_DELAY := 0.34
const SCREEN_SHAKE_DURATION := 0.25

static func speed_at(elapsed_seconds: float) -> float:
    return minf(MAX_SPEED, START_SPEED + elapsed_seconds * SPEED_GAIN_PER_SECOND)

static func spawn_interval_at(elapsed_seconds: float) -> float:
    return maxf(
        MIN_SPAWN_INTERVAL,
        START_SPAWN_INTERVAL - elapsed_seconds * SPAWN_INTERVAL_REDUCTION_PER_SECOND
    )

static func score_rate_at(elapsed_seconds: float) -> float:
    return BASE_SCORE_PER_SECOND + elapsed_seconds * SCORE_ACCELERATION_PER_SECOND

static func followup_chance_at(elapsed_seconds: float) -> float:
    if elapsed_seconds <= FOLLOWUP_UNLOCK_TIME:
        return 0.0
    return minf(FOLLOWUP_MAX_CHANCE, elapsed_seconds / FOLLOWUP_CHANCE_RAMP_SECONDS)
