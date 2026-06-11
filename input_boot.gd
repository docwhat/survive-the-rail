extends Node
## Auto-load node that registers default input action names at startup.
##
## Input bindings (key/button/axis) must be configured in the
## Godot Editor: Project Settings > Input Map.
##
## This node only ensures the "throttle" and "brake" action names
## exist. Bindings are added via the Editor for keyboard and controller support.

const THROTTLE_ACTION: String = "throttle"
const BRAKE_ACTION: String = "brake"
const REVERSE_TOGGLE_ACTION: String = "reverse_toggle"


func _ready() -> void:
	if not InputMap.has_action(THROTTLE_ACTION):
		InputMap.add_action(THROTTLE_ACTION)
	if not InputMap.has_action(BRAKE_ACTION):
		InputMap.add_action(BRAKE_ACTION)
	if not InputMap.has_action(REVERSE_TOGGLE_ACTION):
		InputMap.add_action(REVERSE_TOGGLE_ACTION)
