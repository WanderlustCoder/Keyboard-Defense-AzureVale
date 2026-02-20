class_name E2EInputSimulator
extends RefCounted
## Simulates user input for E2E tests.

var _tree: SceneTree


func _init(tree: SceneTree) -> void:
	_tree = tree


## Type a string character by character (synchronous for headless)
func type_string(text: String) -> void:
	for i in range(text.length()):
		var char_str: String = text.substr(i, 1)
		type_char(char_str)


## Type a single character via input events
func type_char(char_str: String) -> void:
	if char_str.is_empty():
		return
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = char_str.unicode_at(0)
	event.unicode = char_str.unicode_at(0)
	Input.parse_input_event(event)

	var release := InputEventKey.new()
	release.pressed = false
	release.keycode = char_str.unicode_at(0)
	release.unicode = char_str.unicode_at(0)
	Input.parse_input_event(release)


## Press a special key (Escape, Enter, etc.)
func press_key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	Input.parse_input_event(event)

	var release := InputEventKey.new()
	release.pressed = false
	release.keycode = keycode
	Input.parse_input_event(release)


## Press Escape key
func press_escape() -> void:
	press_key(KEY_ESCAPE)


## Press Enter key
func press_enter() -> void:
	press_key(KEY_ENTER)


## Simulate button click by emitting signal
func click_button(button: Button) -> void:
	if button == null or not button.visible:
		return
	button.emit_signal("pressed")


## Simulate mouse click at position
func click_at(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	Input.parse_input_event(press)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	Input.parse_input_event(release)


## Type word directly into TypingSystem and return result
func type_word_for_system(typing_system, word: String) -> Dictionary:
	var last_result: Dictionary = {}
	for i in range(word.length()):
		var letter: String = word.substr(i, 1)
		if typing_system.has_method("input_char"):
			last_result = typing_system.input_char(letter)
	return last_result


## Simulate an input action
func trigger_action(action_name: String) -> void:
	var press := InputEventAction.new()
	press.action = action_name
	press.pressed = true
	Input.parse_input_event(press)

	var release := InputEventAction.new()
	release.action = action_name
	release.pressed = false
	Input.parse_input_event(release)
