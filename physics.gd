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

const ROLLING_FRICTION_FACTOR: float = 0.1
## Fraction of deceleration (brake force rate) applied as rolling friction
## when coasting. Coasting slowdown is independent of engine power.

## --- Collision Detection ---


## Detect collision between two circle entities.
## @param position_a / position_b: Center positions in world space
## @param radius_a / radius_b: Collision radii in world units
## @return True if the circles are touching or overlapping.
static func circles_ahead(
		position_a: Vector2,
		radius_a: float,
		position_b: Vector2,
		radius_b: float,
) -> bool:
	var distance: float = position_a.distance_to(position_b)
	var collision_distance: float = radius_a + radius_b + COLLISION_MARGIN
	return distance < collision_distance


## Convenience wrapper around `circles_ahead` with a semantic name for
## callers that just need a yes/no answer.
static func is_colliding(
		position_a: Vector2,
		radius_a: float,
		position_b: Vector2,
		radius_b: float,
) -> bool:
	return circles_ahead(position_a, radius_a, position_b, radius_b)

## --- Momentum ---


## Return the momentum of a moving entity.
## momentum = speed * mass
static func momentum(speed: float, mass: float) -> float:
	return speed * mass


## Calculate acceleration scaled inversely by total weight.
## @param engine_power: Fixed output of the engine (arbitrary units)
## @param total_weight: Sum of engine + all car weights (must be > 0)
## @return Acceleration in units per second squared.
static func effective_acceleration(engine_power: float, total_weight: float) -> float:
	if total_weight <= 0:
		return INF
	return engine_power / total_weight


## Calculate deceleration scaled inversely by total weight.
## @param brake_force: Fixed braking capability (arbitrary units)
## @param total_weight: Sum of engine + all car weights (must be > 0)
## @return Deceleration in units per second squared.
static func effective_deceleration(brake_force: float, total_weight: float) -> float:
	if total_weight <= 0:
		return INF
	return brake_force / total_weight


## Apply throttle or brake to current speed over a time step.
##
## Only one input (throttle or brake) can be active at a time.
## If neither is active, speed drifts toward 0 (rolling friction).
## @param current_speed: Current speed of the entity
## @param acceleration: Engine-driven acceleration rate
## @param deceleration: Brake-driven deceleration rate
## @param is_throttling: Whether the engine is accelerating
## @param is_braking: Whether brakes are applied
## @param max_speed: Speed cap to enforce
## @param delta: Time step since last frame
## @return Clamped speed in [0, max_speed].
static func update_speed(
		current_speed: float,
		acceleration: float,
		deceleration: float,
		is_throttling: bool,
		is_braking: bool,
		max_speed: float,
		delta: float,
) -> float:
	var speed_change: float = 0.0

	if is_throttling:
		speed_change = acceleration * delta
	elif is_braking:
		speed_change = -deceleration * delta
	else:
		# Rolling friction: gradual slowdown when no input.
		# Uses deceleration (brake force rate), not engine acceleration.
		speed_change = -deceleration * ROLLING_FRICTION_FACTOR * delta

	var new_speed: float = current_speed + speed_change
	return clampf(new_speed, 0.0, max_speed)


## Calculate the distance required to stop from current speed.
## Uses v^2 / (2a) physics for constant deceleration.
## @param current_speed: Speed to stop from
## @param deceleration: Deceleration rate (must be > 0)
## @return Distance required to stop; INF if deceleration <= 0.
static func stopping_distance(current_speed: float, deceleration: float) -> float:
	if deceleration <= 0:
		return INF
	return (current_speed * current_speed) / (2.0 * deceleration)

## --- Elastic Collisions ---


## Solve a 1D elastic collision along the collision normal.
##
## Mutates body_a["velocity"] and body_b["velocity"].
## @param body_a / body_b: Dictionaries with "mass" and "velocity" (Vector2) keys
## @param position_a / position_b: Current positions (for normal calculation)
## @param restitution: Bounciness (1.0 = perfectly elastic, 0.0 = inelastic)
static func elastic_collision(
		body_a: Dictionary,
		body_b: Dictionary,
		position_a: Vector2,
		position_b: Vector2,
		restitution: float = 1.0,
) -> void:
	# Type assertion: validate required keys exist before mutating.
	if not body_a.has("mass") or not body_a.has("velocity"):
		push_error("elastic_collision: body_a missing 'mass' or 'velocity' key")
		return
	if not body_b.has("mass") or not body_b.has("velocity"):
		push_error("elastic_collision: body_b missing 'mass' or 'velocity' key")
		return
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


## Resolve a collision between a heavy train and a lighter entity.
##
## The train continues roughly in its direction; the target bounces off.
## Uses conservation of momentum with reduced mass ratio for feel.
## @param train_mass: Mass of the train
## @param train_speed: Speed of the train before collision
## @param target_mass: Mass of the target entity
## @param target_velocity: Velocity of the target entity (Vector2)
## @param direction: Train's travel direction (normalized)
## @param restitution: Bounciness (0.8 default)
## @return Dictionary with "train_new_speed" and "target_new_velocity".
static func train_push(
		train_mass: float,
		train_speed: float,
		target_mass: float,
		target_velocity: Vector2,
		direction: Vector2,
		restitution: float = 0.8,
) -> Dictionary:
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
