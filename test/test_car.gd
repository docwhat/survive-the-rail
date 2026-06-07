extends GdUnitTestSuite

# --- Helpers ---

## Create a dummy track with one straight horizontal segment at origin.
func _make_dummy_track():
	var track = Track.new()
	track.initialize(100.0, 100)
	var seg = track.create_straight_segment(Vector2i.ZERO, true)
	track.try_place_segment(Vector2i.ZERO, seg)
	return track


## Create a basic cargo car for testing.
func _make_cargo(weight: float = 5.0):
	var car = Car.new()
	car.initialize("cargo", weight, Vector2.ZERO)
	return car


## Create a cannon car for testing.
func _make_cannon():
	var car = Car.new()
	car.initialize("cannon", 8.0, Vector2(0.5, 0.0))
	return car

# ============================================================================
# Car Initialization
# ============================================================================


## A car initializes with the correct type, weight, and bogie offset.
func test_car_initializes_correctly() -> void:
	var car = _make_cargo(15.0)
	assert_str(car.car_type).is_equal("cargo")
	assert_float(car.weight).is_equal_approx(15.0, 0.001)
	assert_float(car.bogie_offset.x).is_equal_approx(0.0, 0.001)
	assert_float(car.bogie_offset.y).is_equal_approx(0.0, 0.001)


## A car starts with 10.0 health.
func test_car_starts_with_default_health() -> void:
	var car = _make_cargo()
	assert_float(car.health).is_equal_approx(10.0, 0.001)


## A car starts with level 0.
func test_car_starts_at_level_zero() -> void:
	var car = _make_cargo()
	assert_int(car.level).is_equal(0)


## A car starts with body_rotation 0.0.
func test_car_starts_with_zero_rotation() -> void:
	var car = _make_cargo()
	assert_float(car.body_rotation).is_equal_approx(0.0, 0.001)


## A car's category defaults to "Utility".
func test_car_defaults_to_utility_category() -> void:
	var car = _make_cargo()
	assert_str(car.category).is_equal("Utility")

# ============================================================================
# Weight
# ============================================================================


## get_weight returns the car's weight.
func test_get_weight_returns_car_weight() -> void:
	var car = _make_cargo(25.0)
	assert_float(car.get_weight()).is_equal_approx(25.0, 0.001)


## Adding a car with 50.0 weight gives 60.0 total (10.0 engine + 50.0 car).
func test_heavy_car_total_weight() -> void:
	var train = Train.new()
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var car = _make_cargo(50.0)
	train.add_car(car)
	assert_float(train.total_weight).is_equal_approx(60.0, 0.001)


## Adding multiple cars: total weight is engine + all cars.
func test_total_weight_with_multiple_cars() -> void:
	var train = Train.new()
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var c1 = _make_cargo(5.0)
	var c2 = _make_cargo(10.0)
	var c3 = _make_cargo(15.0)
	train.add_car(c1)
	train.add_car(c2)
	train.add_car(c3)
	assert_float(train.total_weight).is_equal_approx(40.0, 0.001)


## Weight-based effective acceleration is lower for heavier trains.
func test_heavy_train_has_lower_effective_acceleration() -> void:
	var train = Train.new()
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var car = _make_cargo(90.0)
	train.add_car(car)
	var expected_accel: float = 200.0 / 100.0
	assert_float(train.get_effective_acceleration()).is_equal_approx(expected_accel, 0.001)


## Weight-based effective deceleration is lower for heavier trains.
func test_heavy_train_has_lower_effective_deceleration() -> void:
	var train = Train.new()
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	var car = _make_cargo(90.0)
	train.add_car(car)
	var expected_decel: float = 100.0 / 100.0
	assert_float(train.get_effective_deceleration()).is_equal_approx(expected_decel, 0.001)


## get_weight_with_upgrades returns unmodified weight at level 0.
func test_get_weight_with_upgrades_at_level_zero() -> void:
	var car = _make_cargo(10.0)
	assert_float(car.get_weight_with_upgrades()).is_equal_approx(10.0, 0.001)


## get_weight_with_upgrades adds 10% per level.
func test_get_weight_with_upgrades_at_level_one() -> void:
	var car = _make_cargo(10.0)
	car.level = 1
	assert_float(car.get_weight_with_upgrades()).is_equal_approx(11.0, 0.001)


## get_weight_with_upgrades at level 2 adds 20%.
func test_get_weight_with_upgrades_at_level_two() -> void:
	var car = _make_cargo(10.0)
	car.level = 2
	assert_float(car.get_weight_with_upgrades()).is_equal_approx(12.0, 0.001)


## get_weight_with_upgrades at level 5 adds 50%.
func test_get_weight_with_upgrades_at_level_five() -> void:
	var car = _make_cargo(10.0)
	car.level = 5
	assert_float(car.get_weight_with_upgrades()).is_equal_approx(15.0, 0.001)

