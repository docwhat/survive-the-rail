class_name Physics
## Core 2D physics system for Survive the Rail.
##
## Handles:
## - Momentum calculation (speed * total_weight)
## - Weight-scaled acceleration and deceleration
## - Elastic collision resolution between entities
## - Collision detection via circle overlap (simple 2D)
##
## This system is rendering-independent. All operations work on
## plain Vector2 positions, radii, masses, and velocities.

## --- Constants ---

const COLLISION_MARGIN: float = 0.01
## Extra overlap (in meters) added to collision detection to prevent
## tunneling at low frame rates.

## --- Collision Detection ---


## Returns true if two circles overlap (with margin).
static func circles_ahead(
		position_a: Vector2,
		radius_a: float,
		position_b: Vector2,
		radius_b: float,
) -> bool:
	"""
	Detect collision between two circle entities.

	Parameters:
	- position_a / position_b: Center positions in world space
	- radius_a / radius_b: Collision radii in world units
	Returns: True if the circles are touching or overlapping.
	"""
	var distance: float = position_a.distance_to(position_b)
	var collision_distance: float = radius_a + radius_b + COLLISION_MARGIN
	return distance < collision_distance

## --- Momentum ---


## Calculate momentum for an entity.
## momentum = speed * mass
static func momentum(speed: float, mass: float) -> float:
	"""Return the momentum of a moving entity."""
	return speed * mass


## Calculate effective acceleration using weight scaling.
## effective_acceleration = engine_power / total_weight
## Heavier trains accelerate more slowly.
static func effective_acceleration(engine_power: float, total_weight: float) -> float:
	"""
	Calculate acceleration scaled inversely by total weight.

	Parameters:
	- engine_power: Fixed output of the engine (arbitrary units)
	- total_weight: Sum of engine + all car weights (must be > 0)
	Returns: Acceleration in units per second squared.
	"""
	if total_weight <= 0:
		return INF
	return engine_power / total_weight


## Calculate effective deceleration using weight scaling.
## effective_deceleration = brake_force / total_weight
## Heavier trains take longer to stop.
static func effective_deceleration(brake_force: float, total_weight: float) -> float:
	"""
	Calculate deceleration scaled inversely by total weight.

	Parameters:
	- brake_force: Fixed braking capability (arbitrary units)
	- total_weight: Sum of engine + all car weights (must be > 0)
	Returns: Deceleration in units per second squared.
	"""
	if total_weight <= 0:
		return INF
	return brake_force / total_weight


## Update speed after a time step, applying acceleration or deceleration.
## Returns the new speed (clamped to [0, max_speed]).
static func update_speed(
		current_speed: float,
		acceleration: float,
		deceleration: float,
		is_throttling: bool,
		is_braking: bool,
		max_speed: float,
		delta: float,
) -> float:
	"""
	Apply throttle or brake to current speed over a time step.

	Only one input (throttle or brake) can be active at a time.
	If neither is active, speed drifts toward 0 (rolling friction).

	Returns clamped speed in [0, max_speed].
	"""
	var speed_change: float = 0.0

	if is_throttling:
		speed_change = acceleration * delta
	elif is_braking:
		speed_change = -deceleration * delta
	else:
		# Rolling friction: gradual slowdown when no input
		speed_change = -acceleration * 0.1 * delta

	var new_speed: float = current_speed + speed_change
	return clampf(new_speed, 0.0, max_speed)


## Calculate the time needed to stop from current_speed using deceleration.
static func stopping_distance(current_speed: float, deceleration: float) -> float:
	"""
	Calculate the distance required to stop from current speed.

	Uses v^2 / (2a) physics for constant deceleration.
	"""
	if deceleration <= 0:
		return INF
	return (current_speed * current_speed) / (2.0 * deceleration)

## --- Elastic Collisions ---


## Resolve an elastic collision between two entities.
## Modifies velocities in place (passed by reference via dictionary).
##
## Uses 1D elastic collision along the collision normal.
## For our top-down game, this means entities bounce apart along
## the line connecting their centers.
static func elastic_collision(
		body_a: Dictionary,
		body_b: Dictionary,
		position_a: Vector2,
		position_b: Vector2,
		restitution: float = 1.0,
) -> void:
	"""
	Solve a 1D elastic collision along the collision normal.

	Parameters:
	- body_a / body_b: Dictionaries with "mass" and "velocity" (Vector2) keys
	- position_a / position_b: Current positions (for normal calculation)
	- restitution: Bounciness (1.0 = perfectly elastic, 0.0 = inelastic)

	Mutates body_a["velocity"] and body_b["velocity"].
	"""
	if body_a.has("mass") and body_b.has("mass"):
		if body_a["mass"] <= 0 or body_b["mass"] <= 0:
			return

	var normal: Vector2 = (position_b - position_a).normalized()
	var rel_velocity: Vector2 = body_a["velocity"] - body_b["velocity"]
	var relative_speed: float = rel_velocity.dot(normal)

	# Don't resolve if bodies are already separating (moving apart)
	if relative_speed < 0:
		return

	var mass_a: float = body_a["mass"]
	var mass_b: float = body_b["mass"]

	var impulse: float = (1.0 + restitution) * relative_speed
	impulse /= (1.0 / mass_a) + (1.0 / mass_b)

	body_a["velocity"] -= normal * (impulse / mass_a)
	body_b["velocity"] += normal * (impulse / mass_b)


## Resolve a train-vs-entity push (train maintains course, entity bounces).
## Simpler than full elastic collision — the train barely slows down
## because it's much heavier than individual entities.
static func train_push(
		train_mass: float,
		train_speed: float,
		target_mass: float,
		target_velocity: Vector2,
		direction: Vector2,
		restitution: float = 0.8,
) -> Dictionary:
	"""
	Resolve a collision between a heavy train and a lighter entity.

	The train continues roughly in its direction; the target bounces off.
	Uses conservation of momentum with reduced mass ratio for feel.

	Returns a dictionary with:
		- "train_new_speed": Speed of the train after collision
		- "target_new_velocity": New velocity of the target (Vector2)
	"""
	var direction_vec: Vector2 = direction.normalized()

	# Train velocity before
	var train_velocity: Vector2 = direction_vec * train_speed

	# 1D elastic collision along train direction
	var rel_velocity: float = train_velocity.dot(direction_vec) - target_velocity.dot(direction_vec)
	if rel_velocity < 0:
		# Target moving away — no meaningful collision
		return {
			"train_new_speed": train_speed,
			"target_new_velocity": target_velocity,
		}

	var impulse: float = (1.0 + restitution) * rel_velocity
	impulse /= (1.0 / train_mass) + (1.0 / target_mass)

	var train_new_speed: float = train_speed - (impulse / train_mass)
	train_new_speed = maxf(train_new_speed, 0.0)

	var target_new_velocity: Vector2 = target_velocity + direction_vec * (impulse / target_mass)

	return {
		"train_new_speed": train_new_speed,
		"target_new_velocity": target_new_velocity,
	}
