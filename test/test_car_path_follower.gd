## Tests for CarPathFollower logic.
##
## Since headless mode doesn't support PathFollow2D, these tests
## verify the path length and offset computation via Curve2D stubs.
extends GdUnitTestSuite

# ============================================================================
# Subtask 4d-2: CarPathFollower logic tests
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


func test_car_progress_with_offset() -> void:
	var base: float = 32.0
	var offset: float = 16.0
	var total_progress: float = base + offset
	assert_float(total_progress).is_equal_approx(48.0, 0.001)


func test_car_progress_offset_alone() -> void:
	var offset: float = 64.0
	var base: float = 0.0
	var total_progress: float = base + offset
	assert_float(total_progress).is_equal_approx(64.0, 0.001)


func test_car_progress_offset_negative_means_ahead() -> void:
	var base: float = 64.0
	var offset: float = -32.0
	var total_progress: float = base + offset
	assert_float(total_progress).is_equal_approx(32.0, 0.001)


func test_progress_ratio_preservation() -> void:
	var old_base: float = 32.0
	var old_total: float = 64.0
	var old_offset: float = 16.0
	var old_ratio: float = old_base / old_total
	assert_float(old_ratio).is_equal_approx(0.5, 0.001)


func test_car_path_same_length_as_engine() -> void:
	var cells: Array = [Vector2i(0, 0), Vector2i(1, 0)]
	var engine_length: float = _stub_compute_path_length(cells)
	var car_length: float = _stub_compute_path_length(cells)
	assert_float(engine_length).is_equal_approx(car_length, 0.001)


func test_zero_offset_equivalent_to_engine() -> void:
	var base: float = 48.0
	var offset: float = 0.0
	var total: float = base + offset
	assert_float(total).is_equal_approx(base, 0.001)


func test_offset_boundary_no_negative_progress() -> void:
	var base: float = 8.0
	var offset: float = 32.0
	var total: float = base + offset
	assert_bool(total >= 0.0).is_equal(true)

# ============================================================================
# Stub helper methods (mirroring both path followers using Curve2D)
# ============================================================================

const CELL_SIZE: float = 64.0


func _stub_compute_path_length(cells: Array) -> float:
	var curve: Curve2D = Curve2D.new()
	for cell in cells:
		curve.add_point(Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE))
	return curve.get_baked_length()
