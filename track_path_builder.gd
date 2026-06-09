class_name TrackPathBuilder
## Builds a `Path2D` from the track data model (DataTable + SegmentTable + SegmentType).
##
## This is a pure computation layer — no rendering logic, no scene nodes.
## Given the current state of the track's data model, it produces a `Path2D`
## that can be used by `PathFollow2D` for train movement.

const CELL_SIZE: int = 64
## Size of one grid cell in world units.

# --- Segment type IDs (matches SegmentType) ---
const _STRAIGHT_H: int = 0
const _STRAIGHT_V: int = 1
const _CURVE_1X1: int = 2
const _CURVE_2X2: int = 3
const _CROSSING_90: int = 4

# ============================================================================
# Subtask 4b-1: Cell iteration & grouping
# ============================================================================


## Group cells by segment ID from the data table.
## @param data_table: The DataTable containing cell-to-segment mappings.
## @return Dictionary mapping SegmentID → Array of cell positions.
func group_cells_by_segment(data_table: DataTable) -> Dictionary:
	var result: Dictionary = { }
	var segment_ids: Array[int] = data_table.get_unique_segment_ids()
	for seg_id in segment_ids:
		var cells: Array[Vector2i] = data_table.get_cells_by_segment_id(seg_id)
		result[seg_id] = cells
	return result


## Sort cells into path-drawing order for a single segment.
## For straights: sort along the dominant axis (horizontal first, then vertical).
## For curves: order cells to trace the curve entry→exit.
## @param cells: Array of cell positions belonging to one segment.
## @param type_id: The segment type ID.
## @param orientation: The segment orientation (0-3).
## @return Sorted array of cell positions in drawing order.
func sort_cells_in_path_order(cells: Array[Vector2i], type_id: int, orientation: int) -> Array[Vector2i]:
	if cells.size() <= 1:
		return cells.duplicate()

	var sorted: Array[Vector2i] = []

	match type_id:
		_STRAIGHT_H:
			sorted = _sort_straight_h(cells, orientation)
		_STRAIGHT_V:
			sorted = _sort_straight_v(cells, orientation)
		_CURVE_1X1, _CURVE_2X2:
			sorted = _sort_curve(cells, type_id, orientation)
		_CROSSING_90:
			sorted = _sort_crossing(cells, orientation)
		_:
			sorted = cells.duplicate()

	return sorted


