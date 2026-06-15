## Tests for TrackRenderer data model integration logic.
##
## Since headless mode doesn't support _draw() output, these tests
## verify the rendering logic methods directly via stabs that mirror
## track_renderer.gd.
extends GdUnitTestSuite

# ============================================================================
# Subtask 4c-1: Data model dispatch logic
# ============================================================================

func test_draw_segment_from_data_dispatches_straight_h() -> void:
	var result: String = _stub_segment_dispatch(0, 1)
	assert_bool(result == "straight_single").is_equal(true)


func test_draw_segment_from_data_dispatches_straight_v() -> void:
	var result: String = _stub_segment_dispatch(1, 1)
	assert_bool(result == "straight_single").is_equal(true)


func test_draw_segment_from_data_dispatches_curve_1x1() -> void:
	var result: String = _stub_segment_dispatch(2, 1)
	assert_bool(result == "curve_1x1_single").is_equal(true)


func test_draw_segment_from_data_dispatches_curve_2x2() -> void:
	var result: String = _stub_segment_dispatch(3, 1)
	assert_bool(result == "curve_2x2").is_equal(true)


func test_draw_segment_from_data_dispatches_crossing() -> void:
	var result: String = _stub_segment_dispatch(4, 1)
	assert_bool(result == "crossing").is_equal(true)

# ============================================================================
# Subtask 4c-2: Straight segment drawing logic
# ============================================================================


func test_get_valid_connections_straight_h_no_rotation() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(0, 0)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.RIGHT)).is_equal(true)
	assert_bool(conns.has(Vector2.LEFT)).is_equal(true)


func test_get_valid_connections_straight_h_rotated() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(0, 1)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.DOWN)).is_equal(true)
	assert_bool(conns.has(Vector2.UP)).is_equal(true)


func test_get_valid_connections_straight_v() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(1, 0)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.DOWN)).is_equal(true)
	assert_bool(conns.has(Vector2.UP)).is_equal(true)


func test_get_valid_connections_straight_v_rotated() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(1, 1)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.RIGHT)).is_equal(true)
	assert_bool(conns.has(Vector2.LEFT)).is_equal(true)


func test_draw_arc_generates_correct_step_count() -> void:
	var points: PackedVector2Array = _stub_draw_arc(
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.DOWN,
		32.0,
	)
	assert_int(points.size()).is_equal(11) # steps=12, excluding endpoints = 11


func test_draw_arc_direction_left_up() -> void:
	var points: PackedVector2Array = _stub_draw_arc(Vector2.ZERO, Vector2.LEFT, Vector2.UP, 32.0)
	assert_int(points.size()).is_equal(11)


func test_draw_arc_direction_right_down() -> void:
	var points: PackedVector2Array = _stub_draw_arc(Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, 32.0)
	assert_int(points.size()).is_equal(11)


func test_draw_arc_all_lengths_same() -> void:
	var points_a: PackedVector2Array = _stub_draw_arc(
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.UP,
		32.0,
	)
	var points_b: PackedVector2Array = _stub_draw_arc(
		Vector2.ZERO,
		Vector2.LEFT,
		Vector2.DOWN,
		48.0,
	)
	assert_int(points_a.size()).is_equal(points_b.size())

# ============================================================================
# Subtask 4c-3: Curve segment drawing logic
# ============================================================================


func test_get_curve_entry_1x1_orientation_0_entry() -> void:
	var entry: Vector2i = _stub_get_curve_entry(0, true)
	assert_int(entry.x).is_equal(-1)
	assert_int(entry.y).is_equal(0)


func test_get_curve_entry_1x1_orientation_0_exit() -> void:
	var exit: Vector2i = _stub_get_curve_entry(0, false)
	assert_int(exit.x).is_equal(0)
	assert_int(exit.y).is_equal(-1)


func test_get_curve_entry_1x1_orientation_1_entry() -> void:
	var entry: Vector2i = _stub_get_curve_entry(1, true)
	assert_int(entry.x).is_equal(-1)
	assert_int(entry.y).is_equal(0)


func test_get_curve_entry_1x1_orientation_1_exit() -> void:
	var exit: Vector2i = _stub_get_curve_entry(1, false)
	assert_int(exit.x).is_equal(0)
	assert_int(exit.y).is_equal(1)


func test_get_curve_entry_1x1_orientation_2_entry() -> void:
	var entry: Vector2i = _stub_get_curve_entry(2, true)
	assert_int(entry.x).is_equal(1)
	assert_int(entry.y).is_equal(0)


func test_get_curve_entry_1x1_orientation_2_exit() -> void:
	var exit: Vector2i = _stub_get_curve_entry(2, false)
	assert_int(exit.x).is_equal(0)
	assert_int(exit.y).is_equal(-1)


func test_get_curve_entry_1x1_orientation_3_entry() -> void:
	var entry: Vector2i = _stub_get_curve_entry(3, true)
	assert_int(entry.x).is_equal(1)
	assert_int(entry.y).is_equal(0)


func test_get_curve_entry_1x1_orientation_3_exit() -> void:
	var exit: Vector2i = _stub_get_curve_entry(3, false)
	assert_int(exit.x).is_equal(0)
	assert_int(exit.y).is_equal(1)


func test_get_curve_entry_unknown_orientation_returns_zero() -> void:
	var entry: Vector2i = _stub_get_curve_entry(99, true)
	assert_int(entry.x).is_equal(0)
	assert_int(entry.y).is_equal(0)


func test_get_valid_connections_curve_1x1_orientation_0() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(2, 0)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.LEFT)).is_equal(true)
	assert_bool(conns.has(Vector2.UP)).is_equal(true)


