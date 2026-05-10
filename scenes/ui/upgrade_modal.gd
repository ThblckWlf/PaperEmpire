extends PanelContainer


@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var choiceButtons: Array[Button] = [
	$MarginContainer/VBoxContainer/ChoiceButton1 as Button,
	$MarginContainer/VBoxContainer/ChoiceButton2 as Button,
	$MarginContainer/VBoxContainer/ChoiceButton3 as Button,
]

var eventBus: EventBus
var choiceIds: Array[StringName] = []


func _ready() -> void:
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
			continue

		var upgrade := choices[index] as Dictionary
		choiceIds.append(StringName(str(upgrade.get("id", ""))))
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
