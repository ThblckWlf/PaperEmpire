extends PanelContainer


@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var ownerLabel: Label = $MarginContainer/VBoxContainer/OwnerLabel as Label
@onready var goldLabel: Label = $MarginContainer/VBoxContainer/GoldLabel as Label
@onready var foodLabel: Label = $MarginContainer/VBoxContainer/FoodLabel as Label
@onready var defenseLabel: Label = $MarginContainer/VBoxContainer/DefenseLabel as Label
@onready var armiesLabel: Label = $MarginContainer/VBoxContainer/ArmiesLabel as Label
@onready var recruitLabel: Label = $MarginContainer/VBoxContainer/RecruitLabel as Label
@onready var infantryButton: Button = $MarginContainer/VBoxContainer/RecruitButtons/InfantryButton as Button
@onready var cavalryButton: Button = $MarginContainer/VBoxContainer/RecruitButtons/CavalryButton as Button
@onready var artilleryButton: Button = $MarginContainer/VBoxContainer/RecruitButtons/ArtilleryButton as Button
@onready var createArmyButton: Button = $MarginContainer/VBoxContainer/CreateArmyButton as Button

var eventBus: EventBus
var currentCountryId: StringName = GameIds.EMPTY_ID
var isPlayerOwned: bool = false
var canRecruit: bool = false


func _ready() -> void:
	infantryButton.pressed.connect(_onInfantryPressed)
	cavalryButton.pressed.connect(_onCavalryPressed)
	artilleryButton.pressed.connect(_onArtilleryPressed)
	createArmyButton.pressed.connect(_onCreateArmyPressed)
	_updateCommandButtonStates()


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus
	_updateCommandButtonStates()

func setData(data: Dictionary) -> void:
	if not bool(data.get("hasCountry", false)):
		currentCountryId = GameIds.EMPTY_ID
		isPlayerOwned = false
		canRecruit = false
		titleLabel.text = str(data.get("name", "No country selected"))
		ownerLabel.text = "Owner: -"
		goldLabel.text = "Gold/month: -"
		foodLabel.text = "Food/month: -"
		defenseLabel.text = "Defense: -"
		armiesLabel.text = "Armies: -"
		recruitLabel.text = "Recruitment: -"
		_updateCommandButtonStates()
		return

	currentCountryId = StringName(str(data.get("id", "")))
	isPlayerOwned = bool(data.get("isPlayerOwned", false))
	canRecruit = bool(data.get("canRecruit", false))
	titleLabel.text = str(data.get("name", "Country"))
	ownerLabel.text = "Owner: %s" % str(data.get("ownerId", ""))
	goldLabel.text = "Gold/month: %d" % int(data.get("goldPerMonth", 0))
	foodLabel.text = "Food/month: %d" % int(data.get("foodPerMonth", 0))
	defenseLabel.text = "Defense: %d" % int(data.get("defense", 0))
	armiesLabel.text = "Armies: %d / Units: %d" % [
		int(data.get("stationedArmyCount", 0)),
		int(data.get("stationedUnitCount", 0)),
	]
	recruitLabel.text = "Recruitment: available" if canRecruit else "Recruitment: unavailable"
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
