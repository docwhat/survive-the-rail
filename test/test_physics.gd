extends GdUnitTestSuite

const _Physics = preload("res://physics.gd")
const _Track = preload("res://track.gd")

# --- Helpers ---


## Create a physics body dictionary for collision tests.
func _make_body_dict(mass: float, velocity: Vector2) -> Dictionary:
	return { "mass": mass, "velocity": velocity }

# ============================================================================
# Circle Collision Detection
# ============================================================================


## Two circles exactly at sum-of-radii distance should be touching.
func test_circles_ahead_returns_true_when_touching() -> void:
	var a_pos: Vector2 = Vector2.ZERO
	var b_pos: Vector2 = Vector2.RIGHT * 10.0 # 10 units apart
	# radii: 5 + 5 = 10, so they're just touching (margin adds tiny overlap)
	var result: bool = _Physics.circles_ahead(a_pos, 5.0, b_pos, 5.0)
	assert_bool(result).is_true()


## Circles whose centers are closer than sum-of-radii should collide.
func test_circles_ahead_returns_true_when_overlapping() -> void:
	var a_pos: Vector2 = Vector2.ZERO
	var b_pos: Vector2 = Vector2.RIGHT * 5.0 # 5 units apart, radii 5+5=10
	var result: bool = _Physics.circles_ahead(a_pos, 5.0, b_pos, 5.0)
	assert_bool(result).is_true()


## Circles clearly separated should not collide.
func test_circles_ahead_returns_false_when_separated() -> void:
	var a_pos: Vector2 = Vector2.ZERO
	var b_pos: Vector2 = Vector2.RIGHT * 100.0 # 100 units apart, radii 5+5=10
	var result: bool = _Physics.circles_ahead(a_pos, 5.0, b_pos, 5.0)
	assert_bool(result).is_false()

# ============================================================================
# Momentum Calculation
# ============================================================================


## Momentum = speed * mass, straightforward.
func test_momentum_is_speed_times_mass() -> void:
	var result: float = _Physics.momentum(10.0, 5.0)
	assert_float(result).is_equal_approx(50.0, 0.001)


## Stationary entity has zero momentum.
func test_momentum_zero_speed_yields_zero_momentum() -> void:
	var result: float = _Physics.momentum(0.0, 100.0)
	assert_float(result).is_equal_approx(0.0, 0.001)


## Massless entity has zero momentum.
func test_momentum_zero_mass_yields_zero_momentum() -> void:
	var result: float = _Physics.momentum(50.0, 0.0)
	assert_float(result).is_equal_approx(0.0, 0.001)


## A full train (heavy) has more momentum than engine-only at same speed.
func test_heavier_train_has_more_momentum_at_same_speed() -> void:
	var engine_momentum: float = _Physics.momentum(10.0, 10.0)
	var full_train_momentum: float = _Physics.momentum(10.0, 100.0)
	assert_bool(full_train_momentum > engine_momentum).is_true()


## 5x weight -> 5x momentum at same speed.
func test_momentum_scales_linearly_with_weight() -> void:
	var momentum: float = _Physics.momentum(10.0, 50.0)
	assert_float(momentum).is_equal_approx(500.0, 0.001)

# ============================================================================
# Weight-Scaled Acceleration
# ============================================================================


## More weight -> less acceleration.
func test_acceleration_inversely_scales_with_weight() -> void:
	var light_acc: float = _Physics.effective_acceleration(100.0, 10.0)
	var heavy_acc: float = _Physics.effective_acceleration(100.0, 100.0)
	assert_bool(light_acc > heavy_acc).is_true()
	assert_float(light_acc).is_equal_approx(10.0, 0.001)
	assert_float(heavy_acc).is_equal_approx(1.0, 0.001)


## Same weight -> same acceleration for same engine power.
func test_acceleration_same_weight_same_result() -> void:
	var acc1: float = _Physics.effective_acceleration(200.0, 50.0)
	var acc2: float = _Physics.effective_acceleration(200.0, 50.0)
	assert_float(acc1).is_equal_approx(acc2, 0.001)


## Doubling weight halves acceleration (inverse proportionality).
func test_acceleration_double_weight_halves_acceleration() -> void:
	var base: float = _Physics.effective_acceleration(100.0, 10.0)
	var double: float = _Physics.effective_acceleration(100.0, 20.0)
	assert_float(base).is_equal_approx(double * 2.0, 0.001)


