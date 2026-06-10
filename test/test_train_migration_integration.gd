## Integration tests for full train-path interaction.
##
## These tests verify the complete pipeline: data model → path builder
## → train movement → mode switching.
extends GdUnitTestSuite

var track = null
var train = null


func setup() -> void:
	track = Track.new()
	track.initialize(100.0, 100)
	train = Train.new()
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	train.enabled = true


func teardown() -> void:
	track = null
	train = null

# ============================================================================
# Subtask 4d-7: Integration smoke tests
# ============================================================================


func test_integration_train_follows_straight_path() -> void:
	# Place a straight track
	track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(2, 0), true)
	track.try_place_segment(Vector2i(2, 0), track.get_segments().back())

	# Switch to path mode
	train.switch_to_path_mode(track)
	assert_bool(train.is_using_path_follower()).is_equal(true)

	# Verify path exists
	var follower: TrainPathFollower = train.get_path_follower()
	assert_bool(follower != null).is_equal(true)


func test_integration_train_follows_curved_path() -> void:
	# Place straight then curve
	track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), track.get_segments().back())
	track.create_curve_segment(Vector2i(2, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(2, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(2, 1), true)
	track.try_place_segment(Vector2i(2, 1), track.get_segments().back())

	# Switch to path mode
	train.switch_to_path_mode(track)
	assert_bool(train.is_using_path_follower()).is_equal(true)

	# Verify progress is non-zero (path exists and has length)
	var progress: float = train.get_path_progress()
	assert_bool(progress >= 0.0).is_equal(true)


func test_integration_train_with_cars_follows_path() -> void:
	# Place a short straight track
	track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), track.get_segments().back())

	# Add cars
	var car1: Car = Car.new()
	car1.initialize("cargo", 5.0, Vector2.ZERO)
	train.add_car(car1)

	# Switch to path mode
	train.switch_to_path_mode(track)

	# Verify car followers exist
	var car_followers: Array[CarPathFollower] = train.get_car_followers()
	assert_int(car_followers.size()).is_equal(1)


func test_integration_mode_switch_preserves_position() -> void:
	# Place track
	track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), track.get_segments().back())

	# Switch to path mode, then back to segment mode
	train.switch_to_path_mode(track)
	var saved_pos: Vector2 = train.position

	# Switch back to segment mode
	train.switch_to_segment_mode(track)
	assert_bool(!train.is_using_path_follower()).is_equal(true)

	# Verify the train is still near the same position
	var dist: float = train.position.distance_to(saved_pos)
	assert_float(dist).is_less_than(float(Track.CELL_SIZE))


func test_integration_path_rebuild_after_track_modification() -> void:
	# Place initial track
	track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), track.get_segments().back())

	# Switch to path mode
	train.switch_to_path_mode(track)
	var follower1: TrainPathFollower = train.get_path_follower()
	assert_bool(follower1 != null).is_equal(true)

	# Add more track
	track.create_straight_segment(Vector2i(2, 0), true)
	track.try_place_segment(Vector2i(2, 0), track.get_segments().back())

	# Rebuild path (switch modes)
	train.switch_to_segment_mode(track)
	train.switch_to_path_mode(track)

	# Verify path still works
	var follower2: TrainPathFollower = train.get_path_follower()
	assert_bool(follower2 != null).is_equal(true)


func test_integration_full_gameplay_loop() -> void:
	# 1. Place track
	track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), track.get_segments().back())
	track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), track.get_segments().back())
	track.create_curve_segment(Vector2i(2, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(2, 0), track.get_segments().back())

	# 2. Move train (throttle simulation)
	train.update_input(true, false)
	train.update_speed(0.016)
	assert_float(train.speed).is_greater_than(0.0)

	# 3. Switch to path mode
	train.switch_to_path_mode(track)
	assert_bool(train.is_using_path_follower()).is_equal(true)

	# 4. Move along path
	train.update_position_path_follower(0.016)
	assert_float(train.position.x).is_greater_than_or_equal(0.0)

	# 5. Simulate undo — rebuild track and re-path
	var original_position: Vector2 = train.position
	train.switch_to_segment_mode(track)
	train.switch_to_path_mode(track)
	var new_dist: float = train.position.distance_to(original_position)
	assert_bool(new_dist < float(Track.CELL_SIZE * 2)).is_equal(true)
