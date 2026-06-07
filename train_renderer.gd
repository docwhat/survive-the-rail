extends CanvasItem
## Renders the train data model to visible graphics.
## Draws engine + cars as rectangles with pivot rotation on curves.
## Uses world-space coordinates directly (no transform stack needed).

var train: Train = null
## Reference to the Train data model.

var track: Track = null
## Reference to the Track data model (for direction/pivot calculations).

const ENGINE_COLOR: Color = Color(0.8, 0.2, 0.15)
const ENGINE_OUTLINE: Color = Color(0.5, 0.1, 0.08)
const CAR_COLORS: Array[Color] = [
	Color(0.15, 0.4, 0.8), # Blue - utility
	Color(0.8, 0.5, 0.15), # Orange - weapon
	Color(0.3, 0.7, 0.3), # Green - cargo
	Color(0.6, 0.2, 0.6), # Purple - special
]
const CAR_OUTLINE: Color = Color(0.1, 0.25, 0.5)


func update(train_model: Train, track_model: Track) -> void:
	train = train_model
	track = track_model
	queue_redraw()


func _draw() -> void:
	if train == null or track == null:
		return

	var engine_pos: Vector2 = train.position
	var rotation: float = train.update_orientation(track)

	# Draw cars behind the engine (first car closest to engine)
	var car_count: int = train.get_car_count()
	for i in range(car_count):
		var travel_dir: Vector2 = train.get_travel_direction(track)
		var car_pos: Vector2 = engine_pos - travel_dir.normalized() * (i + 1) * 30.0
		_draw_car(car_pos, rotation, i, car_count)

	# Draw the engine at the front
	_draw_engine(engine_pos, rotation)

	# Draw position marker at engine center
	draw_circle(engine_pos, 3.0, Color(1.0, 1.0, 0.0, 0.4))


## Draw the train engine as a red rectangle with direction indicator.
func _draw_engine(pos: Vector2, rotation: float) -> void:
	var w: float = 32.0
	var h: float = 16.0

	# Compute world-space points of rotated rectangle
	var corners: PackedVector2Array = _get_rect_corners(pos, w, h, rotation)

	# Draw filled rect
	draw_colored_polygon(corners, ENGINE_COLOR)

	# Draw outline
	draw_polyline(corners, ENGINE_OUTLINE, 2.0)

	# Direction arrow at the front (local +x after rotation)
	var tip: Vector2 = pos + Vector2.RIGHT.rotated(rotation) * (w / 2.0)
	var wing_top: Vector2 = pos + (Vector2.RIGHT.rotated(rotation) * (w / 2.0 - 4.0) +
			Vector2.UP.rotated(rotation) * 3.0)
	var wing_bot: Vector2 = pos + (Vector2.RIGHT.rotated(rotation) * (w / 2.0 - 4.0) +
			Vector2.DOWN.rotated(rotation) * 3.0)

	draw_line(tip, wing_top, ENGINE_OUTLINE, 2.0)
	draw_line(tip, wing_bot, ENGINE_OUTLINE, 2.0)


## Get the 4 corners of a rectangle in world space.
func _get_rect_corners(
		center: Vector2,
		width: float,
		height: float,
		rotation: float,
) -> PackedVector2Array:
	var corners: PackedVector2Array = PackedVector2Array()
	var half_w: float = width / 2.0
	var half_h: float = height / 2.0

	# Local corners
	var local: Array[Vector2] = [
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	]

	for v in local:
		corners.append(center + v.rotated(rotation))

	return corners


## Draw a single car as a colored rectangle with pivot rotation.
func _draw_car(pos: Vector2, base_rotation: float, car_index: int, total_cars: int) -> void:
	var w: float = 24.0
	var h: float = 12.0

	# Get car color by type (cycle through available colors)
	var color_idx: int = car_index % CAR_COLORS.size()
	var car_color: Color = CAR_COLORS[color_idx]

	# Calculate pivot rotation for curve segments
	var segments: Array[TrackSegment] = track.get_segments()
	var pivot_angle: float = 0.0
	if segments.size() > 0:
		var seg: TrackSegment = segments[train.segment_index]
		if seg.get_segment_type() == 1:
			# Curve: calculate pivot angle proportional to car position
			var pivot_scale: float = 1.0 - (car_index as float) / maxi(total_cars, 1)
			pivot_angle = (PI / 2.0) * pivot_scale

	var total_rotation: float = base_rotation + pivot_angle

	var corners: PackedVector2Array = _get_rect_corners(pos, w, h, total_rotation)
	draw_colored_polygon(corners, car_color)
	draw_polyline(corners, CAR_OUTLINE, 1.5)

	# Coupling points at top and bottom (in local space, rotated)
	var top_coupling: Vector2 = pos + Vector2.UP.rotated(total_rotation) * (h / 2.0)
	var bot_coupling: Vector2 = pos + Vector2.DOWN.rotated(total_rotation) * (h / 2.0)
	draw_circle(top_coupling, 2.0, CAR_OUTLINE)
	draw_circle(bot_coupling, 2.0, CAR_OUTLINE)
