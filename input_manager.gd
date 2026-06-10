class_name InputManager
## Centralized input abstraction layer (G.U.I.D.E-style).
##
## Provides a clean interface for checking throttle and brake states.
## Input bindings must be configured in the Godot Editor
## (Project Settings > Input Map) for the actions "throttle" and "brake".
## Supports keyboard (W/S/Up/Down/Space) and controller input.

const THROTTLE_ACTION: String = "throttle"
const BRAKE_ACTION: String = "brake"


## Get the current throttle state.
## Returns true if the throttle action is currently active.
func get_throttle() -> bool:
	return Input.is_action_pressed(THROTTLE_ACTION)


## Get the current brake state.
## Returns true if the brake action is currently active.
func get_brake() -> bool:
	return Input.is_action_pressed(BRAKE_ACTION)


## Check if throttle was just pressed this frame.
func throttle_just_pressed() -> bool:
	return Input.is_action_just_pressed(THROTTLE_ACTION)


## Check if brake was just pressed this frame.
func brake_just_pressed() -> bool:
	return Input.is_action_just_pressed(BRAKE_ACTION)


## Get a list of configured action names.
func get_action_names() -> PackedStringArray:
	return InputMap.get_actions()


## Get debug info for all registered actions.
func get_debug_info() -> String:
	return "\n".join(get_action_names())
