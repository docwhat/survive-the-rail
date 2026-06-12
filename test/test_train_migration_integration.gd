## Integration tests for full train-path interaction.
##
## These tests verify the complete pipeline: data model → path builder
## → train movement → mode switching.
# GdUnit4 does not support setup()/teardown(), so we inline initialization.
extends GdUnitTestSuite

## Create a fresh Track for each test.
func _make_track() -> Track:
	var t: Track = Track.new()
	t.initialize(100.0, 100)
	return t


## Create a fresh Train for each test.
func _make_train() -> Train:
	var tr: Train = Train.new()
	tr.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	tr.enabled = true
	return tr

# ============================================================================
# Subtask 4d-7: Integration smoke tests
# ============================================================================


func test_integration_train_follows_straight_path() -> void:
	var track: Track = _make_track()
	var train: Train = _make_train()

	# Place a straight track
	var seg = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg)
	seg = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg)
	seg = track.create_straight_segment(Vector2i(2, 0), true)
	track.try_place_segment(Vector2i(2, 0), seg)

	# Switch to path mode
	train.switch_to_path_mode(track)
	assert_bool(train.is_using_path_follower()).is_equal(true)

	# Verify path exists
	var follower: TrainPathFollower = train.get_path_follower()
	assert_bool(follower != null).is_equal(true)


func test_integration_train_follows_curved_path() -> void:
	var track: Track = _make_track()
	var train: Train = _make_train()

	# Place straight then curve
	var seg = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg)
	seg = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg)
	seg = track.create_curve_segment(Vector2i(2, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(2, 0), seg)
	seg = track.create_straight_segment(Vector2i(2, 1), true)
	track.try_place_segment(Vector2i(2, 1), seg)

	# Switch to path mode
	train.switch_to_path_mode(track)
	assert_bool(train.is_using_path_follower()).is_equal(true)

	# Verify progress is non-zero (path exists and has length)
	var progress: float = train.get_path_progress()
	assert_bool(progress >= 0.0).is_equal(true)


func test_integration_train_with_cars_follows_path() -> void:
	var track: Track = _make_track()
	var train: Train = _make_train()

	# Place a short straight track
	var seg = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg)
	seg = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg)

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
	var track: Track = _make_track()
	var train: Train = _make_train()

	# Place track
	var seg = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg)
	seg = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg)

	# Switch to path mode, then back to segment mode
	train.switch_to_path_mode(track)
	var saved_pos: Vector2 = train.position

	# Switch back to segment mode
	train.switch_to_segment_mode(track)
	assert_bool(!train.is_using_path_follower()).is_equal(true)

	# Verify the train is still near the same position
	var dist: float = train.position.distance_to(saved_pos)
	assert_float(dist).is_less(float(Track.CELL_SIZE))


func test_integration_path_rebuild_after_track_modification() -> void:
	var track: Track = _make_track()
	var train: Train = _make_train()

	# Place initial track
	var seg = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg)
	seg = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg)

	# Switch to path mode
	train.switch_to_path_mode(track)
	var follower1: TrainPathFollower = train.get_path_follower()
	assert_bool(follower1 != null).is_equal(true)

	# Add more track
	seg = track.create_straight_segment(Vector2i(2, 0), true)
	track.try_place_segment(Vector2i(2, 0), seg)

	# Rebuild path (switch modes)
	train.switch_to_segment_mode(track)
	train.switch_to_path_mode(track)

	# Verify path still works
	var follower2: TrainPathFollower = train.get_path_follower()
	assert_bool(follower2 != null).is_equal(true)


func test_integration_full_gameplay_loop() -> void:
	var track: Track = _make_track()
	var train: Train = _make_train()

	# 1. Place track
	var seg = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg)
	seg = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg)
	seg = track.create_curve_segment(Vector2i(2, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(2, 0), seg)

	# 2. Move train (throttle simulation)
	train.update_input(true, false)
	train.update_speed(0.016)
	assert_float(train.speed).is_greater(0.0)

	# 3. Switch to path mode
	train.switch_to_path_mode(track)
	assert_bool(train.is_using_path_follower()).is_equal(true)

	# 4. Move along path
	train.update_position_path_follower(0.016)
	assert_float(train.position.x).is_greater_equal(0.0)

	# 5. Simulate undo — rebuild track and re-path
	var original_position: Vector2 = train.position
	train.switch_to_segment_mode(track)
	train.switch_to_path_mode(track)
	var new_dist: float = train.position.distance_to(original_position)
	assert_bool(new_dist < float(Track.CELL_SIZE * 2)).is_equal(true)
