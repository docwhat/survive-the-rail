class_name Car
## A train car attached to the train.
##
## Cars add weight to the train (slowing acceleration, extending braking).
## Visual-only in this phase: they pivot at their bogie offset point
## when the train enters a curve, simulating a bogie pivot animation.
##
## In later tasks, cars will also carry weapons (auto-aim, auto-fire)
## and utility bonuses (passive stat boosts).
## The type of this car: "cannon", "machine_gun", "booster", "cargo", etc.
var car_type: String = "cargo"

## Category: "Weapon" or "Utility".
var category: String = "Utility"

## How much this car adds to the train's total weight.
var weight: float = 5.0

## The car's health. Can be upgraded over time.
var health: float = 10.0

## Upgrade level (0 = base, higher = better).
var level: int = 0

## Bogie offset: the pivot point around which the car body rotates
## when entering a curve. Expressed as a local offset from the car's
## center (0,0) in world units. The bogie is typically near the
## front or back of the car, not at the center.
var bogie_offset: Vector2 = Vector2.ZERO

## Car body rotation angle (radians) around the bogie pivot.
## This is the visual pivot animation — set during rendering.
## Calculated from the train's current segment curvature.
var body_rotation: float = 0.0

## Coupling offset: where this car connects to the car in front.
## Expressed as a world-space offset from the car's center.
var coupling_offset: Vector2 = Vector2.ZERO

## --- Initialization ---


## Set up the car with basic parameters.
## @param p_car_type: The car type identifier
## @param p_weight: Weight contribution to the train
## @param p_bogie_offset: Pivot point for curve animation
func initialize(p_car_type: String, p_weight: float, p_bogie_offset: Vector2) -> void:
	car_type = p_car_type
	weight = p_weight
	bogie_offset = p_bogie_offset

## --- Weight ---


## Get this car's weight contribution.
## @return The weight added to the train's total_weight.
func get_weight() -> float:
	return weight


## Get the weight after applying level upgrades.
## Level 1: +weight, Level 2: +weight * 2, etc.
## @return Scaled weight based on level.
func get_weight_with_upgrades() -> float:
	var multiplier: float = 1.0 + (level * 0.1) # 10% increase per level
	return weight * multiplier

## --- Health ---


## Take damage to this car.
## @param damage: Amount of damage to apply
func take_damage(damage: float) -> void:
	health = maxf(health - damage, 0.0)


## Check if this car is destroyed (0 health).
## @return True if health has reached zero.
func is_destroyed() -> bool:
	return health <= 0.0

## --- Pivot Animation ---


## Calculate the body rotation for bogie pivot animation.
##
## When the train enters a curve segment, each car body rotates
## around its bogie pivot point to match the curve. The rotation
## is proportional to the curve angle (90 degrees for a full curve
## segment) and the car's position along the train.
##
## @param current_segment: The track segment the engine is currently on.
## @param total_cars: Total number of cars in the train (for pivot scaling).
## @param car_index: This car's index in the cars array (0 = first car behind engine).
## @return Body rotation angle in radians.
func calculate_pivot_angle(current_segment: TrackSegment, total_cars: int, car_index: int) -> float:
	if current_segment.get_segment_type() == 0:
		# Straight segment: no pivot needed
		return 0.0

	# Curve segment: interpolate rotation based on car position.
	# The first car pivots most, subsequent cars pivot less.
	var curve_angle: float = PI / 2.0 # 90 degrees for a single curve segment
	var pivot_scale: float = 1.0 - (car_index as float) / maxi(total_cars, 1)
	return curve_angle * pivot_scale

## --- State ---


## Get a simplified state dictionary for serialization.
## @return Dictionary of car state.
func get_state() -> Dictionary:
	return {
		"car_type": car_type,
		"category": category,
		"weight": weight,
		"health": health,
		"level": level,
		"bogie_offset": bogie_offset,
		"body_rotation": body_rotation,
		"coupling_offset": coupling_offset,
	}
