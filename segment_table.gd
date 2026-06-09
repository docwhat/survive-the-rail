class_name SegmentTable
## Segment registry: maps SegmentID -> SegmentTypeID + Orientation.
##
## Supports rotation by 90° multiples. Orientation values:
##   0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°

## Internal storage: SegmentID -> { type_id, orientation }
var _storage: Dictionary = { }


## Add a segment to the registry.
## @param id: The segment ID (unique integer).
## @param type_id: The segment type ID (from SegmentType constants).
## @param orientation: Orientation in 90° steps (default 0 = no rotation).
func add_segment(id: int, type_id: int, orientation: int = 0) -> void:
	_storage[id] = { "type_id": type_id, "orientation": orientation }


## Get the segment type ID for a segment ID.
## @param id: The segment ID.
## @return The type ID.
func get_segment_type(id: int) -> int:
	if not _storage.has(id):
		push_error("SegmentTable: missing segment id=%d" % id)
		return -1
	return _storage[id]["type_id"]


## Get the orientation for a segment ID.
## @param id: The segment ID.
## @return The orientation (0-3).
func get_orientation(id: int) -> int:
	if not _storage.has(id):
		push_error("SegmentTable: missing segment id=%d" % id)
		return -1
	return _storage[id]["orientation"]


## Rotate a segment's orientation by the given degrees.
## @param id: The segment ID.
## @param degrees: Degrees to rotate (must be multiple of 90).
func rotate_segment(id: int, degrees: int) -> void:
	if not _storage.has(id):
		push_error("SegmentTable: missing segment id=%d" % id)
		return
	var steps: int = degrees / 90
	_storage[id]["orientation"] = (_storage[id]["orientation"] + steps) % 4


## Remove a segment from the registry.
## @param id: The segment ID to remove.
func remove_segment(id: int) -> void:
	_storage.erase(id)


## Check if the registry contains a segment ID.
## @param id: The segment ID.
## @return True if the segment is registered.
func contains(id: int) -> bool:
	return _storage.has(id)


## Get all registered segment IDs.
## @return Array of all segment IDs.
func get_all_ids() -> Array[int]:
	var result: Array[int] = []
	for key in _storage.keys():
		result.append(key)
	return result


## Get the number of registered segments.
## @return Count of segments in the registry.
func get_count() -> int:
	return _storage.size()


## Check if the registry is empty.
## @return True if no segments are registered.
func is_empty() -> bool:
	return _storage.size() == 0


## Get the type for a segment ID, or -1 if missing.
## @param id: The segment ID.
## @return The type ID, or -1 if not found (no error logged).
func try_get_type(id: int) -> int:
	if _storage.has(id):
		return _storage[id]["type_id"]
	return -1


## Get the orientation for a segment ID, or -1 if missing.
## @param id: The segment ID.
## @return The orientation, or -1 if not found (no error logged).
func try_get_orientation(id: int) -> int:
	if _storage.has(id):
		return _storage[id]["orientation"]
	return -1
