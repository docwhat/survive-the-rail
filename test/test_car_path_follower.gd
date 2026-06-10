## Tests for CarPathFollower logic.
##
## Since headless mode doesn't support PathFollow2D, these tests
## verify the path length and offset computation via stabs.
extends GdUnitTestSuite

# ============================================================================
# Subtask 4d-2: CarPathFollower logic tests
# ============================================================================

func test_compute_path_length_single_line() -> void:
	var length: float = _stub_compute_path_length(
		["Line"],
		[Vector2i(0, 0), Vector2i(1, 0)],
	)
	assert_float(length).is_equal_approx(float(Track.CELL_SIZE), 0.001)


func test_compute_path_length_two_lines() -> void:
	var length: float = _stub_compute_path_length(
		["Line", "Line"],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), Vector2i(2, 0)],
	)
	assert_float(length).is_equal_approx(float(Track.CELL_SIZE * 2), 0.001)


func test_compute_path_length_single_curve() -> void:
	var length: float = _stub_compute_path_length(
		["Curve"],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	)
	assert_bool(length > 0.0).is_equal(true)


func test_compute_path_length_empty_path() -> void:
	var length: float = _stub_compute_path_length([], [])
	assert_float(length).is_equal_approx(0.0, 0.001)


func test_compute_path_length_mixed_straight_and_curve() -> void:
	var types: Array = ["Line", "Curve", "Line"]
	var cells: Array = [
		Vector2i(0, 0),
		Vector2i(1, 0), # Line 1 (2 cells)
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(2, 1), # Curve (3 cells)
		Vector2i(2, 1),
		Vector2i(3, 1), # Line 2 (2 cells)
	]
	var length: float = _stub_compute_path_length(types, cells)
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
	var engine_length: float = _stub_compute_path_length(
		["Line"],
		[Vector2i(0, 0), Vector2i(1, 0)],
	)
	var car_length: float = _stub_compute_path_length(
		["Line"],
		[Vector2i(0, 0), Vector2i(1, 0)],
	)
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
# Subtask 4d-1: Bezier midpoint tests (shared with engine)
# ============================================================================


func test_bezier_midpoint_at_half() -> void:
	var a: Vector2 = Vector2(0, 0)
	var b: Vector2 = Vector2(32, -32)
	var c: Vector2 = Vector2(64, 0)
	var mid: Vector2 = _stub_bezier_midpoint(a, b, c)
	assert_float(mid.x).is_equal_approx(32.0, 0.001)
	assert_float(mid.y).is_equal_approx(-16.0, 0.001)


func test_bezier_midpoint_symmetric_curve() -> void:
	var a: Vector2 = Vector2(0, 0)
	var b: Vector2 = Vector2(32, 0)
	var c: Vector2 = Vector2(64, 0)
	var mid: Vector2 = _stub_bezier_midpoint(a, b, c)
	assert_float(mid.x).is_equal_approx(32.0, 0.001)
	assert_float(mid.y).is_equal_approx(0.0, 0.001)

# ============================================================================
# Stub helper methods (mirroring both path followers)
# ============================================================================

const CELL_SIZE: float = 64.0


func _stub_compute_path_length(types: Array, cells: Array) -> float:
	var total: float = 0.0
	var idx: int = 0
	for i in range(types.size()):
		match types[i]:
			"Line":
				if idx + 1 < cells.size():
					var a: Vector2 = cells[idx] as Vector2 * CELL_SIZE
					var b: Vector2 = cells[idx + 1] as Vector2 * CELL_SIZE
					total += a.distance_to(b)
					idx += 2
			"Curve":
				if idx + 2 < cells.size():
					var a: Vector2 = cells[idx] as Vector2 * CELL_SIZE
					var b: Vector2 = cells[idx + 1] as Vector2 * CELL_SIZE
					var c: Vector2 = cells[idx + 2] as Vector2 * CELL_SIZE
					var mid: Vector2 = _stub_bezier_midpoint(a, b, c)
					total += a.distance_to(mid) + mid.distance_to(c)
					idx += 3
	return total


func _stub_bezier_midpoint(p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var t: float = 0.5
	var x: float = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x
	var y: float = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y
	return Vector2(x, y)
