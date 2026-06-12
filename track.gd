class_name Track
## Manages track segments, placement validation, and continuity rules.
##
## Track is an immutable-data model — it contains segment definitions but
## no scene nodes. This makes it fully testable with GUT without a Godot
## scene context.
##
## Continuity rule: a new segment can only be placed if at least one of its
## connection points aligns with an existing segment's connection on a
## shared grid edge.
##
## Data model: normalized 3NF with DataTable (cell->SegmentID),
## SegmentTable (SegmentID->(type_id, orientation)), and read-only
## SegmentType catalog.

const CELL_SIZE: int = 64
## Size of one grid cell in world units.

const COST_PER_SEGMENT: int = 10
## Fixed resource cost for placing any segment.

# --- Data model components ---
var _data_table: DataTable = DataTable.new()
var _segment_table: SegmentTable = SegmentTable.new()
var _next_segment_id: int = 1

var resources: float = 0.0
## Available resources for placing segments.

var max_length: int = 100
## Maximum number of segments allowed on the track.


## Initialize the track with starting resources and max length.
## @param starting_resources: Initial resource pool for placing segments
## @param starting_max_length: Initial maximum segment count
func initialize(starting_resources: float, starting_max_length: int) -> void:
	resources = starting_resources
	max_length = starting_max_length
	_data_table = DataTable.new()
	_segment_table = SegmentTable.new()
	_next_segment_id = 1


## Create a new straight segment at the given grid position, connecting
## along the specified axis (horizontal or vertical).
## @param position: Grid cell position for the segment center
## @param horizontal: True for LEFT-RIGHT connections, false for UP-DOWN
## @return A new TrackSegment instance.
func create_straight_segment(position: Vector2i, horizontal: bool) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	if horizontal:
		seg.initialize(position, [Vector2i.RIGHT, Vector2i.LEFT])
	else:
		seg.initialize(position, [Vector2i.DOWN, Vector2i.UP])
	return seg


## Create a new curve segment at the given grid position with the specified
## connection directions.
## @param position: Grid cell position for the segment center
## @param conns: Two adjacent direction vectors (e.g., [Vector2i.RIGHT, Vector2i.DOWN])
## @return A new TrackSegment instance.
func create_curve_segment(position: Vector2i, conns: Array[Vector2i]) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(position, conns)
	return seg


## Create a new 2x2 curve segment at the given grid position with the specified
## connection directions. The position is the top-left cell of the 2x2 area.
## @param position: Grid cell position for the top-left corner of the 2x2 curve
## @param conns: Two adjacent direction vectors (e.g., [Vector2i.LEFT, Vector2i.DOWN])
## @return A new TrackSegment instance.
func create_curve_2x2_segment(position: Vector2i, conns: Array[Vector2i]) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(position, conns, SegmentType.CURVE_2X2)
	return seg


## Create a new 90° crossing segment at the given grid position.
## The position is the center cell of the cross-shaped segment (5 cells total).
## @param position: Grid cell position for the center of the crossing
## @return A new TrackSegment instance.
func create_crossing_segment(position: Vector2i) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(position, [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT])
	return seg


## Get all valid placement positions — grid cells adjacent to existing
## segment connection points.
## @return Array of Vector2i grid positions where a new segment could be placed.
func get_valid_placement_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var seen: Dictionary = { }

	for seg_id in _segment_table.get_all_ids():
		var type_id: int = _segment_table.get_segment_type(seg_id)
		var orientation: int = _segment_table.get_orientation(seg_id)
		var cell_positions: Array[Vector2i] = _data_table.get_cells_by_segment_id(seg_id)
		var ref_pos: Vector2i = cell_positions[0]
		var conns: Array[Vector2i] = _get_valid_connections(type_id, orientation)
		for dir in conns:
			var neighbor_pos: Vector2i = ref_pos + dir
			if not _data_table.contains(neighbor_pos) and not seen.has(neighbor_pos):
				positions.append(neighbor_pos)
				seen[neighbor_pos] = true

	return positions


## Try to place a segment at the given grid position.
## @param position: Grid cell position to place at
## @param segment: The TrackSegment to place
## @return True if placement succeeded, false otherwise.
func try_place_segment(position: Vector2i, segment: TrackSegment) -> bool:
	# Determine type and orientation from segment connections
	var result: Array[int] = _connections_to_type_and_orientation(
		segment.connections,
		segment,
	)
	var type_id: int = result[0]
	var orientation: int = result[1]

	# Check max length
	if _segment_table.get_count() >= max_length:
		return false

	# Check resources
	if resources < COST_PER_SEGMENT:
		return false

	# Expand segment cells based on type
	var cells: Array[Vector2i] = _expand_segment_cells(position, type_id, orientation)

	# Check overlap for all cells
	for cell in cells:
		if _data_table.contains(cell):
			return false

	# Continuity check: skip if this is the first segment (no existing track to connect to)
	if _segment_table.get_count() > 0 and not _is_continuous(position, type_id, orientation):
		return false

	# Place the segment in the data model
	var seg_id: int = _next_segment_id
	_next_segment_id += 1
	_segment_table.add_segment(seg_id, type_id, orientation)
	for cell in cells:
		_data_table.set_cell(cell, seg_id)
	resources -= COST_PER_SEGMENT
	return true


