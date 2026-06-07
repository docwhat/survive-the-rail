extends Node2D
## Main scene entry point.
## Manages game state transitions between phases:
## TrackLay -> Playing -> Upgrading -> GameOver
## Keyboard controls: W/Up = throttle, S/Down/Space = brake.

var train: Train = null
var track: Track = null

var is_throttle: bool = false
var is_brake: bool = false


func _ready() -> void:
	train = Train.new()
	train.initialize(200.0, 100.0, 100.0, 100.0, 0.0, 0)
	track = Track.new()
	track.initialize(100.0, 100)
	train.enabled = true


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: Key = event.keycode
		var pressed: bool = event.pressed
		if key == KEY_W or key == KEY_UP:
			is_throttle = pressed
		elif key == KEY_S or key == KEY_DOWN or key == KEY_SPACE:
			is_brake = pressed


func _process(delta: float) -> void:
	if train == null:
		return
	train.update_input(is_throttle, is_brake)
	train.update_speed(delta)
	train.update_position(track, delta)
	train.update_orientation(track)
