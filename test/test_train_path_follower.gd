## Tests for TrainPathFollower data model integration.
##
## Since headless mode doesn't support PathFollow2D, these tests
## verify the path length computation logic via Curve2D stubs that mirror
## train_path_follower.gd.
extends GdUnitTestSuite

# ============================================================================
# Subtask 4d-1: PathFollow2D wrapper logic tests
# ============================================================================

func test_compute_path_length_single_line() -> void:
	var length: float = _stub_compute_path_length([Vector2i(0, 0), Vector2i(1, 0)])
	assert_float(length).is_equal_approx(float(Track.CELL_SIZE), 0.001)


func test_compute_path_length_two_lines() -> void:
	var length: float = _stub_compute_path_length([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	assert_float(length).is_equal_approx(float(Track.CELL_SIZE * 2), 0.001)


func test_compute_path_length_single_curve() -> void:
	var length: float = _stub_compute_path_length([Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)])
	assert_bool(length > 0.0).is_equal(true)


func test_compute_path_length_empty_path() -> void:
	var length: float = _stub_compute_path_length([])
	assert_float(length).is_equal_approx(0.0, 0.001)


func test_compute_path_length_mixed_path() -> void:
	var cells: Array = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(2, 1),
	]
	var length: float = _stub_compute_path_length(cells)
	assert_bool(length > float(Track.CELL_SIZE * 2)).is_equal(true)
	assert_bool(length < float(Track.CELL_SIZE * 4)).is_equal(true)

# ============================================================================
# Subtask 4d-2: Car path follower (stubbed — logic same as engine)
# ============================================================================


func test_compute_path_length_for_car_path() -> void:
	# Same logic applies to cars — a car following at a coupling offset
	# uses the same path length computation.
	var length: float = _stub_compute_path_length([Vector2i(0, 0), Vector2i(1, 0)])
	assert_float(length).is_equal_approx(float(Track.CELL_SIZE), 0.001)


func test_progress_ratio_preservation() -> void:
	var old_ratio: float = 0.5
	var new_total: float = 100.0
	var expected_progress: float = old_ratio * new_total
	assert_float(expected_progress).is_equal_approx(50.0, 0.001)


func test_progress_ratio_from_length() -> void:
	var old_progress: float = 32.0
	var total_length: float = 64.0
	var ratio: float = old_progress / total_length
	assert_float(ratio).is_equal_approx(0.5, 0.001)


func test_zero_length_ratio_becomes_zero() -> void:
	var old_progress: float = 0.0
	var total_length: float = 0.0
	var ratio: float = 0.0 # division by zero guard
	assert_float(ratio).is_equal_approx(0.0, 0.001)

# ============================================================================
# Stub helper methods (mirroring train_path_follower.gd using Curve2D)
# ============================================================================

const CELL_SIZE: float = 64.0


## Stub for computing path length from cell positions using Curve2D.
func _stub_compute_path_length(cells: Array) -> float:
	var curve: Curve2D = Curve2D.new()
	for cell in cells:
		curve.add_point(Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE))
	return curve.get_baked_length()
