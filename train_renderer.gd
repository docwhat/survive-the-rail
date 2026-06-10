extends CanvasItem
## Renders the train data model to visible graphics.
## Draws engine + cars as rotated rectangles.
##
## Uses path follower positions when available, falls back to
## segment-based calculation for backward compatibility.

var train: Train = null
## Reference to the Train data model.

var track: Track = null
## Reference to the Track data model.

var camera_offset: Vector2 = Vector2.ZERO
## Camera offset to keep the train centered.

const ENGINE_COLOR: Color = Color(0.8, 0.2, 0.15)
const ENGINE_OUTLINE: Color = Color(0.5, 0.1, 0.08)
const CAR_COLORS: Array[Color] = [
	Color(0.15, 0.4, 0.8), # Blue - utility
	Color(0.8, 0.5, 0.15), # Orange - weapon
	Color(0.3, 0.7, 0.3), # Green - cargo
	Color(0.6, 0.2, 0.6), # Purple - special
]
const CAR_OUTLINE: Color = Color(0.1, 0.25, 0.5)

const CAR_SPACING: float = 30.0


func update(train_model: Train, track_model: Track, cam_offset: Vector2) -> void:
	train = train_model
	track = track_model
	camera_offset = cam_offset
	queue_redraw()


func _draw() -> void:
	if train == null or track == null:
		return

	# Try path follower mode first
	if train.is_using_path_follower():
		_draw_path_mode()
	else:
		_draw_segment_mode()

	# Draw position marker at engine center
	var screen_engine: Vector2 = train.position - camera_offset
	draw_circle(screen_engine, 3.0, Color(1.0, 1.0, 0.0, 0.4))


## Draw using path follower positions.
func _draw_path_mode() -> void:
	var path_follower: TrainPathFollower = train.get_path_follower()
	if path_follower == null:
		_draw_segment_mode()
		return

	var car_followers: Array[CarPathFollower] = train.get_car_followers()

	# Get engine position from path follower
	var engine_pos: Vector2 = path_follower.get_position()
	var screen_engine: Vector2 = engine_pos - camera_offset
	var engine_angle: float = path_follower.get_angle()

	# Draw cars
	for i in range(car_followers.size()):
		var car_pos: Vector2 = car_followers[i].get_position()
		var car_rotation: float = car_followers[i].get_angle()
		_draw_car(car_pos - camera_offset, car_rotation, i, car_followers.size())

	# Draw engine
	_draw_engine(screen_engine, engine_angle)


## Draw using legacy segment-based positions.
func _draw_segment_mode() -> void:
	var screen_engine: Vector2 = train.position - camera_offset
	var rotation: float = train.update_orientation(track)

	# Determine if train is on a curve
	var segments: Array[TrackSegment] = track.get_segments()
	var is_on_curve: bool = false
	if segments.size() > 0 and train.segment_index >= 0:
		var idx: int = mini(train.segment_index, segments.size() - 1)
		is_on_curve = segments[idx].get_segment_type() == 1

	# Draw cars behind the engine
	var car_count: int = train.get_car_count()
	for i in range(car_count):
		var screen_car: Vector2
		var car_rotation: float

		if is_on_curve:
			screen_car = _car_position_on_curve(i)
			car_rotation = _car_rotation_on_curve(i, rotation)
		else:
			var travel_dir: Vector2 = train.get_travel_direction(track)
			screen_car = screen_engine - travel_dir.normalized() * (i + 1) * CAR_SPACING
			car_rotation = rotation + 0.0

		_draw_car(screen_car, car_rotation, i, car_count)

	# Draw the engine at the front
	_draw_engine(screen_engine, rotation)


## Draw the train engine as a red rectangle with direction arrow.
func _draw_engine(pos: Vector2, rotation: float) -> void:
	var w: float = 32.0
	var h: float = 16.0

	var corners: PackedVector2Array = _get_rect_corners(pos, w, h, rotation)
	draw_colored_polygon(corners, ENGINE_COLOR)
	draw_polyline(corners, ENGINE_OUTLINE, 2.0)

	# Arrow pointing forward
	var tip: Vector2 = pos + Vector2.RIGHT.rotated(rotation) * (w / 2.0)
	var wing_top: Vector2 = tip - Vector2.UP.rotated(rotation) * 3.0
	var wing_bot: Vector2 = tip + Vector2.DOWN.rotated(rotation) * 3.0
	draw_line(tip, wing_top, ENGINE_OUTLINE, 2.0)
	draw_line(tip, wing_bot, ENGINE_OUTLINE, 2.0)


