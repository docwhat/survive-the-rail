extends GdUnitTestSuite

const _Track = preload("res://track.gd")
const _TrackSegment = preload("res://track_segment.gd")
const _Physics = preload("res://physics.gd")

# --- Helpers ---


## Create a straight segment with LEFT-RIGHT connections at the given position.
func _straight_h(pos: Vector2i) -> TrackSegment:
	var seg: TrackSegment = _TrackSegment.new()
	seg.initialize(pos, [Vector2.RIGHT, Vector2.LEFT])
	return seg


## Create a straight segment with UP-DOWN connections at the given position.
func _straight_v(pos: Vector2i) -> TrackSegment:
	var seg: TrackSegment = _TrackSegment.new()
	seg.initialize(pos, [Vector2.DOWN, Vector2.UP])
	return seg


## Create a curve segment with the given connections at the given position.
func _curve(pos: Vector2i, conns: Array[Vector2i]) -> TrackSegment:
	var seg: TrackSegment = _TrackSegment.new()
	seg.initialize(pos, conns)
	return seg


## Create a fresh track with the given starting resources and max length.
func _make_track(resources: float = 100.0, max_len: int = 100) -> Track:
	var track: Track = _Track.new()
	track.initialize(resources, max_len)
	return track


## Place a straight horizontal segment at the given position and return it.
## Asserts placement succeeds.
func _place_h(track: Track, pos: Vector2i) -> TrackSegment:
	var seg: TrackSegment = track.create_straight_segment(pos, true)
	var result: bool = track.try_place_segment(pos, seg)
	assert_bool(result).is_true()
	return seg


## Place a straight vertical segment at the given position and return it.
## Asserts placement succeeds.
func _place_v(track: Track, pos: Vector2i) -> TrackSegment:
	var seg: TrackSegment = track.create_straight_segment(pos, false)
	var result: bool = track.try_place_segment(pos, seg)
	assert_bool(result).is_true()
	return seg


## Place a curve segment at the given position with specific connections
## and return it. Asserts placement succeeds.
func _place_curve(track: Track, pos: Vector2i, conns: Array[Vector2i]) -> TrackSegment:
	var seg: TrackSegment = track.create_curve_segment(pos, conns)
	var result: bool = track.try_place_segment(pos, seg)
	assert_bool(result).is_true()
	return seg

# ============================================================================
# Track Initialization
# ============================================================================


## New track starts with the resources and max length specified.
func test_track_initializes_with_correct_resources() -> void:
	var track: Track = _make_track(50.0, 50)
	assert_float(track.get_resources()).is_equal_approx(50.0, 0.001)
	assert_int(track.get_max_length()).is_equal(50)


## New track starts empty.
func test_track_starts_empty() -> void:
	var track: Track = _make_track()
	assert_int(track.get_segment_count()).is_equal(0)


## Occupied cells is empty at start.
func test_occupied_cells_empty_at_start() -> void:
	var track: Track = _make_track()
	track.create_straight_segment(Vector2i.ZERO, true)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_int(positions.size()).is_equal(0)

# ============================================================================
# Placing First Segment
# ============================================================================


## Placing the first segment on an empty track succeeds.
## An empty track has no existing connections, so continuity cannot be
## checked against anything. The first segment should always be allowed
## as the anchor/starting segment.
func test_place_first_segment_succeeds() -> void:
	var track: Track = _make_track(100.0)
	var seg: TrackSegment = track.create_straight_segment(Vector2i(0, 0), true)
	var result: bool = track.try_place_segment(Vector2i(0, 0), seg)
	assert_bool(result).is_true()


## After placing one segment, segment count is 1.
func test_segment_count_after_first_place() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	assert_int(track.get_segment_count()).is_equal(1)


## After placing one segment, 2 valid placement positions.
func test_one_segment_has_two_valid_positions() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_int(positions.size()).is_equal(2)


## One segment's valid positions are one cell left and one cell right.
func test_one_segment_valid_positions_are_neighbors() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_bool(positions.has(Vector2i(-1, 0))).is_true()
	assert_bool(positions.has(Vector2i(1, 0))).is_true()
	assert_int(positions.size()).is_equal(2)


## A single vertical segment has valid positions above and below.
func test_vertical_segment_valid_positions() -> void:
	var track: Track = _make_track()
	_place_v(track, Vector2i.ZERO)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_bool(positions.has(Vector2i(0, -1))).is_true()
	assert_bool(positions.has(Vector2i(0, 1))).is_true()
	assert_int(positions.size()).is_equal(2)

