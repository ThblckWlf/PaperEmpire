extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var ownerLabel: Label = $MarginContainer/VBoxContainer/OwnerLabel as Label
@onready var goldLabel: Label = $MarginContainer/VBoxContainer/GoldLabel as Label
@onready var foodLabel: Label = $MarginContainer/VBoxContainer/FoodLabel as Label
@onready var defenseLabel: Label = $MarginContainer/VBoxContainer/DefenseLabel as Label
@onready var armiesLabel: Label = $MarginContainer/VBoxContainer/ArmiesLabel as Label
@onready var recruitLabel: Label = $MarginContainer/VBoxContainer/RecruitLabel as Label
@onready var recruitButtons: HBoxContainer = $MarginContainer/VBoxContainer/RecruitButtons as HBoxContainer
@onready var infantryButton: Button = $MarginContainer/VBoxContainer/RecruitButtons/InfantryButton as Button
@onready var cavalryButton: Button = $MarginContainer/VBoxContainer/RecruitButtons/CavalryButton as Button
@onready var artilleryButton: Button = $MarginContainer/VBoxContainer/RecruitButtons/ArtilleryButton as Button
@onready var createArmyButton: Button = $MarginContainer/VBoxContainer/CreateArmyButton as Button

var eventBus: EventBus
var currentCountryId: StringName = GameIds.EMPTY_ID
var currentSelectedArmyId: StringName = GameIds.EMPTY_ID
var isPlayerOwned: bool = false
var canRecruit: bool = false
var canAttack: bool = false
var attackBlockedReason: String = ""
var attackButton: Button
var attackControls: VBoxContainer
var attackArmyDropdown: OptionButton
var attackOptions: Array[Dictionary] = []
var selectedAttackArmyId: StringName = GameIds.EMPTY_ID
var attackSourceUnits: Dictionary = {}
var attackDraftUnits: Dictionary = {}
var unitNames: Dictionary = {}
var unitOrder: Array = []
var attackUnitRows: Dictionary = {}
var statRows: Dictionary = {}


func _ready() -> void:
	infantryButton.pressed.connect(_onInfantryPressed)
	cavalryButton.pressed.connect(_onCavalryPressed)
	artilleryButton.pressed.connect(_onArtilleryPressed)
	createArmyButton.pressed.connect(_onCreateArmyPressed)
	attackButton = _ensureAttackButton()
	if attackButton != null:
		attackButton.pressed.connect(_onAttackPressed)
	_ensureAttackControls()
	_ensureStatRows()
	_applyAssetTheme()
	_updateCommandButtonStates()


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus
	_updateCommandButtonStates()


func setData(data: Dictionary) -> void:
	if not bool(data.get("hasCountry", false)):
		currentCountryId = GameIds.EMPTY_ID
		currentSelectedArmyId = GameIds.EMPTY_ID
		isPlayerOwned = false
		canRecruit = false
		canAttack = false
		attackBlockedReason = ""
		_clearAttackData()
		titleLabel.text = "Land auswählen"
		ownerLabel.text = "Klicke auf ein Land auf der Karte."
		_setCountryRowsVisible(false)
		_setRowVisible("OwnerRow", true)
		recruitLabel.visible = false
		recruitButtons.visible = false
		createArmyButton.visible = false
		if attackButton != null:
			attackButton.visible = false
		if attackControls != null:
			attackControls.visible = false
		_updateCommandButtonStates()
		return

	currentCountryId = StringName(str(data.get("id", "")))
	currentSelectedArmyId = StringName(str(data.get("selectedArmyId", "")))
	isPlayerOwned = bool(data.get("isPlayerOwned", false))
	canRecruit = bool(data.get("canRecruit", false))
	canAttack = bool(data.get("canAttack", false))
	attackBlockedReason = str(data.get("attackBlockedReason", ""))
	attackOptions = _readAttackOptions(data.get("attackOptions", []))
	selectedAttackArmyId = StringName(str(data.get("selectedAttackArmyId", "")))
	unitNames = (data.get("unitNames", {}) as Dictionary).duplicate(true)
	unitOrder = (data.get("unitOrder", []) as Array).duplicate()
	if unitOrder.is_empty():
		unitOrder = [
			GameIds.INFANTRY_UNIT_ID,
			GameIds.CAVALRY_UNIT_ID,
			GameIds.ARTILLERY_UNIT_ID,
		]
	_setSelectedAttackOption(selectedAttackArmyId)

	titleLabel.text = str(data.get("name", "Land"))
	ownerLabel.text = "Besitzer: %s" % str(data.get("ownerText", data.get("ownerId", "")))
	goldLabel.text = "Gold/Monat: %s" % _formatSigned(int(data.get("goldPerMonth", 0)))
	foodLabel.text = "Nahrung/Monat: %s" % _formatSigned(int(data.get("foodPerMonth", 0)))
	defenseLabel.text = "Verteidigung: %s" % _formatNumber(int(data.get("defense", 0)))
	armiesLabel.text = "Armeen: %s" % str(data.get("stationedArmySummary", "-"))

	_setCountryRowsVisible(true)
	recruitButtons.visible = isPlayerOwned
	createArmyButton.visible = isPlayerOwned
	if isPlayerOwned:
		recruitLabel.text = "Rekrutieren"
		recruitLabel.visible = true
	else:
		recruitLabel.text = "Angriff vorbereiten" if canAttack else attackBlockedReason
		recruitLabel.visible = canAttack or attackBlockedReason != ""
	if attackButton != null:
		attackButton.visible = not isPlayerOwned and canAttack
	if attackControls != null:
		attackControls.visible = not isPlayerOwned and canAttack
	_updateCommandButtonStates()


