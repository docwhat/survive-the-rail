class_name DataTable
## Grid placement table: maps Vector2i cells → SegmentID.
##
## This is the primary placement interface for the track system.
## Each cell can hold at most one segment ID.

## Internal storage: cell position → segment ID
var _storage: Dictionary = { }


## Set a cell to the given segment ID.
## @param pos: Grid cell position.
## @param segment_id: The segment ID to associate with this cell.
func set_cell(pos: Vector2i, segment_id: int) -> void:
	_storage[pos] = segment_id


## Get the segment ID stored at a cell position.
## @param pos: Grid cell position.
## @return The segment ID.
func get_cell(pos: Vector2i) -> int:
	if not _storage.has(pos):
		push_error("DataTable: cell at %s is empty" % pos)
		return -1
	return _storage[pos]


## Remove a cell from the table.
## @param pos: Grid cell position to remove.
func remove_cell(pos: Vector2i) -> void:
	_storage.erase(pos)


## Check if a cell position has a segment.
## @param pos: Grid cell position.
## @return True if the cell is occupied.
func contains(pos: Vector2i) -> bool:
	return _storage.has(pos)


## Get the number of occupied cells.
## @return Count of cells in the table.
func get_cell_count() -> int:
	return _storage.size()


## Check if the table is empty.
## @return True if no cells are occupied.
func is_empty() -> bool:
	return _storage.size() == 0


## Get all occupied cell positions.
## @return Array of Vector2i positions.
func get_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key in _storage.keys():
		result.append(key)
	return result


## Get all cells grouped by segment ID.
## @param segment_id: The segment ID to filter by.
## @return Array of cell positions that have this segment ID.
func get_cells_by_segment_id(segment_id: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for pos in _storage:
		if _storage[pos] == segment_id:
			cells.append(pos)
	return cells


## Check if a cell position is unoccupied.
## @param pos: Grid cell position.
## @return True if the position is free (no segment placed).
func find_free_cell(pos: Vector2i) -> bool:
	return not _storage.has(pos)


## Get all unique segment IDs in the table.
## @return Array of unique segment IDs.
func get_unique_segment_ids() -> Array[int]:
	var ids: Array[int] = []
	var seen: Dictionary = { }
	for pos in _storage:
		var sid: int = _storage[pos]
		if not seen.has(sid):
			ids.append(sid)
			seen[sid] = true
	return ids


## Clear all cells from the table.
func clear() -> void:
	_storage.clear()


## Check if the table contains any cell belonging to a segment ID.
## @param segment_id: The segment ID.
## @return True if at least one cell has this segment ID.
func has_segment_id(segment_id: int) -> bool:
	for pos in _storage:
		if _storage[pos] == segment_id:
			return true
	return false


## Get the total number of unique segment IDs in the table.
## @return Count of unique segment IDs.
func get_segment_count() -> int:
	return get_unique_segment_ids().size()