## Get neighbors of a cell within a group (4-connectivity).
## @param cells: Array of cell positions in the group.
## @param cell: The cell to find neighbors for.
## @return Array of adjacent cells in the group.
func get_neighbors_in_group(cells: Array[Vector2i], cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for dir in directions:
		var neighbor: Vector2i = cell + dir
		if cells.has(neighbor):
			neighbors.append(neighbor)
	return neighbors

# ============================================================================
# Subtask 4b-2: Straight segment path generation
# ============================================================================


## Build a Path2D for a straight segment.
## @param cells: Sorted cell positions for the segment.
## @param type_id: Segment type ID.
## @param orientation: Segment orientation (0-3).
## @param data_table: The data table (unused, for API consistency).
## @return Path2D containing line segments for the straight.
func build_straight_path(cells: Array[Vector2i], type_id: int, orientation: int, data_table: DataTable) -> Path2D:
	var path: Path2D = Path2D.new()

	if cells.size() == 0:
		return path

	match cells.size():
		1:
			_build_straight_cell(path, cells[0], type_id, orientation)
		_:
			_build_straight_multi_cell(path, cells, type_id, orientation)

	return path


## Build a single-cell straight segment path.
func _build_straight_cell(path: Path2D, cell: Vector2i, type_id: int, orientation: int) -> void:
	var center: Vector2 = _cell_center(cell)
	var line = ClassDB.instantiate("PathSegLine")
	if line == null:
		return

	match type_id:
		_STRAIGHT_H:
			if orientation % 2 == 0:
				# Horizontal (no rotation or 180°)
				line.set_point_a(center + Vector2(-CELL_SIZE / 2, 0))
				line.set_point_b(center + Vector2(CELL_SIZE / 2, 0))
			else:
				# Vertical (90° or 270°)
				line.set_point_a(center + Vector2(0, -CELL_SIZE / 2))
				line.set_point_b(center + Vector2(0, CELL_SIZE / 2))
		_STRAIGHT_V:
			if orientation % 2 == 0:
				# Vertical (no rotation or 180°)
				line.set_point_a(center + Vector2(0, -CELL_SIZE / 2))
				line.set_point_b(center + Vector2(0, CELL_SIZE / 2))
			else:
				# Horizontal (90° or 270°)
				line.set_point_a(center + Vector2(-CELL_SIZE / 2, 0))
				line.set_point_b(center + Vector2(CELL_SIZE / 2, 0))

	path.add_child(line)


## Build a multi-cell straight segment path.
func _build_straight_multi_cell(path: Path2D, cells: Array[Vector2i], type_id: int, orientation: int) -> void:
	if cells.size() < 2:
		return

	for i in range(cells.size() - 1):
		var p1: Vector2 = _cell_center(cells[i])
		var p2: Vector2 = _cell_center(cells[i + 1])
		var line = ClassDB.instantiate("PathSegLine")
		if line == null:
			continue
		line.set_point_a(p1)
		line.set_point_b(p2)
		path.add_child(line)

# ============================================================================
# Subtask 4b-3: Curve segment path generation
# ============================================================================


## Build a Path2D for a curve segment.
## @param cells: Sorted cell positions for the segment.
## @param type_id: Segment type ID.
## @param orientation: Segment orientation (0-3).
## @return Path2D containing curve segments.
func build_curve_path(cells: Array[Vector2i], type_id: int, orientation: int) -> Path2D:
	var path: Path2D = Path2D.new()

	match type_id:
		_CURVE_1X1:
			_build_curve_1x1(path, cells, orientation)
		_CURVE_2X2:
			_build_curve_2x2(path, cells, orientation)

	return path


## Build a 1x1 curve path.
func _build_curve_1x1(path: Path2D, cells: Array[Vector2i], orientation: int) -> void:
	if cells.size() != 1:
		return

	var center: Vector2 = _cell_center(cells[0])
	var entry: Vector2 = _curve_entry_exit_1x1(orientation, true) + center
	var exit: Vector2 = _curve_entry_exit_1x1(orientation, false) + center

	var curve = ClassDB.instantiate("PathSegCurve2D")
	if curve == null:
		return

	curve.set_point_a(entry)
	curve.set_point_b(center)
	curve.set_point_c(exit)
	path.add_child(curve)


## Build a 2x2 curve path.
func _build_curve_2x2(path: Path2D, cells: Array[Vector2i], orientation: int) -> void:
	if cells.size() != 4:
		return

	# 2x2 curve has 4 cells forming a quarter-circle shape
	# Trace through cells in order: entry → inner → corner → exit
	var sorted_cells: Array[Vector2i] = _sort_curve_2x2(cells, orientation)

	for i in range(sorted_cells.size() - 1):
		var p1: Vector2 = _cell_center(sorted_cells[i])
		var p2: Vector2 = _cell_center(sorted_cells[i + 1])

		if i == 0:
			# First segment: curve from entry
			var entry: Vector2 = _curve_entry_exit_1x1(orientation, true) + center_from_2x2(sorted_cells)
			var curve = ClassDB.instantiate("PathSegCurve2D")
			if curve == null:
				continue
			curve.set_point_a(entry)
			curve.set_point_b(p1)
			curve.set_point_c(p2)
			path.add_child(curve)
		elif i == sorted_cells.size() - 2:
			# Last segment: curve to exit
			var curve = ClassDB.instantiate("PathSegCurve2D")
			if curve == null:
				continue
			curve.set_point_a(p1)
			curve.set_point_b(p2)
			curve.set_point_c(_curve_entry_exit_1x1(orientation, false) + center_from_2x2(sorted_cells))
			path.add_child(curve)
		else:
			# Middle segments: line through inner cells
			var line = ClassDB.instantiate("PathSegLine")
			if line == null:
				continue
			line.set_point_a(p1)
			line.set_point_b(p2)
			path.add_child(line)


## Compute the center of a 2x2 curve cell group.
func center_from_2x2(cells: Array[Vector2i]) -> Vector2:
	var cx: float = 0.0
	var cy: float = 0.0
	for cell in cells:
		cx += float(cell.x)
		cy += float(cell.y)
	return Vector2(cx / cells.size(), cy / cells.size())

# ============================================================================
# Subtask 4b-4: Crossing segment path generation
# ============================================================================


## Build a Path2D for a 90° crossing segment.
## @param cells: Sorted cell positions for the segment.
## @param type_id: Segment type ID (must be _CROSSING_90).
## @param orientation: Segment orientation (0-3).
## @return Path2D containing cross-shaped path.
func build_crossing_path(cells: Array[Vector2i], type_id: int, orientation: int) -> Path2D:
	var path: Path2D = Path2D.new()

	if cells.size() != 5:
		return path

	# Find the center cell (the one with neighbors on all 4 sides)
	var center_cell: Vector2i = _find_crossing_center(cells)
	if center_cell == Vector2i(-1, -1):
		return path

	var center_pos: Vector2 = _cell_center(center_cell)

	# Build lines from center to each arm
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

	for dir in directions:
		var neighbor: Vector2i = center_cell + dir
		if cells.has(neighbor):
			var line = ClassDB.instantiate("PathSegLine")
			if line == null:
				continue
			var neighbor_pos: Vector2 = _cell_center(neighbor)
			line.set_point_a(center_pos)
			line.set_point_b(neighbor_pos)
			path.add_child(line)

	return path


## Find the center cell of a crossing pattern.
func _find_crossing_center(cells: Array[Vector2i]) -> Vector2i:
	for cell in cells:
		var neighbors: Array[Vector2i] = get_neighbors_in_group(cells, cell)
		if neighbors.size() >= 4:
			return cell
	return Vector2i(-1, -1)

# ============================================================================
# Subtask 4b-5: Unified path assembly
# ============================================================================


## Build a complete Path2D from the full data model state.
## @param data_table: The track's data table.
## @param segment_table: The track's segment table.
## @return Path2D with all segment geometries.
func build_full_path(data_table: DataTable, segment_table: SegmentTable) -> Path2D:
	var path: Path2D = Path2D.new()
	var segments: Dictionary = group_cells_by_segment(data_table)

	# Sort segments by segment ID for consistent ordering
	var sorted_ids: Array = segments.keys()
	sorted_ids.sort()

	for seg_id in sorted_ids:
		var cells: Array[Vector2i] = segments[seg_id]
		if cells.size() == 0:
			continue

		var type_id: int = segment_table.get_segment_type(seg_id)
		var orientation: int = segment_table.get_orientation(seg_id)

		# Sort cells into path order
		var sorted_cells: Array[Vector2i] = sort_cells_in_path_order(cells, type_id, orientation)

		# Dispatch to the appropriate build method
		match type_id:
			_STRAIGHT_H, _STRAIGHT_V:
				var straight_path: Path2D = build_straight_path(sorted_cells, type_id, orientation, data_table)
				_add_path_segments(path, straight_path)
			_CURVE_1X1, _CURVE_2X2:
				var curve_path: Path2D = build_curve_path(sorted_cells, type_id, orientation)
				_add_path_segments(path, curve_path)
			_CROSSING_90:
				var crossing_path: Path2D = build_crossing_path(sorted_cells, type_id, orientation)
				_add_path_segments(path, crossing_path)

	return path


## Add all PathSeg* children from one Path2D to another.
func _add_path_segments(target: Path2D, source: Path2D) -> void:
	for child in source.get_children():
		if child.get_class() == "PathSeg":
			var copy = child.duplicate()
			if copy != null:
				target.add_child(copy)

# ============================================================================
# Helper methods
# ============================================================================


## Convert a cell position to its center in world coordinates.
func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x) * CELL_SIZE + CELL_SIZE / 2, float(cell.y) * CELL_SIZE + CELL_SIZE / 2)