func _onInfantryPressed() -> void:
	_requestRecruit(GameIds.INFANTRY_UNIT_ID)


func _onCavalryPressed() -> void:
	_requestRecruit(GameIds.CAVALRY_UNIT_ID)


func _onArtilleryPressed() -> void:
	_requestRecruit(GameIds.ARTILLERY_UNIT_ID)


func _onCreateArmyPressed() -> void:
	if eventBus == null or currentCountryId == GameIds.EMPTY_ID:
		return

	eventBus.requestCommand(CommandType.CREATE_ARMY, {
		"countryId": str(currentCountryId),
	})


func _onAttackPressed() -> void:
	if eventBus == null or currentCountryId == GameIds.EMPTY_ID or selectedAttackArmyId == GameIds.EMPTY_ID:
		return

	eventBus.requestCommand(CommandType.START_ATTACK, {
		"armyId": str(selectedAttackArmyId),
		"targetCountryId": str(currentCountryId),
		"attackingUnits": _attackDraftPayload(),
	})


func _requestRecruit(unitId: StringName) -> void:
	if eventBus == null or currentCountryId == GameIds.EMPTY_ID:
		return

	eventBus.requestCommand(CommandType.RECRUIT_UNITS, {
		"countryId": str(currentCountryId),
		"unitType": str(unitId),
		"amount": 1,
	})


func _updateCommandButtonStates() -> void:
	if not is_node_ready():
		return

	var recruitDisabled := eventBus == null or currentCountryId == GameIds.EMPTY_ID or not canRecruit
	infantryButton.disabled = recruitDisabled
	cavalryButton.disabled = recruitDisabled
	artilleryButton.disabled = recruitDisabled
	createArmyButton.disabled = eventBus == null or currentCountryId == GameIds.EMPTY_ID or not isPlayerOwned
	if attackButton != null:
		attackButton.disabled = eventBus == null or currentCountryId == GameIds.EMPTY_ID or not canAttack or _attackDraftUnitCount() <= 0
	_refreshAttackControls()


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_LARGE_PATH, 38.0, 14.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 24)
	UI_ASSET_THEME.applyLabel(ownerLabel, 18)
	UI_ASSET_THEME.applyLabel(goldLabel, 18)
	UI_ASSET_THEME.applyLabel(foodLabel, 18)
	UI_ASSET_THEME.applyLabel(defenseLabel, 18)
	UI_ASSET_THEME.applyLabel(armiesLabel, 18)
	UI_ASSET_THEME.applyLabel(recruitLabel, 18)
	recruitButtons.add_theme_constant_override("separation", 8)
	_applyRecruitButton(infantryButton, UI_ASSET_THEME.ICON_INFANTRY_PATH, "Inf", "Infanterie rekrutieren (+1)")
	_applyRecruitButton(cavalryButton, UI_ASSET_THEME.ICON_CAVALRY_PATH, "Kav", "Kavallerie rekrutieren (+1)")
	_applyRecruitButton(artilleryButton, UI_ASSET_THEME.ICON_ARTILLERY_PATH, "Art", "Artillerie rekrutieren (+1)")
	UI_ASSET_THEME.applyTextButton(createArmyButton, false, false)
	UI_ASSET_THEME.applyButtonIcon(createArmyButton, UI_ASSET_THEME.ICON_MANAGE_ARMY_PATH, "Neue Armee im ausgewählten Land", 28)
	createArmyButton.text = "Neue Armee"
	createArmyButton.custom_minimum_size = Vector2(0.0, 48.0)
	if attackButton != null:
		UI_ASSET_THEME.applyTextButton(attackButton, true, false)
		UI_ASSET_THEME.applyButtonIcon(attackButton, UI_ASSET_THEME.ICON_ATTACK_PATH, "Angriff starten", 32)
		attackButton.text = "Angriff starten"
		attackButton.custom_minimum_size = Vector2(0.0, 52.0)
	_applyAttackControlsTheme()


