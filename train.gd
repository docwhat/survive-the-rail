class_name Train
## Train entity with physics-controlled movement along a track.
##
## The train is a scene node (Node2D-based) with:
## - Speed, acceleration, braking managed via `Physics` system
## - Position tracking along track segments
## - Health and collision response via `Physics` system
## - Keyboard input for throttle/brake control
##
## The train owns a single engine sprite and an array of car sprites.
## It does NOT handle rendering itself — that's delegated to
## a separate renderer node. This keeps the Train logic fully
## testable via GUT.

const CELL_SIZE: float = 64.0
## Grid cell size in world units (matches Track.CELL_SIZE).

## Constant for the first segment — the train always starts here.
const STARTING_SEGMENT_INDEX: int = 0

## --- State ---

var position: Vector2 = Vector2.ZERO
## Current world position of the train (engine center).

var speed: float = 0.0
## Current speed in world units per second. Clamped to [0, max_speed].

var max_speed: float = 100.0
## Maximum speed in world units per second.

var engine_power: float = 200.0
## Fixed engine output. Effective acceleration = engine_power / total_weight.

var brake_force: float = 100.0
## Fixed braking capability. Effective deceleration = brake_force / total_weight.

var total_weight: float = 10.0
## Sum of engine + all car weights. Affects acceleration and braking.

var health: float = 100.0
## Current health. Reaches 0 -> train destroyed.

var max_health: float = 100.0
## Maximum health.

var segment_index: int = 0
## Current segment index the train is traversing.

var segment_progress: float = 0.0
## Progress along the current segment: 0.0 (start) to 1.0 (end).

var is_throttling: bool = false
## Whether the throttle input is active.

var is_braking: bool = false
## Whether the brake input is active.

var cars: Array = []
## Attached car nodes. Each car contributes to total_weight.

var enabled: bool = false
## When false, the train doesn't respond to input (e.g. game-over).

## --- Setup ---


## Initialize the train with starting parameters.
## @param starting_max_speed: Maximum speed in world units per second
## @param starting_engine_power: Fixed engine output
## @param starting_brake_force: Fixed braking capability
## @param starting_weight: Total train weight (engine + initial cars)
## @param starting_health: Starting health points
func initialize(
		starting_max_speed: float,
		starting_engine_power: float,
		starting_brake_force: float,
		starting_health: float,
		starting_weight: float,
		initial_speed: float = 0.0,
		starting_segment_index: int = 0,
) -> void:
	max_speed = starting_max_speed
	engine_power = starting_engine_power
	brake_force = starting_brake_force
	health = starting_health
	max_health = starting_health
	total_weight = starting_weight
	speed = initial_speed
	segment_index = starting_segment_index
	segment_progress = 0.0
	is_throttling = false
	is_braking = false


## Add a car to the train.
## @param car: The car to attach
func add_car(car: Car) -> void:
	cars.append(car)
	# Recalculate total weight
	total_weight = _calculate_total_weight()


## Remove a car from the train.
## @param car: The car to detach
func remove_car(car: Car) -> void:
	if car in cars:
		cars.erase(car)
		total_weight = _calculate_total_weight()

## --- Physics ---


## Update speed based on current input and time step.
## Uses the Physics system for all calculations.
## @param delta: Time step since last frame
## @return Updated speed value.
func update_speed(delta: float) -> float:
	var effective_accel: float = Physics.effective_acceleration(engine_power, total_weight)
	var effective_decel: float = Physics.effective_deceleration(brake_force, total_weight)
	speed = Physics.update_speed(
		speed,
		effective_accel,
		effective_decel,
		is_throttling,
		is_braking,
		max_speed,
		delta,
	)
	return speed


## Advance the train along the track based on speed and delta.
## Updates segment_progress and position, advancing segment_index
## when progress reaches 1.0.
## @param track: The Track data model to read segment positions from.
## @param delta: Time step since last frame.
func update_position(track: Track, delta: float) -> void:
	if speed <= 0.0:
		return

	var segments: Array[TrackSegment] = track.get_segments()
	if segments.size() == 0:
		return

	# Clamp segment_index to valid range
	if segment_index < 0:
		segment_index = 0
	if segment_index >= segments.size():
		segment_index = segments.size() - 1

	var current_seg: TrackSegment = segments[segment_index]

	# Distance to move this frame
	var distance: float = speed * delta
	segment_progress += distance / CELL_SIZE

	# If progress exceeds 1.0, advance to next segment
	while segment_progress >= 1.0 and segment_index < segments.size() - 1:
		segment_progress -= 1.0
		segment_index += 1
		if segment_index < segments.size():
			current_seg = segments[segment_index]
			# Recalculate total weight at segment boundary
			total_weight = _calculate_total_weight()

	# Update position along current segment
	var seg: TrackSegment = segments[segment_index]
	position = _segment_position(seg)