## Get the entry direction for a curve (first direction in entrance pair).
func _curve_entry_exit_1x1(orientation: int, is_entry: bool) -> Vector2:
	match orientation:
		0: # LEFT-UP
			return Vector2(-1.0, -1.0) if is_entry else Vector2(-1.0, -1.0)
		1: # LEFT-DOWN
			return Vector2(-1.0, -1.0) if is_entry else Vector2(-1.0, -1.0)
		2: # RIGHT-UP
			return Vector2(1.0, -1.0) if is_entry else Vector2(1.0, -1.0)
		3: # RIGHT-DOWN
			return Vector2(1.0, -1.0) if is_entry else Vector2(1.0, -1.0)
		_:
			return Vector2.ZERO


## Sort straight horizontal cells.
func _sort_straight_h(cells: Array[Vector2i], orientation: int) -> Array[Vector2i]:
	var sorted: Array[Vector2i] = cells.duplicate()
	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return a.x < b.x
	)
	return sorted


## Sort straight vertical cells.
func _sort_straight_v(cells: Array[Vector2i], orientation: int) -> Array[Vector2i]:
	var sorted: Array[Vector2i] = cells.duplicate()
	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return a.y < b.y
	)
	return sorted


## Sort curve cells in entry→exit order.
func _sort_curve(cells: Array[Vector2i], type_id: int, orientation: int) -> Array[Vector2i]:
	if cells.size() == 1:
		return cells.duplicate()
	# For multi-cell curves, sort by distance from a canonical entry point
	var sorted: Array[Vector2i] = cells.duplicate()
	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			var dist_a: float = _dist_to_entry(a, orientation)
			var dist_b: float = _dist_to_entry(b, orientation)
			return dist_a < dist_b
	)
	return sorted


