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

## --- Path Follower State (Task 4d) ---

var _path_follower: TrainPathFollower = null
## Engine path follower wrapper.

var _car_followers: Array[CarPathFollower] = []
## Car path follower wrappers, indexed by car index.

var _has_path: bool = false
## Whether a valid path has been set up.

var _coupling_offsets: Array[float] = []
## Distance behind engine for each car (world units).

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
		# Clean up car follower
		if _car_followers.size() > 0:
			_car_followers.remove_at(cars.find(car))
			if _car_followers.size() > 0:
				_coupling_offsets.remove_at(cars.find(car))

## --- Path Follower Integration (Task 4d) ---


## Set up the path followers with a track's built path.
## @param path: The Path2D to follow.
## @param track: The Track data model (for segment info).
func set_path(path: Path2D, track: Track = null) -> void:
	_path_follower = TrainPathFollower.new()
	_path_follower.initialize(path)
	_has_path = true

	# Recreate car followers based on current cars
	_car_followers = []
	_coupling_offsets = []
	for car: Car in cars:
		var follower: CarPathFollower = CarPathFollower.new()
		var offset: float = _get_car_coupling_offset(car, _car_followers.size())
		follower.initialize(path, offset)
		_car_followers.append(follower)
		_coupling_offsets.append(offset)


## Get the engine path follower.
func get_path_follower() -> TrainPathFollower:
	return _path_follower


## Get the car path followers array.
func get_car_followers() -> Array[CarPathFollower]:
	return _car_followers


## Get the train's current progress along the path.
func get_progress() -> float:
	if _path_follower != null:
		return _path_follower.get_progress()
	# No path follower — return 0 for segment mode
	return 0.0


## Set the train's progress along the path.
## @param progress: Progress value (0.0 to 1.0 range).
func set_progress(progress: float) -> void:
	if _path_follower != null:
		# Clamp progress to valid range, then set
		_path_follower.set_progress(clampf(progress, 0.0, 1.0))
		# Update car followers with their offsets
		for i in range(_car_followers.size()):
			_car_followers[i].set_base_progress(
				_path_follower.get_progress() - _coupling_offsets[i],
			)


## Update position using the path follower.
## @param delta: Time step since last frame.
func update_position_path_follower(delta: float) -> void:
	if _path_follower == null or not _has_path:
		# Fallback to segment-based position
		update_position(_dummy_track(), delta)
		return

	if speed <= 0.0:
		return

	# Distance to move this frame
	var distance: float = speed * delta
	var total_length: float = _path_follower._total_path_length

	# Advance progress
	var current_progress: float = _path_follower.get_progress() + distance

	# Clamp to path bounds
	current_progress = clampf(current_progress, 0.0, total_length)
	_path_follower.set_progress(current_progress)

	# Update position from the path follower
	position = _path_follower.get_position()

	# Update car followers
	for i in range(_car_followers.size()):
		var car_progress: float = current_progress - _coupling_offsets[i]
		car_progress = clampf(car_progress, 0.0, total_length)
		_car_followers[i].set_base_progress(car_progress)


## Update orientation using the path follower.
func update_orientation_path_follower() -> float:
	if _path_follower != null and _has_path:
		return _path_follower.get_angle()
	return update_orientation(_dummy_track())


## Get the travel direction from the path follower.
func get_travel_direction_path_follower() -> Vector2:
	if _path_follower != null and _has_path:
		var angle: float = _path_follower.get_angle()
		return Vector2(cos(angle), sin(angle))
	return get_travel_direction(_dummy_track())


## Get a dummy track for fallback methods.
func _dummy_track() -> Track:
	return null

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
	position = _segment_position(track, seg)


## Get the world position of the train on the current segment.
## @param track: The track data model for lookups.
## @param seg: The current track segment.
## @return World-space position of the train on this segment.
func _segment_position(track: Track, seg: TrackSegment) -> Vector2:
	var center: Vector2 = seg.grid_position as Vector2 * CELL_SIZE

	# Determine if this is a straight or curve segment
	var seg_type: int = seg.get_segment_type()
	if seg_type == 0:
		# Straight: edge-to-edge interpolation
		var travel_dir: Vector2 = _get_travel_direction_for_segment(track, seg)
		return center - travel_dir * 32.0 + travel_dir * segment_progress * CELL_SIZE
	# Curve: interpolate along the arc
	return _curve_position(center, seg.connections, segment_progress)


## Calculate position along a curve segment arc.
## The curve is modeled as a quarter-circle arc. The arc center is
## positioned so that progress 0.0 connects to the previous segment
## and progress 1.0 connects to the next segment.
## @param center: The grid center position of the curve segment.
## @param connections: Two adjacent direction vectors defining the curve.
## @param progress: Progress along the curve (0.0 to 1.0).
## @return World-space position on the curve arc.
func _curve_position(center: Vector2, connections: Array[Vector2i], progress: float) -> Vector2:
	# Connections represent edge directions. Travel direction is opposite at entry.
	var entry_edge: Vector2 = connections[0] as Vector2
	var exit_edge: Vector2 = connections[1] as Vector2
	var radius: float = 32.0

	# Travel direction at entry is opposite of entry edge direction
	var entry_angle: float = atan2(-entry_edge.y, -entry_edge.x)
	# Travel direction at exit follows exit edge direction
	var exit_angle: float = atan2(exit_edge.y, exit_edge.x)

	# Determine the short arc direction between the two directions
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	var curve_angle: float = entry_angle + diff * progress

	return center + Vector2(cos(curve_angle), sin(curve_angle)) * radius


