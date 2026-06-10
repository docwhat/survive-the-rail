class_name InputAction
## Defines a named input action for checking input state.
##
## This provides a clean interface for querying input actions.
## Bindings are configured in project settings (project.godot).

var action_name: String = ""
## The name of this action as defined in project settings.


## Initialize the action with a project settings action name.
func initialize(name: String) -> void:
	action_name = name


## Check if this action is currently pressed.
func is_down() -> bool:
	return Input.is_action_pressed(action_name)


## Check if this action was just pressed this frame.
func is_just_pressed() -> bool:
	return Input.is_action_just_pressed(action_name)


## Check if this action was just released this frame.
func is_just_released() -> bool:
	return Input.is_action_just_released(action_name)


## Get debug info for this action.
func get_debug_info() -> String:
	return action_name


## Get the default throttle action name.
func get_throttle_action_name() -> String:
	return "throttle"


## Get the default brake action name.
func get_brake_action_name() -> String:
	return "brake"
