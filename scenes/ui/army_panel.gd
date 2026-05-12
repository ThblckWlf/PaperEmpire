extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var statusLabel: Label = $MarginContainer/VBoxContainer/RunLabel as Label
@onready var locationLabel: Label = $MarginContainer/VBoxContainer/LocationLabel as Label
@onready var targetLabel: Label = $MarginContainer/VBoxContainer/TargetLabel as Label
@onready var unitsLabel: Label = $MarginContainer/VBoxContainer/UnitsLabel as Label

var eventBus: EventBus
var statusIcon: TextureRect
var powerLabel: Label
var upkeepLabel: Label
var costLabel: Label
var updateArmyButton: Button
var createArmyButton: Button
var previousArmyButton: Button
var nextArmyButton: Button
var currentArmyId: StringName = GameIds.EMPTY_ID
var selectedCountryId: StringName = GameIds.EMPTY_ID
var currentUnits: Dictionary = {}
var draftUnits: Dictionary = {}
var unitCosts: Dictionary = {}
var unitNames: Dictionary = {}
var unitOrder: Array = []
var hasArmy: bool = false
var canEdit: bool = false
var canCreateArmy: bool = false
var unitEditorRows: Dictionary = {}


func _ready() -> void:
	_ensureManagementControls()
	_applyAssetTheme()
	_updateEditorState()


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus
	_updateEditorState()


func setData(data: Dictionary) -> void:
	if not bool(data.get("hasArmy", false)):
		hasArmy = false
		currentArmyId = GameIds.EMPTY_ID
		selectedCountryId = StringName(str(data.get("selectedCountryId", "")))
		canEdit = false
		canCreateArmy = bool(data.get("canCreateArmy", false))
		currentUnits = _emptyUnits()
		draftUnits = currentUnits.duplicate(true)
		unitCosts = {}
		unitNames = {}
		unitOrder = [
			GameIds.INFANTRY_UNIT_ID,
			GameIds.CAVALRY_UNIT_ID,
			GameIds.ARTILLERY_UNIT_ID,
		]
		titleLabel.text = str(data.get("playerCountryName", "Spielerland"))
		statusLabel.text = "Keine Armee ausgewählt"
		locationLabel.visible = false
		targetLabel.visible = false
		unitsLabel.visible = false
		_setPowerAndUpkeep(0.0, 0)
		_setStatusIcon(UI_ASSET_THEME.ICON_CROWN_PATH)
		_updateEditorState()
		return

	hasArmy = true
	currentArmyId = StringName(str(data.get("id", "")))
	selectedCountryId = StringName(str(data.get("selectedCountryId", "")))
	canEdit = bool(data.get("canEdit", false))
	canCreateArmy = bool(data.get("canCreateArmy", false))
	currentUnits = (data.get("units", {}) as Dictionary).duplicate(true)
	draftUnits = currentUnits.duplicate(true)
	unitCosts = (data.get("unitCosts", {}) as Dictionary).duplicate(true)
	unitNames = (data.get("unitNames", {}) as Dictionary).duplicate(true)
	unitOrder = (data.get("unitOrder", []) as Array).duplicate()
	titleLabel.text = str(data.get("playerCountryName", "Spielerland"))
	var statusText := str(data.get("status", "Unknown"))
	statusLabel.text = "Armee: %s (%s)" % [str(data.get("name", "Armee")), _statusText(statusText)]
	locationLabel.visible = false
	targetLabel.visible = false
	unitsLabel.visible = false
	_setPowerAndUpkeep(float(data.get("totalCombatPower", 0.0)), int(data.get("foodUpkeepPerMonth", 0)))
	_setStatusIcon(UI_ASSET_THEME.iconForArmyStatus(statusText))
	_updateEditorState()


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_LARGE_PATH, 38.0, 10.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 20)
	UI_ASSET_THEME.applyLabel(statusLabel, 16)
	UI_ASSET_THEME.applyLabel(locationLabel, 16)
	UI_ASSET_THEME.applyLabel(targetLabel, 16)
	UI_ASSET_THEME.applyLabel(unitsLabel, 16)
	if powerLabel != null:
		UI_ASSET_THEME.applyLabel(powerLabel, 16)
	if upkeepLabel != null:
		UI_ASSET_THEME.applyLabel(upkeepLabel, 16)
	if costLabel != null:
		UI_ASSET_THEME.applyLabel(costLabel, 16)
	for unitId in unitEditorRows.keys():
		var row := unitEditorRows[unitId] as Dictionary
		var label := row.get("label", null) as Label
		var minusButton := row.get("minusButton", null) as Button
		var plusButton := row.get("plusButton", null) as Button
		if label != null:
			UI_ASSET_THEME.applyLabel(label, 16)
		if minusButton != null:
			UI_ASSET_THEME.applyTextButton(minusButton, false, true)
		if plusButton != null:
			UI_ASSET_THEME.applyTextButton(plusButton, false, true)
	if previousArmyButton != null:
		UI_ASSET_THEME.applyTextButton(previousArmyButton, false, true)
	if nextArmyButton != null:
		UI_ASSET_THEME.applyTextButton(nextArmyButton, false, true)
	if updateArmyButton != null:
		UI_ASSET_THEME.applyTextButton(updateArmyButton, false, false)
		UI_ASSET_THEME.applyButtonIcon(updateArmyButton, UI_ASSET_THEME.ICON_MANAGE_ARMY_PATH, "Armee aktualisieren", 24)
	if createArmyButton != null:
		UI_ASSET_THEME.applyTextButton(createArmyButton, false, false)
		UI_ASSET_THEME.applyButtonIcon(createArmyButton, UI_ASSET_THEME.ICON_MANAGE_ARMY_PATH, "Neue Armee im ausgewählten Land", 24)
	statusIcon = _ensureStatusIcon()
	_setStatusIcon(UI_ASSET_THEME.ICON_ARMY_PATH)