## Get the world position of the train on the current segment.
## @param seg: The current track segment.
## @return World-space position of the train on this segment.
func _segment_position(seg: TrackSegment) -> Vector2:
	var base_pos: Vector2 = seg.grid_position as Vector2 * CELL_SIZE
	var connections: Array[Vector2i] = seg.connections

	# Determine if this is a straight or curve segment
	var seg_type: int = seg.get_segment_type()
	if seg_type == 0:
		# Straight: linear interpolation
		var travel_dir: Vector2
		if segment_index == 0:
			travel_dir = connections[0] as Vector2
		else:
			travel_dir = -connections[1] as Vector2
		travel_dir = travel_dir.normalized()
		return base_pos + travel_dir * segment_progress * CELL_SIZE
	# Curve: interpolate along the arc
	return _curve_position(base_pos, connections, segment_progress)


## Calculate position along a curve segment arc.
## The curve is modeled as a quarter-circle arc. The arc center is
## positioned so that progress 0.0 connects to the previous segment
## and progress 1.0 connects to the next segment.
## @param center: The grid center position of the curve segment.
## @param connections: Two adjacent direction vectors defining the curve.
## @param progress: Progress along the curve (0.0 to 1.0).
## @return World-space position on the curve arc.
func _curve_position(center: Vector2, connections: Array[Vector2i], progress: float) -> Vector2:
	var entry_dir: Vector2 = connections[0] as Vector2
	var exit_dir: Vector2 = connections[1] as Vector2

	# The arc radius equals CELL_SIZE. The arc center is offset from
	# the grid center so that the entry point connects to the
	# previous straight segment and the exit point connects to the
	# next straight segment.
	var radius: float = CELL_SIZE

	# Entry point on the arc (where the previous segment connects):
	# This is one cell away from the curve center in the entry direction.
	var arc_entry: Vector2 = center + entry_dir * radius
	# Exit point on the arc (where the next segment connects):
	var arc_exit: Vector2 = center + exit_dir * radius

	# The center of the arc (the pivot point for the quarter-circle):
	# For a LEFT->DOWN curve, entry = LEFT, exit = DOWN.
	# arc_entry = center + LEFT * R = (center.x - R, center.y)
	# arc_exit = center + DOWN * R = (center.x, center.y + R)
	# The arc center is at (arc_entry.x, arc_exit.y) = (center.x - R, center.y + R)
	var arc_center: Vector2 = Vector2(arc_entry.x, arc_exit.y)

	# Entry and exit angles relative to arc center.
	var entry_angle: float = atan2(
		arc_entry.y - arc_center.y,
		arc_entry.x - arc_center.x,
	)
	var exit_angle: float = atan2(
		arc_exit.y - arc_center.y,
		arc_exit.x - arc_center.x,
	)

	# Determine the short arc direction between the two directions
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	var curve_angle: float = entry_angle + diff * progress

	return Vector2(
		arc_center.x + cos(curve_angle) * radius,
		arc_center.y + sin(curve_angle) * radius,
	)


## Update the train's rotation to match the current segment's orientation.
## The train's rotation aligns with the segment's travel direction.
## For curves, interpolates between entry and exit angles.
## @param track: The Track data model to read segment orientation from.
## @return Rotation angle in radians.
func update_orientation(track: Track) -> float:
	var segments: Array[TrackSegment] = track.get_segments()
	if segments.size() == 0:
		return 0.0

	if segment_index < 0:
		segment_index = 0
	if segment_index >= segments.size():
		segment_index = segments.size() - 1

	var seg: TrackSegment = segments[segment_index]
	var seg_type: int = seg.get_segment_type()
	if seg_type == 0:
		# Straight segment: face the exit direction
		var travel_dir: Vector2 = get_travel_direction(track)
		return atan2(travel_dir.y, travel_dir.x)
	# Curve: interpolate rotation along the arc
	var entry_dir: Vector2 = seg.connections[0] as Vector2
	var exit_dir: Vector2 = seg.connections[1] as Vector2
	var radius: float = CELL_SIZE

	# Arc geometry (same as _curve_position)
	var arc_entry: Vector2 = seg.grid_position as Vector2 * CELL_SIZE + entry_dir * radius
	var arc_exit: Vector2 = seg.grid_position as Vector2 * CELL_SIZE + exit_dir * radius
	var arc_center: Vector2 = Vector2(arc_entry.x, arc_exit.y)
	var entry_angle: float = atan2(
		arc_entry.y - arc_center.y,
		arc_entry.x - arc_center.x,
	)
	var exit_angle: float = atan2(
		arc_exit.y - arc_center.y,
		arc_exit.x - arc_center.x,
	)
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI
	return entry_angle + diff * segment_progress