# ============================================================================
# Health & Damage
# ============================================================================


## Taking damage reduces health by the damage amount.
func test_take_damage_reduces_health() -> void:
	var car = _make_cargo()
	car.take_damage(5.0)
	assert_float(car.health).is_equal_approx(5.0, 0.001)


## Health cannot go below zero.
func test_damage_clamped_to_zero() -> void:
	var car = _make_cargo()
	car.take_damage(20.0)
	assert_float(car.health).is_equal_approx(0.0, 0.001)


## is_destroyed returns false when health > 0.
func test_not_destroyed_at_positive_health() -> void:
	var car = _make_cargo()
	assert_bool(car.is_destroyed()).is_false()


## is_destroyed returns true at health 0.
func test_destroyed_at_zero_health() -> void:
	var car = _make_cargo()
	car.take_damage(10.0)
	assert_bool(car.is_destroyed()).is_true()


## Taking no damage leaves health at 10.0.
func test_no_damage_keeps_default_health() -> void:
	var car = _make_cargo()
	car.take_damage(0.0)
	assert_float(car.health).is_equal_approx(10.0, 0.001)


## Multiple small damages accumulate correctly.
func test_multiple_damages_accumulate() -> void:
	var car = _make_cargo()
	car.take_damage(3.0)
	car.take_damage(4.0)
	car.take_damage(5.0)
	assert_float(car.health).is_equal_approx(0.0, 0.001)

# ============================================================================
# Pivot Animation
# ============================================================================


## On a straight segment, pivot angle is 0.0.
func test_pivot_angle_on_straight_segment() -> void:
	var car = _make_cargo()
	var track = _make_dummy_track()
	var segments: Array[TrackSegment] = track.get_segments()
	var seg = segments[0]
	var angle: float = car.calculate_pivot_angle(seg, 5, 0)
	assert_float(angle).is_equal_approx(0.0, 0.001)


## On a curve segment, the first car gets full 90-degree rotation.
func test_pivot_angle_first_car_on_curve() -> void:
	var car = _make_cargo()
	var track = _make_dummy_track()
	var curve_seg = track.create_curve_segment(
		Vector2i(1, 0),
		[Vector2.RIGHT, Vector2.DOWN],
	)
	var angle: float = car.calculate_pivot_angle(curve_seg, 5, 0)
	assert_float(angle).is_equal_approx(PI / 2.0, 0.001)


## Subsequent cars get reduced pivot rotation.
func test_pivot_angle_later_cars_are_reduced() -> void:
	var car = _make_cargo()
	var track = _make_dummy_track()
	var curve_seg = track.create_curve_segment(
		Vector2i(1, 0),
		[Vector2.RIGHT, Vector2.DOWN],
	)
	var first_angle: float = car.calculate_pivot_angle(curve_seg, 5, 0)
	var second_angle: float = car.calculate_pivot_angle(curve_seg, 5, 1)
	assert_bool(second_angle < first_angle).is_true()


## The last car has minimal pivot rotation.
func test_pivot_angle_last_car_is_small() -> void:
	var car = _make_cargo()
	var track = _make_dummy_track()
	var curve_seg = track.create_curve_segment(
		Vector2i(1, 0),
		[Vector2.RIGHT, Vector2.DOWN],
	)
	var last_angle: float = car.calculate_pivot_angle(curve_seg, 5, 4)
	assert_bool(last_angle < PI / 4.0).is_true()


## With only one car (total_cars=1), scale is 1.0 and the car pivots fully.
func test_pivot_angle_single_car_fills_full_rotation() -> void:
	var car = _make_cargo()
	var track = _make_dummy_track()
	var curve_seg = track.create_curve_segment(
		Vector2i(1, 0),
		[Vector2.RIGHT, Vector2.DOWN],
	)
	var angle: float = car.calculate_pivot_angle(curve_seg, 1, 0)
	assert_float(angle).is_equal_approx(PI / 2.0, 0.001)

# ============================================================================
# State Serialization
# ============================================================================


## get_state returns a dictionary with all car state fields.
func test_get_state_returns_all_fields() -> void:
	var car = _make_cargo()
	var state: Dictionary = car.get_state()
	assert_bool(state.has("car_type")).is_true()
	assert_bool(state.has("category")).is_true()
	assert_bool(state.has("weight")).is_true()
	assert_bool(state.has("health")).is_true()
	assert_bool(state.has("level")).is_true()
	assert_bool(state.has("bogie_offset")).is_true()
	assert_bool(state.has("body_rotation")).is_true()
	assert_bool(state.has("coupling_offset")).is_true()


## get_state captures the car type correctly.
func test_get_state_captures_car_type() -> void:
	var car = _make_cargo()
	car.level = 3
	var state: Dictionary = car.get_state()
	assert_str(state["car_type"]).is_equal("cargo")
	assert_int(state["level"]).is_equal(3)
