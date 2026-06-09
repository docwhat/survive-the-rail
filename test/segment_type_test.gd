extends GdUnitTestSuite

# ============================================================================
# Static API: get_type_by_name
# ============================================================================

## get_type_by_name returns correct ID for "straight_h".
func test_get_type_by_name_straight_h() -> void:
	var result: int = SegmentType.get_type_by_name("straight_h")
	assert_int(result).is_equal(SegmentType.STRAIGHT_H)


## get_type_by_name returns correct ID for "curve_1x1".
func test_get_type_by_name_curve_1x1() -> void:
	var result: int = SegmentType.get_type_by_name("curve_1x1")
	assert_int(result).is_equal(SegmentType.CURVE_1X1)


## get_type_by_name returns correct ID for "curve_2x2".
func test_get_type_by_name_curve_2x2() -> void:
	var result: int = SegmentType.get_type_by_name("curve_2x2")
	assert_int(result).is_equal(SegmentType.CURVE_2X2)


## get_type_by_name returns correct ID for "crossing_90".
func test_get_type_by_name_crossing_90() -> void:
	var result: int = SegmentType.get_type_by_name("crossing_90")
	assert_int(result).is_equal(SegmentType.CROSSING_90)


## get_type_by_name returns -1 for unknown type.
func test_get_type_by_name_unknown_returns_minus_one() -> void:
	var result: int = SegmentType.get_type_by_name("nonexistent")
	assert_int(result).is_equal(-1)


## get_type_by_name returns correct IDs for all types.
func test_get_type_by_name_all_types() -> void:
	assert_int(SegmentType.get_type_by_name("straight_h")).is_equal(SegmentType.STRAIGHT_H)
	assert_int(SegmentType.get_type_by_name("straight_v")).is_equal(SegmentType.STRAIGHT_V)
	assert_int(SegmentType.get_type_by_name("curve_1x1")).is_equal(SegmentType.CURVE_1X1)
	assert_int(SegmentType.get_type_by_name("curve_2x2")).is_equal(SegmentType.CURVE_2X2)
	assert_int(SegmentType.get_type_by_name("crossing_90")).is_equal(SegmentType.CROSSING_90)

# ============================================================================
# Patterns
# ============================================================================


## Straight horizontal pattern has 2 cells.
func test_straight_h_pattern_two_cells() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.STRAIGHT_H)
	assert_int(pattern.size()).is_equal(2)


## Straight vertical pattern has 2 cells.
func test_straight_v_pattern_two_cells() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.STRAIGHT_V)
	assert_int(pattern.size()).is_equal(2)


## Curve 1x1 pattern has 1 cell.
func test_curve_1x1_pattern_one_cell() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.CURVE_1X1)
	assert_int(pattern.size()).is_equal(1)


## Curve 2x2 pattern has 4 cells.
func test_curve_2x2_pattern_four_cells() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.CURVE_2X2)
	assert_int(pattern.size()).is_equal(4)


## Crossing 90 pattern has 5 cells.
func test_crossing_90_pattern_five_cells() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.CROSSING_90)
	assert_int(pattern.size()).is_equal(5)


## Unknown type returns empty pattern.
func test_unknown_type_returns_empty_pattern() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(999)
	assert_int(pattern.size()).is_equal(0)


## Straight horizontal pattern includes origin and RIGHT cell.
func test_straight_h_pattern_includes_origin_and_right() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.STRAIGHT_H)
	assert_bool(pattern.has(Vector2i.ZERO)).is_true()
	assert_bool(pattern.has(Vector2i.RIGHT)).is_true()


## Straight vertical pattern includes origin and DOWN cell.
func test_straight_v_pattern_includes_origin_and_down() -> void:
	var pattern: Array[Vector2i] = SegmentType.get_pattern(SegmentType.STRAIGHT_V)
	assert_bool(pattern.has(Vector2i.ZERO)).is_true()
	assert_bool(pattern.has(Vector2i.DOWN)).is_true()

# ============================================================================
# Entrance Pairs
# ============================================================================


## Straight horizontal has entrance pairs for horizontal and vertical.
func test_straight_h_entrance_pairs_h_and_v() -> void:
	assert_int(SegmentType.get_entrance_pair_count(SegmentType.STRAIGHT_H)).is_equal(2)


## Straight vertical has entrance pairs for horizontal and vertical.
func test_straight_v_entrance_pairs_h_and_v() -> void:
	assert_int(SegmentType.get_entrance_pair_count(SegmentType.STRAIGHT_V)).is_equal(2)


