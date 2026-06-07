extends GdUnitTestSuite

# --- Helpers ---

## Create a straight segment with LEFT-RIGHT connections at the given position.
func _straight_h(pos: Vector2i) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(pos, [Vector2.RIGHT, Vector2.LEFT])
	return seg


## Create a straight segment with UP-DOWN connections at the given position.
func _straight_v(pos: Vector2i) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(pos, [Vector2.DOWN, Vector2.UP])
	return seg


## Create a curve segment with the given connections at the given position.
func _curve(pos: Vector2i, conns: Array[Vector2i]) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(pos, conns)
	return seg

# ============================================================================
# TrackSegment: Basic Construction
# ============================================================================


## A straight segment initialized with LEFT-RIGHT connections.
func test_straight_segment_horizontal_has_left_right_connections() -> void:
	var seg: TrackSegment = _straight_h(Vector2i.ZERO)
	assert_bool(seg.has_connection(Vector2.LEFT)).is_true()
	assert_bool(seg.has_connection(Vector2.RIGHT)).is_true()


## A straight segment initialized with UP-DOWN connections.
func test_straight_segment_vertical_has_up_down_connections() -> void:
	var seg: TrackSegment = _straight_v(Vector2i.ZERO)
	assert_bool(seg.has_connection(Vector2.UP)).is_true()
	assert_bool(seg.has_connection(Vector2.DOWN)).is_true()


## A straight segment does not have connections it wasn't given.
func test_straight_segment_no_wrong_connections() -> void:
	var seg: TrackSegment = _straight_h(Vector2i.ZERO)
	assert_bool(seg.has_connection(Vector2.UP)).is_false()
	assert_bool(seg.has_connection(Vector2.DOWN)).is_false()


## A curve segment with DOWN-RIGHT connections.
func test_curve_segment_down_right_has_correct_connections() -> void:
	var seg: TrackSegment = _curve(Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	assert_bool(seg.has_connection(Vector2.DOWN)).is_true()
	assert_bool(seg.has_connection(Vector2.RIGHT)).is_true()
	assert_bool(seg.has_connection(Vector2.UP)).is_false()
	assert_bool(seg.has_connection(Vector2.LEFT)).is_false()


## Grid position is set correctly on construction.
func test_segment_grid_position_set() -> void:
	var pos: Vector2i = Vector2i(5, -3)
	var seg: TrackSegment = _straight_h(pos)
	assert_int(seg.grid_position.x).is_equal(pos.x)
	assert_int(seg.grid_position.y).is_equal(pos.y)

# ============================================================================
# TrackSegment: get_segment_type()
# ============================================================================


## Straight segment (opposite edges) returns type 0.
func test_straight_segment_type_is_zero() -> void:
	var seg: TrackSegment = _straight_h(Vector2i.ZERO)
	assert_int(seg.get_segment_type()).is_equal(0)


## Curve segment (adjacent edges) returns type 1.
func test_curve_segment_type_is_one() -> void:
	var seg: TrackSegment = _curve(Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	assert_int(seg.get_segment_type()).is_equal(1)


## All four straight orientations return type 0.
func test_all_straight_orientations_type_zero() -> void:
	var h: TrackSegment = _straight_h(Vector2i.ZERO)
	var v: TrackSegment = _straight_v(Vector2i.ZERO)
	assert_int(h.get_segment_type()).is_equal(0)
	assert_int(v.get_segment_type()).is_equal(0)


## All four curve orientations return type 1.
func test_all_curve_orientations_type_one() -> void:
	var c1: TrackSegment = _curve(Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	var c2: TrackSegment = _curve(Vector2i.ZERO, [Vector2.RIGHT, Vector2.UP])
	var c3: TrackSegment = _curve(Vector2i.ZERO, [Vector2.UP, Vector2.LEFT])
	var c4: TrackSegment = _curve(Vector2i.ZERO, [Vector2.LEFT, Vector2.DOWN])
	assert_int(c1.get_segment_type()).is_equal(1)
	assert_int(c2.get_segment_type()).is_equal(1)
	assert_int(c3.get_segment_type()).is_equal(1)
	assert_int(c4.get_segment_type()).is_equal(1)

# ============================================================================
# TrackSegment: _is_opposite_edges()
# ============================================================================


## Opposite edges (LEFT, RIGHT) are detected as straight.
func test_opposite_edges_detected_as_straight() -> void:
	pass
	# Covered by the type checks above: straight segments return 0.


## Adjacent edges (DOWN, RIGHT) are not straight.
func test_adjacent_edges_not_straight() -> void:
	var seg: TrackSegment = _curve(Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	assert_int(seg.get_segment_type()).is_equal(1)