## Massless entity accelerates infinitely (edge case).
func test_zero_weight_returns_inf_acceleration() -> void:
	var result: float = _Physics.effective_acceleration(100.0, 0.0)
	assert_bool(is_inf(result)).is_true()

# ============================================================================
# Weight-Scaled Deceleration
# ============================================================================


## More weight -> less deceleration (harder to stop).
func test_deceleration_inversely_scales_with_weight() -> void:
	var light_dec: float = _Physics.effective_deceleration(100.0, 10.0)
	var heavy_dec: float = _Physics.effective_deceleration(100.0, 100.0)
	assert_bool(light_dec > heavy_dec).is_true()
	assert_float(light_dec).is_equal_approx(10.0, 0.001)
	assert_float(heavy_dec).is_equal_approx(1.0, 0.001)


## The formula is the same for both acceleration and deceleration.
func test_deceleration_same_as_acceleration_formula() -> void:
	var acc: float = _Physics.effective_acceleration(50.0, 25.0)
	var dec: float = _Physics.effective_deceleration(50.0, 25.0)
	assert_float(acc).is_equal_approx(dec, 0.001)

# ============================================================================
# Speed Update (Throttle / Brake / Friction)
# ============================================================================


## Throttling should increase speed by acceleration * delta.
func test_throttle_increases_speed() -> void:
	var new_speed: float = _Physics.update_speed(0.0, 5.0, 5.0, true, false, 100.0, 1.0)
	assert_float(new_speed).is_equal_approx(5.0, 0.001)


## Braking should decrease speed by deceleration * delta.
func test_brake_decreases_speed() -> void:
	var new_speed: float = _Physics.update_speed(20.0, 5.0, 10.0, false, true, 100.0, 1.0)
	assert_float(new_speed).is_equal_approx(10.0, 0.001)


## With no throttle or brake, speed decreases slowly (rolling friction).
func test_no_input_applies_friction() -> void:
	var new_speed: float = _Physics.update_speed(20.0, 5.0, 10.0, false, false, 100.0, 1.0)
	# Friction = deceleration * ROLLING_FRICTION_FACTOR * delta = 10.0 * 0.1 * 1.0 = 1.0
	assert_float(new_speed).is_equal_approx(19.0, 0.001)


## Speed cannot exceed max_speed.
func test_speed_is_clamped_to_max() -> void:
	var new_speed: float = _Physics.update_speed(95.0, 10.0, 5.0, true, false, 100.0, 1.0)
	assert_float(new_speed).is_equal_approx(100.0, 0.001)


## Speed cannot go below zero (braking doesn't reverse).
func test_speed_is_clamped_to_zero() -> void:
	var new_speed: float = _Physics.update_speed(3.0, 5.0, 10.0, false, true, 100.0, 1.0)
	assert_float(new_speed).is_equal_approx(0.0, 0.001)


## Throttle takes priority when specified.
func test_throttle_takes_priority() -> void:
	var new_speed: float = _Physics.update_speed(0.0, 5.0, 20.0, true, false, 100.0, 1.0)
	# Throttle: speed += 5 * 1 = 5
	assert_float(new_speed).is_equal_approx(5.0, 0.001)


## Speed change is proportional to delta time.
func test_small_delta_proportional_speed_change() -> void:
	var speed_1s: float = _Physics.update_speed(0.0, 10.0, 5.0, true, false, 100.0, 1.0)
	var speed_0_5s: float = _Physics.update_speed(0.0, 10.0, 5.0, true, false, 100.0, 0.5)
	assert_float(speed_1s).is_equal_approx(speed_0_5s * 2.0, 0.001)

# ============================================================================
# Stopping Distance
# ============================================================================


## stopping_distance = v^2 / (2a).
func test_stopping_distance_formula() -> void:
	# v=20, a=10 -> d = 400 / 20 = 20
	var dist: float = _Physics.stopping_distance(20.0, 10.0)
	assert_float(dist).is_equal_approx(20.0, 0.001)


