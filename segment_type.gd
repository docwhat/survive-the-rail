class_name SegmentType
## Read-only segment type catalog with patterns and entrance-pair definitions.
##
## Each segment type has:
## - A unique integer ID.
## - A `pattern`: relative cell positions forming its visual footprint.
## - `entrance_pairs`: direction pairs that form valid entrances.
##
## This is a pure data catalog — no scene nodes, no rendering.

# --- Segment type constants ---
const STRAIGHT_H: int = 0
const STRAIGHT_V: int = 1
const CURVE_1X1: int = 2
const CURVE_2X2: int = 3
const CROSSING_90: int = 4

# --- Type name to ID lookup ---
const _TYPE_NAMES: Dictionary = {
	"straight_h": STRAIGHT_H,
	"straight_v": STRAIGHT_V,
	"curve_1x1": CURVE_1X1,
	"curve_2x2": CURVE_2X2,
	"crossing_90": CROSSING_90,
}

# --- Base patterns (relative cell positions) ---
const _PATTERNS: Dictionary = {
	STRAIGHT_H: [Vector2i.ZERO, Vector2i.RIGHT],
	STRAIGHT_V: [Vector2i.ZERO, Vector2i.DOWN],
	CURVE_1X1: [Vector2i.ZERO],
	CURVE_2X2: [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.RIGHT + Vector2i.DOWN],
	CROSSING_90: [
		Vector2i.ZERO,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	],
}

# --- Base entrance pairs (directions that are valid entry/exit points) ---
# For straights: horizontal + vertical entrances.
# For curves: two directions (entry + exit).
# For crossing: all four cardinal directions.
const _ENTRANCE_PAIRS: Dictionary = {
	STRAIGHT_H: [
		[Vector2i.RIGHT, Vector2i.LEFT],
		[Vector2i.UP, Vector2i.DOWN],
	],
	STRAIGHT_V: [
		[Vector2i.RIGHT, Vector2i.LEFT],
		[Vector2i.UP, Vector2i.DOWN],
	],
	CURVE_1X1: [
		[Vector2i.LEFT, Vector2i.DOWN],
		[Vector2i.RIGHT, Vector2i.UP],
		[Vector2i.DOWN, Vector2i.LEFT],
		[Vector2i.UP, Vector2i.RIGHT],
	],
	CURVE_2X2: [
		[Vector2i.LEFT, Vector2i.DOWN],
		[Vector2i.RIGHT, Vector2i.UP],
		[Vector2i.DOWN, Vector2i.LEFT],
		[Vector2i.UP, Vector2i.RIGHT],
	],
	CROSSING_90: [
		[Vector2i.UP],
		[Vector2i.DOWN],
		[Vector2i.LEFT],
		[Vector2i.RIGHT],
	],
}


## Get the segment type ID by name.
## @param name: String name of the segment type.
## @return The integer type ID, or -1 if not found.
static func get_type_by_name(name: String) -> int:
	if _TYPE_NAMES.has(name):
		return _TYPE_NAMES[name]
	return -1


## Get the pattern (cell positions) for a segment type.
## @param type_id: The segment type ID.
## @return Array of Vector2i relative positions, or empty if unknown.
static func get_pattern(type_id: int) -> Array[Vector2i]:
	if _PATTERNS.has(type_id):
		var result: Array[Vector2i] = []
		for pos in _PATTERNS[type_id]:
			result.append(pos)
		return result
	return []


## Check if a direction is covered by any entrance pair for this type.
## @param type_id: The segment type ID.
## @param dir: The direction to check.
## @return True if the direction appears in any entrance pair.
static func has_valid_entrance(type_id: int, dir: Vector2i) -> bool:
	if not _ENTRANCE_PAIRS.has(type_id):
		return false
	for pair in _ENTRANCE_PAIRS[type_id]:
		for d in pair:
			if d == dir:
				return true
	return false


## Get the number of entrance pairs for a segment type.
## @param type_id: The segment type ID.
## @return Number of entrance pair groups.
static func get_entrance_pair_count(type_id: int) -> int:
	if _ENTRANCE_PAIRS.has(type_id):
		return _ENTRANCE_PAIRS[type_id].size()
	return 0


## Get all entrance directions for a segment type (flattened).
## @param type_id: The segment type ID.
## @return Array of all unique directions from entrance pairs.
static func get_all_entrance_directions(type_id: int) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	if not _ENTRANCE_PAIRS.has(type_id):
		return directions
	for pair in _ENTRANCE_PAIRS[type_id]:
		for d in pair:
			if not directions.has(d):
				directions.append(d)
	return directions
