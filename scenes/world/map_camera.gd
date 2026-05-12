extends Camera2D
class_name MapCameraController


const START_ZOOM: float = 0.46
const MIN_ZOOM: float = 0.42
const MAX_ZOOM: float = 3.2
const ZOOM_STEP: float = 0.15
const KEYBOARD_PAN_SPEED: float = 760.0
const BOUNDS_PADDING: float = 460.0
const SMOOTH_FOCUS_SPEED: float = 9.0
const SMOOTH_FOCUS_SNAP_DISTANCE: float = 1.5
const FALLBACK_BOUNDS := Rect2(Vector2.ZERO, Vector2(4096.0, 2304.0))
const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")

var mapBounds: Rect2 = FALLBACK_BOUNDS
var isDragging: bool = false
var activeDragButton: int = MOUSE_BUTTON_NONE
var hasCenteredOnBounds: bool = false
var smoothFocusTargetPosition: Vector2 = Vector2.ZERO
var hasSmoothFocusTarget: bool = false


func _ready() -> void:
	INPUT_ACTIONS.ensureDefaultActions()
	enabled = true
	setZoomScalar(START_ZOOM)
	centerOnMap()


func _process(delta: float) -> void:
	_advanceSmoothFocus(delta)
	if get_viewport().gui_get_focus_owner() != null:
		return

	var direction := _keyboardPanDirection()
	if direction == Vector2.ZERO:
		return

	cancelSmoothFocus()
	var panDistance := KEYBOARD_PAN_SPEED * delta / getZoomScalar()
	panBy(direction.normalized() * panDistance)


func _unhandled_input(event: InputEvent) -> void:
	if _isPointerOverUi(event):
		return

	var mouseButton := event as InputEventMouseButton
	if mouseButton != null:
		if event.is_action_pressed(INPUT_ACTIONS.ACTION_ZOOM_IN):
			zoomAtCursor(ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(INPUT_ACTIONS.ACTION_ZOOM_OUT):
			zoomAtCursor(-ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		_handleMouseButton(mouseButton)
		return

	var mouseMotion := event as InputEventMouseMotion
	if mouseMotion != null and isDragging:
		cancelSmoothFocus()
		panBy(-mouseMotion.relative / getZoomScalar())
		get_viewport().set_input_as_handled()


func setMapBounds(newMapBounds: Rect2) -> void:
	if newMapBounds.size.x <= 0.0 or newMapBounds.size.y <= 0.0:
		return

	mapBounds = newMapBounds
	_applyCameraLimits()
	if not hasCenteredOnBounds:
		centerOnMap()
	else:
		_clampPosition()


func centerOnMap() -> void:
	position = mapBounds.get_center()
	hasCenteredOnBounds = true
	_clampPosition()


func panBy(deltaWorld: Vector2) -> void:
	position += deltaWorld
	_clampPosition()


func focusOnWorldPosition(target: Vector2) -> void:
	smoothFocusTargetPosition = _positionWithinBounds(target)
	hasSmoothFocusTarget = true


func cancelSmoothFocus() -> void:
	hasSmoothFocusTarget = false


func _advanceSmoothFocus(delta: float) -> void:
	if not hasSmoothFocusTarget:
		return

	var weight := clampf(SMOOTH_FOCUS_SPEED * delta, 0.0, 1.0)
	position = position.lerp(smoothFocusTargetPosition, weight)
	_clampPosition()
	if position.distance_to(smoothFocusTargetPosition) <= SMOOTH_FOCUS_SNAP_DISTANCE:
		position = smoothFocusTargetPosition
		_clampPosition()
		hasSmoothFocusTarget = false


func _positionWithinBounds(target: Vector2) -> Vector2:
	var bounds := getMovementBounds()
	return Vector2(
		clampf(target.x, bounds.position.x, bounds.end.x),
		clampf(target.y, bounds.position.y, bounds.end.y)
	)


func setZoomScalar(nextZoom: float) -> void:
	var zoomScalar := clampf(nextZoom, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(zoomScalar, zoomScalar)
	_clampPosition()


func getZoomScalar() -> float:
	return zoom.x


func getMovementBounds() -> Rect2:
	return mapBounds.grow(BOUNDS_PADDING)


func getMinZoom() -> float:
	return MIN_ZOOM


func getMaxZoom() -> float:
	return MAX_ZOOM


func _handleMouseButton(mouseButton: InputEventMouseButton) -> void:
	match mouseButton.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if mouseButton.pressed:
				zoomAtCursor(ZOOM_STEP)
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_DOWN:
			if mouseButton.pressed:
				zoomAtCursor(-ZOOM_STEP)
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			isDragging = mouseButton.pressed
			activeDragButton = mouseButton.button_index if mouseButton.pressed else MOUSE_BUTTON_NONE
			get_viewport().set_input_as_handled()


func zoomAtCursor(deltaZoom: float) -> void:
	cancelSmoothFocus()
	var worldBeforeZoom := get_global_mouse_position()
	setZoomScalar(getZoomScalar() + deltaZoom)
	var worldAfterZoom := get_global_mouse_position()
	position += worldBeforeZoom - worldAfterZoom
	_clampPosition()


func _keyboardPanDirection() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_action_pressed(INPUT_ACTIONS.ACTION_PAN_LEFT):
		direction.x -= 1.0
	if Input.is_action_pressed(INPUT_ACTIONS.ACTION_PAN_RIGHT):
		direction.x += 1.0
	if Input.is_action_pressed(INPUT_ACTIONS.ACTION_PAN_UP):
		direction.y -= 1.0
	if Input.is_action_pressed(INPUT_ACTIONS.ACTION_PAN_DOWN):
		direction.y += 1.0
	return direction


func _applyCameraLimits() -> void:
	var bounds := getMovementBounds()
	limit_left = int(floor(bounds.position.x))
	limit_top = int(floor(bounds.position.y))
	limit_right = int(ceil(bounds.end.x))
	limit_bottom = int(ceil(bounds.end.y))


func _clampPosition() -> void:
	var bounds := getMovementBounds()
	position = Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x),
		clampf(position.y, bounds.position.y, bounds.end.y)
	)


func _isPointerOverUi(event: InputEvent) -> bool:
	if not (event is InputEventMouse):
		return false

	return get_viewport().gui_get_hovered_control() != null
