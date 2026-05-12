extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var choiceButtons: Array[Button] = [
	$MarginContainer/VBoxContainer/ChoiceButton1 as Button,
	$MarginContainer/VBoxContainer/ChoiceButton2 as Button,
	$MarginContainer/VBoxContainer/ChoiceButton3 as Button,
]

var eventBus: EventBus
var choiceIds: Array[StringName] = []


func _ready() -> void:
	_applyAssetTheme()
	for index in range(choiceButtons.size()):
		choiceButtons[index].pressed.connect(_onChoicePressed.bind(index))


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus


func setData(data: Dictionary) -> void:
	titleLabel.text = "Choose Upgrade"
	choiceIds.clear()
	var choices: Array = data.get("choices", [])
	for index in range(choiceButtons.size()):
		var button := choiceButtons[index]
		if index >= choices.size() or not (choices[index] is Dictionary):
			button.text = "-"
			button.disabled = true
			button.icon = null
			continue

		var upgrade := choices[index] as Dictionary
		choiceIds.append(StringName(str(upgrade.get("id", ""))))
		UI_ASSET_THEME.applyUpgradeButton(button, str(upgrade.get("rarity", "common")))
		UI_ASSET_THEME.applyButtonIcon(button, UI_ASSET_THEME.iconForUpgradeEffect(str(upgrade.get("effectType", ""))), str(upgrade.get("rarity", "common")).capitalize(), 54)
		button.text = "%s\n%s" % [
			str(upgrade.get("name", "Upgrade")),
			str(upgrade.get("description", "")),
		]
		button.disabled = false


func _onChoicePressed(index: int) -> void:
	if eventBus == null or index < 0 or index >= choiceIds.size():
		return

	eventBus.requestCommand(CommandType.CHOOSE_UPGRADE, {
		"upgradeId": str(choiceIds[index]),
	})


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_MODAL_PATH, 42.0, 14.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 24)
	for button in choiceButtons:
		UI_ASSET_THEME.applyUpgradeButton(button, "common")
		button.custom_minimum_size = Vector2(0.0, 96.0)
