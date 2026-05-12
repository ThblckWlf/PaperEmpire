extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

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


func _ready() -> void:
	_applyAssetTheme()


func setData(data: Dictionary) -> void:
	goldLabel.text = "Gold: %s (%s)" % [
		_formatNumber(int(data.get("gold", 0))),
		_formatMonthlyDelta(int(data.get("goldPerMonth", 0))),
	]
	foodLabel.text = "Nahrung: %s (%s)" % [
		_formatNumber(int(data.get("food", 0))),
		_formatMonthlyDelta(int(data.get("foodPerMonth", 0))),
	]
	armyLabel.text = "Armee: %s" % _formatNumber(int(data.get("armyStrength", 0)))
	var threatState := str(data.get("threatState", "low"))
	threatLabel.text = "Bedrohung: %d%%" % int(data.get("threat", 0))
	threatLabel.modulate = THREAT_COLORS.get(threatState, THREAT_COLORS["low"])
	shortageLabel.text = ""
	shortageLabel.visible = false
	_setIconVisible("ShortageIcon", false)
	dateLabel.text = str(data.get("dateText", "Y1 M1 W1"))


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyTopBarPanel(self)
	var container := goldLabel.get_parent() as HBoxContainer
	if container != null:
		container.add_theme_constant_override("separation", 8)
	goldLabel.tooltip_text = "Wird monatlich durch eigene Länder produziert."
	foodLabel.tooltip_text = "Wird monatlich produziert und von Armeen verbraucht."
	armyLabel.tooltip_text = "Gesamtzahl deiner Einheiten."
	threatLabel.tooltip_text = "Steigt durch Zeit, Kriege, Eroberungen und große Armeen."
	UI_ASSET_THEME.applyLabel(goldLabel, 16)
	UI_ASSET_THEME.applyLabel(foodLabel, 16)
	UI_ASSET_THEME.applyLabel(armyLabel, 16)
	UI_ASSET_THEME.applyLabel(threatLabel, 16)
	UI_ASSET_THEME.applyLabel(shortageLabel, 16)
	UI_ASSET_THEME.applyLabel(dateLabel, 14)
	_ensureInlineIcon("GoldIcon", goldLabel, UI_ASSET_THEME.ICON_GOLD_PATH)
	_ensureInlineIcon("FoodIcon", foodLabel, UI_ASSET_THEME.ICON_FOOD_PATH)
	_ensureInlineIcon("ArmyIcon", armyLabel, UI_ASSET_THEME.ICON_ARMY_PATH)
	_ensureInlineIcon("ThreatIcon", threatLabel, UI_ASSET_THEME.ICON_THREAT_PATH)
	_ensureInlineIcon("ShortageIcon", shortageLabel, UI_ASSET_THEME.ICON_WARNING_PATH)
	_setIconVisible("ShortageIcon", false)


func _ensureInlineIcon(iconName: String, beforeNode: Control, texturePath: String) -> void:
	var parent := beforeNode.get_parent() as Control
	if parent == null:
		return

	var icon := parent.get_node_or_null(iconName) as TextureRect
	if icon == null:
		icon = UI_ASSET_THEME.makeIcon(texturePath, Vector2(28.0, 28.0))
		icon.name = iconName
		parent.add_child(icon)
		parent.move_child(icon, beforeNode.get_index())
	else:
		icon.texture = UI_ASSET_THEME.loadTexture(texturePath)
	icon.tooltip_text = beforeNode.tooltip_text


func _setIconVisible(iconName: String, visible: bool) -> void:
	var icon := get_node_or_null("MarginContainer/HBoxContainer/%s" % iconName) as TextureRect
	if icon != null:
		icon.visible = visible


func _formatMonthlyDelta(value: int) -> String:
	var prefix := "+" if value >= 0 else ""
	return "%s%s/Monat" % [prefix, _formatNumber(value)]


func _formatNumber(value: int) -> String:
	var absoluteText := str(absi(value))
	var result := ""
	while absoluteText.length() > 3:
		result = ".%s%s" % [absoluteText.substr(absoluteText.length() - 3, 3), result]
		absoluteText = absoluteText.substr(0, absoluteText.length() - 3)
	result = "%s%s" % [absoluteText, result]
	return "-%s" % result if value < 0 else result
