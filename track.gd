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

const CELL_SIZE: int = 64
## Size of one grid cell in world units.

const COST_PER_SEGMENT: int = 10
## Fixed resource cost for placing any segment.

var segments: Array[TrackSegment] = []
## All placed segments in order of placement.

var occupied_cells: Dictionary
## Map of grid_position (Vector2i) -> true for quick overlap lookup.

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
	occupied_cells = { }


## Create a new straight segment at the given grid position, connecting
## along the specified axis (horizontal or vertical).
## @param position: Grid cell position for the segment center
## @param horizontal: True for LEFT-RIGHT connections, false for UP-DOWN
## @return A new TrackSegment instance.
func create_straight_segment(position: Vector2i, horizontal: bool) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	if horizontal:
		seg.initialize(position, [Vector2.RIGHT, Vector2.LEFT])
	else:
		seg.initialize(position, [Vector2.DOWN, Vector2.UP])
	return seg


## Create a new curve segment at the given grid position with the specified
## connection directions.
## @param position: Grid cell position for the segment center
## @param conns: Two adjacent direction vectors (e.g., [Vector2.RIGHT, Vector2.DOWN])
## @return A new TrackSegment instance.
func create_curve_segment(position: Vector2i, conns: Array[Vector2i]) -> TrackSegment:
	var seg: TrackSegment = TrackSegment.new()
	seg.initialize(position, conns)
	return seg


## Get all valid placement positions — grid cells adjacent to existing
## segment connection points.
## @return Array of Vector2i grid positions where a new segment could be placed.
func get_valid_placement_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var seen: Dictionary = { }

	for seg in segments:
		for dir in seg.connections:
			var neighbor_pos: Vector2i = seg.grid_position + dir
			if not occupied_cells.has(neighbor_pos) and not seen.has(neighbor_pos):
				positions.append(neighbor_pos)
				seen[neighbor_pos] = true

	return positions


## Try to place a segment at the given grid position.
## @param position: Grid cell position to place at
## @param segment: The TrackSegment to place
## @return True if placement succeeded, false otherwise.
func try_place_segment(position: Vector2i, segment: TrackSegment) -> bool:
	# Check overlap
	if occupied_cells.has(position):
		return false

	# Check max length
	if segments.size() >= max_length:
		return false

	# Check resources
	if resources < COST_PER_SEGMENT:
		return false

	# Continuity check: skip if this is the first segment (no existing track to connect to)
	if segments.size() > 0 and not _is_continuous(position, segment):
		return false

	# Place the segment
	segments.append(segment)
	occupied_cells[position] = true
	resources -= COST_PER_SEGMENT
	return true


## Check if placing a segment at the given position maintains continuity.
## A segment is continuous if at least one of its connection points
## aligns with an existing segment's connection on a shared grid edge.
func _is_continuous(position: Vector2i, segment: TrackSegment) -> bool:
	for dir in segment.connections:
		var neighbor_pos: Vector2i = position + dir
		if occupied_cells.has(neighbor_pos):
			var neighbor: TrackSegment = _get_segment_at(neighbor_pos)
			if neighbor != null and neighbor.has_connection(-dir):
				return true
	return false


## Get the segment at a specific grid position, or null if none exists.
func _get_segment_at(position: Vector2i) -> TrackSegment:
	for seg in segments:
		if seg.grid_position == position:
			return seg
	return null


## Get the total number of segments currently placed.
func get_segment_count() -> int:
	return segments.size()


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
	return segments