## Sort 2x2 curve cells in proper trace order.
func _sort_curve_2x2(cells: Array[Vector2i], orientation: int) -> Array[Vector2i]:
	# For 2x2 curves: [entry_cell, inner_cell_1, inner_cell_2, exit_cell]
	if cells.size() != 4:
		return cells.duplicate()

	# The entry cell is the one closest to the entry direction
	var entry_dirs: Array[Vector2i] = [_curve_entry_exit_1x1(orientation, true)]
	var sorted: Array[Vector2i] = cells.duplicate()
	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			var dist_a: float = _dist_to_entry(a, orientation)
			var dist_b: float = _dist_to_entry(b, orientation)
			return dist_a < dist_b
	)
	return sorted


## Compute distance from a cell to the curve entry point.
func _dist_to_entry(cell: Vector2i, orientation: int) -> float:
	var center: Vector2 = _cell_center(cell)
	match orientation:
		0: # LEFT-UP
			var entry: Vector2 = Vector2(-CELL_SIZE, -CELL_SIZE) + center
			return center.distance_to(entry)
		1: # LEFT-DOWN
			var entry: Vector2 = Vector2(-CELL_SIZE, CELL_SIZE) + center
			return center.distance_to(entry)
		2: # RIGHT-UP
			var entry: Vector2 = Vector2(CELL_SIZE, -CELL_SIZE) + center
			return center.distance_to(entry)
		3: # RIGHT-DOWN
			var entry: Vector2 = Vector2(CELL_SIZE, CELL_SIZE) + center
			return center.distance_to(entry)
		_:
			return 0.0


## Sort crossing cells by distance from center.
func _sort_crossing(cells: Array[Vector2i], orientation: int) -> Array[Vector2i]:
	var center: Vector2i = _find_crossing_center(cells)
	if center == Vector2i(-1, -1):
		return cells.duplicate()

	var sorted: Array[Vector2i] = cells.duplicate()
	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			var dist_a: float = a.distance_to(center)
			var dist_b: float = b.distance_to(center)
			return dist_a < dist_b
	)
	return sorted
