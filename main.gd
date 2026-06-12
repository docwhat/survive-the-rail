extends Node2D
## Main scene entry point.
## Manages game state transitions between phases:
## TrackLay -> Playing -> Upgrading -> GameOver
## Input abstraction via InputManager (G.U.I.D.E-style).

const INITIAL_SPEED: float = 6.4
## Starting speed in world units per second.

const DECK_TRACK_LENGTH: float = 640.0
## Approximate length of the demo track in world units.

var train: Train = null
var track: Track = null

var input_manager: InputManager = null

var train_renderer: Control = null
var track_renderer: Control = null
var ui_renderer: CanvasLayer = null

var is_reverse_mode: bool = false
## Visual indicator for reverse mode display.


func _ready() -> void:
	# Initialize input manager
	input_manager = InputManager.new()

	# Initialize data models
	train = Train.new()
	train.initialize(200.0, 200.0, 100.0, 100.0, 10.0, INITIAL_SPEED, 0)
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

	# Build path for the train to follow
	_build_demo_path()


func _place_initial_track() -> void:
	# Build a demo track with straights, a curve, and a crossing:
	#
	#  (3,0) ─── (2,0) ─── (1,0) ─── (0,0)     <-- horizontal straights (start at 0,0)
	#      │
	#  (3,1)     (4,1)
	#      │         ─── (5,1) ─── (6,1) ─── (7,1)  <-- horizontal after crossing
	#
	# Horizontal straights (leftward direction)
	var seg0 = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg0)
	var seg1 = track.create_straight_segment(Vector2i(1, 0), true)
	track.try_place_segment(Vector2i(1, 0), seg1)
	var seg2 = track.create_straight_segment(Vector2i(2, 0), true)
	track.try_place_segment(Vector2i(2, 0), seg2)

	# Curve at (3,0): connects LEFT (incoming from (2,0)) → DOWN (outgoing)
	var seg3 = track.create_curve_segment(Vector2i(3, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(3, 0), seg3)

	# Vertical straight after the curve: (3,1)
	var seg4 = track.create_straight_segment(Vector2i(3, 1), true)
	track.try_place_segment(Vector2i(3, 1), seg4)

	# Crossing segment at (3,2): connects DOWN (incoming) → RIGHT (outgoing)
	# This is a "crossing" type — modeled as a curve segment with DOWN→RIGHT
	var seg5 = track.create_curve_segment(Vector2i(3, 2), [Vector2i.DOWN, Vector2i.RIGHT])
	track.try_place_segment(Vector2i(3, 2), seg5)

	# Horizontal straights after the crossing: (4,2), (5,2), (6,2)
	var seg6 = track.create_straight_segment(Vector2i(4, 2), true)
	track.try_place_segment(Vector2i(4, 2), seg6)
	var seg7 = track.create_straight_segment(Vector2i(5, 2), true)
	track.try_place_segment(Vector2i(5, 2), seg7)
	var seg8 = track.create_straight_segment(Vector2i(6, 2), true)
	track.try_place_segment(Vector2i(6, 2), seg8)


func _build_demo_path() -> void:
	## Build a Path2D for the demo track so the train can follow it.
	## Uses public Track/Train APIs instead of private members.
	train.load_track_path(track)


func _process(delta: float) -> void:
	if train == null or track == null:
		return

	# Check reverse toggle key (R)
	var reverse_toggle: bool = Input.is_action_just_pressed("reverse_toggle")

	# Update input from manager
	var throttle: bool = input_manager.get_throttle()
	var brake: bool = input_manager.get_brake()
	train.update_input(throttle, brake, reverse_toggle)
	train.update_speed(delta)

	# Use path follower mode if available
	if train.is_using_path_follower():
		train.update_position_path_follower(delta)
	else:
		train.update_position(track, delta)
	train.update_orientation(track)

	# Update reverse mode indicator
	is_reverse_mode = train.is_in_reverse()

	# Camera offset: center on train
	var viewport_size: Vector2 = get_viewport_rect().size
	var cam_offset: Vector2 = train.position - viewport_size / 2.0

	# Update renderers
	track_renderer.update(track, cam_offset)
	train_renderer.update(train, track, cam_offset)
	ui_renderer.update(train, track)
