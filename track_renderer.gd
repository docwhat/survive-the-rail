class_name TrackRenderer
extends Control
## Renders the track data model to visible graphics.
## Draws segments on the canvas with a camera offset.

var track: Track = null
## Reference to the Track data model.

var camera_offset: Vector2 = Vector2.ZERO
## Camera offset to keep the track centered in view.

var show_grid: bool = true
## Whether to draw grid reference lines.

var preview_cell: Vector2i = Vector2i(-1, -1)
## Preview cell position for placement preview.

var preview_type_id: int = -1
## Preview segment type ID.

var preview_orientation: int = -1
## Preview segment orientation.

var preview_valid_positions: Array[Vector2i] = []
## Valid placement positions for preview.

const GRID_COLOR: Color = Color(0.3, 0.4, 0.3, 0.3)
const SEGMENT_COLOR: Color = Color(0.65, 0.65, 0.6)
const SEGMENT_OUTLINE: Color = Color(0.35, 0.35, 0.3)
const START_MARKER: Color = Color(0.2, 0.8, 0.2)
const PREVIEW_COLOR: Color = Color(0.65, 0.65, 0.6, 0.4)
const PREVIEW_OUTLINE: Color = Color(0.35, 0.35, 0.3, 0.4)
const ENTRANCE_MARKER_COLOR: Color = Color(0.8, 0.8, 0.2)
const VALID_POS_COLOR: Color = Color(0.5, 0.5, 0.5, 0.5)

# Segment type IDs (matches SegmentType)
const _STRAIGHT_H: int = 0
const _STRAIGHT_V: int = 1
const _CURVE_1X1: int = 2
const _CURVE_2X2: int = 3
const _CROSSING_90: int = 4


func update(track_model: Track, cam_offset: Vector2) -> void:
	track = track_model
	camera_offset = cam_offset
	preview_cell = Vector2i(-1, -1)
	preview_type_id = -1
	preview_orientation = -1
	preview_valid_positions = []
	queue_redraw()


## Set placement preview state.
func set_preview(cell: Vector2i, seg_type: int, orientation: int, valid_positions: Array[Vector2i]) -> void:
	preview_cell = cell
	preview_type_id = seg_type
	preview_orientation = orientation
	preview_valid_positions = valid_positions
	queue_redraw()


func _draw() -> void:
	if track == null:
		return

	var center: Vector2 = camera_offset

	# Draw grid reference (centered on camera)
	if show_grid:
		_draw_grid(center)

	# Draw all segments from the data model
	var all_seg_ids: Array = track.get_all_segment_ids()
	for seg_id in all_seg_ids:
		var type_id: int = track.get_segment_type_by_id(seg_id)
		var orientation: int = track.get_segment_orientation_by_id(seg_id)
		var cells: Array[Vector2i] = track.get_cells_by_segment_id(seg_id)
		if cells.size() == 0:
			continue

		_draw_segment_from_data(cells, type_id, orientation, center)

	# Draw start marker on first segment
	if track.get_segment_count() > 0:
		var first_id: int = track.get_all_segment_ids()[0]
		var first_type: int = track.get_segment_type_by_id(first_id)
		var first_cells: Array[Vector2i] = track.get_cells_by_segment_id(first_id)
		if first_cells.size() > 0:
			var screen_center: Vector2 = first_cells[0] as Vector2 * Track.CELL_SIZE - center
			draw_circle(screen_center, 8.0, START_MARKER)

	# Draw preview graphics if active
	if preview_cell.x >= 0:
		_draw_preview(center)

	# Draw valid placement positions
	_draw_valid_positions(center)


## Draw grid lines for reference.
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
		var x2: float = minf(grid_end, center.x - view_half_w)
		draw_line(Vector2(x1, y_coord), Vector2(x2, y_coord), GRID_COLOR, 1.0)


## Dispatch segment drawing based on type from the data model.
func _draw_segment_from_data(cells: Array[Vector2i], type_id: int, orientation: int, center: Vector2) -> void:
	match type_id:
		_STRAIGHT_H, _STRAIGHT_V:
			_draw_straight_segment(cells, type_id, orientation, center)
		_CURVE_1X1, _CURVE_2X2:
			_draw_curve_segment(cells, type_id, orientation, center)
		_CROSSING_90:
			_draw_crossing_segment(cells, type_id, orientation, center)


## Draw a straight segment from the data model.
func _draw_straight_segment(cells: Array[Vector2i], type_id: int, orientation: int, center: Vector2) -> void:
	if cells.size() == 0:
		return

	match cells.size():
		1:
			_draw_single_straight(cells[0], type_id, orientation, center)
		_:
			_draw_multi_straight(cells, type_id, orientation, center)