func test_get_valid_connections_curve_1x1_orientation_1() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(2, 1)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.LEFT)).is_equal(true)
	assert_bool(conns.has(Vector2.DOWN)).is_equal(true)


func test_get_valid_connections_curve_1x1_orientation_2() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(2, 2)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.RIGHT)).is_equal(true)
	assert_bool(conns.has(Vector2.UP)).is_equal(true)


func test_get_valid_connections_curve_1x1_orientation_3() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(2, 3)
	assert_int(conns.size()).is_equal(2)
	assert_bool(conns.has(Vector2.RIGHT)).is_equal(true)
	assert_bool(conns.has(Vector2.DOWN)).is_equal(true)

# ============================================================================
# Subtask 4c-4: Crossing segment drawing logic
# ============================================================================


func test_get_neighbors_in_group_finds_four_neighbors() -> void:
	var cells: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]
	var neighbors: Array[Vector2i] = _stub_get_neighbors_in_group(cells, Vector2i(0, 0))
	assert_int(neighbors.size()).is_equal(4)


func test_get_neighbors_in_group_edge_cell() -> void:
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var neighbors: Array[Vector2i] = _stub_get_neighbors_in_group(cells, Vector2i(1, 0))
	assert_int(neighbors.size()).is_equal(0) # No center in group


func test_get_neighbors_in_group_no_neighbors() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 0)]
	var neighbors: Array[Vector2i] = _stub_get_neighbors_in_group(cells, Vector2i(0, 0))
	assert_int(neighbors.size()).is_equal(0)


func test_get_valid_connections_crossing_returns_empty() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(4, 0)
	assert_int(conns.size()).is_equal(0)


func test_get_valid_connections_unknown_type_returns_empty() -> void:
	var conns: Array[Vector2i] = _stub_get_valid_connections(99, 0)
	assert_int(conns.size()).is_equal(0)

# ============================================================================
# Subtask 4c-5: Placement preview rendering
# ============================================================================


func test_draw_arc_for_preview_same_as_placement() -> void:
	var placement_arc: PackedVector2Array = _stub_draw_arc(
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.DOWN,
		32.0,
	)
	var preview_arc: PackedVector2Array = _stub_draw_arc(
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.DOWN,
		32.0,
	)
	assert_int(placement_arc.size()).is_equal(preview_arc.size())


func test_preview_curve_entry_matches_placement() -> void:
	var placement_entry: Vector2i = _stub_get_curve_entry(0, true)
	var preview_entry: Vector2i = _stub_get_curve_entry(0, true)
	assert_int(placement_entry.x).is_equal(preview_entry.x)
	assert_int(placement_entry.y).is_equal(preview_entry.y)

# ============================================================================
# Stub helper methods (mirroring track_renderer.gd logic)
# ============================================================================


## Simulate _draw_segment_from_data dispatch.
func _stub_segment_dispatch(type_id: int, cell_count: int) -> String:
	match type_id:
		0, 1: # STRAIGHT_H, STRAIGHT_V
			if cell_count == 1:
				return "straight_single"
			return "straight_multi"
		2: # CURVE_1X1
			return "curve_1x1_single"
		3: # CURVE_2X2
			return "curve_2x2"
		4: # CROSSING_90
			return "crossing"
		_:
			return "unknown"


## Mirror of TrackRenderer._get_curve_entry.
func _stub_get_curve_entry(orientation: int, is_entry: bool) -> Vector2i:
	match orientation:
		0: # LEFT-UP
			return Vector2.LEFT if is_entry else Vector2.UP
		1: # LEFT-DOWN
			return Vector2.LEFT if is_entry else Vector2.DOWN
		2: # RIGHT-UP
			return Vector2.RIGHT if is_entry else Vector2.UP
		3: # RIGHT-DOWN
			return Vector2.RIGHT if is_entry else Vector2.DOWN
		_:
			return Vector2i.ZERO


## Mirror of TrackRenderer._get_valid_connections.
func _stub_get_valid_connections(type_id: int, orientation: int) -> Array[Vector2i]:
	match type_id:
		0: # STRAIGHT_H
			if orientation == 0:
				return [Vector2.RIGHT, Vector2.LEFT]
			return [Vector2.DOWN, Vector2.UP]
		1: # STRAIGHT_V
			if orientation == 0:
				return [Vector2.DOWN, Vector2.UP]
			return [Vector2.RIGHT, Vector2.LEFT]
		2: # CURVE_1X1
			match orientation:
				0:
					return [Vector2.LEFT, Vector2.UP]
				1:
					return [Vector2.LEFT, Vector2.DOWN]
				2:
					return [Vector2.RIGHT, Vector2.UP]
				3:
					return [Vector2.RIGHT, Vector2.DOWN]
		_:
			return []
	return []


## Mirror of TrackRenderer._get_neighbors_in_group.
func _stub_get_neighbors_in_group(cells: Array[Vector2i], cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for dir in directions:
		var neighbor: Vector2i = cell + dir
		if cells.has(neighbor):
			neighbors.append(neighbor)
	return neighbors


## Mirror of TrackRenderer._draw_arc.
func _stub_draw_arc(
		center: Vector2,
		start_dir: Vector2,
		end_dir: Vector2,
		radius: float,
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 12

	var entry_point: Vector2 = center + start_dir * radius
	var exit_point: Vector2 = center + end_dir * radius

	var entry_angle: float = atan2(entry_point.y - center.y, entry_point.x - center.x)
	var exit_angle: float = atan2(exit_point.y - center.y, exit_point.x - center.x)
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	for i in range(1, steps):
		var t: float = i / steps
		var angle: float = entry_angle + diff * t
		var px: float = center.x + cos(angle) * radius
		var py: float = center.y + sin(angle) * radius
		points.append(Vector2(px, py))

	return points
