class_name TrackSegment
## Immutable track segment data model.
##
## A segment is defined by its grid position and which edges it connects to.
## Connections are expressed as direction vectors (Vector2i) pointing from
## this segment's grid cell toward the neighbor it connects to.
##
## Straight segments connect opposite edges.
## Curve segments connect adjacent edges.

var grid_position: Vector2i
## Directions this segment connects to, pointing toward connected neighbors.
## For straight: two opposite directions (e.g., RIGHT and LEFT).
## For curve: two adjacent directions (e.g., RIGHT and DOWN).
## For crossing: four directions (UP, DOWN, LEFT, RIGHT).
var connections: Array[Vector2i]
## Optional base type for segments with ambiguous connections (e.g., 1x1 vs 2x2 curves).
## When set, this overrides the auto-detected type in _connections_to_type_and_orientation.
var base_type: int = -1


## Create a new track segment.
## @param position: Grid cell position (Vector2i)
## @param conns: Array of direction vectors pointing to connected neighbors
## @param base_type: Optional base type to override auto-detection (e.g., CURVE_2X2)
func initialize(position: Vector2i, conns: Array[Vector2i], base_type: int = -1) -> void:
	grid_position = position
	connections = conns
	self.base_type = base_type


## Check if this segment connects to a neighbor in the given direction.
## @param direction: The direction to check (e.g. Vector2.RIGHT)
## @return True if this segment has a connection point toward that neighbor.
func has_connection(direction: Vector2i) -> bool:
	for conn in connections:
		if conn == direction:
			return true
	return false


## Return the segment type based on connection geometry.
## @return 0 = straight (opposite edges), 1 = curve (adjacent edges).
func get_segment_type() -> int:
	if _is_opposite_edges():
		return 0
	return 1


## Check if the two connection edges are opposite (straight) or adjacent (curve).
func _is_opposite_edges() -> bool:
	if connections.size() != 2:
		return false
	var a: Vector2i = connections[0]
	var b: Vector2i = connections[1]
	# Opposite means they sum to zero
	return a == -b