func _ensureStatusIcon() -> TextureRect:
	var column := titleLabel.get_parent() as VBoxContainer
	if column == null:
		return null

	var icon := column.get_node_or_null("ArmyStatusIcon") as TextureRect
	if icon == null:
		icon = UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.ICON_ARMY_PATH, Vector2(44.0, 44.0))
		icon.name = "ArmyStatusIcon"
		column.add_child(icon)
		column.move_child(icon, titleLabel.get_index())
	return icon


func _setStatusIcon(texturePath: String) -> void:
	if statusIcon == null:
		statusIcon = _ensureStatusIcon()
	if statusIcon != null:
		statusIcon.texture = UI_ASSET_THEME.loadTexture(texturePath)


func _ensureManagementControls() -> void:
	var column := titleLabel.get_parent() as VBoxContainer
	if column == null:
		return

	_ensureArmyNavigationRow(column)
	powerLabel = _ensureLabel(column, "PowerLabel", "Stärke: -")
	upkeepLabel = _ensureLabel(column, "UpkeepLabel", "Nahrung/Monat: -")
	costLabel = _ensureLabel(column, "PendingCostLabel", "Kosten: 0")

	var editorBox := column.get_node_or_null("UnitEditorRows") as VBoxContainer
	if editorBox == null:
		editorBox = VBoxContainer.new()
		editorBox.name = "UnitEditorRows"
		editorBox.add_theme_constant_override("separation", 4)
		column.add_child(editorBox)

	for unitId in [GameIds.INFANTRY_UNIT_ID, GameIds.CAVALRY_UNIT_ID, GameIds.ARTILLERY_UNIT_ID]:
		_ensureUnitEditorRow(editorBox, unitId)

	updateArmyButton = column.get_node_or_null("UpdateArmyButton") as Button
	if updateArmyButton == null:
		updateArmyButton = Button.new()
		updateArmyButton.name = "UpdateArmyButton"
		updateArmyButton.text = "Armee verwalten"
		column.add_child(updateArmyButton)
	updateArmyButton.text = "Armee verwalten"
	updateArmyButton.pressed.connect(_onUpdateArmyPressed)

	createArmyButton = column.get_node_or_null("CreateArmyButton") as Button
	if createArmyButton == null:
		createArmyButton = Button.new()
		createArmyButton.name = "CreateArmyButton"
		createArmyButton.text = "Neue Armee"
		column.add_child(createArmyButton)
	createArmyButton.text = "Neue Armee"
	createArmyButton.pressed.connect(_onCreateArmyPressed)


