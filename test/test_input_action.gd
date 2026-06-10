## Tests for InputAction logic.
##
## Tests that InputAction provides the right interface for input checks.
extends GdUnitTestSuite

func test_initialize_sets_action_name() -> void:
	var action: InputAction = InputAction.new()
	action.initialize("throttle")
	assert_bool(action.action_name == "throttle").is_equal(true)


func test_is_down_uses_input_map() -> void:
	var action: InputAction = InputAction.new()
	action.initialize("throttle")
	# In headless mode, throttle should not be pressed
	assert_bool(action.is_down()).is_equal(false)


func test_is_just_pressed_returns_false_in_headless() -> void:
	var action: InputAction = InputAction.new()
	action.initialize("nonexistent_action")
	assert_bool(action.is_just_pressed()).is_equal(false)


func test_is_just_released_returns_false_in_headless() -> void:
	var action: InputAction = InputAction.new()
	action.initialize("nonexistent_action")
	assert_bool(action.is_just_released()).is_equal(false)


func test_get_debug_info_returns_name() -> void:
	var action: InputAction = InputAction.new()
	action.initialize("my_action")
	assert_bool(action.get_debug_info() == "my_action").is_equal(true)


func test_get_throttle_action_name_returns_string() -> void:
	var action: InputAction = InputAction.new()
	assert_bool(action.get_throttle_action_name() == "throttle").is_equal(true)


func test_get_brake_action_name_returns_string() -> void:
	var action: InputAction = InputAction.new()
	assert_bool(action.get_brake_action_name() == "brake").is_equal(true)