## Already stopped -> zero distance.
func test_stopping_distance_zero_speed() -> void:
	var dist: float = _Physics.stopping_distance(0.0, 10.0)
	assert_float(dist).is_equal_approx(0.0, 0.001)


## No deceleration -> infinite stopping distance (can't stop).
func test_stopping_distance_zero_deceleration() -> void:
	var dist: float = _Physics.stopping_distance(10.0, 0.0)
	assert_bool(is_inf(dist)).is_true()


## Stopping distance scales with v^2, so doubling speed quadruples distance.
func test_double_speed_quadruples_stopping_distance() -> void:
	var d1: float = _Physics.stopping_distance(10.0, 10.0)
	var d2: float = _Physics.stopping_distance(20.0, 10.0)
	assert_float(d2).is_equal_approx(d1 * 4.0, 0.001)

# ============================================================================
# Elastic Collision Resolution
# ============================================================================


## Two equal masses: one moving at 10, one stationary -> they exchange.
func test_elastic_collision_equal_masses_exchange_velocities() -> void:
	var body_a: Dictionary = _make_body_dict(10.0, Vector2(10.0, 0.0))
	var body_b: Dictionary = _make_body_dict(10.0, Vector2.ZERO)
	var pos_a: Vector2 = Vector2.ZERO
	var pos_b: Vector2 = Vector2.RIGHT * 5.0

	_Physics.elastic_collision(body_a, body_b, pos_a, pos_b)

	# After 1D elastic collision with equal masses:
	# body_a should have 0, body_b should have 10
	assert_float(body_a["velocity"].x).is_equal_approx(0.0, 0.001)
	assert_float(body_b["velocity"].x).is_equal_approx(10.0, 0.001)


## A heavy train hits a light enemy: train barely slows, enemy flies off.
func test_elastic_collision_heavy_hits_light() -> void:
	var body_a: Dictionary = _make_body_dict(100.0, Vector2(5.0, 0.0)) # Heavy train
	var body_b: Dictionary = _make_body_dict(1.0, Vector2.ZERO) # Light enemy
	var pos_a: Vector2 = Vector2.ZERO
	var pos_b: Vector2 = Vector2.RIGHT * 3.0

	_Physics.elastic_collision(body_a, body_b, pos_a, pos_b)

	# Train should slow slightly, enemy should fly off fast
	assert_bool(body_a["velocity"].x < 5.0).is_true()
	assert_bool(body_a["velocity"].x > 4.0).is_true()
	assert_bool(body_b["velocity"].x > 8.0).is_true()


## A light enemy hits a heavy train: enemy bounces back, train barely affected.
func test_elastic_collision_light_hits_heavy() -> void:
	var body_a: Dictionary = _make_body_dict(1.0, Vector2(5.0, 0.0)) # Light enemy coming at train
	var body_b: Dictionary = _make_body_dict(100.0, Vector2.ZERO) # Heavy stationary train
	var pos_a: Vector2 = Vector2.ZERO
	var pos_b: Vector2 = Vector2.RIGHT * 3.0

	_Physics.elastic_collision(body_a, body_b, pos_a, pos_b)

	# Enemy should bounce backward (x velocity becomes negative)
	assert_bool(body_a["velocity"].x < 0.0).is_true()
	# Train should barely move (heavy mass absorbs little)
	assert_bool(absf(body_b["velocity"].x) < 0.5).is_true()


## If bodies are already moving apart, no collision impulse.
func test_elastic_collision_already_separating() -> void:
	var body_a: Dictionary = _make_body_dict(10.0, Vector2(-5.0, 0.0)) # Moving left
	var body_b: Dictionary = _make_body_dict(10.0, Vector2(5.0, 0.0)) # Moving right
	var pos_a: Vector2 = Vector2.ZERO
	var pos_b: Vector2 = Vector2.RIGHT * 3.0

	_Physics.elastic_collision(body_a, body_b, pos_a, pos_b)

	assert_float(body_a["velocity"].x).is_equal_approx(-5.0, 0.001)
	assert_float(body_b["velocity"].x).is_equal_approx(5.0, 0.001)