## Get the 4 corners of a rotated rectangle.
func _get_rect_corners(
		center: Vector2,
		width: float,
		height: float,
		rotation: float,
) -> PackedVector2Array:
	var corners: PackedVector2Array = PackedVector2Array()
	var half_w: float = width / 2.0
	var half_h: float = height / 2.0

	for v in [
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	]:
		corners.append(center + v.rotated(rotation))

	return corners


## Get screen position for a car on a curve segment.
## Cars are spaced along the arc radius behind the engine.
func _car_position_on_curve(
		car_index: int,
) -> Vector2:
	var segments: Array[TrackSegment] = track.get_segments()
	if segments.size() == 0:
		return Vector2.ZERO

	var seg: TrackSegment = segments[train.segment_index]
	# Connections represent edge directions. Travel is opposite at entry.
	var entry_edge: Vector2 = seg.connections[0] as Vector2
	var exit_edge: Vector2 = seg.connections[1] as Vector2
	var arc_radius: float = 32.0
	var curve_center: Vector2 = seg.grid_position as Vector2 * Track.CELL_SIZE

	# Travel direction at entry is opposite of entry edge direction
	var entry_angle: float = atan2(-entry_edge.y, -entry_edge.x)
	# Travel direction at exit follows exit edge direction
	var exit_angle: float = atan2(exit_edge.y, exit_edge.x)
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	# Engine angle on the arc
	var engine_angle: float = entry_angle + diff * train.segment_progress

	# Arc length = radius * |diff| = 32 * PI/2.
	# Cars trail behind by CAR_SPACING along the arc.
	var arc_length: float = arc_radius * abs(diff)
	var car_arc_offset: float = (car_index + 1) * CAR_SPACING

	# Car's angle on the arc (behind the engine)
	var new_angle: float = engine_angle + car_arc_offset / arc_length * diff

	return curve_center + Vector2(cos(new_angle), sin(new_angle)) * arc_radius


## Get rotation for a car on a curve segment.
func _car_rotation_on_curve(car_index: int, engine_rotation: float) -> float:
	var segments: Array[TrackSegment] = track.get_segments()
	if segments.size() == 0:
		return engine_rotation

	var seg: TrackSegment = segments[train.segment_index]
	if seg.get_segment_type() != 1:
		return engine_rotation

	# Connections represent edge directions. Travel is opposite at entry.
	var entry_edge: Vector2 = seg.connections[0] as Vector2
	var exit_edge: Vector2 = seg.connections[1] as Vector2
	var arc_radius: float = 32.0

	# Travel direction at entry is opposite of entry edge direction
	var entry_angle: float = atan2(-entry_edge.y, -entry_edge.x)
	# Travel direction at exit follows exit edge direction
	var exit_angle: float = atan2(exit_edge.y, exit_edge.x)
	var diff: float = exit_angle - entry_angle
	if diff > PI:
		diff -= 2.0 * PI
	elif diff < -PI:
		diff += 2.0 * PI

	var arc_length: float = arc_radius * abs(diff)
	var car_arc_offset: float = (car_index + 1) * CAR_SPACING

	# Car's angle on the arc (slightly behind engine)
	var new_angle: float = engine_rotation + car_arc_offset / arc_length * diff

	return new_angle


## Draw a single car as a colored rectangle.
func _draw_car(pos: Vector2, rotation: float, car_index: int, _total_cars: int) -> void:
	var w: float = 24.0
	var h: float = 12.0

	var color_idx: int = car_index % CAR_COLORS.size()
	var car_color: Color = CAR_COLORS[color_idx]

	var corners: PackedVector2Array = _get_rect_corners(pos, w, h, rotation)
	draw_colored_polygon(corners, car_color)
	draw_polyline(corners, CAR_OUTLINE, 1.5)

	# Coupling points
	var top: Vector2 = pos + Vector2.UP.rotated(rotation) * (h / 2.0)
	var bot: Vector2 = pos + Vector2.DOWN.rotated(rotation) * (h / 2.0)
	draw_circle(top, 2.0, CAR_OUTLINE)
	draw_circle(bot, 2.0, CAR_OUTLINE)
