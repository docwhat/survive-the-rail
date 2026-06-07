extends Node2D
## Main scene entry point.
## Manages game state transitions between phases:
## TrackLay -> Playing -> Upgrading -> GameOver
## Keyboard controls: W/Up = throttle, S/Down/Space = brake.

var train: Train = null
var track: Track = null

var is_throttle: bool = false
var is_brake: bool = false

var train_renderer: CanvasItem = null
var track_renderer: CanvasItem = null
var ui_renderer: CanvasLayer = null


func _ready() -> void:
	# Initialize data models
	train = Train.new()
	train.initialize(100.0, 200.0, 100.0, 100.0, 10.0, 0.0, 0)
	train.enabled = true
	# Add some cars for visual interest and pivot demonstration
	var car1 = Car.new()
	car1.initialize("utility", 5.0, Vector2.ZERO)
	train.add_car(car1)
	var car2 = Car.new()
	car2.initialize("weapon", 5.0, Vector2.ZERO)
	train.add_car(car2)
	var car3 = Car.new()
	car3.initialize("cargo", 5.0, Vector2.ZERO)
	train.add_car(car3)

	track = Track.new()
	track.initialize(100.0, 100)
	# Place a few initial track segments
	_place_initial_track()

	# Reference renderer nodes from scene
	train_renderer = $TrainRenderer as CanvasItem
	track_renderer = $TrackRenderer as CanvasItem
	ui_renderer = $UIDisplay as CanvasLayer


func _place_initial_track() -> void:
	# Place a track with straights and a curve:
	# Row 0: straight segments (0,0) → (1,0) → (2,0)
	# Curve at (3,0): turns DOWN from RIGHT
	# Vertical down: (3,1), (3,2)

	# Horizontal straights
	var seg0 = track.create_straight_segment(Vector2i.ZERO, true)
	track.try_place_segment(Vector2i.ZERO, seg0)
	var seg1 = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg1)
	var seg2 = track.create_straight_segment(Vector2i(2, 0), true)
	track.try_place_segment(Vector2i(2, 0), seg2)

	# Curve segment: connects LEFT (incoming) → DOWN (outgoing)
	var seg3 = track.create_curve_segment(Vector2i(3, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(3, 0), seg3)

	# Vertical straights after the curve
	var seg4 = track.create_straight_segment(Vector2i(3, 1), true)
	track.try_place_segment(Vector2i(3, 1), seg4)
	var seg5 = track.create_straight_segment(Vector2i(3, 2), true)
	track.try_place_segment(Vector2i(3, 2), seg5)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: Key = event.keycode
		var pressed: bool = event.pressed
		if key == KEY_W or key == KEY_UP:
			is_throttle = pressed
		elif key == KEY_S or key == KEY_DOWN or key == KEY_SPACE:
			is_brake = pressed


func _process(delta: float) -> void:
	if train == null or track == null:
		return

	# Update physics
	train.update_input(is_throttle, is_brake)
	train.update_speed(delta)
	train.update_position(track, delta)
	train.update_orientation(track)

	# Update renderers
	track_renderer.update(track)
	train_renderer.update(train, track)
	ui_renderer.update(train, track)
