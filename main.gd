extends Node2D
## Main scene entry point.
## Manages game state transitions between phases:
## TrackLay -> Playing -> Upgrading -> GameOver
## Input abstraction via InputManager (G.U.I.D.E-style).

var train: Train = null
var track: Track = null

var input_manager: InputManager = null

var train_renderer: Control = null
var track_renderer: Control = null
var ui_renderer: CanvasLayer = null


func _ready() -> void:
	# Initialize input manager
	input_manager = InputManager.new()

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
	train_renderer = $TrainRenderer as Control
	track_renderer = $TrackRenderer as Control
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


func _process(delta: float) -> void:
	if train == null or track == null:
		return

	# Update input from manager
	var throttle: bool = input_manager.get_throttle()
	var brake: bool = input_manager.get_brake()
	train.update_input(throttle, brake)
	train.update_speed(delta)
	train.update_position(track, delta)
	train.update_orientation(track)

	# Camera offset: center on train
	var viewport_size: Vector2 = get_viewport_rect().size
	var cam_offset: Vector2 = train.position - viewport_size / 2.0

	# Update renderers
	track_renderer.update(track, cam_offset)
	train_renderer.update(train, track, cam_offset)
	ui_renderer.update(train, track)
