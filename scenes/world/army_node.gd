extends Node2D
class_name ArmyNode


signal armyPressed(armyId: StringName)

const TOKEN_PLAYER_TEXTURE: Texture2D = preload("res://assets/map/markers/armyTokenPlayer.png")
const TOKEN_ENEMY_TEXTURE: Texture2D = preload("res://assets/map/markers/armyTokenEnemy.png")
const TOKEN_MOVING_TEXTURE: Texture2D = preload("res://assets/map/markers/armyTokenMoving.png")
const TOKEN_FIGHTING_TEXTURE: Texture2D = preload("res://assets/map/markers/armyTokenFighting.png")
const TOKEN_SELECTED_TEXTURE: Texture2D = preload("res://assets/map/markers/armyTokenSelected.png")

const PLAYER_COLOR: Color = Color(0.18, 0.35, 0.78, 1.0)
const SELECTED_COLOR: Color = Color(1.0, 0.82, 0.24, 1.0)
const MOVING_COLOR: Color = Color(0.16, 0.6, 0.46, 1.0)

@onready var markerNode: Polygon2D = $Marker as Polygon2D
@onready var outlineNode: Line2D = $Outline as Line2D
@onready var countLabel: Label = $CountLabel as Label
@onready var areaNode: Area2D = $Area2D as Area2D

var armyId: StringName = GameIds.EMPTY_ID
var ownerId: StringName = GameIds.EMPTY_ID
var isSelected: bool = false
var isMovingVisual: bool = false
var currentStatus: int = ArmyStatus.Value.Stationed
var tokenNode: Sprite2D


func _ready() -> void:
	_ensureTokenNode()
	markerNode.visible = false
	outlineNode.visible = false
	countLabel.add_theme_color_override("font_color", Color("#211d17"))
	countLabel.add_theme_color_override("font_shadow_color", Color(1.0, 0.92, 0.72, 0.86))
	countLabel.add_theme_constant_override("shadow_offset_x", 1)
	countLabel.add_theme_constant_override("shadow_offset_y", 1)
	countLabel.add_theme_font_size_override("font_size", 16)
	areaNode.input_event.connect(_onAreaInputEvent)
	_applyVisualState(false)


func bindArmy(army: ArmyData, countries: Dictionary, selected: bool) -> void:
	armyId = army.id
	ownerId = army.ownerId
	isSelected = selected
	updateFromArmy(army, countries)


func updateFromArmy(army: ArmyData, countries: Dictionary) -> void:
	armyId = army.id
	ownerId = army.ownerId
	currentStatus = army.status
	position = _armyPosition(army, countries)
	countLabel.text = str(_unitCount(army.units))
	isMovingVisual = army.status == ArmyStatus.Value.Moving
	_applyVisualState(isMovingVisual)


func setSelected(selected: bool) -> void:
	if isSelected == selected:
		return

	isSelected = selected
	_applyVisualState(isMovingVisual)


func _onAreaInputEvent(_viewport: Viewport, event: InputEvent, _shapeIdx: int) -> void:
	if _isPointerOverUi():
		return

	var mouseButton := event as InputEventMouseButton
	if mouseButton == null:
		return

	if mouseButton.button_index == MOUSE_BUTTON_LEFT and mouseButton.pressed:
		armyPressed.emit(armyId)
		get_viewport().set_input_as_handled()


func _applyVisualState(isMoving: bool) -> void:
	if not is_node_ready():
		return

	markerNode.color = MOVING_COLOR if isMoving else PLAYER_COLOR
	outlineNode.default_color = SELECTED_COLOR if isSelected else Color(0.06, 0.07, 0.09, 1.0)
	outlineNode.width = 3.0 if isSelected else 2.0
	if tokenNode != null:
		tokenNode.texture = _tokenTexture(isMoving)
		tokenNode.scale = Vector2(0.05, 0.05)
	z_index = 30 if isSelected else 20


func _ensureTokenNode() -> void:
	if tokenNode != null:
		return

	tokenNode = Sprite2D.new()
	tokenNode.name = "Token"
	tokenNode.centered = true
	tokenNode.texture = TOKEN_PLAYER_TEXTURE
	add_child(tokenNode)
	move_child(tokenNode, markerNode.get_index())


func _tokenTexture(isMoving: bool) -> Texture2D:
	if isSelected:
		return TOKEN_SELECTED_TEXTURE
	if currentStatus == ArmyStatus.Value.Attacking or currentStatus == ArmyStatus.Value.Defending:
		return TOKEN_FIGHTING_TEXTURE
	if isMoving:
		return TOKEN_MOVING_TEXTURE
	if ownerId != GameIds.PLAYER_OWNER_ID:
		return TOKEN_ENEMY_TEXTURE
	return TOKEN_PLAYER_TEXTURE


func _armyPosition(army: ArmyData, countries: Dictionary) -> Vector2:
	var sourceCountry := countries.get(army.locationCountryId, null) as CountryData
	if sourceCountry == null:
		return Vector2.ZERO

	if army.status != ArmyStatus.Value.Moving or army.targetCountryId == GameIds.EMPTY_ID:
		return sourceCountry.center

	var targetCountry := countries.get(army.targetCountryId, null) as CountryData
	if targetCountry == null:
		return sourceCountry.center

	return sourceCountry.center.lerp(targetCountry.center, clampf(army.movementProgress, 0.0, 1.0))


func _unitCount(units: Dictionary) -> int:
	var total := 0
	for unitId in units.keys():
		total += int(units[unitId])
	return total


func _isPointerOverUi() -> bool:
	return get_viewport().gui_get_hovered_control() != null