## Draw a single-cell straight segment.
func _draw_single_straight(cell: Vector2i, type_id: int, orientation: int, center: Vector2) -> void:
	var screen_pos: Vector2 = cell as Vector2 * Track.CELL_SIZE - center
	var half_size: float = Track.CELL_SIZE * 0.45

	var is_horizontal: bool = (type_id == _STRAIGHT_H and orientation % 2 == 0) or \
			(type_id == _STRAIGHT_V and orientation % 2 != 0)

	if is_horizontal:
		# Horizontal or rotated horizontal
		var rect: Rect2 = Rect2(
			screen_pos.x - half_size,
			screen_pos.y - half_size * 0.3,
			half_size * 2.0,
			half_size * 0.6,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)
	else:
		# Vertical or rotated vertical
		var rect: Rect2 = Rect2(
			screen_pos.x - half_size * 0.3,
			screen_pos.y - half_size,
			half_size * 0.6,
			half_size * 2.0,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)


## Draw a multi-cell straight segment.
func _draw_multi_straight(cells: Array[Vector2i], type_id: int, orientation: int, center: Vector2) -> void:
	var half_size: float = Track.CELL_SIZE * 0.45
	var first: Vector2 = cells[0] as Vector2 * Track.CELL_SIZE - center
	var last: Vector2 = cells[cells.size() - 1] as Vector2 * Track.CELL_SIZE - center

	# Determine if primarily horizontal or vertical
	var dx: float = absf(last.x - first.x)
	var dy: float = absf(last.y - first.y)
	var is_horizontal: bool = dx >= dy

	if is_horizontal:
		var rect: Rect2 = Rect2(
			minf(first.x, last.x) - half_size,
			first.y - half_size * 0.3,
			absf(last.x - first.x) + half_size * 2.0,
			half_size * 0.6,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)
	else:
		var rect: Rect2 = Rect2(
			first.x - half_size * 0.3,
			minf(first.y, last.y) - half_size,
			half_size * 0.6,
			absf(last.y - first.y) + half_size * 2.0,
		)
		draw_rect(rect, SEGMENT_COLOR, false)
		draw_rect(rect, SEGMENT_OUTLINE, true)


## Draw a curve segment from the data model.
func _draw_curve_segment(cells: Array[Vector2i], type_id: int, orientation: int, center: Vector2) -> void:
	match cells.size():
		1:
			_draw_1x1_curve(cells[0], orientation, center)
		4:
			_draw_2x2_curve(cells, orientation, center)


## Draw a 1x1 curve segment.
func _draw_1x1_curve(cell: Vector2i, orientation: int, center: Vector2) -> void:
	var screen_pos: Vector2 = cell as Vector2 * Track.CELL_SIZE - center
	var radius: float = 32.0

	var entry_dir: Vector2i = _get_curve_entry(orientation, true)
	var exit_dir: Vector2i = _get_curve_entry(orientation, false)

	var start_dir: Vector2 = entry_dir as Vector2
	var end_dir: Vector2 = exit_dir as Vector2

	# Draw fill polygon
	var entry_point: Vector2 = screen_pos + start_dir * radius
	var exit_point: Vector2 = screen_pos + end_dir * radius
	var filled_points: PackedVector2Array = PackedVector2Array()
	filled_points.append(screen_pos)
	filled_points.append(entry_point)
	filled_points.append(exit_point)
	filled_points.append(screen_pos)
	draw_colored_polygon(filled_points, SEGMENT_COLOR)

	# Draw arc outline
	var arc_points: PackedVector2Array = _draw_arc(screen_pos, start_dir, end_dir, radius)
	draw_polyline(arc_points, SEGMENT_OUTLINE, 2.0)


## Draw a 2x2 curve segment.
func _draw_2x2_curve(cells: Array[Vector2i], orientation: int, center: Vector2) -> void:
	var radius: float = 48.0

	# Find the entry and exit cells based on orientation
	var entry_dir: Vector2i = _get_curve_entry(orientation, true)
	var exit_dir: Vector2i = _get_curve_entry(orientation, false)

	# The entry cell is the one in the entry direction from center
	var center_cell: Vector2i = cells[0]
	for cell in cells:
		var neighbors: Array[Vector2i] = _get_neighbors_in_group(cells, cell)
		if neighbors.size() >= 2:
			center_cell = cell
			break

	var screen_center: Vector2 = center_cell as Vector2 * Track.CELL_SIZE - center
	var entry_point: Vector2 = screen_center + (entry_dir as Vector2) * radius
	var exit_point: Vector2 = screen_center + (exit_dir as Vector2) * radius

	# Draw fill polygon
	var filled_points: PackedVector2Array = PackedVector2Array()
	filled_points.append(screen_center)
	filled_points.append(entry_point)
	filled_points.append(exit_point)
	filled_points.append(screen_center)
	draw_colored_polygon(filled_points, SEGMENT_COLOR)

	# Draw arc outline
	var arc_points: PackedVector2Array = _draw_arc(screen_center, entry_dir as Vector2, exit_dir as Vector2, radius)
	draw_polyline(arc_points, SEGMENT_OUTLINE, 2.0)


