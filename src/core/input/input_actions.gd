extends RefCounted
class_name InputActions


const ACTION_OPEN_MENU: StringName = &"open_menu"
const ACTION_PAUSE: StringName = &"pause"
const ACTION_PAN_LEFT: StringName = &"pan_left"
const ACTION_PAN_RIGHT: StringName = &"pan_right"
const ACTION_PAN_UP: StringName = &"pan_up"
const ACTION_PAN_DOWN: StringName = &"pan_down"
const ACTION_ZOOM_IN: StringName = &"zoom_in"
const ACTION_ZOOM_OUT: StringName = &"zoom_out"
const ACTION_SPEED_NORMAL: StringName = &"speed_normal"
const ACTION_SPEED_FAST: StringName = &"speed_fast"
const ACTION_SPEED_VERY_FAST: StringName = &"speed_very_fast"


static func ensureDefaultActions() -> void:
	_ensureKeyAction(ACTION_OPEN_MENU, [KEY_ESCAPE])
	_ensureKeyAction(ACTION_PAUSE, [KEY_SPACE])
	_ensureKeyAction(ACTION_PAN_LEFT, [KEY_A, KEY_LEFT])
	_ensureKeyAction(ACTION_PAN_RIGHT, [KEY_D, KEY_RIGHT])
	_ensureKeyAction(ACTION_PAN_UP, [KEY_W, KEY_UP])
	_ensureKeyAction(ACTION_PAN_DOWN, [KEY_S, KEY_DOWN])
	_ensureMouseButtonAction(ACTION_ZOOM_IN, [MOUSE_BUTTON_WHEEL_UP])
	_ensureMouseButtonAction(ACTION_ZOOM_OUT, [MOUSE_BUTTON_WHEEL_DOWN])
	_ensureKeyAction(ACTION_SPEED_NORMAL, [KEY_1])
	_ensureKeyAction(ACTION_SPEED_FAST, [KEY_2])
	_ensureKeyAction(ACTION_SPEED_VERY_FAST, [KEY_3])


static func _ensureKeyAction(actionName: StringName, keycodes: Array[int]) -> void:
	_ensureAction(actionName)
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(actionName, event):
			InputMap.action_add_event(actionName, event)


static func _ensureMouseButtonAction(actionName: StringName, buttons: Array[int]) -> void:
	_ensureAction(actionName)
	for buttonIndex in buttons:
		var event := InputEventMouseButton.new()
		event.button_index = buttonIndex
		if not InputMap.action_has_event(actionName, event):
			InputMap.action_add_event(actionName, event)


static func _ensureAction(actionName: StringName) -> void:
	if not InputMap.has_action(actionName):
		InputMap.add_action(actionName)