func _ensureArmyNavigationRow(column: VBoxContainer) -> void:
	var navigationRow := column.get_node_or_null("ArmyNavRow") as HBoxContainer
	if navigationRow == null:
		navigationRow = HBoxContainer.new()
		navigationRow.name = "ArmyNavRow"
		navigationRow.add_theme_constant_override("separation", 4)
		navigationRow.alignment = BoxContainer.ALIGNMENT_END
		column.add_child(navigationRow)
		column.move_child(navigationRow, 0)

	previousArmyButton = navigationRow.get_node_or_null("PreviousArmyButton") as Button
	if previousArmyButton == null:
		previousArmyButton = Button.new()
		previousArmyButton.name = "PreviousArmyButton"
		previousArmyButton.text = "<"
		previousArmyButton.tooltip_text = "Vorherige Armee"
		previousArmyButton.custom_minimum_size = Vector2(32.0, 28.0)
		previousArmyButton.focus_mode = Control.FOCUS_NONE
		navigationRow.add_child(previousArmyButton)
	if not previousArmyButton.pressed.is_connected(_onPreviousArmyPressed):
		previousArmyButton.pressed.connect(_onPreviousArmyPressed)

	nextArmyButton = navigationRow.get_node_or_null("NextArmyButton") as Button
	if nextArmyButton == null:
		nextArmyButton = Button.new()
		nextArmyButton.name = "NextArmyButton"
		nextArmyButton.text = ">"
		nextArmyButton.tooltip_text = "Nächste Armee"
		nextArmyButton.custom_minimum_size = Vector2(32.0, 28.0)
		nextArmyButton.focus_mode = Control.FOCUS_NONE
		navigationRow.add_child(nextArmyButton)
	if not nextArmyButton.pressed.is_connected(_onNextArmyPressed):
		nextArmyButton.pressed.connect(_onNextArmyPressed)


func _onPreviousArmyPressed() -> void:
	if eventBus == null:
		return
	eventBus.requestCommand(CommandType.SELECT_PREVIOUS_PLAYER_ARMY)


func _onNextArmyPressed() -> void:
	if eventBus == null:
		return
	eventBus.requestCommand(CommandType.SELECT_NEXT_PLAYER_ARMY)


func _ensureLabel(column: VBoxContainer, labelName: String, defaultText: String) -> Label:
	var label := column.get_node_or_null(labelName) as Label
	if label == null:
		label = Label.new()
		label.name = labelName
		label.text = defaultText
		column.add_child(label)
	return label


func _ensureUnitEditorRow(parent: VBoxContainer, unitId: StringName) -> void:
	var rowNode := parent.get_node_or_null("%sRow" % str(unitId)) as HBoxContainer
	if rowNode == null:
		rowNode = HBoxContainer.new()
		rowNode.name = "%sRow" % str(unitId)
		rowNode.add_theme_constant_override("separation", 4)
		parent.add_child(rowNode)

	var label := rowNode.get_node_or_null("CountLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "CountLabel"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rowNode.add_child(label)
	if rowNode.get_node_or_null("UnitIcon") == null:
		var icon := UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.iconForUnit(unitId), Vector2(24.0, 24.0))
		icon.name = "UnitIcon"
		rowNode.add_child(icon)
		rowNode.move_child(icon, 0)

	var minusButton := rowNode.get_node_or_null("MinusButton") as Button
	if minusButton == null:
		minusButton = Button.new()
		minusButton.name = "MinusButton"
		minusButton.text = "-"
		minusButton.custom_minimum_size = Vector2(32.0, 28.0)
		rowNode.add_child(minusButton)
	minusButton.pressed.connect(Callable(self, "_changeDraftUnit").bind(unitId, -1))

	var plusButton := rowNode.get_node_or_null("PlusButton") as Button
	if plusButton == null:
		plusButton = Button.new()
		plusButton.name = "PlusButton"
		plusButton.text = "+"
		plusButton.custom_minimum_size = Vector2(32.0, 28.0)
		rowNode.add_child(plusButton)
	plusButton.pressed.connect(Callable(self, "_changeDraftUnit").bind(unitId, 1))

	unitEditorRows[unitId] = {
		"label": label,
		"minusButton": minusButton,
		"plusButton": plusButton,
	}


func _changeDraftUnit(unitId: StringName, amount: int) -> void:
	if not canEdit:
		return

	draftUnits[unitId] = maxi(0, int(draftUnits.get(unitId, 0)) + amount)
	_updateEditorState()