## Draw a crossing segment (cross shape).
func _draw_crossing_segment(cells: Array[Vector2i], type_id: int, orientation: int, center: Vector2) -> void:
	if cells.size() < 5:
		return

	# Find center cell
	var center_cell: Vector2i = cells[0]
	for cell in cells:
		var neighbors: Array[Vector2i] = _get_neighbors_in_group(cells, cell)
		if neighbors.size() >= 4:
			center_cell = cell
			break

	var screen_center: Vector2 = center_cell as Vector2 * Track.CELL_SIZE - center
	var half_size: float = Track.CELL_SIZE * 0.45

	# Draw cross shape: horizontal + vertical rectangles
	var h_rect: Rect2 = Rect2(
		screen_center.x - half_size * 2.0,
		screen_center.y - half_size * 0.3,
		half_size * 4.0,
		half_size * 0.6,
	)
	draw_rect(h_rect, SEGMENT_COLOR, false)
	draw_rect(h_rect, SEGMENT_OUTLINE, true)

	var v_rect: Rect2 = Rect2(
		screen_center.x - half_size * 0.3,
		screen_center.y - half_size * 2.0,
		half_size * 0.6,
		half_size * 4.0,
	)
	draw_rect(v_rect, SEGMENT_COLOR, false)
	draw_rect(v_rect, SEGMENT_OUTLINE, true)


## Draw preview graphics for a placement preview.
func _draw_preview(center: Vector2) -> void:
	if preview_cell.x < 0 or preview_type_id < 0:
		return

	var screen_pos: Vector2 = preview_cell as Vector2 * Track.CELL_SIZE - center

	match preview_type_id:
		_STRAIGHT_H, _STRAIGHT_V:
			_draw_preview_straight(preview_cell, preview_type_id, preview_orientation, screen_pos, center)
		_CURVE_1X1, _CURVE_2X2:
			_draw_preview_curve(preview_cell, preview_type_id, preview_orientation, screen_pos, center)
		_CROSSING_90:
			_draw_preview_crossing(preview_cell, preview_type_id, preview_orientation, screen_pos, center)

	# Draw entrance markers on preview
	_draw_entrance_markers(preview_cell, preview_type_id, preview_orientation, center)


## Draw preview for a straight segment.
func _draw_preview_straight(cell: Vector2i, type_id: int, orientation: int, screen_pos: Vector2, center: Vector2) -> void:
	var half_size: float = Track.CELL_SIZE * 0.45
	var is_horizontal: bool = (type_id == _STRAIGHT_H and orientation % 2 == 0) or \
			(type_id == _STRAIGHT_V and orientation % 2 != 0)

	if is_horizontal:
		var rect: Rect2 = Rect2(
			screen_pos.x - half_size,
			screen_pos.y - half_size * 0.3,
			half_size * 2.0,
			half_size * 0.6,
		)
		draw_rect(rect, PREVIEW_COLOR, false)
		draw_rect(rect, PREVIEW_OUTLINE, true)
	else:
		var rect: Rect2 = Rect2(
			screen_pos.x - half_size * 0.3,
			screen_pos.y - half_size,
			half_size * 0.6,
			half_size * 2.0,
		)
		draw_rect(rect, PREVIEW_COLOR, false)
		draw_rect(rect, PREVIEW_OUTLINE, true)


## Draw preview for a curve segment.
func _draw_preview_curve(cell: Vector2i, type_id: int, orientation: int, screen_pos: Vector2, center: Vector2) -> void:
	var radius: float = 32.0
	var entry_dir: Vector2 = _get_curve_entry(orientation, true) as Vector2
	var exit_dir: Vector2 = _get_curve_entry(orientation, false) as Vector2

	var entry_point: Vector2 = screen_pos + entry_dir * radius
	var exit_point: Vector2 = screen_pos + exit_dir * radius

	var filled_points: PackedVector2Array = PackedVector2Array()
	filled_points.append(screen_pos)
	filled_points.append(entry_point)
	filled_points.append(exit_point)
	filled_points.append(screen_pos)
	draw_colored_polygon(filled_points, PREVIEW_COLOR)

	var arc_points: PackedVector2Array = _draw_arc(screen_pos, entry_dir, exit_dir, radius)
	draw_polyline(arc_points, PREVIEW_OUTLINE, 2.0)


