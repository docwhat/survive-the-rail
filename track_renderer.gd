extends Control
## Renders the track data model to visible graphics.
## Draws segments on the canvas using grid positions.

var track: Track = null
## Reference to the Track data model.

var show_grid: bool = true
## Whether to draw grid reference lines.

const GRID_COLOR: Color = Color(0.3, 0.4, 0.3, 0.3)
const SEGMENT_COLOR: Color = Color(0.65, 0.65, 0.6)
const SEGMENT_OUTLINE: Color = Color(0.35, 0.35, 0.3)
const START_MARKER: Color = Color(0.2, 0.8, 0.2)


func update(track_model: Track) -> void:
	track = track_model
	queue_redraw()


func _draw() -> void:
	if track == null:
		return

	# Draw grid reference
	if show_grid:
		_draw_grid()

	# Draw all segments
	for seg in track.get_segments():
		_draw_segment(seg)

	# Draw the first segment as a start marker
	if track.get_segment_count() > 0:
		var first_seg: TrackSegment = track.get_segments()[0]
		var center: Vector2 = first_seg.grid_position as Vector2 * Track.CELL_SIZE
		draw_circle(center, 8.0, START_MARKER)


## Draw subtle grid lines for reference.
func _draw_grid() -> void:
	for x in range(-20, 21):
		for y in range(-20, 21):
			var world_pos: Vector2 = Vector2(x * Track.CELL_SIZE, y * Track.CELL_SIZE)
			draw_line(world_pos, world_pos + Vector2.RIGHT * Track.CELL_SIZE, GRID_COLOR, 1.0)
			draw_line(world_pos, world_pos + Vector2.DOWN * Track.CELL_SIZE, GRID_COLOR, 1.0)


## Draw a single track segment.
func _draw_segment(seg: TrackSegment) -> void:
	var center: Vector2 = seg.grid_position as Vector2 * Track.CELL_SIZE
	var seg_type: int = seg.get_segment_type()

	if seg_type == 0:
		_draw_straight_segment(center, seg)
	else:
		_draw_curve_segment(center, seg)


## Draw a straight segment as a rectangle.
func _draw_straight_segment(center: Vector2, seg: TrackSegment) -> void:
	var half_size: float = Track.CELL_SIZE * 0.45
	var conn: Array[Vector2i] = seg.connections

	if conn[0] == Vector2i.RIGHT or conn[0] == Vector2i.LEFT:
		# Horizontal segment
		var rect: Rect2 = Rect2(
			center.x - half_size,
			center.y - half_size * 0.3,
			half_size * 2.0,
			half_size * 0.6,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)
	else:
		# Vertical segment
		var rect: Rect2 = Rect2(
			center.x - half_size * 0.3,
			center.y - half_size,
			half_size * 0.6,
			half_size * 2.0,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)


## Draw a curve segment as an arc.
func _draw_curve_segment(center: Vector2, seg: TrackSegment) -> void:
	var half_size: float = Track.CELL_SIZE * 0.45
	var conn: Array[Vector2i] = seg.connections

	var start_dir: Vector2 = conn[0] as Vector2
	var end_dir: Vector2 = conn[1] as Vector2

	# Draw connecting line from center to each endpoint
	draw_line(center, center + start_dir * half_size * 0.8, SEGMENT_OUTLINE, 2.0)
	draw_line(center, center + end_dir * half_size * 0.8, SEGMENT_OUTLINE, 2.0)

	# Draw the arc connecting the two arms
	var arc_points: PackedVector2Array = _draw_arc(center, start_dir, end_dir, half_size * 0.8)
	draw_polyline(arc_points, SEGMENT_OUTLINE, 2.0)

	# Fill the curve area
	var filled_points: PackedVector2Array = PackedVector2Array()
	filled_points.append(center)
	for p in arc_points:
		filled_points.append(p)
	filled_points.append(center)
	draw_colored_polygon(filled_points, SEGMENT_COLOR)


## Generate arc points between two directions at a center point.
func _draw_arc(
		center: Vector2,
		start_dir: Vector2,
		end_dir: Vector2,
		radius: float,
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 12

	var start_angle: float = atan2(start_dir.y, start_dir.x)
	var end_angle: float = atan2(end_dir.y, end_dir.x)

	# Determine rotation direction (curves turn 90 degrees)
	var diff: float = end_angle - start_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	for i in range(steps + 1):
		var t: float = i / steps
		var angle: float = start_angle + diff * t
		var px: float = center.x + cos(angle) * radius
		var py: float = center.y + sin(angle) * radius
		points.append(Vector2(px, py))

	return points