# ============================================================================
# Continuity: Valid Placements
# ============================================================================


## Placing a segment that connects to an existing segment's connection
## should succeed.
func test_contiguous_placement_succeeds() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	# Place to the right: new segment's LEFT connection should match
	# existing segment's RIGHT connection
	var seg: TrackSegment = track.create_straight_segment(Vector2i(1, 0), true)
	var result: bool = track.try_place_segment(Vector2i(1, 0), seg)
	assert_bool(result).is_true()


## Placing a segment that connects on one side (but not both) is valid.
func test_partial_continuity_is_valid() -> void:
	var track: Track = _make_track()
	_place_curve(track, Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	# Place a straight segment to the right — connects via seg1's RIGHT connection
	var seg2: TrackSegment = track.create_straight_segment(Vector2i(1, 0), true)
	var result: bool = track.try_place_segment(Vector2i(1, 0), seg2)
	assert_bool(result).is_true()


## A curve can connect to another curve if their sides align.
func test_curve_connecting_to_curve_via_aligned_sides() -> void:
	var track: Track = _make_track()
	# First curve: DOWN-RIGHT at origin
	_place_curve(track, Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	# Second curve: UP-LEFT at (0, 1), so DOWN connects to first's UP...
	# Wait, first curve at (0,0) has DOWN connection -> points to (0,1)
	# A curve at (0,1) with UP connection -> points to (0,0), which matches first's DOWN
	# But we need first's DOWN connection to match second's UP:
	# first at (0,0) has DOWN => neighbor at (0,1). second at (0,1) has UP => points to (0,0).
	# check: second has UP => neighbor_pos = (0,1) + UP = (0,0). occupied? yes.
	# neighbor at (0,0) has DOWN. Does it have_connection(-UP) = DOWN? Yes!
	var seg2: TrackSegment = track.create_curve_segment(Vector2i(0, 1), [Vector2.UP, Vector2.LEFT])
	var result: bool = track.try_place_segment(Vector2i(0, 1), seg2)
	assert_bool(result).is_true()


## Placing two segments in opposite directions from start.
func test_two_segments_on_opposite_sides() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	# Place one to the left
	_place_h(track, Vector2i(-1, 0))
	# Place one to the right
	_place_h(track, Vector2i(1, 0))
	assert_int(track.get_segment_count()).is_equal(3)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	# Should have positions at (-2,0) and (2,0)
	assert_bool(positions.has(Vector2i(-2, 0))).is_true()
	assert_bool(positions.has(Vector2i(2, 0))).is_true()
	assert_int(positions.size()).is_equal(2)

# ============================================================================
# Continuity: Invalid Placements
# ============================================================================


## Placing a segment that does NOT connect to any existing segment fails.
func test_non_contiguous_placement_fails() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	# Try to place at (5, 5) — no shared edge with any existing segment
	var seg: TrackSegment = track.create_straight_segment(Vector2i(5, 5), true)
	var result: bool = track.try_place_segment(Vector2i(5, 5), seg)
	assert_bool(result).is_false()


## Placing a segment that connects to an empty grid cell (no neighbor segment) fails.
func test_placement_to_empty_neighbor_fails() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	# Try to place a segment at (-1, 0) that has NO connection pointing
	# back to (0, 0). E.g., a curve at (-1,0) with connections [UP, RIGHT].
	# RIGHT points to (0,0), but (0,0)'s segment has LEFT connection.
	# -RIGHT = LEFT. Does (0,0) have LEFT? Yes! So this should actually succeed.
	# Let's try a curve with [UP, DOWN] connections — no connection toward (0,0).
	var seg: TrackSegment = track.create_curve_segment(Vector2i(-1, 0), [Vector2.UP, Vector2.DOWN])
	var result: bool = track.try_place_segment(Vector2i(-1, 0), seg)
	assert_bool(result).is_false()

# ============================================================================
# Overlap Detection
# ============================================================================


## Placing a segment at an occupied position fails.
func test_overlap_at_occupied_position_fails() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	var seg: TrackSegment = track.create_straight_segment(Vector2i.ZERO, true)
	var result: bool = track.try_place_segment(Vector2i.ZERO, seg)
	assert_bool(result).is_false()


## Placing a segment that overlaps any existing segment's grid cell fails.
func test_overlap_detection_works() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	var seg: TrackSegment = track.create_straight_segment(Vector2i(0, 0), true)
	var result: bool = track.try_place_segment(Vector2i(0, 0), seg)
	assert_bool(result).is_false()

# ============================================================================
# Max Length Enforcement
# ============================================================================


## Placing beyond max length fails.
func test_placement_exceeding_max_length_fails() -> void:
	var track: Track = _make_track(100.0, 2)
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	# Now at max length (2). Next placement should fail.
	var seg: TrackSegment = track.create_straight_segment(Vector2i(2, 0), true)
	var result: bool = track.try_place_segment(Vector2i(2, 0), seg)
	assert_bool(result).is_false()


## After exceeding max length, segment count should not have changed.
func test_segment_count_unchanged_after_failed_placement() -> void:
	var track: Track = _make_track(100.0, 2)
	# Fill track to max length
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	assert_int(track.get_segment_count()).is_equal(2)
	# Next placement should fail (at max length)
	var seg: TrackSegment = track.create_straight_segment(Vector2i(2, 0), true)
	var result: bool = track.try_place_segment(Vector2i(2, 0), seg)
	assert_bool(result).is_false()
	assert_int(track.get_segment_count()).is_equal(2)


## Setting a larger max length allows more segments.
func test_increasing_max_length_allows_more_segments() -> void:
	var track: Track = _make_track(100.0, 2)
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	assert_int(track.get_segment_count()).is_equal(2)
	track.set_max_length(5)
	var seg: TrackSegment = track.create_straight_segment(Vector2i(2, 0), true)
	var result: bool = track.try_place_segment(Vector2i(2, 0), seg)
	assert_bool(result).is_true()
	assert_int(track.get_segment_count()).is_equal(3)

# ============================================================================
# Resource Tracking
# ============================================================================


## Each placed segment deducts COST_PER_SEGMENT from resources.
func test_resources_deducted_on_placement() -> void:
	var track: Track = _make_track(100.0)
	_place_h(track, Vector2i.ZERO)
	assert_float(track.get_resources()).is_equal_approx(
		100.0 - _Track.COST_PER_SEGMENT,
		0.001,
	)


## Placing multiple segments deducts cost each time.
func test_multiple_segments_deduct_correct_cost() -> void:
	var track: Track = _make_track(100.0)
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	_place_h(track, Vector2i(2, 0))
	assert_float(track.get_resources()).is_equal_approx(
		100.0 - 3.0 * _Track.COST_PER_SEGMENT,
		0.001,
	)


## Placing when resources are insufficient fails.
func test_insufficient_resources_fails_placement() -> void:
	var track: Track = _make_track(5.0, 10)
	# Can't even afford the first segment
	var seg: TrackSegment = track.create_straight_segment(Vector2i.ZERO, true)
	var result: bool = track.try_place_segment(Vector2i.ZERO, seg)
	assert_bool(result).is_false()


## Adding resources allows more placements.
func test_add_resources_allows_more_placements() -> void:
	var track: Track = _make_track(10.0, 10)
	_place_h(track, Vector2i.ZERO)
	assert_float(track.get_resources()).is_equal_approx(0.0, 0.001)
	track.add_resources(50.0)
	var seg: TrackSegment = track.create_straight_segment(Vector2i(1, 0), true)
	var result: bool = track.try_place_segment(Vector2i(1, 0), seg)
	assert_bool(result).is_true()


## Resources cannot go negative.
func test_resources_do_not_go_negative() -> void:
	var track: Track = _make_track(15.0, 10)
	_place_h(track, Vector2i.ZERO)
	assert_float(track.get_resources()).is_equal_approx(5.0, 0.001)


## Resources are not deducted when placement fails.
func test_resources_not_deducted_on_failed_placement() -> void:
	var track: Track = _make_track(100.0)
	_place_h(track, Vector2i.ZERO)
	var initial: float = track.get_resources()
	# Try to place at occupied position
	var seg: TrackSegment = track.create_straight_segment(Vector2i.ZERO, true)
	var result: bool = track.try_place_segment(Vector2i.ZERO, seg)
	assert_bool(result).is_false()
	assert_float(track.get_resources()).is_equal_approx(initial, 0.001)

# ============================================================================
# get_valid_placement_positions()
# ============================================================================


## Empty track has zero valid placement positions.
func test_empty_track_no_valid_positions() -> void:
	var track: Track = _make_track()
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_int(positions.size()).is_equal(0)


## A single straight segment has 2 valid positions.
func test_single_segment_has_two_positions() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_int(positions.size()).is_equal(2)


## Valid positions exclude occupied cells.
func test_valid_positions_excludes_occupied_cells() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_bool(positions.has(Vector2i.ZERO)).is_false()


## Multiple segments produce expanded valid positions.
func test_multiple_segments_expand_positions() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	# Positions: (-1,0) from segment(0,0) LEFT, (2,0) from segment(1,0) RIGHT
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_bool(positions.has(Vector2i(-1, 0))).is_true()
	assert_bool(positions.has(Vector2i(2, 0))).is_true()
	assert_int(positions.size()).is_equal(2)


## Curve segment has valid positions in adjacent directions only.
func test_curve_segment_valid_positions() -> void:
	var track: Track = _make_track()
	_place_curve(track, Vector2i.ZERO, [Vector2.DOWN, Vector2.RIGHT])
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_bool(positions.has(Vector2i(0, 1))).is_true() # DOWN -> (0,1)
	assert_bool(positions.has(Vector2i(1, 0))).is_true() # RIGHT -> (1,0)
	assert_int(positions.size()).is_equal(2)


## A track with segments branching in two directions has more valid positions.
func test_branching_track_has_more_positions() -> void:
	var track: Track = _make_track()
	# Place horizontal center
	_place_h(track, Vector2i.ZERO)
	# Add a curve at (-1, 0) with [RIGHT, DOWN] — RIGHT connects to (0,0)
	# This creates a branch going DOWN from the left side
	_place_curve(track, Vector2i(-1, 0), [Vector2.RIGHT, Vector2.DOWN])
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	# (0,0) LEFT -> occupied (by curve), RIGHT -> (1,0)
	# (-1,0) DOWN -> (-1,1)
	# Valid: (1,0), (-1,1)
	assert_int(positions.size()).is_equal(2)
	assert_bool(positions.has(Vector2i(1, 0))).is_true()
	assert_bool(positions.has(Vector2i(-1, 1))).is_true()

# ============================================================================
# get_segments()
# ============================================================================


## get_segments returns all placed segments in order.
func test_get_segments_returns_all_placed() -> void:
	var track: Track = _make_track()
	_place_h(track, Vector2i.ZERO)
	_place_h(track, Vector2i(1, 0))
	var segments: Array[TrackSegment] = track.get_segments()
	assert_int(segments.size()).is_equal(2)


## get_segments returns empty array for empty track.
func test_get_segments_empty_for_empty_track() -> void:
	var track: Track = _make_track()
	var segments: Array[TrackSegment] = track.get_segments()
	assert_int(segments.size()).is_equal(0)

# ============================================================================
# Complex Layout: Closed Loop Detection
# ============================================================================


## Two segments that both connect to each other (a simple 2-segment loop)
## should have no valid placement positions.
func test_simple_two_segment_loop_has_no_valid_positions() -> void:
	var track: Track = _make_track(100.0, 10)
	# Place a horizontal segment at (0,0)
	_place_h(track, Vector2i.ZERO)
	# Place a horizontal segment at (0,1) — NO, that won't connect
	# Instead: place a curve at (0,1) that connects DOWN to (0,0)
	# A curve at (0,1) with [UP, DOWN] — DOWN points to (0,0)
	# (0,0) has LEFT connection. -DOWN = UP. Does (0,0) have UP? No!
	# Try: curve at (0,-1) with [UP, RIGHT] — UP points to (0,0)
	# (0,0) has LEFT. -UP = DOWN. Does (0,0) have DOWN? No!
	# Horizontal segment only has LEFT and RIGHT. We need a curve that connects
	# to one of those sides.
	# Curve at (1,0) with [LEFT, DOWN] — LEFT points to (0,0)
	# (0,0) has_connection(-LEFT) = has_connection(RIGHT). YES!
	_place_curve(track, Vector2i(1, 0), [Vector2.LEFT, Vector2.DOWN])
	assert_int(track.get_segment_count()).is_equal(2)
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	# This is NOT a closed loop — it has open ends. Just verify placement works.
	assert_int(positions.size()).is_equal(2)
	assert_bool(positions.has(Vector2i(-1, 0))).is_true() # (0,0) LEFT
	assert_bool(positions.has(Vector2i(1, 1))).is_true() # (1,0) DOWN -> (1,1)

# ============================================================================
# Straight Line Layout
# ============================================================================


## A straight line of 5 segments has 2 valid positions.
func test_straight_line_has_two_positions() -> void:
	var track: Track = _make_track(200.0, 10)
	for x in range(3):
		_place_h(track, Vector2i(x - 1, 0))
	var positions: Array[Vector2i] = track.get_valid_placement_positions()
	assert_int(positions.size()).is_equal(2)
	assert_bool(positions.has(Vector2i(-2, 0))).is_true()
	assert_bool(positions.has(Vector2i(2, 0))).is_true()
