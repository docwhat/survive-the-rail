extends CanvasItem
## Renders the train data model to visible graphics.
## Draws engine + cars as rectangles with pivot rotation on curves.
## Uses world-space coordinates with camera offset.

var train: Train = null
## Reference to the Train data model.

var track: Track = null
## Reference to the Track data model (for direction/pivot calculations).

var camera_offset: Vector2 = Vector2.ZERO
## Camera offset to keep the train centered in view.

const ENGINE_COLOR: Color = Color(0.8, 0.2, 0.15)
const ENGINE_OUTLINE: Color = Color(0.5, 0.1, 0.08)
const CAR_COLORS: Array[Color] = [
	Color(0.15, 0.4, 0.8), # Blue - utility
	Color(0.8, 0.5, 0.15), # Orange - weapon
	Color(0.3, 0.7, 0.3), # Green - cargo
	Color(0.6, 0.2, 0.6), # Purple - special
]
const CAR_OUTLINE: Color = Color(0.1, 0.25, 0.5)


func update(train_model: Train, track_model: Track, cam_offset: Vector2) -> void:
	train = train_model
	track = track_model
	camera_offset = cam_offset
	queue_redraw()


func _draw() -> void:
	if train == null or track == null:
		return

	var screen_engine: Vector2 = train.position - camera_offset
	var rotation: float = train.update_orientation(track)

	# Draw cars behind the engine
	var car_count: int = train.get_car_count()
	for i in range(car_count):
		# Position cars behind engine using the engine's current travel direction
		var travel_dir: Vector2 = train.get_travel_direction(track)
		var screen_car: Vector2 = screen_engine - travel_dir.normalized() * (i + 1) * 30.0
		_draw_car(screen_car, rotation, i, car_count)

	# Draw the engine at the front
	_draw_engine(screen_engine, rotation)

	# Draw position marker at engine center
	draw_circle(screen_engine, 3.0, Color(1.0, 1.0, 0.0, 0.4))


## Draw the train engine as a red rectangle with direction indicator.
func _draw_engine(pos: Vector2, rotation: float) -> void:
	var w: float = 32.0
	var h: float = 16.0

	# Draw rotated rectangle using corners
	var corners: PackedVector2Array = _get_rect_corners(pos, w, h, rotation)
	draw_colored_polygon(corners, ENGINE_COLOR)
	draw_polyline(corners, ENGINE_OUTLINE, 2.0)

	# Direction arrow at the front
	var tip: Vector2 = pos + Vector2.RIGHT.rotated(rotation) * (w / 2.0)
	var wing_top: Vector2 = tip - Vector2.UP.rotated(rotation) * 3.0
	var wing_bot: Vector2 = tip + Vector2.DOWN.rotated(rotation) * 3.0

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
	# Cars trail behind the engine and pivot inward on curves.
	# The pivot angle represents how much each car angles relative
	# to the engine's direction — first car pivots most, others less.
	var segments: Array[TrackSegment] = track.get_segments()
	var pivot_angle: float = 0.0
	if segments.size() > 0:
		var seg: TrackSegment = segments[train.segment_index]
		if seg.get_segment_type() == 1:
			# Each car angles progressively less as it trails behind.
			# The first car angles most toward the curve center.
			pivot_angle = -(PI / 2.0) * ((car_index as float) / maxi(total_cars, 1))

	var total_rotation: float = base_rotation + pivot_angle

	var corners: PackedVector2Array = _get_rect_corners(pos, w, h, total_rotation)
	draw_colored_polygon(corners, car_color)
	draw_polyline(corners, CAR_OUTLINE, 1.5)

	# Coupling points at top and bottom (rotated)
	var top_coupling: Vector2 = pos + Vector2.UP.rotated(total_rotation) * (h / 2.0)
	var bot_coupling: Vector2 = pos + Vector2.DOWN.rotated(total_rotation) * (h / 2.0)
	draw_circle(top_coupling, 2.0, CAR_OUTLINE)
	draw_circle(bot_coupling, 2.0, CAR_OUTLINE)
