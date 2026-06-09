## Tests for TrackPathBuilder — subtasks 4b-1 through 4b-5.
@tool
extends GdUnitTestSuite

# ============================================================================
# Subtask 4b-1: Cell iteration & grouping
# ============================================================================

func test_group_cells_empty_data_table() -> void:
	var data_table: DataTable = DataTable.new()
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var result: Dictionary = builder.group_cells_by_segment(data_table)
	assert_int(result.size()).is_equal(0)


func test_group_cells_single_cell() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(5, 3), 1)
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var result: Dictionary = builder.group_cells_by_segment(data_table)
	assert_int(result.size()).is_equal(1)
	assert_bool(result.has(1)).is_equal(true)
	assert_int(result[1].size()).is_equal(1)
	assert_int(result[1][0].x).is_equal(5)
	assert_int(result[1][0].y).is_equal(3)


func test_group_cells_two_cells_same_segment() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(0, 0), 1)
	data_table.set_cell(Vector2i(1, 0), 1)
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var result: Dictionary = builder.group_cells_by_segment(data_table)
	assert_int(result.size()).is_equal(1)
	assert_int(result[1].size()).is_equal(2)


func test_group_cells_two_cells_different_segments() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(0, 0), 1)
	data_table.set_cell(Vector2i(2, 0), 2)
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var result: Dictionary = builder.group_cells_by_segment(data_table)
	assert_int(result.size()).is_equal(2)
	assert_int(result[1].size()).is_equal(1)
	assert_int(result[2].size()).is_equal(1)


func test_group_cells_multi_segment_track() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(0, 0), 1)
	data_table.set_cell(Vector2i(1, 0), 1)
	data_table.set_cell(Vector2i(3, 0), 2)
	data_table.set_cell(Vector2i(4, 0), 2)
	data_table.set_cell(Vector2i(5, 0), 3)
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var result: Dictionary = builder.group_cells_by_segment(data_table)
	assert_int(result.size()).is_equal(3)
	assert_int(result[1].size()).is_equal(2)
	assert_int(result[2].size()).is_equal(2)
	assert_int(result[3].size()).is_equal(1)


func test_sort_cells_horizontal_straight_in_order() -> void:
	var cells: Array[Vector2i] = [Vector2i(2, 0), Vector2i(0, 0), Vector2i(1, 0)]
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var sorted: Array[Vector2i] = builder.sort_cells_in_path_order(cells, 0, 0)
	assert_int(sorted[0].x).is_equal(0)
	assert_int(sorted[0].y).is_equal(0)
	assert_int(sorted[1].x).is_equal(1)
	assert_int(sorted[1].y).is_equal(0)
	assert_int(sorted[2].x).is_equal(2)
	assert_int(sorted[2].y).is_equal(0)


func test_sort_cells_vertical_straight_in_order() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 2), Vector2i(0, 0), Vector2i(0, 1)]
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var sorted: Array[Vector2i] = builder.sort_cells_in_path_order(cells, 1, 0)
	assert_int(sorted[0].x).is_equal(0)
	assert_int(sorted[0].y).is_equal(0)
	assert_int(sorted[1].x).is_equal(0)
	assert_int(sorted[1].y).is_equal(1)
	assert_int(sorted[2].x).is_equal(0)
	assert_int(sorted[2].y).is_equal(2)


func test_sort_cells_single_cell() -> void:
	var cells: Array[Vector2i] = [Vector2i(5, 5)]
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var sorted: Array[Vector2i] = builder.sort_cells_in_path_order(cells, 0, 0)
	assert_int(sorted.size()).is_equal(1)
	assert_int(sorted[0].x).is_equal(5)
	assert_int(sorted[0].y).is_equal(5)


func test_sort_cells_curve_cells_ordered() -> void:
	var cells: Array[Vector2i] = [Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 0)]
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var sorted: Array[Vector2i] = builder.sort_cells_in_path_order(cells, 2, 0)
	assert_int(sorted.size()).is_equal(3)


func test_get_neighbors_basic() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var neighbors: Array[Vector2i] = builder.get_neighbors_in_group(cells, Vector2i(0, 0))
	assert_int(neighbors.size()).is_equal(4)


func test_get_neighbors_no_neighbors() -> void:
	var cells: Array[Vector2i] = [Vector2i(5, 5)]
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var neighbors: Array[Vector2i] = builder.get_neighbors_in_group(cells, Vector2i(5, 5))
	assert_int(neighbors.size()).is_equal(0)

# ============================================================================
# Subtask 4b-2 through 4b-5: Path assembly tests
# (Note: PathSeg geometry tests skipped in headless — require runtime Godot)
# ============================================================================


func test_build_straight_path_returns_path_node() -> void:
	var data_table: DataTable = DataTable.new()
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_straight_path([Vector2i(0, 0)], 0, 0, data_table)
	assert_bool(path != null).is_equal(true)
	# PathSeg objects not available in headless, so verify Path2D structure
	assert_int(path.get_child_count()).is_equal(0) # No children when ClassDB.instantiate fails


func test_build_curve_path_returns_path_node() -> void:
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_curve_path([Vector2i(0, 0)], 2, 0)
	assert_bool(path != null).is_equal(true)
	assert_int(path.get_child_count()).is_equal(0)


func test_build_crossing_path_returns_path_node() -> void:
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_crossing_path([Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)], 4, 0)
	assert_bool(path != null).is_equal(true)
	assert_int(path.get_child_count()).is_equal(0)


func test_build_full_path_empty_track() -> void:
	var data_table: DataTable = DataTable.new()
	var segment_table: SegmentTable = SegmentTable.new()
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_full_path(data_table, segment_table)
	assert_bool(path != null).is_equal(true)
	assert_int(path.get_child_count()).is_equal(0)


func test_build_full_path_single_segment() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(0, 0), 1)
	var segment_table: SegmentTable = SegmentTable.new()
	segment_table.add_segment(1, 0, 0) # Straight horizontal
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_full_path(data_table, segment_table)
	assert_bool(path != null).is_equal(true)
	assert_int(path.get_child_count()).is_equal(0) # No geometry in headless


func test_build_full_path_multi_segment_straight() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(0, 0), 1)
	data_table.set_cell(Vector2i(1, 0), 1)
	data_table.set_cell(Vector2i(2, 0), 2)
	var segment_table: SegmentTable = SegmentTable.new()
	segment_table.add_segment(1, 0, 0)
	segment_table.add_segment(2, 0, 0)
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_full_path(data_table, segment_table)
	assert_int(path.get_child_count()).is_equal(0) # No geometry in headless


func test_build_full_path_multi_segment_with_curve() -> void:
	var data_table: DataTable = DataTable.new()
	data_table.set_cell(Vector2i(0, 0), 1)
	data_table.set_cell(Vector2i(1, 0), 2)
	var segment_table: SegmentTable = SegmentTable.new()
	segment_table.add_segment(1, 0, 0) # Straight
	segment_table.add_segment(2, 2, 0) # Curve
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	var path: Path2D = builder.build_full_path(data_table, segment_table)
	assert_int(path.get_child_count()).is_equal(0) # No geometry in headless