func _applyRecruitButton(button: Button, iconPath: String, shortName: String, tooltipText: String) -> void:
	UI_ASSET_THEME.applyTextButton(button, false, true)
	UI_ASSET_THEME.applyButtonIcon(button, iconPath, tooltipText, 28)
	button.text = "%s +1" % shortName
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(96.0, 46.0)


func _ensureAttackButton() -> Button:
	var column := titleLabel.get_parent() as VBoxContainer
	if column == null:
		return null

	var button := column.get_node_or_null("AttackButton") as Button
	if button == null:
		button = Button.new()
		button.name = "AttackButton"
		button.text = "Angriff starten"
		column.add_child(button)
	return button


func _ensureAttackControls() -> void:
	var column := titleLabel.get_parent() as VBoxContainer
	if column == null:
		return

	attackControls = column.get_node_or_null("AttackControls") as VBoxContainer
	if attackControls == null:
		attackControls = VBoxContainer.new()
		attackControls.name = "AttackControls"
		attackControls.add_theme_constant_override("separation", 6)
		column.add_child(attackControls)
	if attackButton != null:
		column.move_child(attackControls, attackButton.get_index())

	attackArmyDropdown = attackControls.get_node_or_null("AttackArmyDropdown") as OptionButton
	if attackArmyDropdown == null:
		attackArmyDropdown = OptionButton.new()
		attackArmyDropdown.name = "AttackArmyDropdown"
		attackArmyDropdown.custom_minimum_size = Vector2(0.0, 42.0)
		attackControls.add_child(attackArmyDropdown)
	if not attackArmyDropdown.item_selected.is_connected(_onAttackArmySelected):
		attackArmyDropdown.item_selected.connect(_onAttackArmySelected)

	var rowsBox := attackControls.get_node_or_null("AttackUnitRows") as VBoxContainer
	if rowsBox == null:
		rowsBox = VBoxContainer.new()
		rowsBox.name = "AttackUnitRows"
		rowsBox.add_theme_constant_override("separation", 4)
		attackControls.add_child(rowsBox)

	for unitId in [GameIds.INFANTRY_UNIT_ID, GameIds.CAVALRY_UNIT_ID, GameIds.ARTILLERY_UNIT_ID]:
		_ensureAttackUnitRow(rowsBox, unitId)
	attackControls.visible = false


func _ensureAttackUnitRow(parent: VBoxContainer, unitId: StringName) -> void:
	var rowNode := parent.get_node_or_null("%sAttackRow" % str(unitId)) as HBoxContainer
	if rowNode == null:
		rowNode = HBoxContainer.new()
		rowNode.name = "%sAttackRow" % str(unitId)
		rowNode.add_theme_constant_override("separation", 4)
		parent.add_child(rowNode)

	if rowNode.get_node_or_null("UnitIcon") == null:
		var icon := UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.iconForUnit(unitId), Vector2(24.0, 24.0))
		icon.name = "UnitIcon"
		rowNode.add_child(icon)

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
		minusButton.custom_minimum_size = Vector2(40.0, 34.0)
		rowNode.add_child(minusButton)
	minusButton.pressed.connect(Callable(self, "_changeAttackDraftUnit").bind(unitId, -1))

	var plusButton := rowNode.get_node_or_null("PlusButton") as Button
	if plusButton == null:
		plusButton = Button.new()
		plusButton.name = "PlusButton"
		plusButton.text = "+"
		plusButton.custom_minimum_size = Vector2(40.0, 34.0)
		rowNode.add_child(plusButton)
	plusButton.pressed.connect(Callable(self, "_changeAttackDraftUnit").bind(unitId, 1))

	attackUnitRows[unitId] = {
		"label": label,
		"minusButton": minusButton,
		"plusButton": plusButton,
	}


