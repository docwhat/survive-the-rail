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
var connections: Array[Vector2i]


## Create a new track segment.
## @param position: Grid cell position (Vector2i)
## @param conns: Array of direction vectors pointing to connected neighbors
func initialize(position: Vector2i, conns: Array[Vector2i]) -> void:
	grid_position = position
	connections = conns


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
