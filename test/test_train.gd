extends GdUnitTestSuite

# --- Helpers ---

## Create a Train with default parameters for testing.
func _make_train(
		engine_power: float = 200.0,
		brake_force: float = 100.0,
		max_speed: float = 100.0,
		max_health: float = 100.0,
		initial_speed: float = 0.0,
		initial_segment_index: int = 0,
):
	var train = Train.new()
	train.initialize(
		max_speed,
		engine_power,
		brake_force,
		max_health,
		10.0,
		initial_speed,
		initial_segment_index,
	)
	return train


## Create a Train with an attached car.
func _make_train_with_car(
		car_type: String,
		car_weight: float = 5.0,
		car_bogie_offset: Vector2 = Vector2(0.5, 0.0),
):
	var train = _make_train()
	var car = Car.new()
	car.initialize(car_type, car_weight, car_bogie_offset)
	train.add_car(car)
	return { "a": train, "b": car }


## Create a dummy Track with one straight horizontal segment at origin.
## For multi-segment tests, use _make_multi_segment_track().
func _make_dummy_track():
	var track = Track.new()
	track.initialize(100.0, 100)
	var seg = track.create_straight_segment(Vector2i.ZERO, true)
	track.try_place_segment(Vector2i.ZERO, seg)
	return track


## Create a Track with two consecutive straight horizontal segments.
func _make_multi_segment_track():
	var track = Track.new()
	track.initialize(100.0, 100)
	var seg0 = track.create_straight_segment(Vector2i.ZERO, true)
	track.try_place_segment(Vector2i.ZERO, seg0)
	var seg1 = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg1)
	return track

# ============================================================================
# Train Initialization
# ============================================================================


## A new train starts with the engine power, brake force, max speed, and max health specified.
func test_train_initializes_with_correct_parameters():
	var train = _make_train(200.0, 100.0, 80.0, 50.0)
	assert_float(train.engine_power).is_equal_approx(200.0, 0.001)
	assert_float(train.brake_force).is_equal_approx(100.0, 0.001)
	assert_float(train.max_speed).is_equal_approx(80.0, 0.001)
	assert_float(train.max_health).is_equal_approx(50.0, 0.001)


## A new train starts at zero speed.
func test_train_starts_at_zero_speed():
	var train = _make_train()
	assert_float(train.speed).is_equal_approx(0.0, 0.001)


## A new train starts with segment index 0.
func test_train_starts_at_segment_index_zero():
	var train = _make_train()
	assert_int(train.segment_index).is_equal(0)


## A new train starts with segment progress 0.0.
func test_train_starts_with_zero_segment_progress():
	var train = _make_train()
	assert_float(train.segment_progress).is_equal_approx(0.0, 0.001)


## A new train starts with no cars.
func test_train_starts_with_no_cars():
	var train = _make_train()
	assert_int(train.get_car_count()).is_equal(0)


## A new train starts with total_weight equal to engine base weight.
func test_train_total_weight_equals_engine_weight():
	var train = _make_train()
	assert_float(train.total_weight).is_equal_approx(10.0, 0.001)


## A new train starts with health equal to max_health.
func test_train_health_equals_max_health():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 0.0, 0)
	assert_float(train.health).is_equal_approx(100.0, 0.001)


## A new train starts disabled.
func test_train_starts_disabled():
	var train = _make_train()
	assert_bool(train.enabled).is_false()

# ============================================================================
# Car Attachment
# ============================================================================


## Adding a car increases total_weight by the car's weight.
func test_adding_car_increases_total_weight():
	var train = _make_train()
	var car = Car.new()
	car.initialize("cargo", 5.0, Vector2.ZERO)
	train.add_car(car)
	assert_float(train.total_weight).is_equal_approx(15.0, 0.001)


## Adding a car increments car count.
func test_adding_car_increases_count():
	var train = _make_train()
	var car = Car.new()
	car.initialize("cannon", 8.0, Vector2.ZERO)
	train.add_car(car)
	assert_int(train.get_car_count()).is_equal(1)


