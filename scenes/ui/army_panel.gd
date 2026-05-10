extends PanelContainer


@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var statusLabel: Label = $MarginContainer/VBoxContainer/RunLabel as Label
@onready var locationLabel: Label = $MarginContainer/VBoxContainer/LocationLabel as Label
@onready var targetLabel: Label = $MarginContainer/VBoxContainer/TargetLabel as Label
@onready var unitsLabel: Label = $MarginContainer/VBoxContainer/UnitsLabel as Label


func setData(data: Dictionary) -> void:
	if not bool(data.get("hasArmy", false)):
		titleLabel.text = str(data.get("name", "No army selected"))
		statusLabel.text = "Status: -"
		locationLabel.text = "Location: -"
		targetLabel.text = "Target: -"
		unitsLabel.text = "Units: -"
		return

	titleLabel.text = str(data.get("name", "Army"))
	statusLabel.text = "Status: %s" % str(data.get("status", "Unknown"))
	locationLabel.text = "Location: %s" % str(data.get("location", "-"))
	targetLabel.text = "Target: %s" % str(data.get("target", "-"))
	unitsLabel.text = "Units:\n%s" % "\n".join(data.get("unitRows", []))
