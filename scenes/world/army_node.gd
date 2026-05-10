extends Node2D
class_name ArmyNode


signal armyPressed(armyId: StringName)

const PLAYER_COLOR: Color = Color(0.18, 0.35, 0.78, 1.0)
const SELECTED_COLOR: Color = Color(1.0, 0.82, 0.24, 1.0)
const MOVING_COLOR: Color = Color(0.16, 0.6, 0.46, 1.0)

@onready var markerNode: Polygon2D = $Marker as Polygon2D
@onready var outlineNode: Line2D = $Outline as Line2D
@onready var countLabel: Label = $CountLabel as Label
@onready var areaNode: Area2D = $Area2D as Area2D

var armyId: StringName = GameIds.EMPTY_ID
var isSelected: bool = false
var isMovingVisual: bool = false


func _ready() -> void:
	areaNode.input_event.connect(_onAreaInputEvent)
	_applyVisualState(false)


func bindArmy(army: ArmyData, countries: Dictionary, selected: bool) -> void:
	armyId = army.id
	isSelected = selected
	updateFromArmy(army, countries)


func updateFromArmy(army: ArmyData, countries: Dictionary) -> void:
	armyId = army.id
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
	z_index = 30 if isSelected else 20


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