## Expand a segment's footprint into its constituent cells.
## For 1x1 and straights: returns a single cell.
## For 2x2 curves: returns 4 cells.
## For crossings: returns 5 cells (center + 4 arms).
func _expand_segment_cells(position: Vector2i, type_id: int, _orientation: int) -> Array[Vector2i]:
	match type_id:
		SegmentType.CURVE_2X2:
			# 2x2 block anchored at position (top-left)
			return [
				position,
				Vector2i(position.x + 1, position.y),
				Vector2i(position.x, position.y + 1),
				Vector2i(position.x + 1, position.y + 1),
			]
		SegmentType.CROSSING_90:
			# Cross shape: center + 4 arms
			return [
				position,
				Vector2i(position.x, position.y - 1),
				Vector2i(position.x, position.y + 1),
				Vector2i(position.x - 1, position.y),
				Vector2i(position.x + 1, position.y),
			]
		_:
			return [position]
		_:
			return [position]
	return [position]


## Check if placing a segment at the given position maintains continuity.
## A segment is continuous if at least one of its connection points
## aligns with an existing segment's connection on a shared grid edge.
func _is_continuous(position: Vector2i, type_id: int, orientation: int) -> bool:
	var conns: Array[Vector2i] = _get_valid_connections(type_id, orientation)
	for dir in conns:
		var neighbor_pos: Vector2i = position + dir
		if _data_table.contains(neighbor_pos):
			var neighbor_id: int = _data_table.get_cell(neighbor_pos)
			var neighbor_type: int = _segment_table.get_segment_type(neighbor_id)
			var neighbor_orientation: int = _segment_table.get_orientation(neighbor_id)
			if _is_entrance_pair_match(neighbor_type, neighbor_orientation, -dir):
				return true
	return false


## Get the total number of segments currently placed.
func get_segment_count() -> int:
	return _segment_table.get_count()


## Get the current resource balance.
func get_resources() -> float:
	return resources


## Get the maximum allowed segment count.
func get_max_length() -> int:
	return max_length


## Set a new maximum segment count.
func set_max_length(new_max: int) -> void:
	max_length = new_max


## Add resources to the track pool.
func add_resources(amount: float) -> void:
	resources += amount


## Get all placed segments (for iteration).
func get_segments() -> Array[TrackSegment]:
	var result: Array[TrackSegment] = []
	for seg_id in _segment_table.get_all_ids():
		var type_id: int = _segment_table.get_segment_type(seg_id)
		var orientation: int = _segment_table.get_orientation(seg_id)
		var cell_positions: Array[Vector2i] = _data_table.get_cells_by_segment_id(seg_id)
		var ref_pos: Vector2i = cell_positions[0]
		var conns: Array[Vector2i] = _get_valid_connections(type_id, orientation)
		var seg: TrackSegment = TrackSegment.new()
		seg.initialize(ref_pos, conns)
		result.append(seg)
	return result


## Get all segment IDs for rendering.
## @return Array of all segment IDs in the track.
func get_all_segment_ids() -> Array:
	return _segment_table.get_all_ids()


## Get segment type by ID.
## @param seg_id: The segment ID.
## @return The type ID for this segment.
func get_segment_type_by_id(seg_id: int) -> int:
	return _segment_table.get_segment_type(seg_id)


## Get segment orientation by ID.
## @param seg_id: The segment ID.
## @return The orientation for this segment.
func get_segment_orientation_by_id(seg_id: int) -> int:
	return _segment_table.get_orientation(seg_id)


## Get cells for a segment by ID.
## @param seg_id: The segment ID.
## @return Array of cell positions for this segment.
func get_cells_by_segment_id(seg_id: int) -> Array[Vector2i]:
	return _data_table.get_cells_by_segment_id(seg_id)

# ============================================================================
# Helper methods for data model integration
# ============================================================================