func _onUpdateArmyPressed() -> void:
	if eventBus == null or currentArmyId == GameIds.EMPTY_ID:
		return

	eventBus.requestCommand(CommandType.UPDATE_ARMY_COMPOSITION, {
		"armyId": str(currentArmyId),
		"targetUnits": {
			str(GameIds.INFANTRY_UNIT_ID): int(draftUnits.get(GameIds.INFANTRY_UNIT_ID, 0)),
			str(GameIds.CAVALRY_UNIT_ID): int(draftUnits.get(GameIds.CAVALRY_UNIT_ID, 0)),
			str(GameIds.ARTILLERY_UNIT_ID): int(draftUnits.get(GameIds.ARTILLERY_UNIT_ID, 0)),
		},
	})


func _onCreateArmyPressed() -> void:
	if eventBus == null or selectedCountryId == GameIds.EMPTY_ID:
		return

	eventBus.requestCommand(CommandType.CREATE_ARMY, {
		"countryId": str(selectedCountryId),
	})


func _updateEditorState() -> void:
	if not is_node_ready():
		return

	for unitId in unitEditorRows.keys():
		var row := unitEditorRows[unitId] as Dictionary
		var label := row.get("label", null) as Label
		var minusButton := row.get("minusButton", null) as Button
		var plusButton := row.get("plusButton", null) as Button
		var rowNode: Control = null
		if label != null:
			rowNode = label.get_parent() as Control
		var unitName := str(unitNames.get(unitId, str(unitId).capitalize()))
		var count := int(draftUnits.get(unitId, 0))
		var cost := int(unitCosts.get(unitId, 0))
		if rowNode != null:
			rowNode.visible = hasArmy and canEdit
		if label != null:
			label.text = "%d (%d Gold)" % [count, cost]
			label.tooltip_text = unitName
		if minusButton != null:
			minusButton.disabled = not canEdit or count <= 0
		if plusButton != null:
			plusButton.disabled = not canEdit

	var pendingCost := _pendingGoldCost()
	if costLabel != null:
		costLabel.text = "Kosten: %d Gold" % pendingCost
		costLabel.visible = hasArmy and canEdit
	if updateArmyButton != null:
		updateArmyButton.disabled = eventBus == null or not canEdit or not _draftChanged()
		updateArmyButton.visible = hasArmy and canEdit
	if createArmyButton != null:
		createArmyButton.disabled = eventBus == null or not canCreateArmy
		createArmyButton.visible = canCreateArmy


func _pendingGoldCost() -> int:
	var totalCost := 0
	for unitId in [GameIds.INFANTRY_UNIT_ID, GameIds.CAVALRY_UNIT_ID, GameIds.ARTILLERY_UNIT_ID]:
		var currentAmount := int(currentUnits.get(unitId, 0))
		var draftAmount := int(draftUnits.get(unitId, 0))
		var addedAmount := maxi(0, draftAmount - currentAmount)
		totalCost += addedAmount * int(unitCosts.get(unitId, 0))
	return totalCost


func _draftChanged() -> bool:
	for unitId in [GameIds.INFANTRY_UNIT_ID, GameIds.CAVALRY_UNIT_ID, GameIds.ARTILLERY_UNIT_ID]:
		if int(currentUnits.get(unitId, 0)) != int(draftUnits.get(unitId, 0)):
			return true
	return false


func _setPowerAndUpkeep(power: float, upkeep: int) -> void:
	if powerLabel != null:
		powerLabel.text = "Stärke: %.0f" % power
		powerLabel.visible = hasArmy
	if upkeepLabel != null:
		upkeepLabel.text = "Nahrung/Monat: -%d" % upkeep
		upkeepLabel.visible = hasArmy


func _emptyUnits() -> Dictionary:
	return {
		GameIds.INFANTRY_UNIT_ID: 0,
		GameIds.CAVALRY_UNIT_ID: 0,
		GameIds.ARTILLERY_UNIT_ID: 0,
	}


func _statusText(statusText: String) -> String:
	match statusText.to_lower():
		"stationed":
			return "bereit"
		"moving":
			return "unterwegs"
		"attacking":
			return "Angriff"
		"defending":
			return "Verteidigung"
		"fighting":
			return "Kampf"
		"defeated":
			return "besiegt"
		_:
			return statusText