## Adding two cars: total_weight is engine + both cars.
func test_adding_two_cars():
	var train = _make_train()
	var car1 = Car.new()
	car1.initialize("cargo", 5.0, Vector2.ZERO)
	var car2 = Car.new()
	car2.initialize("cargo", 10.0, Vector2.ZERO)
	train.add_car(car1)
	train.add_car(car2)
	assert_float(train.total_weight).is_equal_approx(25.0, 0.001)
	assert_int(train.get_car_count()).is_equal(2)


## Removing a car decreases total_weight.
func test_removing_car_decreases_total_weight():
	var pair = _make_train_with_car("cargo", 5.0)
	var train = pair["a"]
	var car = pair["b"]
	assert_float(train.total_weight).is_equal_approx(15.0, 0.001)
	train.remove_car(car)
	assert_float(train.total_weight).is_equal_approx(10.0, 0.001)
	assert_int(train.get_car_count()).is_equal(0)


## Removing a car that isn't attached is a no-op.
func test_removing_nonexistent_car_is_noop():
	var train = _make_train()
	var car = Car.new()
	car.initialize("cargo", 5.0, Vector2.ZERO)
	train.remove_car(car)
	assert_int(train.get_car_count()).is_equal(0)
	assert_float(train.total_weight).is_equal_approx(10.0, 0.001)


## Adding a car updates total_weight via _calculate_total_weight.
func test_add_car_updates_total_weight():
	var train = _make_train()
	var heavy_car = Car.new()
	heavy_car.initialize("cargo", 50.0, Vector2.ZERO)
	train.add_car(heavy_car)
	assert_float(train.total_weight).is_equal_approx(60.0, 0.001)

# ============================================================================
# Speed Update (via Physics)
# ============================================================================


## Throttling a stationary train increases speed.
func test_throttle_increases_speed():
	var train = _make_train()
	train.enabled = true
	train.update_input(true, false)
	train.update_speed(1.0)
	assert_float(train.speed).is_equal_approx(20.0, 0.001)


## Braking from max_speed decreases speed.
func test_brake_decreases_speed():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 100.0, 0)
	train.enabled = true
	train.update_input(false, true)
	train.update_speed(1.0)
	assert_float(train.speed).is_equal_approx(90.0, 0.001)


## No input: rolling friction slows the train.
func test_no_input_applies_rolling_friction():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 50.0, 0)
	train.update_input(false, false)
	train.update_speed(1.0)
	# Friction = deceleration * ROLLING_FRICTION_FACTOR * delta
	# effective_deceleration = 100.0 / 10.0 = 10.0
	# friction = 10.0 * 0.1 * 1.0 = 1.0
	assert_float(train.speed).is_equal_approx(49.0, 0.001)


## Speed cannot exceed max_speed.
func test_speed_capped_at_max_speed():
	var train = _make_train(200.0, 100.0, 50.0, 100.0, 45.0, 0)
	train.enabled = true
	train.update_input(true, false)
	train.update_speed(1.0)
	# effective_acceleration = 200.0 / 10.0 = 20.0
	# speed would be 65.0, but capped at 50.0
	assert_float(train.speed).is_equal_approx(50.0, 0.001)


## Speed cannot go below zero.
func test_speed_clamped_to_zero():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 5.0, 0)
	train.enabled = true
	train.update_input(false, true)
	train.update_speed(1.0)
	assert_float(train.speed).is_equal_approx(0.0, 0.001)


## A heavier train (with cars) accelerates slower than engine-only.
func test_heavier_train_accelerates_slower():
	var engine = _make_train()
	engine.enabled = true
	engine.update_input(true, false)
	engine.update_speed(1.0)

	var pair = _make_train_with_car("cargo", 40.0)
	var heavy = pair["a"]
	heavy.enabled = true
	heavy.update_input(true, false)
	heavy.update_speed(1.0)

	assert_bool(heavy.speed < engine.speed).is_true()