## Curve 1x1 has 4 entrance pairs.
func test_curve_1x1_entrance_pairs_four() -> void:
	assert_int(SegmentType.get_entrance_pair_count(SegmentType.CURVE_1X1)).is_equal(4)


## Curve 2x2 has 4 entrance pairs.
func test_curve_2x2_entrance_pairs_four() -> void:
	assert_int(SegmentType.get_entrance_pair_count(SegmentType.CURVE_2X2)).is_equal(4)


## Crossing 90 has 4 entrance pairs (one direction each).
func test_crossing_90_entrance_pairs_four() -> void:
	assert_int(SegmentType.get_entrance_pair_count(SegmentType.CROSSING_90)).is_equal(4)

# ============================================================================
# has_valid_entrance
# ============================================================================


## Straight horizontal has valid entrance for RIGHT.
func test_has_valid_entrance_straight_h_right() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.STRAIGHT_H, Vector2i.RIGHT)).is_true()


## Straight horizontal has valid entrance for LEFT.
func test_has_valid_entrance_straight_h_left() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.STRAIGHT_H, Vector2i.LEFT)).is_true()


## Straight horizontal has valid entrance for UP.
func test_has_valid_entrance_straight_h_up() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.STRAIGHT_H, Vector2i.UP)).is_true()


## Straight horizontal has valid entrance for DOWN.
func test_has_valid_entrance_straight_h_down() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.STRAIGHT_H, Vector2i.DOWN)).is_true()


## Curve 1x1 has valid entrance for LEFT.
func test_has_valid_entrance_curve_1x1_left() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.CURVE_1X1, Vector2i.LEFT)).is_true()


## Curve 1x1 has valid entrance for DOWN.
func test_has_valid_entrance_curve_1x1_down() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.CURVE_1X1, Vector2i.DOWN)).is_true()


## Crossing 90 has valid entrance for all directions.
func test_has_valid_entrance_crossing_all_directions() -> void:
	assert_bool(SegmentType.has_valid_entrance(SegmentType.CROSSING_90, Vector2i.RIGHT)).is_true()
	assert_bool(SegmentType.has_valid_entrance(SegmentType.CROSSING_90, Vector2i.LEFT)).is_true()
	assert_bool(SegmentType.has_valid_entrance(SegmentType.CROSSING_90, Vector2i.UP)).is_true()
	assert_bool(SegmentType.has_valid_entrance(SegmentType.CROSSING_90, Vector2i.DOWN)).is_true()


## Unknown type returns false for any entrance.
func test_has_valid_entrance_unknown_type_returns_false() -> void:
	assert_bool(SegmentType.has_valid_entrance(999, Vector2i.RIGHT)).is_false()
	assert_bool(SegmentType.has_valid_entrance(999, Vector2i.DOWN)).is_false()

# ============================================================================
# get_all_entrance_directions
# ============================================================================


## Straight horizontal returns all 4 cardinal directions.
func test_straight_h_all_entrance_directions_four() -> void:
	var dirs: Array[Vector2i] = SegmentType.get_all_entrance_directions(SegmentType.STRAIGHT_H)
	assert_int(dirs.size()).is_equal(4)
	assert_bool(dirs.has(Vector2i.RIGHT)).is_true()
	assert_bool(dirs.has(Vector2i.LEFT)).is_true()
	assert_bool(dirs.has(Vector2i.UP)).is_true()
	assert_bool(dirs.has(Vector2i.DOWN)).is_true()


## Crossing 90 returns all 4 cardinal directions.
func test_crossing_90_all_entrance_directions_four() -> void:
	var dirs: Array[Vector2i] = SegmentType.get_all_entrance_directions(SegmentType.CROSSING_90)
	assert_int(dirs.size()).is_equal(4)


## Curve 1x1 returns 4 unique directions (LEFT, DOWN, RIGHT, UP).
func test_curve_1x1_all_entrance_directions_four() -> void:
	var dirs: Array[Vector2i] = SegmentType.get_all_entrance_directions(SegmentType.CURVE_1X1)
	assert_int(dirs.size()).is_equal(4)


## Unknown type returns empty directions array.
func test_unknown_type_returns_empty_directions() -> void:
	var dirs: Array[Vector2i] = SegmentType.get_all_entrance_directions(999)
	assert_int(dirs.size()).is_equal(0)
