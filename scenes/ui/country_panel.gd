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
var statRows: Dictionary = {}


func _ready() -> void:
	infantryButton.pressed.connect(_onInfantryPressed)
	cavalryButton.pressed.connect(_onCavalryPressed)
	artilleryButton.pressed.connect(_onArtilleryPressed)
	createArmyButton.pressed.connect(_onCreateArmyPressed)
	attackButton = _ensureAttackButton()
	if attackButton != null:
		attackButton.pressed.connect(_onAttackPressed)
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
		titleLabel.text = "Land auswählen"
		ownerLabel.text = "Klicke auf ein Land auf der Karte."
		_setCountryRowsVisible(false)
		_setRowVisible("OwnerRow", true)
		recruitLabel.visible = false
		recruitButtons.visible = false
		createArmyButton.visible = false
		if attackButton != null:
			attackButton.visible = false
		_updateCommandButtonStates()
		return

	currentCountryId = StringName(str(data.get("id", "")))
	currentSelectedArmyId = StringName(str(data.get("selectedArmyId", "")))
	isPlayerOwned = bool(data.get("isPlayerOwned", false))
	canRecruit = bool(data.get("canRecruit", false))
	canAttack = bool(data.get("canAttack", false))
	attackBlockedReason = str(data.get("attackBlockedReason", ""))

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
		recruitLabel.text = attackBlockedReason
		recruitLabel.visible = attackBlockedReason != ""
	if attackButton != null:
		attackButton.visible = not isPlayerOwned and canAttack
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
	if eventBus == null or currentCountryId == GameIds.EMPTY_ID or currentSelectedArmyId == GameIds.EMPTY_ID:
		return

	eventBus.requestCommand(CommandType.START_ATTACK, {
		"armyId": str(currentSelectedArmyId),
		"targetCountryId": str(currentCountryId),
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
		attackButton.disabled = eventBus == null or currentCountryId == GameIds.EMPTY_ID or not canAttack


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_LARGE_PATH, 38.0, 10.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 20)
	UI_ASSET_THEME.applyLabel(ownerLabel, 16)
	UI_ASSET_THEME.applyLabel(goldLabel, 16)
	UI_ASSET_THEME.applyLabel(foodLabel, 16)
	UI_ASSET_THEME.applyLabel(defenseLabel, 16)
	UI_ASSET_THEME.applyLabel(armiesLabel, 16)
	UI_ASSET_THEME.applyLabel(recruitLabel, 16)
	_applyRecruitButton(infantryButton, UI_ASSET_THEME.ICON_INFANTRY_PATH, "Infanterie rekrutieren")
	_applyRecruitButton(cavalryButton, UI_ASSET_THEME.ICON_CAVALRY_PATH, "Kavallerie rekrutieren")
	_applyRecruitButton(artilleryButton, UI_ASSET_THEME.ICON_ARTILLERY_PATH, "Artillerie rekrutieren")
	UI_ASSET_THEME.applyTextButton(createArmyButton, false, true)
	UI_ASSET_THEME.applyButtonIcon(createArmyButton, UI_ASSET_THEME.ICON_MANAGE_ARMY_PATH, "Neue Armee im ausgewählten Land", 24)
	createArmyButton.text = "Neue Armee"
	createArmyButton.custom_minimum_size = Vector2(0.0, 38.0)
	if attackButton != null:
		UI_ASSET_THEME.applyTextButton(attackButton, true, false)
		UI_ASSET_THEME.applyButtonIcon(attackButton, UI_ASSET_THEME.ICON_ATTACK_PATH, "Angriff starten", 28)
		attackButton.text = "Angriff starten"
		attackButton.custom_minimum_size = Vector2(0.0, 42.0)


func _applyRecruitButton(button: Button, iconPath: String, tooltipText: String) -> void:
	UI_ASSET_THEME.applyTextButton(button, false, true)
	UI_ASSET_THEME.applyButtonIcon(button, iconPath, tooltipText, 24)
	button.text = "+1"
	button.custom_minimum_size = Vector2(74.0, 36.0)


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
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(row)
		column.move_child(row, labelIndex)
		if iconPath != "":
			row.add_child(UI_ASSET_THEME.makeIcon(iconPath, Vector2(22.0, 22.0)))
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