## A heavier train decelerates slower than engine-only.
func test_heavier_train_decelerates_slower():
	var engine = _make_train(200.0, 100.0, 100.0, 100.0, 50.0, 0)
	engine.enabled = true
	engine.update_input(false, true)
	engine.update_speed(1.0)

	var pair = _make_train_with_car("cargo", 40.0)
	pair["a"].enabled = true
	pair["a"].initialize(100.0, 200.0, 100.0, 50.0, 50.0, 50.0, 0) # Reset with same initial speed
	pair["a"].update_input(false, true)
	pair["a"].update_speed(1.0)

	assert_bool(pair["a"].speed > engine.speed).is_true()


## Multiple cars compound the weight effect: 5 cars accelerate much slower.
func test_five_cars_significantly_slows_acceleration():
	var engine = _make_train()
	engine.enabled = true
	engine.update_input(true, false)
	engine.update_speed(1.0)

	var full_train = _make_train()
	full_train.enabled = true
	for i in range(5):
		var car = Car.new()
		car.initialize("cargo", 10.0, Vector2.ZERO)
		full_train.add_car(car)
	full_train.update_input(true, false)
	full_train.update_speed(1.0)

	assert_bool(full_train.speed < engine.speed).is_true()
	assert_float(engine.speed).is_equal_approx(20.0, 0.001) # Engine: acc = 200/10 = 20


## A train with cars has more momentum at the same speed.
func test_train_with_cars_has_more_momentum():
	var engine = _make_train()
	engine.speed = 10.0
	var engine_momentum: float = engine.get_momentum()

	var pair = _make_train_with_car("cargo", 40.0)
	pair["a"].speed = 10.0
	var heavy_momentum: float = pair["a"].get_momentum()

	assert_bool(heavy_momentum > engine_momentum).is_true()
	assert_float(engine_momentum).is_equal_approx(100.0, 0.001) # 10.0 * 10.0

# ============================================================================
# Collision Resolution
# ============================================================================


## The train pushes a stationary enemy forward.
func test_train_pushes_stationary_enemy():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 10.0, 0)
	var result: Dictionary = train.resolve_collision(
		5.0, # target_mass
		Vector2.ZERO, # target_velocity
		Vector2.RIGHT,
	)
	assert_bool(result["target_new_velocity"].x > 0.0).is_true()
	assert_bool(result["train_new_speed"] < 10.0).is_true()


## A heavy target (bigger than train) slows the train more.
func test_train_heavy_target_slows_more():
	var result1: Dictionary = _make_train(200.0, 100.0, 100.0, 100.0, 10.0, 0).resolve_collision(
		5.0,
		Vector2.ZERO,
		Vector2.RIGHT,
	)
	var result2: Dictionary = _make_train(200.0, 100.0, 100.0, 100.0, 10.0, 0).resolve_collision(
		100.0,
		Vector2.ZERO,
		Vector2.RIGHT,
	)
	assert_bool(result2["train_new_speed"] < result1["train_new_speed"]).is_true()


## The train resolves collision with restitution=0 (inelastic).
func test_train_inelastic_collision_restitution_zero():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 10.0, 0)
	var result: Dictionary = train.resolve_collision(
		10.0,
		Vector2.ZERO,
		Vector2.RIGHT,
		0.0,
	)
	# With restitution=0 (inelastic), less impulse is transferred
	# Train retains MORE speed than elastic case
	var elastic: Dictionary = _make_train(200.0, 100.0, 100.0, 100.0, 10.0, 0).resolve_collision(
		10.0,
		Vector2.ZERO,
		Vector2.RIGHT,
		1.0,
	)
	assert_bool(result["train_new_speed"] > elastic["train_new_speed"]).is_true()


