extends PanelContainer


const THREAT_COLORS := {
	"low": Color(0.86, 0.86, 0.86, 1.0),
	"caution": Color(1.0, 0.82, 0.32, 1.0),
	"high": Color(1.0, 0.52, 0.24, 1.0),
	"critical": Color(1.0, 0.28, 0.24, 1.0),
}

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
	var threatState := str(data.get("threatState", "low"))
	threatLabel.text = "Threat: %d (%s)" % [int(data.get("threat", 0)), threatState.capitalize()]
	threatLabel.modulate = THREAT_COLORS.get(threatState, THREAT_COLORS["low"])
	shortageLabel.text = "Food shortage" if bool(data.get("isFoodShortage", false)) else ""
	dateLabel.text = str(data.get("dateText", "Y1 M1 W1"))