## Update the train's rotation to match the current segment's orientation.
## The train's rotation aligns with the segment's travel direction.
## For curves, interpolates between entry and exit angles.
## @param track: The Track data model to read segment orientation from.
## @return Rotation angle in radians.
func update_orientation(track: Track) -> float:
	# Guard against null track (e.g. from path follower fallback)
	if track == null:
		return 0.0
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
	# Connections represent edge directions. Travel direction is opposite at entry.
	var entry_edge: Vector2 = seg.connections[0] as Vector2
	var exit_edge: Vector2 = seg.connections[1] as Vector2

	# Travel direction at entry is opposite of entry edge direction
	var entry_angle: float = atan2(-entry_edge.y, -entry_edge.x)
	# Travel direction at exit follows exit edge direction
	var exit_angle: float = atan2(exit_edge.y, exit_edge.x)
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
	if seg.get_segment_type() == 1:
		# Curve: return the tangent direction at current progress.
		# Connections represent edge directions. Travel is opposite at entry.
		var entry_edge: Vector2 = seg.connections[0] as Vector2
		var exit_edge: Vector2 = seg.connections[1] as Vector2
		var entry_angle: float = atan2(-entry_edge.y, -entry_edge.x)
		var exit_angle: float = atan2(exit_edge.y, exit_edge.x)
		var diff: float = exit_angle - entry_angle
		if diff > PI:
			diff -= 2.0 * PI
		elif diff < -PI:
			diff += 2.0 * PI
		var tangent_angle: float = entry_angle + diff * segment_progress
		return Vector2(cos(tangent_angle), sin(tangent_angle))
	# Straight: use helper that looks at previous segment
	return _get_travel_direction_for_segment(track, seg)


## Compute the travel direction for a straight segment.
## The travel direction is the direction from the previous segment's
## center toward this segment's center.
## @param track: The track data model for segment lookups.
## @param seg: The track segment.
## @return Normalized travel direction vector.
func _get_travel_direction_for_segment(track: Track, seg: TrackSegment) -> Vector2:
	# For the first segment, travel direction is connections[0]
	if segment_index == 0:
		return seg.connections[0] as Vector2

	# For subsequent segments, find the previous segment and determine
	# which of its connection edges points toward this segment.
	var segments: Array[TrackSegment] = track.get_segments()
	var prev_seg: TrackSegment = segments[segment_index - 1]

	# The direction from prev_seg center to this seg center is one of
	# prev_seg's connections. That connection IS the travel direction.
	for conn in prev_seg.connections:
		if prev_seg.grid_position + conn == seg.grid_position:
			return conn as Vector2

	# Fallback: return current segment's first connection
	return seg.connections[0] as Vector2


## Calculate the coupling offset for a car at the given index.
## Each car is spaced by CELL_SIZE along the path behind the engine.
func _get_car_coupling_offset(car: Car, car_index: int) -> float:
	# Each car sits one cell length behind the previous one
	return (car_index + 1) * CELL_SIZE


## Get a simplified state dictionary for serialization.
## @return Dictionary of train state suitable for save/load.
func get_state() -> Dictionary:
	var state: Dictionary = {
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
		"using_path_follower": _has_path,
		"progress": get_progress(),
		"car_coupling_offsets": _coupling_offsets.duplicate(),
	}
	return state


## Check if the train is using path follower mode.
func is_using_path_follower() -> bool:
	return _has_path


## Switch from segment-based to path follower mode.
## @param track: The Track data model to build the path from.
func switch_to_path_mode(track_model: Track) -> void:
	# Build the path using the path builder
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_full_path(track_model._data_table, track_model._segment_table)
	set_path(path, track_model)
	_has_path = true

	# Compute the train's current position on the new path
	_compute_path_progress_from_position(track_model)


## Switch from path follower mode back to segment-based mode.
## Preserves the train's physical position on the track.
## @param track: The Track data model for segment lookups.
func switch_to_segment_mode(track_model: Track) -> void:
	# Compute segment_index and segment_progress from current position
	_compute_segment_state_from_position(track_model)
	_has_path = false
	# Cleanup path followers
	_path_follower = null
	_car_followers = []
	_coupling_offsets = []


## Get the current path progress value (0.0 to 1.0).
func get_path_progress() -> float:
	return get_progress()