## Enemy moving away from train: no meaningful push.
func test_enemy_moving_away_no_push():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 10.0, 0)
	var result: Dictionary = train.resolve_collision(
		5.0,
		Vector2.RIGHT * 20.0,
		Vector2.RIGHT,
	)
	assert_float(result["train_new_speed"]).is_equal_approx(10.0, 0.001)
	assert_float(result["target_new_velocity"].x).is_equal_approx(20.0, 0.001)

# ============================================================================
# Damage & Health
# ============================================================================


## Taking damage reduces health.
func test_take_damage_reduces_health():
	var train = _make_train(200.0, 100.0, 100.0, 100.0, 0.0, 0)
	train.take_damage(30.0)
	assert_float(train.health).is_equal_approx(70.0, 0.001)


## Health cannot go below zero.
func test_damage_clamped_to_zero_health():
	var train = _make_train(200.0, 100.0, 100.0, 10.0, 0.0, 0)
	train.take_damage(20.0)
	assert_float(train.health).is_equal_approx(0.0, 0.001)


## Damage to a destroyed train is a no-op.
func test_damage_to_destroyed_train_is_noop():
	var train = _make_train(200.0, 100.0, 100.0, 10.0, 0.0, 0)
	train.take_damage(10.0)
	train.take_damage(5.0)
	assert_float(train.health).is_equal_approx(0.0, 0.001)
	assert_bool(train.is_destroyed()).is_true()


## Train is not destroyed immediately.
func test_train_not_destroyed_on_creation():
	var train = _make_train()
	assert_bool(train.is_destroyed()).is_false()


## Train is destroyed when health reaches zero.
func test_train_destroyed_at_zero_health():
	var train = _make_train(200.0, 100.0, 100.0, 10.0, 0.0, 0)
	train.take_damage(10.0)
	assert_bool(train.is_destroyed()).is_true()

# ============================================================================
# Input Handling
# ============================================================================


## Throttle input sets is_throttling true.
func test_throttle_input_sets_throttling():
	var train = _make_train()
	train.enabled = true
	train.update_input(true, false)
	assert_bool(train.is_throttling).is_true()
	assert_bool(train.is_braking).is_false()


## Brake input sets is_braking true.
func test_brake_input_sets_braking():
	var train = _make_train()
	train.enabled = true
	train.update_input(false, true)
	assert_bool(train.is_throttling).is_false()
	assert_bool(train.is_braking).is_true()


## Both throttle and brake: throttle wins (explicit priority).
func test_both_inputs_throttle_wins():
	var train = _make_train()
	train.enabled = true
	train.update_input(true, true)
	assert_bool(train.is_throttling).is_true()
	assert_bool(train.is_braking).is_true() # Both set, but throttle takes priority in update_speed


## Disabled train ignores input.
func test_disabled_train_ignores_input():
	var train = _make_train()
	train.enabled = false
	train.update_input(true, false)
	assert_bool(train.is_throttling).is_false()
	assert_bool(train.is_braking).is_false()

# ============================================================================
# Getters
# ============================================================================


## get_effective_acceleration returns engine_power / total_weight.
func test_get_effective_acceleration():
	var train = _make_train()
	var expected: float = 200.0 / 10.0 # 20.0
	assert_float(train.get_effective_acceleration()).is_equal_approx(expected, 0.001)


## Adding a car reduces effective_acceleration.
func test_effective_acceleration_decreases_with_cars():
	var train = _make_train()
	var initial: float = train.get_effective_acceleration()
	var car = Car.new()
	car.initialize("cargo", 40.0, Vector2.ZERO)
	train.add_car(car)
	assert_bool(train.get_effective_acceleration() < initial).is_true()


## get_effective_deceleration returns brake_force / total_weight.
func test_get_effective_deceleration():
	var train = _make_train()
	var expected: float = 100.0 / 10.0 # 10.0
	assert_float(train.get_effective_deceleration()).is_equal_approx(expected, 0.001)


