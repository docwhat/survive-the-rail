extends GdUnitTestSuite

# --- Helpers ---

## Create a fresh data table.
func _make_table() -> DataTable:
	return DataTable.new()

# ============================================================================
# Basic Cell Operations
# ============================================================================


## set_cell and get_cell work correctly.
func test_set_and_get_cell() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(1, 2), 42)
	assert_int(table.get_cell(Vector2i(1, 2))).is_equal(42)


## get_cell returns -1 for empty cell (with error).
func test_get_empty_cell_returns_error() -> void:
	var table: DataTable = _make_table()
	var result: int = table.get_cell(Vector2i.ZERO)
	assert_int(result).is_equal(-1)


## contains returns true after set_cell.
func test_contains_returns_true_after_set() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(3, 4), 1)
	assert_bool(table.contains(Vector2i(3, 4))).is_true()


## contains returns false for a never-set position.
func test_contains_returns_false_for_empty() -> void:
	var table: DataTable = _make_table()
	assert_bool(table.contains(Vector2i(0, 0))).is_false()


## remove_cell and contains_after_remove: cell is removed, contains returns false.
func test_remove_cell_and_contains_after_remove() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(1, 1), 1)
	assert_bool(table.contains(Vector2i(1, 1))).is_true()
	table.remove_cell(Vector2i(1, 1))
	assert_bool(table.contains(Vector2i(1, 1))).is_false()


## remove_cell does not affect other cells.
func test_remove_does_not_affect_other_cells() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(1, 0), 2)
	table.remove_cell(Vector2i(0, 0))
	assert_bool(table.contains(Vector2i(0, 0))).is_false()
	assert_bool(table.contains(Vector2i(1, 0))).is_true()
	assert_int(table.get_cell(Vector2i(1, 0))).is_equal(2)


## remove_cell on empty table is a no-op.
func test_remove_empty_cell_is_noop() -> void:
	var table: DataTable = _make_table()
	table.remove_cell(Vector2i(0, 0))


## Overwriting a cell replaces the segment ID.
func test_overwrite_cell_replaces_id() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(0, 0), 2)
	assert_int(table.get_cell(Vector2i(0, 0))).is_equal(2)

# ============================================================================
# Counting
# ============================================================================


## get_cell_count returns 0 for empty table.
func test_get_cell_count_for_empty_table() -> void:
	var table: DataTable = _make_table()
	assert_int(table.get_cell_count()).is_equal(0)


## get_cell_count returns correct count after placements.
func test_get_cell_count_after_placement() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	assert_int(table.get_cell_count()).is_equal(1)
	table.set_cell(Vector2i(1, 0), 2)
	table.set_cell(Vector2i(2, 0), 3)
	assert_int(table.get_cell_count()).is_equal(3)


## get_cell_count correct after remove.
func test_get_cell_count_after_remove() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(1, 0), 2)
	table.remove_cell(Vector2i(0, 0))
	assert_int(table.get_cell_count()).is_equal(1)


## is_empty returns true for empty table.
func test_is_empty_empty_table() -> void:
	var table: DataTable = _make_table()
	assert_bool(table.is_empty()).is_true()


## is_empty returns false after placement.
func test_is_empty_false_after_placement() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	assert_bool(table.is_empty()).is_false()


## is_empty returns true after clearing all cells.
func test_is_empty_true_after_clear() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.clear()
	assert_bool(table.is_empty()).is_true()

# ============================================================================
# get_cells
# ============================================================================


## get_cells returns all occupied positions.
func test_get_cells_returns_all_occupied() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(1, 0), 2)
	table.set_cell(Vector2i(2, 0), 3)
	var cells: Array[Vector2i] = table.get_cells()
	assert_int(cells.size()).is_equal(3)
	assert_bool(cells.has(Vector2i(0, 0))).is_true()
	assert_bool(cells.has(Vector2i(1, 0))).is_true()
	assert_bool(cells.has(Vector2i(2, 0))).is_true()


## get_cells returns empty array for empty table.
func test_get_cells_empty_for_empty_table() -> void:
	var table: DataTable = _make_table()
	var cells: Array[Vector2i] = table.get_cells()
	assert_int(cells.size()).is_equal(0)

# ============================================================================
# get_cells_by_segment_id
# ============================================================================


## get_cells_by_segment_id groups cells correctly.
func test_get_cells_by_segment_id_groups_correctly() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(1, 0), 1)
	table.set_cell(Vector2i(2, 0), 2)
	var cells1: Array[Vector2i] = table.get_cells_by_segment_id(1)
	var cells2: Array[Vector2i] = table.get_cells_by_segment_id(2)
	assert_int(cells1.size()).is_equal(2)
	assert_int(cells2.size()).is_equal(1)
	assert_bool(cells1.has(Vector2i(0, 0))).is_true()
	assert_bool(cells1.has(Vector2i(1, 0))).is_true()
	assert_bool(cells2.has(Vector2i(2, 0))).is_true()


## get_cells_by_segment_id returns empty array for unknown ID.
func test_get_cells_by_segment_id_unknown_returns_empty() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	var cells: Array[Vector2i] = table.get_cells_by_segment_id(999)
	assert_int(cells.size()).is_equal(0)


## get_segment_count returns correct count of unique IDs.
func test_get_segment_count_unique_ids() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(1, 0), 1)
	table.set_cell(Vector2i(2, 0), 2)
	assert_int(table.get_segment_count()).is_equal(2)


## has_segment_id returns true when segment exists.
func test_has_segment_id_true() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	assert_bool(table.has_segment_id(1)).is_true()


## has_segment_id returns false when segment doesn't exist.
func test_has_segment_id_false() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	assert_bool(table.has_segment_id(999)).is_false()

# ============================================================================
# find_free_cell
# ============================================================================


## find_free_cell returns true for unoccupied position.
func test_find_free_cell_on_free_position() -> void:
	var table: DataTable = _make_table()
	assert_bool(table.find_free_cell(Vector2i(0, 0))).is_true()


## find_free_cell returns false for occupied position.
func test_find_free_cell_on_occupied_position() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	assert_bool(table.find_free_cell(Vector2i(0, 0))).is_false()


## find_free_cell works on neighbor of occupied cell.
func test_find_free_cell_neighbor_of_occupied() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	assert_bool(table.find_free_cell(Vector2i(1, 0))).is_true()
	assert_bool(table.find_free_cell(Vector2i(-1, 0))).is_true()

# ============================================================================
# get_unique_segment_ids
# ============================================================================


## get_unique_segment_ids returns all unique IDs.
func test_get_unique_segment_ids() -> void:
	var table: DataTable = _make_table()
	table.set_cell(Vector2i(0, 0), 1)
	table.set_cell(Vector2i(1, 0), 2)
	table.set_cell(Vector2i(2, 0), 1)
	var ids: Array[int] = table.get_unique_segment_ids()
	assert_int(ids.size()).is_equal(2)
	assert_bool(ids.has(1)).is_true()
	assert_bool(ids.has(2)).is_true()


## get_unique_segment_ids returns empty for empty table.
func test_get_unique_segment_ids_empty() -> void:
	var table: DataTable = _make_table()
	var ids: Array[int] = table.get_unique_segment_ids()
	assert_int(ids.size()).is_equal(0)
