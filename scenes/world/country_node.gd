extends Node2D
class_name CountryNode


signal countryPressed(countryId: StringName)
signal countryMoveTargetPressed(countryId: StringName)
signal countryHoverChanged(countryId: StringName, isHovered: bool)

const PLAYER_COLOR: Color = Color(0.43, 0.56, 0.39, 0.30)
const NEUTRAL_COLOR: Color = Color(0.0, 0.0, 0.0, 0.0)
const WORLD_COLOR: Color = Color(0.64, 0.29, 0.25, 0.26)
const UNKNOWN_COLOR: Color = Color(0.49, 0.61, 0.65, 0.18)
const HOVER_COLOR: Color = Color(0.76, 0.58, 0.20, 0.24)
const SELECTED_OUTLINE_COLOR: Color = Color("#C39535")
const HOVER_OUTLINE_COLOR: Color = Color(0.18, 0.16, 0.12, 0.72)

@onready var polygonTemplate: Polygon2D = $Polygon2D as Polygon2D
@onready var outlineTemplate: Line2D = $Outline as Line2D
@onready var labelNode: Label = $NameLabel as Label
@onready var areaNode: Area2D = $Area2D as Area2D
@onready var collisionTemplate: CollisionPolygon2D = $Area2D/CollisionPolygon2D as CollisionPolygon2D

var countryId: StringName = GameIds.EMPTY_ID
var countryName: String = ""
var ownerId: StringName = GameIds.NEUTRAL_OWNER_ID
var shapePolygons: Array[PackedVector2Array] = []
var polygonNodes: Array[Polygon2D] = []
var outlineNodes: Array[Line2D] = []
var isSelected: bool = false
var isHovered: bool = false


func _ready() -> void:
	areaNode.input_event.connect(_onAreaInputEvent)
	areaNode.mouse_entered.connect(_onMouseEntered)
	areaNode.mouse_exited.connect(_onMouseExited)
	polygonTemplate.visible = false
	outlineTemplate.visible = false
	labelNode.visible = false
	collisionTemplate.polygon = PackedVector2Array()
	if shapePolygons.is_empty():
		shapePolygons = [_defaultPoints()]
	_rebuildShapeNodes()
	_applyVisualState()


func bindCountry(country: CountryData, polygons: Array[PackedVector2Array], selected: bool) -> void:
	countryId = country.id
	countryName = country.name
	ownerId = country.ownerId
	position = country.center
	if not polygons.is_empty():
		shapePolygons = polygons
	else:
		shapePolygons = [_defaultPoints()]
	isSelected = selected
	if is_node_ready():
		_rebuildShapeNodes()
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


func setHovered(hovered: bool) -> void:
	if isHovered == hovered:
		return

	isHovered = hovered
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
	elif mouseButton.button_index == MOUSE_BUTTON_RIGHT and mouseButton.pressed:
		countryMoveTargetPressed.emit(countryId)
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

	var fillColor := HOVER_COLOR if isHovered else _ownerColor(ownerId)
	for polygonNode in polygonNodes:
		polygonNode.color = fillColor

	for outlineNode in outlineNodes:
		outlineNode.visible = isSelected or isHovered
		outlineNode.default_color = SELECTED_OUTLINE_COLOR if isSelected else HOVER_OUTLINE_COLOR
		outlineNode.width = 5.0 if isSelected else 2.4
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


func _rebuildShapeNodes() -> void:
	for polygonNode in polygonNodes:
		polygonNode.queue_free()
	for outlineNode in outlineNodes:
		outlineNode.queue_free()
	polygonNodes.clear()
	outlineNodes.clear()

	for index in range(shapePolygons.size()):
		var points := shapePolygons[index]

		var polygonNode := Polygon2D.new()
		polygonNode.name = "Fill%d" % index
		polygonNode.polygon = points
		add_child(polygonNode)
		polygonNodes.append(polygonNode)

		var outlineNode := Line2D.new()
		outlineNode.name = "Outline%d" % index
		outlineNode.points = _closedOutlinePoints(points)
		outlineNode.joint_mode = Line2D.LINE_JOINT_ROUND
		outlineNode.begin_cap_mode = Line2D.LINE_CAP_ROUND
		outlineNode.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(outlineNode)
		outlineNodes.append(outlineNode)


func _defaultPoints() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-24.0, -20.0),
		Vector2(24.0, -20.0),
		Vector2(28.0, 18.0),
		Vector2(-22.0, 22.0),
	])


func _isPointerOverUi() -> bool:
	return get_viewport().gui_get_hovered_control() != null