## Adding a car increases stopping distance.
func test_stopping_distance_increases_with_cars():
	var engine = _make_train(200.0, 100.0, 100.0, 100.0, 20.0, 0)
	engine.enabled = true
	engine.speed = 50.0
	engine.update_input(false, true) # Set braking

	var pair = _make_train_with_car("cargo", 40.0)
	pair["a"].enabled = true
	pair["a"].initialize(100.0, 200.0, 100.0, 20.0, 50.0, 50.0, 0) # Same initial speed
	pair["a"].update_input(false, true)

	assert_bool(pair["a"].get_stopping_distance() > engine.get_stopping_distance()).is_true()


## get_momentum returns speed * total_weight.
func test_get_momentum():
	var train = _make_train()
	train.speed = 10.0
	assert_float(train.get_momentum()).is_equal_approx(100.0, 0.001) # 10 * 10


## get_car_count returns the number of attached cars.
func test_get_car_count():
	var train = _make_train()
	assert_int(train.get_car_count()).is_equal(0)
	var car = Car.new()
	car.initialize("cargo", 5.0, Vector2.ZERO)
	train.add_car(car)
	assert_int(train.get_car_count()).is_equal(1)

# ============================================================================
# get_state() for serialization
# ============================================================================


## get_state returns a dictionary with all train state.
func test_get_state_returns_valid_dictionary():
	var train = _make_train()
	var state: Dictionary = train.get_state()
	assert_bool(state.has("position")).is_true()
	assert_bool(state.has("speed")).is_true()
	assert_bool(state.has("health")).is_true()
	assert_bool(state.has("segment_index")).is_true()
	assert_bool(state.has("total_weight")).is_true()
	assert_bool(state.has("enabled")).is_true()


## get_state captures the current speed.
func test_get_state_captures_speed():
	var train = _make_train()
	train.speed = 42.0
	var state: Dictionary = train.get_state()
	assert_float(state["speed"]).is_equal_approx(42.0, 0.001)

# ============================================================================
# Segment Movement
# ============================================================================


## update_position moves the train along the track.
func test_update_position_advances_along_track() -> void:
	var train = _make_train()
	train.enabled = true
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var track = _make_dummy_track()
	train.speed = 64.0 # 1 cell per second
	train.update_position(track, 1.0)
	assert_float(train.segment_progress).is_equal_approx(1.0, 0.001)


## update_position advances segment_index when progress reaches 1.0.
func test_update_position_advances_segment_index() -> void:
	var train = _make_train()
	train.enabled = true
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var track = _make_multi_segment_track()
	train.speed = 64.0
	train.segment_progress = 0.5
	train.update_position(track, 1.0)
	assert_int(train.segment_index).is_equal(1)
	assert_float(train.segment_progress).is_equal_approx(0.5, 0.001)


## update_position with zero speed does not move.
func test_update_position_zero_speed_no_movement() -> void:
	var train = _make_train()
	var track = _make_dummy_track()
	train.speed = 0.0
	train.update_position(track, 1.0)
	assert_float(train.segment_progress).is_equal_approx(0.0, 0.001)
	assert_int(train.segment_index).is_equal(0)


## update_position on empty track does nothing.
func test_update_position_empty_track_no_movement() -> void:
	var train = _make_train()
	train.enabled = true
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var track = Track.new()
	track.initialize(100.0, 100)
	train.speed = 64.0
	train.update_position(track, 1.0)
	assert_int(train.segment_index).is_equal(0)


## update_orientation returns a valid rotation angle.
func test_update_orientation_returns_valid_angle() -> void:
	var train = _make_train()
	var track = _make_dummy_track()
	var angle: float = train.update_orientation(track)
	assert_bool(angle >= -PI).is_true()
	assert_bool(angle <= PI).is_true()


## update_orientation on straight horizontal segment returns 0.
func test_update_orientation_straight_horizontal_is_zero() -> void:
	var train = _make_train()
	var track = _make_dummy_track()
	var angle: float = train.update_orientation(track)
	assert_float(angle).is_equal_approx(0.0, 0.001)