func _applyAttackControlsTheme() -> void:
	if attackArmyDropdown != null:
		attackArmyDropdown.add_theme_font_size_override("font_size", 16)
		attackArmyDropdown.add_theme_color_override("font_color", UI_ASSET_THEME.INK_COLOR)
	for unitId in attackUnitRows.keys():
		var row := attackUnitRows[unitId] as Dictionary
		var label := row.get("label", null) as Label
		var minusButton := row.get("minusButton", null) as Button
		var plusButton := row.get("plusButton", null) as Button
		if label != null:
			UI_ASSET_THEME.applyLabel(label, 16)
		if minusButton != null:
			UI_ASSET_THEME.applyTextButton(minusButton, false, true)
		if plusButton != null:
			UI_ASSET_THEME.applyTextButton(plusButton, false, true)


func _onAttackArmySelected(index: int) -> void:
	if attackArmyDropdown == null or index < 0 or index >= attackArmyDropdown.item_count:
		return

	var armyId := StringName(str(attackArmyDropdown.get_item_metadata(index)))
	_setSelectedAttackOption(armyId)
	if eventBus != null and armyId != GameIds.EMPTY_ID:
		eventBus.requestCommand(CommandType.SELECT_ARMY, {
			"armyId": str(armyId),
		})
	_refreshAttackControls()


func _changeAttackDraftUnit(unitId: StringName, amount: int) -> void:
	if not canAttack:
		return

	var currentAmount := int(attackDraftUnits.get(unitId, 0))
	var maximumAmount := int(attackSourceUnits.get(unitId, 0))
	attackDraftUnits[unitId] = clampi(currentAmount + amount, 0, maximumAmount)
	_updateCommandButtonStates()


func _setSelectedAttackOption(armyId: StringName) -> void:
	var option := _attackOptionById(armyId)
	if option.is_empty() and not attackOptions.is_empty():
		option = attackOptions[0]

	if option.is_empty():
		selectedAttackArmyId = GameIds.EMPTY_ID
		attackSourceUnits = _emptyUnitCounts()
		attackDraftUnits = _emptyUnitCounts()
		return

	selectedAttackArmyId = StringName(str(option.get("id", "")))
	attackSourceUnits = (option.get("units", {}) as Dictionary).duplicate(true)
	attackDraftUnits = (option.get("defaultAttackUnits", {}) as Dictionary).duplicate(true)


func _attackOptionById(armyId: StringName) -> Dictionary:
	for option in attackOptions:
		if StringName(str(option.get("id", ""))) == armyId:
			return option
	return {}


func _refreshAttackControls() -> void:
	if not is_node_ready() or attackControls == null or attackArmyDropdown == null:
		return

	attackControls.visible = not isPlayerOwned and canAttack
	attackArmyDropdown.clear()
	var selectedIndex := -1
	for index in range(attackOptions.size()):
		var option := attackOptions[index]
		var optionArmyId := StringName(str(option.get("id", "")))
		var labelText := "%s (%d)" % [
			str(option.get("sourceCountryName", optionArmyId)),
			int(option.get("unitCount", 0)),
		]
		attackArmyDropdown.add_item(labelText)
		attackArmyDropdown.set_item_metadata(index, optionArmyId)
		if optionArmyId == selectedAttackArmyId:
			selectedIndex = index
	if selectedIndex >= 0:
		attackArmyDropdown.select(selectedIndex)
	attackArmyDropdown.disabled = attackOptions.size() <= 1

	for unitId in attackUnitRows.keys():
		var row := attackUnitRows[unitId] as Dictionary
		var label := row.get("label", null) as Label
		var minusButton := row.get("minusButton", null) as Button
		var plusButton := row.get("plusButton", null) as Button
		var rowNode: Control = null
		if label != null:
			rowNode = label.get_parent() as Control
		var currentAmount := int(attackDraftUnits.get(unitId, 0))
		var maximumAmount := int(attackSourceUnits.get(unitId, 0))
		var unitName := str(unitNames.get(unitId, str(unitId).capitalize()))
		if rowNode != null:
			rowNode.visible = not isPlayerOwned and canAttack
		if label != null:
			label.text = "%s: %d/%d" % [unitName, currentAmount, maximumAmount]
		if minusButton != null:
			minusButton.disabled = not canAttack or currentAmount <= 0
		if plusButton != null:
			plusButton.disabled = not canAttack or currentAmount >= maximumAmount


