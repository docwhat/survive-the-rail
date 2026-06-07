extends Control
## Renders the track data model to visible graphics.
## Draws segments on the canvas with a camera offset.

var track: Track = null
## Reference to the Track data model.

var camera_offset: Vector2 = Vector2.ZERO
## Camera offset to keep the track centered in view.

var show_grid: bool = true
## Whether to draw grid reference lines.

const GRID_COLOR: Color = Color(0.3, 0.4, 0.3, 0.3)
const SEGMENT_COLOR: Color = Color(0.65, 0.65, 0.6)
const SEGMENT_OUTLINE: Color = Color(0.35, 0.35, 0.3)
const START_MARKER: Color = Color(0.2, 0.8, 0.2)


func update(track_model: Track, cam_offset: Vector2) -> void:
	track = track_model
	camera_offset = cam_offset
	queue_redraw()


func _draw() -> void:
	if track == null:
		return

	var center: Vector2 = camera_offset

	# Draw grid reference (centered on camera)
	if show_grid:
		_draw_grid(center)

	# Draw all segments
	for seg in track.get_segments():
		_draw_segment(seg, center)

	# Draw the first segment as a start marker
	if track.get_segment_count() > 0:
		var first_seg: TrackSegment = track.get_segments()[0]
		var screen_center: Vector2 = first_seg.grid_position as Vector2 * Track.CELL_SIZE - center
		draw_circle(screen_center, 8.0, START_MARKER)


## Draw subtle grid lines for reference.
func _draw_grid(center: Vector2) -> void:
	var view_half_w: float = size.x / 2.0
	var view_half_h: float = size.y / 2.0
	var grid_start: float = center.x - view_half_w
	var grid_end: float = center.x + view_half_w
	var line_start: int = floori(grid_start / Track.CELL_SIZE) - 1
	var line_end: int = ceil(grid_end / Track.CELL_SIZE) + 1

	var view_top: float = center.y - view_half_h
	var view_bot: float = center.y + view_half_h
	var row_start: int = floori(view_top / Track.CELL_SIZE) - 1
	var row_end: int = ceil(view_bot / Track.CELL_SIZE) + 1

	for x in range(line_start, line_end + 1):
		var x_coord: float = x * Track.CELL_SIZE
		var y1: float = maxf(view_top, center.y - view_half_h)
		var y2: float = minf(view_bot, center.y + view_half_h)
		var start_pt: Vector2 = Vector2(x_coord, y1) - center + center
		var end_pt: Vector2 = Vector2(x_coord, y2) - center + center
		draw_line(start_pt, end_pt, GRID_COLOR, 1.0)

	for y in range(row_start, row_end + 1):
		var y_coord: float = y * Track.CELL_SIZE
		var x1: float = maxf(grid_start, center.x - view_half_w)
		var x2: float = minf(grid_end, center.x + view_half_w)
		draw_line(Vector2(x1, y_coord), Vector2(x2, y_coord), GRID_COLOR, 1.0)


## Draw a single track segment.
func _draw_segment(seg: TrackSegment, center: Vector2) -> void:
	var screen_pos: Vector2 = seg.grid_position as Vector2 * Track.CELL_SIZE - center
	var seg_type: int = seg.get_segment_type()

	if seg_type == 0:
		_draw_straight_segment(screen_pos, seg)
	else:
		_draw_curve_segment(screen_pos, seg)


## Draw a straight segment as a rectangle.
func _draw_straight_segment(pos: Vector2, seg: TrackSegment) -> void:
	var half_size: float = Track.CELL_SIZE * 0.45
	var conn: Array[Vector2i] = seg.connections

	if conn[0] == Vector2i.RIGHT or conn[0] == Vector2i.LEFT:
		# Horizontal segment
		var rect: Rect2 = Rect2(
			pos.x - half_size,
			pos.y - half_size * 0.3,
			half_size * 2.0,
			half_size * 0.6,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)
	else:
		# Vertical segment
		var rect: Rect2 = Rect2(
			pos.x - half_size * 0.3,
			pos.y - half_size,
			half_size * 0.6,
			half_size * 2.0,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)


## Draw a curve segment as a filled quarter-circle arc.
# The arc center is offset from the grid center so the arc connects
# smoothly with adjacent straight segments.
func _draw_curve_segment(pos: Vector2, seg: TrackSegment) -> void:
	var conn: Array[Vector2i] = seg.connections
	var start_dir: Vector2 = conn[0] as Vector2
	var end_dir: Vector2 = conn[1] as Vector2
	var radius: float = Track.CELL_SIZE

	# Arc geometry matching train.gd
	var arc_entry: Vector2 = pos + start_dir * radius
	var arc_exit: Vector2 = pos + end_dir * radius
	var arc_center: Vector2 = Vector2(arc_entry.x, arc_exit.y)

	# Draw fill polygon
	var filled_points: PackedVector2Array = PackedVector2Array()
	filled_points.append(arc_entry)
	filled_points.append(arc_exit)
	filled_points.append(arc_entry)
	draw_colored_polygon(filled_points, SEGMENT_COLOR)

	# Draw the arc outline using the same arc function
	var arc_points: PackedVector2Array = _draw_arc(arc_center, start_dir, end_dir, radius)
	draw_polyline(arc_points, SEGMENT_OUTLINE, 2.0)

	# Draw subtle connecting lines to arc center (shows the radius)
	draw_line(arc_center, arc_entry, SEGMENT_OUTLINE, 1.0)
	draw_line(arc_center, arc_exit, SEGMENT_OUTLINE, 1.0)


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

	# Generate intermediate points (exclude endpoints to avoid duplication)
	for i in range(1, steps):
		var t: float = i / steps
		var angle: float = start_angle + diff * t
		var px: float = center.x + cos(angle) * radius
		var py: float = center.y + sin(angle) * radius
		points.append(Vector2(px, py))

	return points
