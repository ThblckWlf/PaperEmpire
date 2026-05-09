extends PanelContainer


@onready var goldLabel: Label = $MarginContainer/HBoxContainer/GoldLabel as Label
@onready var foodLabel: Label = $MarginContainer/HBoxContainer/FoodLabel as Label
@onready var armyLabel: Label = $MarginContainer/HBoxContainer/ArmyLabel as Label
@onready var threatLabel: Label = $MarginContainer/HBoxContainer/ThreatLabel as Label
@onready var shortageLabel: Label = $MarginContainer/HBoxContainer/ShortageLabel as Label
@onready var dateLabel: Label = $MarginContainer/HBoxContainer/DateLabel as Label


func setData(data: Dictionary) -> void:
	goldLabel.text = "Gold: %d" % int(data.get("gold", 0))
	foodLabel.text = "Food: %d" % int(data.get("food", 0))
	armyLabel.text = "Army: %d" % int(data.get("armyStrength", 0))
	threatLabel.text = "Threat: %d" % int(data.get("threat", 0))
	shortageLabel.text = "Food shortage" if bool(data.get("isFoodShortage", false)) else ""
	dateLabel.text = str(data.get("dateText", "Y1 M1 W1"))
