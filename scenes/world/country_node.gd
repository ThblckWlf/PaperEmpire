extends Node2D
class_name CountryNode


signal countryPressed(countryId: StringName)
signal countryHoverChanged(countryId: StringName, isHovered: bool)

const PLAYER_COLOR: Color = Color(0.25, 0.56, 0.84, 1.0)
const NEUTRAL_COLOR: Color = Color(0.74, 0.69, 0.58, 1.0)
const WORLD_COLOR: Color = Color(0.63, 0.37, 0.34, 1.0)
const UNKNOWN_COLOR: Color = Color(0.45, 0.48, 0.5, 1.0)
const HOVER_TINT: Color = Color(1.18, 1.12, 0.9, 1.0)
const SELECTED_OUTLINE_COLOR: Color = Color(1.0, 0.88, 0.34, 1.0)
const NORMAL_OUTLINE_COLOR: Color = Color(0.1, 0.12, 0.14, 1.0)

@onready var polygonNode: Polygon2D = $Polygon2D as Polygon2D
@onready var outlineNode: Line2D = $Outline as Line2D
@onready var areaNode: Area2D = $Area2D as Area2D
@onready var collisionNode: CollisionPolygon2D = $Area2D/CollisionPolygon2D as CollisionPolygon2D

var countryId: StringName = GameIds.EMPTY_ID
var ownerId: StringName = GameIds.NEUTRAL_OWNER_ID
var shapePoints: PackedVector2Array = PackedVector2Array()
var isSelected: bool = false
var isHovered: bool = false


func _ready() -> void:
	areaNode.input_event.connect(_onAreaInputEvent)
	areaNode.mouse_entered.connect(_onMouseEntered)
	areaNode.mouse_exited.connect(_onMouseExited)
	if shapePoints.is_empty():
		shapePoints = _defaultPoints()
	_applyVisualState()


func bindCountry(country: CountryData, points: PackedVector2Array, selected: bool) -> void:
	countryId = country.id
	ownerId = country.ownerId
	position = country.center
	if points.size() >= 3:
		shapePoints = points
	else:
		shapePoints = _defaultPoints()
	isSelected = selected
	_applyVisualState()


func setSelected(selected: bool) -> void:
	if isSelected == selected:
		return

	isSelected = selected
	_applyVisualState()


func setOwner(newOwnerId: StringName) -> void:
	if ownerId == newOwnerId:
		return

	ownerId = newOwnerId
	_applyVisualState()


func _onAreaInputEvent(_viewport: Viewport, event: InputEvent, _shapeIdx: int) -> void:
	if _isPointerOverUi():
		return

	var mouseButton := event as InputEventMouseButton
	if mouseButton == null:
		return

	if mouseButton.button_index == MOUSE_BUTTON_LEFT and mouseButton.pressed:
		countryPressed.emit(countryId)
		get_viewport().set_input_as_handled()


func _onMouseEntered() -> void:
	isHovered = true
	_applyVisualState()
	countryHoverChanged.emit(countryId, true)


func _onMouseExited() -> void:
	isHovered = false
	_applyVisualState()
	countryHoverChanged.emit(countryId, false)


func _applyVisualState() -> void:
	if not is_node_ready():
		return

	polygonNode.polygon = shapePoints
	collisionNode.polygon = shapePoints
	outlineNode.points = _closedOutlinePoints(shapePoints)
	polygonNode.color = _ownerColor(ownerId)
	if isHovered:
		polygonNode.color *= HOVER_TINT

	outlineNode.default_color = SELECTED_OUTLINE_COLOR if isSelected else NORMAL_OUTLINE_COLOR
	outlineNode.width = 4.0 if isSelected else 2.0
	z_index = 10 if isSelected else 0


func _ownerColor(currentOwnerId: StringName) -> Color:
	match currentOwnerId:
		GameIds.PLAYER_OWNER_ID:
			return PLAYER_COLOR
		GameIds.NEUTRAL_OWNER_ID:
			return NEUTRAL_COLOR
		GameIds.WORLD_OWNER_ID:
			return WORLD_COLOR
		_:
			return UNKNOWN_COLOR


func _closedOutlinePoints(points: PackedVector2Array) -> PackedVector2Array:
	var outline := PackedVector2Array()
	for point in points:
		outline.append(point)

	if points.size() > 0:
		outline.append(points[0])
	return outline


func _defaultPoints() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-24.0, -20.0),
		Vector2(24.0, -20.0),
		Vector2(28.0, 18.0),
		Vector2(-22.0, 22.0),
	])


func _isPointerOverUi() -> bool:
	return get_viewport().gui_get_hovered_control() != null
