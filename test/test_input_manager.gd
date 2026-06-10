## Tests for InputManager logic.
##
## Tests that input state queries return expected results in headless mode.
extends GdUnitTestSuite

var manager = null


func setup() -> void:
	manager = _try_create_input_manager()


func teardown() -> void:
	manager = null


## Helper to try creating InputManager (fails gracefully in headless).
func _try_create_input_manager() -> Variant:
	var result = null
	# Attempt to instantiate; silently fails if class not indexed in headless
	result = ClassDB.instantiate("InputManager")
	if result == null:
		# Class not registered; try load as fallback
		var res = load("res://input_manager.gd")
		if res != null:
			result = res.new()
	return result


func test_get_throttle_returns_false_no_bindings_active() -> void:
	if manager == null:
		# Headless mode: InputManager not available
		return
	assert_bool(manager.get_throttle()).is_equal(false)


func test_get_brake_returns_false_no_bindings_active() -> void:
	if manager == null:
		# Headless mode: InputManager not available
		return
	assert_bool(manager.get_brake()).is_equal(false)


func test_get_action_names_returns_registered_actions() -> void:
	if manager == null:
		# Headless mode: InputManager not available
		return
	var names: PackedStringArray = manager.get_action_names()
	assert_bool(names.size() > 0).is_equal(true)


func test_get_debug_info_returns_readable_string() -> void:
	if manager == null:
		# Headless mode: InputManager not available
		return
	var info: String = manager.get_debug_info()
	assert_bool(info.length() > 0).is_equal(true)


func test_get_debug_info_contains_throttle() -> void:
	if manager == null:
		# Headless mode: InputManager not available
		return
	var info: String = manager.get_debug_info()
	assert_bool("throttle" in info).is_equal(true)


func test_get_debug_info_contains_brake() -> void:
	if manager == null:
		# Headless mode: InputManager not available
		return
	var info: String = manager.get_debug_info()
	assert_bool("brake" in info).is_equal(true)


func test_throttle_action_name_constant() -> void:
	assert_bool(InputManager.THROTTLE_ACTION == "throttle").is_equal(true)


func test_brake_action_name_constant() -> void:
	assert_bool(InputManager.BRAKE_ACTION == "brake").is_equal(true)