## Set the train's progress along the current path.
## Used for undo/rebuild operations.
## @param progress: Progress value (0.0 to 1.0).
func set_path_progress(progress: float) -> void:
	if _path_follower != null:
		var total_length: float = _compute_path_total_length(_path_follower)
		if total_length > 0:
			_path_follower.set_progress(clampf(progress, 0.0, 1.0) * total_length)
			# Update car followers
			for i in range(_car_followers.size()):
				_car_followers[i].set_base_progress(
					_path_follower.get_progress() - _coupling_offsets[i],
				)


## Compute the train's progress along the path from its current world position.
## Finds the closest point on the path to the train's current position.
func _compute_path_progress_from_position(track_model: Track) -> void:
	if _path_follower == null:
		return
	var pf_node: PathFollow2D = _path_follower.get_path_follow_node()
	var path: Path2D = pf_node.path
	if path == null:
		return

	# Find the closest point on the path to the train's position
	var closest_progress: float = _find_closest_path_progress(path)
	var total_length: float = _compute_path_total_length(_path_follower)

	# Clamp and set
	if total_length > 0:
		_path_follower.set_progress(clampf(closest_progress, 0.0, total_length))


## Compute the train's segment_index and segment_progress from its position.
func _compute_segment_state_from_position(track_model: Track) -> void:
	if track_model == null:
		return
	var closest_seg: int = _find_closest_segment(track_model)
	segment_index = closest_seg
	segment_progress = 0.0
	position = track_model.get_segment_position(closest_seg)


## Find the path progress value closest to a world position.
func _find_closest_path_progress(path: Path2D) -> float:
	var best_progress: float = 0.0
	var best_distance: float = INF
	var total_length: float = _compute_path_total_length_from_path(path)
	if total_length <= 0:
		return 0.0

	var step: float = maxf(total_length / 100.0, 0.1)
	for p in range(0, int(total_length / step) + 1):
		var t: float = minf(p * step, total_length)
		var pos_at_t: Vector2 = _get_point_at_path_progress(path, t)
		var d: float = position.distance_to(pos_at_t)
		if d < best_distance:
			best_distance = d
			best_progress = t

	return best_progress


## Compute total path length from the path followers.
func _compute_path_total_length(path_follower: TrainPathFollower) -> float:
	if path_follower == null:
		return 0.0
	return path_follower._total_path_length


## Compute total path length from a Path2D node.
func _compute_path_total_length_from_path(path: Path2D) -> float:
	var total: float = 0.0
	for child in path.get_children():
		match child.get_class():
			"PathSegLine":
				var a: Vector2 = child.get_point_a()
				var b: Vector2 = child.get_point_b()
				total += a.distance_to(b)
			"PathSegCurve2D":
				var a: Vector2 = child.get_point_a()
				var b: Vector2 = child.get_point_b()
				var c: Vector2 = child.get_point_c()
				var mid: Vector2 = _bezier_midpoint(a, b, c)
				total += a.distance_to(mid) + mid.distance_to(c)
			_:
				pass
	return total


## Get the world position at a specific progress value along the path.
func _get_point_at_path_progress(path: Path2D, progress: float) -> Vector2:
	var remaining: float = progress
	for child in path.get_children():
		match child.get_class():
			"PathSegLine":
				var a: Vector2 = child.get_point_a()
				var b: Vector2 = child.get_point_b()
				var seg_len: float = a.distance_to(b)
				if remaining <= seg_len:
					return a.lerp(b, remaining / seg_len)
				remaining -= seg_len
			"PathSegCurve2D":
				var a: Vector2 = child.get_point_a()
				var b: Vector2 = child.get_point_b()
				var c: Vector2 = child.get_point_c()
				var mid: Vector2 = _bezier_midpoint(a, b, c)
				var seg_len: float = a.distance_to(mid) + mid.distance_to(c)
				if remaining <= seg_len:
					return _get_point_on_curve_at_progress(child, remaining / seg_len)
				remaining -= seg_len
			_:
				pass
	return Vector2.ZERO


## Get a point on a curve segment at local progress (0.0 to 1.0).
func _get_point_on_curve_at_progress(curve_segment, local_progress: float) -> Vector2:
	var a: Vector2 = curve_segment.get_point_a()
	var b: Vector2 = curve_segment.get_point_b()
	var c: Vector2 = curve_segment.get_point_c()
	var mid: Vector2 = _bezier_midpoint(a, b, c)

	if local_progress <= 0.5:
		# First half: a -> mid
		var local_t: float = local_progress * 2.0
		return a.lerp(mid, local_t)
	else:
		# Second half: mid -> c
		var local_t: float = (local_progress - 0.5) * 2.0
		return mid.lerp(c, local_t)


## Find the closest segment index for a given position.
func _find_closest_segment(track_model: Track) -> int:
	var segments: Array[TrackSegment] = track_model.get_segments()
	if segments.size() == 0:
		return 0

	var best_dist: float = INF
	var best_idx: int = 0
	for i in range(segments.size()):
		var seg_pos: Vector2 = track_model.get_segment_position(i)
		var d: float = position.distance_to(seg_pos)
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx


## Compute a Bezier midpoint at t=0.5.
func _bezier_midpoint(p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var t: float = 0.5
	var x: float = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x
	var y: float = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y
	return Vector2(x, y)
