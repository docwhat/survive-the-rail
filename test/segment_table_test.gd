extends GdUnitTestSuite

# --- Helpers ---

## Create a fresh segment table.
func _make_table() -> SegmentTable:
	return SegmentTable.new()

# ============================================================================
# Basic Addition and Retrieval
# ============================================================================


## add_segment and retrieval works for a single segment.
func test_add_segment() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	assert_int(table.get_segment_type(0)).is_equal(0)
	assert_int(table.get_orientation(0)).is_equal(0)


## add_segment stores multiple segments independently.
func test_add_multiple_segments_independent() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	table.add_segment(1, 1, 1)
	table.add_segment(2, 2, 2)
	assert_int(table.get_segment_type(0)).is_equal(0)
	assert_int(table.get_segment_type(1)).is_equal(1)
	assert_int(table.get_segment_type(2)).is_equal(2)
	assert_int(table.get_orientation(0)).is_equal(0)
	assert_int(table.get_orientation(1)).is_equal(1)
	assert_int(table.get_orientation(2)).is_equal(2)


## add_segment defaults orientation to 0.
func test_add_segment_defaults_orientation_zero() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 5)
	assert_int(table.get_orientation(0)).is_equal(0)


## get_segment_type returns -1 for missing ID.
func test_get_missing_segment_returns_error() -> void:
	var table: SegmentTable = _make_table()
	var result: int = table.get_segment_type(999)
	assert_int(result).is_equal(-1)


## get_orientation returns -1 for missing ID.
func test_get_missing_orientation_returns_error() -> void:
	var table: SegmentTable = _make_table()
	var result: int = table.get_orientation(999)
	assert_int(result).is_equal(-1)

# ============================================================================
# Rotation
# ============================================================================


## rotate_segment 90 degrees increments orientation.
func test_rotate_segment_90_degrees() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	table.rotate_segment(0, 90)
	assert_int(table.get_orientation(0)).is_equal(1)


## rotate_segment 180 degrees increments orientation by 2.
func test_rotate_segment_180_degrees() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	table.rotate_segment(0, 180)
	assert_int(table.get_orientation(0)).is_equal(2)


## rotate_segment wraps at 360 degrees.
func test_rotate_segment_wraps_at_360() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 3)
	table.rotate_segment(0, 90)
	assert_int(table.get_orientation(0)).is_equal(0)


## rotate_segment 270 degrees.
func test_rotate_segment_270_degrees() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	table.rotate_segment(0, 270)
	assert_int(table.get_orientation(0)).is_equal(3)


## rotate_segment on missing ID logs error (no crash).
func test_rotate_segment_missing_id_no_crash() -> void:
	var table: SegmentTable = _make_table()
	# Should not crash, just log error
	table.rotate_segment(999, 90)


## rotate_segment preserves type_id.
func test_rotate_segment_preserves_type() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 4, 0)
	table.rotate_segment(0, 180)
	assert_int(table.get_segment_type(0)).is_equal(4)
	assert_int(table.get_orientation(0)).is_equal(2)

# ============================================================================
# Removal and Containment
# ============================================================================


## remove_segment removes a segment and contains returns false.
func test_remove_segment() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	assert_bool(table.contains(0)).is_true()
	table.remove_segment(0)
	assert_bool(table.contains(0)).is_false()


## contains returns true after add and false after remove.
func test_contains_after_add_and_remove() -> void:
	var table: SegmentTable = _make_table()
	assert_bool(table.contains(0)).is_false()
	table.add_segment(0, 0, 0)
	assert_bool(table.contains(0)).is_true()
	table.remove_segment(0)
	assert_bool(table.contains(0)).is_false()


## contains returns false for never-added IDs.
func test_contains_returns_false_for_unadded() -> void:
	var table: SegmentTable = _make_table()
	assert_bool(table.contains(999)).is_false()


## remove_segment on missing ID is a no-op (no crash).
func test_remove_missing_segment_is_noop() -> void:
	var table: SegmentTable = _make_table()
	table.remove_segment(999)


## get_count returns correct count after add and remove.
func test_get_count_after_add_remove() -> void:
	var table: SegmentTable = _make_table()
	assert_int(table.get_count()).is_equal(0)
	table.add_segment(0, 0, 0)
	table.add_segment(1, 1, 0)
	assert_int(table.get_count()).is_equal(2)
	table.remove_segment(0)
	assert_int(table.get_count()).is_equal(1)


## is_empty returns true for empty table.
func test_is_empty_empty_table() -> void:
	var table: SegmentTable = _make_table()
	assert_bool(table.is_empty()).is_true()


## is_empty returns false after adding segments.
func test_is_empty_false_after_add() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	assert_bool(table.is_empty()).is_false()


## get_all_ids returns all registered IDs.
func test_get_all_ids_returns_ids() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 0)
	table.add_segment(1, 1, 1)
	table.add_segment(2, 2, 2)
	var ids: Array[int] = table.get_all_ids()
	assert_int(ids.size()).is_equal(3)
	assert_bool(ids.has(0)).is_true()
	assert_bool(ids.has(1)).is_true()
	assert_bool(ids.has(2)).is_true()

# ============================================================================
# Safe Try Methods
# ============================================================================


## try_get_type returns type for existing segment.
func test_try_get_type_existing() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 5, 0)
	assert_int(table.try_get_type(0)).is_equal(5)


## try_get_type returns -1 for missing segment (no error).
func test_try_get_type_missing() -> void:
	var table: SegmentTable = _make_table()
	var result: int = table.try_get_type(999)
	assert_int(result).is_equal(-1)


## try_get_orientation returns orientation for existing segment.
func test_try_get_orientation_existing() -> void:
	var table: SegmentTable = _make_table()
	table.add_segment(0, 0, 2)
	assert_int(table.try_get_orientation(0)).is_equal(2)


## try_get_orientation returns -1 for missing segment (no error).
func test_try_get_orientation_missing() -> void:
	var table: SegmentTable = _make_table()
	var result: int = table.try_get_orientation(999)
	assert_int(result).is_equal(-1)