## Map connection directions to (type_id, orientation).
## Uses the segment's base_type when available to disambiguate curve types.
## @param conns: Array of Vector2i connection directions.
## @param seg: The segment (used for base_type lookup).
## @return Array[int] of [type_id, orientation].
func _connections_to_type_and_orientation(conns: Array[Vector2i], seg: TrackSegment) -> Array[int]:
	# Handle 4-connection crossing segments
	if conns.size() == 4:
		return [SegmentType.CROSSING_90, 0]

	# Check for straight segments (opposite directions)
	if conns.size() == 2 and _are_opposite(conns[0], conns[1]):
		if _is_horizontal(conns[0]) or _is_horizontal(conns[1]):
			return [SegmentType.STRAIGHT_H, 0]
		else:
			return [SegmentType.STRAIGHT_V, 0]

	# Curve segment (2 adjacent connections)
	if conns.size() == 2:
		# Use base_type if set (for 2x2 curves), otherwise default to 1x1
		var type_id: int = seg.base_type if seg.base_type >= 0 else SegmentType.CURVE_1X1
		return _curve_to_type_and_orientation(conns[0], conns[1], type_id)

	return [SegmentType.CURVE_1X1, 0]


## Check if two directions are opposite.
func _are_opposite(a: Vector2i, b: Vector2i) -> bool:
	return a == -b


## Check if a direction is horizontal.
func _is_horizontal(dir: Vector2i) -> bool:
	return dir.y == 0


## Map curve direction pair to (type_id, orientation).
## @param a: First connection direction.
## @param b: Second connection direction.
## @param type_id: The base type (CURVE_1X1 or CURVE_2X2).
func _curve_to_type_and_orientation(a: Vector2i, b: Vector2i, type_id: int) -> Array[int]:
	# Determine canonical orientation based on direction pair
	# Using the unordered pair {a, b} mapped to orientations 0-3:
	# {LEFT, UP} -> orientation 0
	# {LEFT, DOWN} -> orientation 1
	# {RIGHT, UP} -> orientation 2
	# {RIGHT, DOWN} -> orientation 3
	var dir_a: int = _direction_to_index(a)
	var dir_b: int = _direction_to_index(b)
	# Use the direction with x=0 (vertical) to distinguish horizontal vs vertical
	if a.x == 0:
		# 'a' is vertical (UP or DOWN)
		if b.x == -1: # LEFT
			return [type_id, 0]
		else: # RIGHT
			if a.y == -1: # UP + RIGHT
				return [type_id, 2]
			else: # DOWN + RIGHT
				return [type_id, 3]
	else:
		# 'a' is horizontal (LEFT or RIGHT), 'b' is vertical
		if b.y == -1: # UP
			if a.x == -1: # LEFT + UP
				return [type_id, 0]
			else: # RIGHT + UP
				return [type_id, 2]
		else: # DOWN
			if a.x == -1: # LEFT + DOWN
				return [type_id, 1]
			else: # RIGHT + DOWN
				return [type_id, 3]


## Convert a direction vector to a canonical index.
func _direction_to_index(dir: Vector2i) -> int:
	match dir:
		Vector2i.RIGHT:
			return 0
		Vector2i.LEFT:
			return 1
		Vector2i.DOWN:
			return 2
		Vector2i.UP:
			return 3
	return -1


## Get valid connection directions for a (type_id, orientation).
func _get_valid_connections(type_id: int, orientation: int) -> Array[Vector2i]:
	match type_id:
		SegmentType.STRAIGHT_H:
			if orientation == 0:
				return [Vector2i.RIGHT, Vector2i.LEFT]
			else:
				return [Vector2i.DOWN, Vector2i.UP]
		SegmentType.STRAIGHT_V:
			if orientation == 0:
				return [Vector2i.DOWN, Vector2i.UP]
			return [Vector2i.RIGHT, Vector2i.LEFT]
		SegmentType.CURVE_1X1:
			match orientation:
				0:
					return [Vector2i.LEFT, Vector2i.UP]
				1:
					return [Vector2i.LEFT, Vector2i.DOWN]
				2:
					return [Vector2i.RIGHT, Vector2i.UP]
				3:
					return [Vector2i.RIGHT, Vector2i.DOWN]
		SegmentType.CURVE_2X2:
			# Same orientation mapping as CURVE_1X1 for consistency in path building
			match orientation:
				0:
					return [Vector2i.LEFT, Vector2i.UP]
				1:
					return [Vector2i.LEFT, Vector2i.DOWN]
				2:
					return [Vector2i.RIGHT, Vector2i.UP]
				3:
					return [Vector2i.RIGHT, Vector2i.DOWN]
		SegmentType.CROSSING_90:
			return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		_:
			return []
	return []


## Check if placing direction dir at a segment's boundary matches the neighbor's entrance.
func _is_entrance_pair_match(type_id: int, orientation: int, dir: Vector2i) -> bool:
	var valid_conns: Array[Vector2i] = _get_valid_connections(type_id, orientation)
	return valid_conns.has(dir)


## Build a Path2D from the current track data model.
## @return A Path2D containing all segment geometries, or null if empty.
func build_path() -> Path2D:
	var builder: TrackPathBuilder = TrackPathBuilder.new()
	return builder.build_full_path(_data_table, _segment_table)
