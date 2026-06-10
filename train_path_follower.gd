class_name TrainPathFollower
## Manages a `PathFollow2D` node for train engine movement along a `Path2D`.
##
## This wrapper provides a clean API for progress/position/angle queries
## that the `Train` class uses during movement updates.

var _path_follow: PathFollow2D = null
## Internal PathFollow2D node reference.

var _path: Path2D = null
## Reference to the source Path2D.

var _total_path_length: float = 0.0
## Cached total length of the path.


## Initialize the follower with a Path2D.
## @param path: The Path2D to follow.
func initialize(path: Path2D) -> void:
	_path = path
	_path_follow = PathFollow2D.new()
	_path_follow.loop = false
	_total_path_length = _compute_path_length(path)


## Get the PathFollow2D node.
## @return The internal PathFollow2D node.
func get_path_follow_node() -> PathFollow2D:
	return _path_follow


## Get the current progress along the path.
## @return Current progress value (0.0 = start, total_length = end).
func get_progress() -> float:
	if _path_follow == null:
		return 0.0
	return _path_follow.progress


## Set the progress along the path.
## @param progress: Progress value to set.
func set_progress(progress: float) -> void:
	if _path_follow != null:
		_path_follow.progress = progress


## Get the current world position of the train engine.
## @return Current world position from the PathFollow2D node.
func get_position() -> Vector2:
	if _path_follow == null:
		return Vector2.ZERO
	return _path_follow.global_position


## Get the current angle of travel (radians).
## @return Current angle in radians, derived from the PathFollow2D rotation.
func get_angle() -> float:
	if _path_follow == null:
		return 0.0
	return _path_follow.rotation


## Replace the underlying path, preserving progress proportionally.
## @param new_path: The new Path2D to follow.
func update_path(new_path: Path2D) -> void:
	if new_path == null:
		_path = null
		_path_follow = null
		_total_path_length = 0.0
		return

	_path = new_path
	_total_path_length = _compute_path_length(new_path)

	# Preserve progress proportionally
	var old_progress: float = 0.0
	if _path_follow != null:
		old_progress = _path_follow.progress

	var old_ratio: float = 0.0
	if _total_path_length > 0:
		old_ratio = old_progress / _total_path_length

	_path_follow = PathFollow2D.new()
	_path_follow.loop = false
	_path_follow.progress = old_ratio * _total_path_length


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
			# Approximate Bezier curve length with midpoint
			var mid: Vector2 = _bezier_midpoint(a, b, c)
			total += a.distance_to(mid) + mid.distance_to(c)
	return total


## Compute the midpoint of a quadratic Bezier curve.
func _bezier_midpoint(p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var t: float = 0.5
	var x: float = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x
	var y: float = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y
	return Vector2(x, y)