## Resolve a collision with another entity.
## Uses the physics train_push for heavy-vs-light collisions.
## @param target_mass: Mass of the target entity
## @param target_velocity: Velocity of the target entity (Vector2)
## @param direction: Train's travel direction (normalized Vector2)
## @param restitution: Bounciness factor (0.8 default)
## @return Dictionary with updated train speed and target velocity.
func resolve_collision(
		target_mass: float,
		target_velocity: Vector2,
		direction: Vector2,
		restitution: float = 0.8,
) -> Dictionary:
	var result: Dictionary = Physics.train_push(
		total_weight,
		speed,
		target_mass,
		target_velocity,
		direction,
		restitution,
	)
	speed = result["train_new_speed"]
	return result


## Take damage from an enemy collision or projectile hit.
## @param damage: Amount of health to subtract
func take_damage(damage: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - damage, 0.0)


## Check if the train is destroyed.
## @return True if health has reached zero.
func is_destroyed() -> bool:
	return health <= 0.0

## --- Input ---


## Update throttle/brake state from input events.
## Call from _input() or from an input handler.
## @param is_throttle_pressed: Whether throttle input is active
## @param is_brake_pressed: Whether brake input is active
func update_input(is_throttle_pressed: bool, is_brake_pressed: bool) -> void:
	if not enabled:
		return
	is_throttling = is_throttle_pressed
	is_braking = is_brake_pressed

## --- Car Management ---


## Calculate total weight from the engine and all attached cars.
## @return Sum of all car weights (minimum engine weight).
func _calculate_total_weight() -> float:
	var weight: float = 10.0 # Engine base weight
	for car: Car in cars:
		if car.has_method("get_weight"):
			weight += car.get_weight()
	return weight

## --- Getters ---


## Get the current momentum.
## @return speed * total_weight.
func get_momentum() -> float:
	return Physics.momentum(speed, total_weight)


## Get the effective acceleration rate.
## @return engine_power / total_weight.
func get_effective_acceleration() -> float:
	return Physics.effective_acceleration(engine_power, total_weight)


## Get the effective deceleration rate.
## @return brake_force / total_weight.
func get_effective_deceleration() -> float:
	return Physics.effective_deceleration(brake_force, total_weight)


## Get the stopping distance at current speed.
## @return Distance required to stop.
func get_stopping_distance() -> float:
	return Physics.stopping_distance(speed, get_effective_deceleration())


## Get the current number of attached cars.
## @return Length of the cars array.
func get_car_count() -> int:
	return cars.size()


## Get the current direction of travel.
## The train always moves forward along the track.
## @param track: The Track data model to read segment orientation from.
## @return Normalized direction vector of travel.
func get_travel_direction(track: Track) -> Vector2:
	if track.get_segment_count() == 0:
		return Vector2.RIGHT
	var segments: Array[TrackSegment] = track.get_segments()
	if segment_index >= segments.size():
		segment_index = segments.size() - 1
	var seg: TrackSegment = segments[segment_index]
	# For curves, the exit direction is the second connection.
	# For straights, the first connection is the exit direction.
	# On a curve, return the tangent direction at current progress.
	# This gives the instantaneous travel direction along the arc.
	if seg.get_segment_type() == 1:
		var entry_dir: Vector2 = seg.connections[0] as Vector2
		var exit_dir: Vector2 = seg.connections[1] as Vector2
		var radius: float = CELL_SIZE
		var arc_entry: Vector2 = seg.grid_position as Vector2 * CELL_SIZE + entry_dir * radius
		var arc_exit: Vector2 = seg.grid_position as Vector2 * CELL_SIZE + exit_dir * radius
		var arc_center: Vector2 = Vector2(arc_entry.x, arc_exit.y)
		var entry_angle: float = atan2(
			arc_entry.y - arc_center.y,
			arc_entry.x - arc_center.x,
		)
		var exit_angle: float = atan2(
			arc_exit.y - arc_center.y,
			arc_exit.x - arc_center.x,
		)
		var diff: float = exit_angle - entry_angle
		if diff > PI:
			diff -= 2.0 * PI
		elif diff < -PI:
			diff += 2.0 * PI
		var tangent_angle: float = entry_angle + diff * segment_progress
		return Vector2(cos(tangent_angle), sin(tangent_angle))
	return seg.connections[0] # Exit direction of straight


## Get a simplified state dictionary for serialization.
## @return Dictionary of train state suitable for save/load.
func get_state() -> Dictionary:
	return {
		"position": position,
		"speed": speed,
		"health": health,
		"max_health": max_health,
		"segment_index": segment_index,
		"segment_progress": segment_progress,
		"total_weight": total_weight,
		"engine_power": engine_power,
		"brake_force": brake_force,
		"max_speed": max_speed,
		"car_count": cars.size(),
		"enabled": enabled,
	}
