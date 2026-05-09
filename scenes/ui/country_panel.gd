extends PanelContainer


@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var ownerLabel: Label = $MarginContainer/VBoxContainer/OwnerLabel as Label
@onready var goldLabel: Label = $MarginContainer/VBoxContainer/GoldLabel as Label
@onready var foodLabel: Label = $MarginContainer/VBoxContainer/FoodLabel as Label
@onready var defenseLabel: Label = $MarginContainer/VBoxContainer/DefenseLabel as Label
@onready var armiesLabel: Label = $MarginContainer/VBoxContainer/ArmiesLabel as Label


func setData(data: Dictionary) -> void:
	if not bool(data.get("hasCountry", false)):
		titleLabel.text = str(data.get("name", "No country selected"))
		ownerLabel.text = "Owner: -"
		goldLabel.text = "Gold/month: -"
		foodLabel.text = "Food/month: -"
		defenseLabel.text = "Defense: -"
		armiesLabel.text = "Armies: -"
		return

	titleLabel.text = str(data.get("name", "Country"))
	ownerLabel.text = "Owner: %s" % str(data.get("ownerId", ""))
	goldLabel.text = "Gold/month: %d" % int(data.get("goldPerMonth", 0))
	foodLabel.text = "Food/month: %d" % int(data.get("foodPerMonth", 0))
	defenseLabel.text = "Defense: %d" % int(data.get("defense", 0))
	armiesLabel.text = "Armies: %d / Units: %d" % [
		int(data.get("stationedArmyCount", 0)),
		int(data.get("stationedUnitCount", 0)),
	]