## Zero mass bodies should not produce division errors.
func test_elastic_collision_zero_mass_noop() -> void:
	var body_a: Dictionary = _make_body_dict(0.0, Vector2(5.0, 0.0))
	var body_b: Dictionary = _make_body_dict(10.0, Vector2.ZERO)
	var pos_a: Vector2 = Vector2.ZERO
	var pos_b: Vector2 = Vector2.RIGHT * 3.0

	# Should not crash or produce NaN
	_Physics.elastic_collision(body_a, body_b, pos_a, pos_b)

	assert_bool(body_a["velocity"].x > -INF).is_true()
	assert_bool(body_b["velocity"].x > -INF).is_true()

# ============================================================================
# Train Push (specialized collision)
# ============================================================================


## Train pushes a stationary enemy forward.
func test_train_push_enemy_bounces_forward() -> void:
	var result: Dictionary = _Physics.train_push(
		100.0, # train_mass
		5.0, # train_speed
		2.0, # target_mass
		Vector2.ZERO, # target_velocity (stationary)
		Vector2.RIGHT, # direction
	)

	assert_bool(result["target_new_velocity"].x > 0.0).is_true()
	assert_bool(result["train_new_speed"] < 5.0).is_true()


## Pushing a heavier enemy slows the train more.
func test_train_push_heavy_enemy_slows_train_more() -> void:
	var result_light: Dictionary = _Physics.train_push(100.0, 5.0, 1.0, Vector2.ZERO, Vector2.RIGHT)
	var result_heavy: Dictionary = _Physics.train_push(100.0, 5.0, 50.0, Vector2.ZERO, Vector2.RIGHT)

	assert_bool(result_heavy["train_new_speed"] < result_light["train_new_speed"]).is_true()


## If enemy is already moving away from train, no meaningful push.
func test_train_push_enemy_moving_away() -> void:
	var result: Dictionary = _Physics.train_push(
		100.0,
		5.0, # train
		2.0,
		Vector2.RIGHT * 10, # enemy moving away at 10 m/s
		Vector2.RIGHT,
	)

	assert_float(result["train_new_speed"]).is_equal_approx(5.0, 0.001)
	assert_float(result["target_new_velocity"].x).is_equal_approx(10.0, 0.001)


## Direction vector is normalized regardless of length.
func test_train_push_direction_normalization() -> void:
	var result1: Dictionary = _Physics.train_push(100.0, 5.0, 2.0, Vector2.ZERO, Vector2.RIGHT * 100)
	var result2: Dictionary = _Physics.train_push(100.0, 5.0, 2.0, Vector2.ZERO, Vector2.RIGHT)

	# Results should be identical since direction is normalized
	assert_float(result1["train_new_speed"]) \
			.is_equal_approx(result2["train_new_speed"], 0.001)
	assert_float(result1["target_new_velocity"].x) \
			.is_equal_approx(result2["target_new_velocity"].x, 0.001)

# ============================================================================
# Weight Scaling Feel - Gameplay Integration
# ============================================================================


## A full train (50 units weight) accelerates slower than engine-only (10 units).
func test_full_train_acceleration_is_slower() -> void:
	var light_acc: float = _Physics.effective_acceleration(200.0, 10.0)
	var heavy_acc: float = _Physics.effective_acceleration(200.0, 50.0)

	assert_bool(heavy_acc < light_acc).is_true()
	assert_float(light_acc).is_equal_approx(20.0, 0.001)
	assert_float(heavy_acc).is_equal_approx(4.0, 0.001)


## A full train takes longer to stop than engine-only.
func test_full_train_braking_distance_is_longer() -> void:
	var light_stop: float = _Physics.stopping_distance(
		10.0,
		_Physics.effective_deceleration(100.0, 10.0),
	)
	var heavy_stop: float = _Physics.stopping_distance(
		10.0,
		_Physics.effective_deceleration(100.0, 50.0),
	)

	assert_bool(heavy_stop > light_stop).is_true()
	assert_float(light_stop).is_equal_approx(5.0, 0.001)


## 5x weight should give 5x momentum, confirming linear scaling.
func test_momentum_ratio_matches_weight_ratio() -> void:
	var engine_momentum: float = _Physics.momentum(10.0, 10.0)
	var full_train_momentum: float = _Physics.momentum(10.0, 50.0)

	assert_bool(full_train_momentum > engine_momentum).is_true()
	assert_float(full_train_momentum / engine_momentum).is_equal_approx(5.0, 0.001)