func _readAttackOptions(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not (value is Array):
		return result

	for option in value:
		if option is Dictionary:
			result.append(option as Dictionary)
	return result


func _clearAttackData() -> void:
	attackOptions.clear()
	selectedAttackArmyId = GameIds.EMPTY_ID
	attackSourceUnits = _emptyUnitCounts()
	attackDraftUnits = _emptyUnitCounts()
	unitNames = {}


func _attackDraftPayload() -> Dictionary:
	return {
		str(GameIds.INFANTRY_UNIT_ID): int(attackDraftUnits.get(GameIds.INFANTRY_UNIT_ID, 0)),
		str(GameIds.CAVALRY_UNIT_ID): int(attackDraftUnits.get(GameIds.CAVALRY_UNIT_ID, 0)),
		str(GameIds.ARTILLERY_UNIT_ID): int(attackDraftUnits.get(GameIds.ARTILLERY_UNIT_ID, 0)),
	}


func _attackDraftUnitCount() -> int:
	var total := 0
	for unitId in [GameIds.INFANTRY_UNIT_ID, GameIds.CAVALRY_UNIT_ID, GameIds.ARTILLERY_UNIT_ID]:
		total += int(attackDraftUnits.get(unitId, 0))
	return total


func _emptyUnitCounts() -> Dictionary:
	return {
		GameIds.INFANTRY_UNIT_ID: 0,
		GameIds.CAVALRY_UNIT_ID: 0,
		GameIds.ARTILLERY_UNIT_ID: 0,
	}


func _ensureStatRows() -> void:
	_wrapLabelInRow("OwnerRow", ownerLabel, "")
	_wrapLabelInRow("GoldRow", goldLabel, UI_ASSET_THEME.ICON_GOLD_PATH)
	_wrapLabelInRow("FoodRow", foodLabel, UI_ASSET_THEME.ICON_FOOD_PATH)
	_wrapLabelInRow("DefenseRow", defenseLabel, UI_ASSET_THEME.ICON_DEFENSE_PATH)
	_wrapLabelInRow("ArmiesRow", armiesLabel, UI_ASSET_THEME.ICON_ARMY_PATH)


func _wrapLabelInRow(rowName: String, label: Label, iconPath: String) -> void:
	var column := titleLabel.get_parent() as VBoxContainer
	if column == null or label == null:
		return

	var row := column.get_node_or_null(rowName) as HBoxContainer
	if row == null:
		var labelIndex := label.get_index()
		var previousParent := label.get_parent()
		if previousParent != null:
			previousParent.remove_child(label)
		row = HBoxContainer.new()
		row.name = rowName
		row.add_theme_constant_override("separation", 10)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(row)
		column.move_child(row, labelIndex)
		if iconPath != "":
			row.add_child(UI_ASSET_THEME.makeIcon(iconPath, Vector2(28.0, 28.0)))
		row.add_child(label)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	statRows[rowName] = row


func _setCountryRowsVisible(isVisible: bool) -> void:
	for rowName in ["OwnerRow", "GoldRow", "FoodRow", "DefenseRow", "ArmiesRow"]:
		_setRowVisible(rowName, isVisible)


func _setRowVisible(rowName: String, isVisible: bool) -> void:
	var row := statRows.get(rowName, null) as Control
	if row != null:
		row.visible = isVisible


func _formatSigned(value: int) -> String:
	var prefix := "+" if value >= 0 else ""
	return "%s%s" % [prefix, _formatNumber(value)]


func _formatNumber(value: int) -> String:
	var absoluteText := str(absi(value))
	var result := ""
	while absoluteText.length() > 3:
		result = ".%s%s" % [absoluteText.substr(absoluteText.length() - 3, 3), result]
		absoluteText = absoluteText.substr(0, absoluteText.length() - 3)
	result = "%s%s" % [absoluteText, result]
	return "-%s" % result if value < 0 else result
