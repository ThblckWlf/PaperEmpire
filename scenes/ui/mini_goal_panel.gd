extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var goalButtons: Array[Button] = [
	$MarginContainer/VBoxContainer/GoalButton1 as Button,
	$MarginContainer/VBoxContainer/GoalButton2 as Button,
	$MarginContainer/VBoxContainer/GoalButton3 as Button,
	$MarginContainer/VBoxContainer/GoalButton4 as Button,
	$MarginContainer/VBoxContainer/GoalButton5 as Button,
	$MarginContainer/VBoxContainer/GoalButton6 as Button,
]

var eventBus: EventBus
var goalIds: Array[StringName] = []


func _ready() -> void:
	_applyAssetTheme()
	for index in range(goalButtons.size()):
		goalButtons[index].pressed.connect(_onGoalPressed.bind(index))


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus
	_updateButtonsEnabled()


func setData(data: Dictionary) -> void:
	goalIds.clear()
	var rows: Array = data.get("goalRows", [])
	for index in range(goalButtons.size()):
		var button := goalButtons[index]
		if index >= 3 or index >= rows.size() or not (rows[index] is Dictionary):
			button.text = "-"
			button.disabled = true
			button.icon = null
			button.visible = false
			continue

		button.visible = true
		var row := rows[index] as Dictionary
		goalIds.append(StringName(str(row.get("id", ""))))
		var suffix := ""
		if bool(row.get("isRewardClaimed", false)):
			suffix = " erledigt"
		elif bool(row.get("canClaim", false)):
			suffix = " abholen"
		button.text = "%s: %s%s" % [
			str(row.get("shortText", row.get("name", "Ziel"))),
			str(row.get("progressText", "0/1")),
			suffix,
		]
		button.tooltip_text = str(row.get("description", ""))
		button.disabled = not bool(row.get("canClaim", false)) or eventBus == null
		_applyGoalButtonIcon(button, row)


func _onGoalPressed(index: int) -> void:
	if eventBus == null or index < 0 or index >= goalIds.size():
		return

	eventBus.requestCommand(CommandType.CLAIM_MINI_GOAL_REWARD, {
		"goalId": str(goalIds[index]),
	})


func _updateButtonsEnabled() -> void:
	if not is_node_ready():
		return

	for button in goalButtons:
		button.disabled = true


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_SMALL_PATH, 32.0, 8.0)
	for button in goalButtons:
		UI_ASSET_THEME.applyListButton(button)
		button.custom_minimum_size = Vector2(0.0, 32.0)


func _applyGoalButtonIcon(button: Button, row: Dictionary) -> void:
	if bool(row.get("isRewardClaimed", false)):
		UI_ASSET_THEME.applyButtonIcon(button, UI_ASSET_THEME.ICON_CROWN_PATH, "Reward claimed", 22)
	elif bool(row.get("canClaim", false)):
		UI_ASSET_THEME.applyButtonIcon(button, UI_ASSET_THEME.ICON_CONFIRM_PATH, "Claim reward", 22)
	else:
		UI_ASSET_THEME.applyButtonIcon(button, _iconForGoalType(str(row.get("goalType", ""))), "Mini goal progress", 22)


func _iconForGoalType(goalType: String) -> String:
	match goalType:
		"reachGold":
			return UI_ASSET_THEME.ICON_GOLD_PATH
		"reachArmyPower":
			return UI_ASSET_THEME.ICON_ARMY_PATH
		"holdThreatenedCountryMonths", "conquerWithThreatBelow":
			return UI_ASSET_THEME.ICON_WARNING_PATH
		"conquerCountries", "defeatStrongerCountry":
			return UI_ASSET_THEME.ICON_ATTACK_PATH
		_:
			return UI_ASSET_THEME.ICON_HELP_PATH