## Draw preview for a crossing segment.
func _draw_preview_crossing(cell: Vector2i, type_id: int, orientation: int, screen_pos: Vector2, center: Vector2) -> void:
	var half_size: float = Track.CELL_SIZE * 0.45

	var h_rect: Rect2 = Rect2(
		screen_pos.x - half_size * 2.0,
		screen_pos.y - half_size * 0.3,
		half_size * 4.0,
		half_size * 0.6,
	)
	draw_rect(h_rect, PREVIEW_COLOR, false)
	draw_rect(h_rect, PREVIEW_OUTLINE, true)

	var v_rect: Rect2 = Rect2(
		screen_pos.x - half_size * 0.3,
		screen_pos.y - half_size * 2.0,
		half_size * 0.6,
		half_size * 4.0,
	)
	draw_rect(v_rect, PREVIEW_COLOR, false)
	draw_rect(v_rect, PREVIEW_OUTLINE, true)


## Draw entrance direction markers on a preview cell.
func _draw_entrance_markers(cell: Vector2i, type_id: int, orientation: int, center: Vector2) -> void:
	var screen_pos: Vector2 = cell as Vector2 * Track.CELL_SIZE - center
	var conns: Array[Vector2i] = _get_valid_connections(type_id, orientation)
	for dir in conns:
		var marker_pos: Vector2 = screen_pos + (dir as Vector2) * Track.CELL_SIZE * 0.3
		draw_circle(marker_pos, 4.0, ENTRANCE_MARKER_COLOR)


## Draw valid placement position markers.
func _draw_valid_positions(center: Vector2) -> void:
	for pos in preview_valid_positions:
		var screen_pos: Vector2 = pos as Vector2 * Track.CELL_SIZE - center
		draw_circle(screen_pos, 3.0, VALID_POS_COLOR)


## Generate arc points between two directions at a center point.
func _draw_arc(
		center: Vector2,
		start_dir: Vector2,
		end_dir: Vector2,
		radius: float,
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 12

	var entry_point: Vector2 = center + start_dir * radius
	var exit_point: Vector2 = center + end_dir * radius

	var entry_angle: float = atan2(entry_point.y - center.y, entry_point.x - center.x)
	var exit_angle: float = atan2(exit_point.y - center.y, exit_point.x - center.x)
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	for i in range(1, steps):
		var t: float = i / steps
		var angle: float = entry_angle + diff * t
		var px: float = center.x + cos(angle) * radius
		var py: float = center.y + sin(angle) * radius
		points.append(Vector2(px, py))

	return points

# ============================================================================
# Helper methods (mirroring track.gd logic for preview rendering)
# ============================================================================


## Get neighbors of a cell within a group (4-connectivity).
func _get_neighbors_in_group(cells: Array[Vector2i], cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for dir in directions:
		var neighbor: Vector2i = cell + dir
		if cells.has(neighbor):
			neighbors.append(neighbor)
	return neighbors


## Get curve entry/exit directions for a given orientation.
func _get_curve_entry(orientation: int, is_entry: bool) -> Vector2i:
	match orientation:
		0: # LEFT-UP
			return Vector2.LEFT if is_entry else Vector2.UP
		1: # LEFT-DOWN
			return Vector2.LEFT if is_entry else Vector2.DOWN
		2: # RIGHT-UP
			return Vector2.RIGHT if is_entry else Vector2.UP
		3: # RIGHT-DOWN
			return Vector2.RIGHT if is_entry else Vector2.DOWN
		_:
			return Vector2i.ZERO


## Get valid connection directions for a (type_id, orientation).
func _get_valid_connections(type_id: int, orientation: int) -> Array[Vector2i]:
	match type_id:
		_STRAIGHT_H:
			if orientation == 0:
				return [Vector2.RIGHT, Vector2.LEFT]
			else:
				return [Vector2.DOWN, Vector2.UP]
		_STRAIGHT_V:
			if orientation == 0:
				return [Vector2.DOWN, Vector2.UP]
			else:
				return [Vector2.RIGHT, Vector2.LEFT]
		_CURVE_1X1:
			match orientation:
				0:
					return [Vector2.LEFT, Vector2.UP]
				1:
					return [Vector2.LEFT, Vector2.DOWN]
				2:
					return [Vector2.RIGHT, Vector2.UP]
				3:
					return [Vector2.RIGHT, Vector2.DOWN]
		_:
			return []
	return []
