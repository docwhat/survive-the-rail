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
	# Demo track layout (all segment types represented):
	#
	#  seg0: STRAIGHT_H at (0,0)    ─ exits RIGHT
	#  seg1: CURVE_2X2 at (1,0)     ─ occupies (1,0),(2,0),(1,1),(2,1), enters LEFT, exits DOWN
	#  seg2: STRAIGHT_V at (1,2)    ─ enters UP, exits DOWN
	#  seg3: CURVE_1X1 at (1,3)     ─ enters DOWN, exits RIGHT
	#  seg4: CROSSING_90 at (3,3)   ─ enters LEFT, exits RIGHT
	#  seg5: STRAIGHT_H at (5,3)    ─ continues RIGHT
	#
	# Grid layout (x increases right, y increases down):
	#  y=0: (0,0)── (1,0)(2,0)  ← seg0 → seg1 (2x2 block)
	#  y=1:       (1,1)(2,1)
	#  y=2: (1,2)     (3,2)     ← seg2 → seg4 (crossing up arm)
	#  y=3: (1,3)── (2,3)(3,3)(4,3)── (5,3)  ← seg3 → seg4 → seg5
	#  y=4:       (3,4)          ← seg4 (crossing down arm)
	#
	# seg0: Horizontal straight at (0,0), exits RIGHT
	var seg0 = track.create_straight_segment(Vector2i(0, 0), true)
	track.try_place_segment(Vector2i(0, 0), seg0)

	# seg1: 2x2 curve at (1,0), occupies (1,0),(2,0),(1,1),(2,1)
	# enters LEFT from seg0's RIGHT exit, exits DOWN
	var seg1 = track.create_curve_2x2_segment(Vector2i(1, 0), [Vector2i.LEFT, Vector2i.DOWN])
	track.try_place_segment(Vector2i(1, 0), seg1)

	# seg2: Vertical straight at (1,2), continues DOWN from 2x2 curve
	var seg2 = track.create_straight_segment(Vector2i(1, 2), false)
	track.try_place_segment(Vector2i(1, 2), seg2)

	# seg3: 1x1 curve at (1,3), enters DOWN from seg2, exits RIGHT
	var seg3 = track.create_curve_segment(Vector2i(1, 3), [Vector2i.DOWN, Vector2i.RIGHT])
	track.try_place_segment(Vector2i(1, 3), seg3)

	# seg4: Crossing at (3,3) occupies 5 cells
	# enters LEFT from seg3's RIGHT exit, exits RIGHT
	var seg4 = track.create_crossing_segment(Vector2i(3, 3))
	track.try_place_segment(Vector2i(3, 3), seg4)

	# seg5: Horizontal straight at (5,3), continues RIGHT from crossing
	var seg5 = track.create_straight_segment(Vector2i(5, 3), true)
	track.try_place_segment(Vector2i(5, 3), seg5)


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
