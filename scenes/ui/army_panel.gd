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
var currentArmyId: StringName = GameIds.EMPTY_ID
var selectedCountryId: StringName = GameIds.EMPTY_ID
var currentUnits: Dictionary = {}
var draftUnits: Dictionary = {}
var unitCosts: Dictionary = {}
var unitNames: Dictionary = {}
var unitOrder: Array = []
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
		currentArmyId = GameIds.EMPTY_ID
		selectedCountryId = StringName(str(data.get("selectedCountryId", "")))
		canEdit = false
		canCreateArmy = bool(data.get("canCreateArmy", false))
		currentUnits = _emptyUnits()
		draftUnits = currentUnits.duplicate(true)
		titleLabel.text = str(data.get("name", "No army selected"))
		statusLabel.text = "Status: -"
		locationLabel.text = "Location: -"
		targetLabel.text = "Target: -"
		unitsLabel.text = "Units: -"
		_setPowerAndUpkeep(0.0, 0)
		_setStatusIcon(UI_ASSET_THEME.ICON_ARMY_PATH)
		_updateEditorState()
		return

	currentArmyId = StringName(str(data.get("id", "")))
	selectedCountryId = StringName(str(data.get("selectedCountryId", "")))
	canEdit = bool(data.get("canEdit", false))
	canCreateArmy = bool(data.get("canCreateArmy", false))
	currentUnits = (data.get("units", {}) as Dictionary).duplicate(true)
	draftUnits = currentUnits.duplicate(true)
	unitCosts = (data.get("unitCosts", {}) as Dictionary).duplicate(true)
	unitNames = (data.get("unitNames", {}) as Dictionary).duplicate(true)
	unitOrder = (data.get("unitOrder", []) as Array).duplicate()
	titleLabel.text = str(data.get("name", "Army"))
	var statusText := str(data.get("status", "Unknown"))
	statusLabel.text = "Status: %s" % statusText
	locationLabel.text = "Location: %s" % str(data.get("location", "-"))
	targetLabel.text = "Target: %s" % str(data.get("target", "-"))
	unitsLabel.text = "Units:\n%s" % "\n".join(data.get("unitRows", []))
	_setPowerAndUpkeep(float(data.get("totalCombatPower", 0.0)), int(data.get("foodUpkeepPerMonth", 0)))
	_setStatusIcon(UI_ASSET_THEME.iconForArmyStatus(statusText))
	_updateEditorState()


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_LARGE_PATH, 38.0, 12.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 22)
	UI_ASSET_THEME.applyLabel(statusLabel, 17)
	UI_ASSET_THEME.applyLabel(locationLabel, 17)
	UI_ASSET_THEME.applyLabel(targetLabel, 17)
	UI_ASSET_THEME.applyLabel(unitsLabel, 17)
	if powerLabel != null:
		UI_ASSET_THEME.applyLabel(powerLabel, 17)
	if upkeepLabel != null:
		UI_ASSET_THEME.applyLabel(upkeepLabel, 17)
	if costLabel != null:
		UI_ASSET_THEME.applyLabel(costLabel, 17)
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
	if updateArmyButton != null:
		UI_ASSET_THEME.applyTextButton(updateArmyButton, false, false)
	if createArmyButton != null:
		UI_ASSET_THEME.applyTextButton(createArmyButton, false, false)
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

	powerLabel = _ensureLabel(column, "PowerLabel", "Power: -")
	upkeepLabel = _ensureLabel(column, "UpkeepLabel", "Food upkeep/month: -")
	costLabel = _ensureLabel(column, "PendingCostLabel", "Pending cost: 0")

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
		updateArmyButton.text = "Update Army"
		column.add_child(updateArmyButton)
	updateArmyButton.pressed.connect(_onUpdateArmyPressed)

	createArmyButton = column.get_node_or_null("CreateArmyButton") as Button
	if createArmyButton == null:
		createArmyButton = Button.new()
		createArmyButton.name = "CreateArmyButton"
		createArmyButton.text = "Create Army"
		column.add_child(createArmyButton)
	createArmyButton.pressed.connect(_onCreateArmyPressed)


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
		var unitName := str(unitNames.get(unitId, str(unitId).capitalize()))
		var count := int(draftUnits.get(unitId, 0))
		var cost := int(unitCosts.get(unitId, 0))
		if label != null:
			label.text = "%s: %d (%dg)" % [unitName, count, cost]
		if minusButton != null:
			minusButton.disabled = not canEdit or count <= 0
		if plusButton != null:
			plusButton.disabled = not canEdit

	var pendingCost := _pendingGoldCost()
	if costLabel != null:
		costLabel.text = "Pending cost: %d gold" % pendingCost
	if updateArmyButton != null:
		updateArmyButton.disabled = eventBus == null or not canEdit or not _draftChanged()
	if createArmyButton != null:
		createArmyButton.disabled = eventBus == null or not canCreateArmy


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
		powerLabel.text = "Power: %.1f" % power
	if upkeepLabel != null:
		upkeepLabel.text = "Food upkeep/month: %d" % upkeep


func _emptyUnits() -> Dictionary:
	return {
		GameIds.INFANTRY_UNIT_ID: 0,
		GameIds.CAVALRY_UNIT_ID: 0,
		GameIds.ARTILLERY_UNIT_ID: 0,
	}
