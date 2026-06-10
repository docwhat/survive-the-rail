class_name CarPathFollower
## Manages a `PathFollow2D` node for a train car's movement along a `Path2D`.
##
## Unlike the engine follower, each car has a `progress_offset` that
## represents its distance behind the engine along the path.

var _path_follow: PathFollow2D = null
## Internal PathFollow2D node reference.

var _path: Path2D = null
## Reference to the source Path2D.

var _total_path_length: float = 0.0
## Cached total length of the path.

var _progress_offset: float = 0.0
## Offset behind the engine along the path (positive = behind).


## Initialize the car follower with a Path2D and initial progress offset.
## @param path: The Path2D to follow.
## @param initial_offset: Distance behind the engine along the path.
func initialize(path: Path2D, initial_offset: float = 0.0) -> void:
	_path = path
	_progress_offset = initial_offset
	_path_follow = PathFollow2D.new()
	_path_follow.loop = false
	_total_path_length = _compute_path_length(path)


## Get the PathFollow2D node.
## @return The internal PathFollow2D node.
func get_path_follow_node() -> PathFollow2D:
	return _path_follow


## Get the car's current progress along the path.
## This is the engine's progress plus the car's offset.
## @return Current progress value.
func get_progress() -> float:
	if _path_follow == null:
		return 0.0
	return _path_follow.progress + _progress_offset


## Set the base progress along the path (excluding offset).
## @param progress: Progress value to set.
func set_base_progress(progress: float) -> void:
	if _path_follow != null:
		_path_follow.progress = progress


## Get the progress offset (distance behind engine).
## @return Current progress offset value.
func get_progress_offset() -> float:
	return _progress_offset


## Set the progress offset.
## @param offset: Offset value to set (positive = behind engine).
func set_progress_offset(offset: float) -> void:
	_progress_offset = offset


## Get the current world position of the car.
## @return Current world position from the PathFollow2D node.
func get_position() -> Vector2:
	if _path_follow == null:
		return Vector2.ZERO
	return _path_follow.global_position


## Get the current angle of travel (radians).
## @return Current angle in radians.
func get_angle() -> float:
	if _path_follow == null:
		return 0.0
	return _path_follow.rotation


## Update the underlying path, preserving progress proportionally.
## @param new_path: The new Path2D to follow.
func update_path(new_path: Path2D) -> void:
	if new_path == null:
		_path = null
		_path_follow = null
		_total_path_length = 0.0
		return

	_path = new_path
	_total_path_length = _compute_path_length(new_path)

	# Preserve base progress proportionally
	var old_base: float = 0.0
	if _path_follow != null:
		old_base = _path_follow.progress - _progress_offset

	var old_ratio: float = 0.0
	if _total_path_length > 0:
		old_ratio = old_base / _total_path_length

	_path_follow = PathFollow2D.new()
	_path_follow.loop = false
	_path_follow.progress = maxf(0.0, old_ratio * _total_path_length - _progress_offset)


## Compute the total length of a Path2D by summing its segments.
func _compute_path_length(path: Path2D) -> float:
	var total: float = 0.0
	for child in path.get_children():
		var child_class: String = child.get_class()
		if child_class == "PathSegLine":
			var a: Vector2 = child.get_point_a()
			var b: Vector2 = child.get_point_b()
			total += a.distance_to(b)
		elif child_class == "PathSegCurve2D":
			var a: Vector2 = child.get_point_a()
			var b: Vector2 = child.get_point_b()
			var c: Vector2 = child.get_point_c()
			var mid: Vector2 = _bezier_midpoint(a, b, c)
			total += a.distance_to(mid) + mid.distance_to(c)
	return total


## Compute the midpoint of a quadratic Bezier curve.
func _bezier_midpoint(p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var t: float = 0.5
	var x: float = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x
	var y: float = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y
	return Vector2(x, y)
