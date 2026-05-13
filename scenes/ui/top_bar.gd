extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

const THREAT_COLORS := {
	"low": Color(0.86, 0.86, 0.86, 1.0),
	"caution": Color(1.0, 0.82, 0.32, 1.0),
	"high": Color(1.0, 0.52, 0.24, 1.0),
	"critical": Color(1.0, 0.28, 0.24, 1.0),
	"coalition": Color(1.0, 0.08, 0.06, 1.0),
}

@onready var goldSection: HBoxContainer = $MarginContainer/HBoxContainer/GoldSection as HBoxContainer
@onready var foodSection: HBoxContainer = $MarginContainer/HBoxContainer/FoodSection as HBoxContainer
@onready var armySection: HBoxContainer = $MarginContainer/HBoxContainer/ArmySection as HBoxContainer
@onready var threatSection: HBoxContainer = $MarginContainer/HBoxContainer/ThreatSection as HBoxContainer
@onready var dateSection: HBoxContainer = $MarginContainer/HBoxContainer/DateSection as HBoxContainer
@onready var goldLabel: Label = $MarginContainer/HBoxContainer/GoldSection/GoldLabel as Label
@onready var foodLabel: Label = $MarginContainer/HBoxContainer/FoodSection/FoodLabel as Label
@onready var armyLabel: Label = $MarginContainer/HBoxContainer/ArmySection/ArmyLabel as Label
@onready var threatLabel: Label = $MarginContainer/HBoxContainer/ThreatSection/ThreatLabel as Label
@onready var shortageLabel: Label = $MarginContainer/HBoxContainer/ThreatSection/ShortageLabel as Label
@onready var dateLabel: Label = $MarginContainer/HBoxContainer/DateSection/DateLabel as Label


func _ready() -> void:
	_applyAssetTheme()


func setData(data: Dictionary) -> void:
	var goldValue := int(data.get("gold", 0))
	var goldPerMonth := int(data.get("goldPerMonth", 0))
	goldLabel.text = "%s (%s)" % [
		_formatNumber(goldValue),
		_formatMonthlyDelta(goldPerMonth),
	]
	goldLabel.tooltip_text = "Gold: %s\nMonatliches Einkommen: %s\nWird durch eigene Länder produziert und für Rekrutierung und Versorgung verbraucht." % [
		_formatNumber(goldValue),
		_formatMonthlyDelta(goldPerMonth),
	]

	var foodValue := int(data.get("food", 0))
	var foodPerMonth := int(data.get("foodPerMonth", 0))
	foodLabel.text = "%s (%s)" % [
		_formatNumber(foodValue),
		_formatMonthlyDelta(foodPerMonth),
	]
	var isFoodShortage := bool(data.get("isFoodShortage", false))
	var foodWarning := bool(data.get("foodWarning", false))
	foodLabel.modulate = Color(1.0, 0.28, 0.24, 1.0) if isFoodShortage else Color(1.0, 0.64, 0.22, 1.0) if foodWarning else Color.WHITE
	foodLabel.tooltip_text = "Nahrung: %s\nEinnahmen: +%s/Monat\nUnterhalt: -%s/Monat\nVersorgung: -%s Gold/Monat\nNegatives Monatsnetto verbraucht zuerst Vorrat. Danach wird fehlende Versorgung mit Gold bezahlt; Kampfkraft sinkt erst, wenn Gold nicht reicht." % [
		_formatNumber(foodValue),
		_formatNumber(int(data.get("foodIncomePerMonth", 0))),
		_formatNumber(int(data.get("foodUpkeepPerMonth", 0))),
		_formatNumber(int(data.get("emergencySupplyGoldPerMonth", 0))),
	]
	if isFoodShortage:
		foodLabel.tooltip_text += "\nUngedeckter Mangel: %s Nahrung/Monat. Kampfkraft: %d%%." % [
			_formatNumber(int(data.get("unfundedSupplyDeficit", 0))),
			int(round(float(data.get("combatPowerMultiplier", 1.0)) * 100.0)),
		]

	var armyStrength := int(data.get("armyStrength", 0))
	armyLabel.text = _formatNumber(armyStrength)
	armyLabel.tooltip_text = "Armee: %s\nGesamtzahl deiner Einheiten über alle Armeen." % _formatNumber(armyStrength)

	var threat := int(data.get("threat", 0))
	var threatState := str(data.get("threatState", "low"))
	threatLabel.text = "%d%%" % threat
	threatLabel.modulate = THREAT_COLORS.get(threatState, THREAT_COLORS["low"])
	threatLabel.tooltip_text = "Bedrohung: %d%%\nStufe: %s\nSteigt durch Zeit, Kriege, Eroberungen und große Armeen. Bei 100%% greifen alle Nachbarländer den Spieler gleichzeitig an." % [
		threat,
		_threatStateLabel(threatState),
	]

	shortageLabel.text = "Mangel" if isFoodShortage else "Versorgung" if foodWarning else ""
	shortageLabel.visible = isFoodShortage or foodWarning
	_setIconVisible("ShortageIcon", isFoodShortage or foodWarning)
	shortageLabel.tooltip_text = foodLabel.tooltip_text

	var dateText := str(data.get("dateText", "Y1 M1 W1"))
	dateLabel.text = "Datum  %s" % dateText
	dateLabel.tooltip_text = "Datum: %s\nZeit läuft kontinuierlich; Wirtschaft und Bedrohung werden monatlich abgerechnet." % dateText

	_syncIconTooltip("GoldIcon", goldLabel.tooltip_text)
	_syncIconTooltip("FoodIcon", foodLabel.tooltip_text)
	_syncIconTooltip("ArmyIcon", armyLabel.tooltip_text)
	_syncIconTooltip("ThreatIcon", threatLabel.tooltip_text)
	_syncIconTooltip("ShortageIcon", foodLabel.tooltip_text)


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyMainTopBarPanel(self)
	var container := goldLabel.get_parent() as HBoxContainer
	if container != null:
		container = container.get_parent() as HBoxContainer
	if container != null:
		container.add_theme_constant_override("separation", 0)
		container.alignment = BoxContainer.ALIGNMENT_CENTER
		var marginContainer := container.get_parent() as MarginContainer
		if marginContainer != null:
			marginContainer.add_theme_constant_override("margin_left", 0)
			marginContainer.add_theme_constant_override("margin_top", 10)
			marginContainer.add_theme_constant_override("margin_right", 0)
			marginContainer.add_theme_constant_override("margin_bottom", 10)
	_applySectionLayout(goldSection)
	_applySectionLayout(foodSection)
	_applySectionLayout(armySection)
	_applySectionLayout(threatSection)
	_applySectionLayout(dateSection)
	UI_ASSET_THEME.applyLabel(goldLabel, 18)
	UI_ASSET_THEME.applyLabel(foodLabel, 18)
	UI_ASSET_THEME.applyLabel(armyLabel, 18)
	UI_ASSET_THEME.applyLabel(threatLabel, 18)
	UI_ASSET_THEME.applyLabel(shortageLabel, 16)
	UI_ASSET_THEME.applyLabel(dateLabel, 16)
	_applySectionLabel(goldLabel)
	_applySectionLabel(foodLabel)
	_applySectionLabel(armyLabel)
	_applySectionLabel(threatLabel)
	_applySectionLabel(dateLabel, true)
	_applySectionLabel(shortageLabel)
	_ensureInlineIcon("GoldIcon", goldLabel, UI_ASSET_THEME.ICON_GOLD_PATH)
	_ensureInlineIcon("FoodIcon", foodLabel, UI_ASSET_THEME.ICON_FOOD_PATH)
	_ensureInlineIcon("ArmyIcon", armyLabel, UI_ASSET_THEME.ICON_ARMY_PATH)
	_ensureInlineIcon("ThreatIcon", threatLabel, UI_ASSET_THEME.ICON_THREAT_PATH)
	_ensureInlineIcon("ShortageIcon", shortageLabel, UI_ASSET_THEME.ICON_WARNING_PATH)
	_setIconVisible("ShortageIcon", false)


func _applySectionLayout(section: HBoxContainer) -> void:
	if section == null:
		return

	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.custom_minimum_size = Vector2(0.0, 0.0)
	section.add_theme_constant_override("separation", 0)
	section.alignment = BoxContainer.ALIGNMENT_CENTER


func _applySectionLabel(label: Label, _isCentered: bool = false) -> void:
	if label == null:
		return

	label.custom_minimum_size = Vector2(0.0, 36.0)
	label.size_flags_horizontal = Control.SIZE_FILL
	label.clip_text = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_theme_constant_override("line_spacing", 0)


func _ensureInlineIcon(iconName: String, beforeNode: Control, texturePath: String) -> void:
	var parent := beforeNode.get_parent() as Control
	if parent == null:
		return

	var icon := parent.get_node_or_null(iconName) as TextureRect
	if icon == null:
		icon = UI_ASSET_THEME.makeIcon(texturePath, Vector2(36.0, 36.0))
		icon.name = iconName
		parent.add_child(icon)
		parent.move_child(icon, beforeNode.get_index())
	else:
		icon.texture = UI_ASSET_THEME.loadTexture(texturePath)
		icon.custom_minimum_size = Vector2(36.0, 36.0)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.tooltip_text = beforeNode.tooltip_text


func _setIconVisible(iconName: String, visible: bool) -> void:
	var icon := find_child(iconName, true, false) as TextureRect
	if icon != null:
		icon.visible = visible


func _syncIconTooltip(iconName: String, tooltipText: String) -> void:
	var icon := find_child(iconName, true, false) as TextureRect
	if icon != null:
		icon.tooltip_text = tooltipText


func _threatStateLabel(state: String) -> String:
	match state:
		"coalition":
			return "Koalition (alle greifen an)"
		"critical":
			return "Kritisch"
		"high":
			return "Hoch"
		"caution":
			return "Aufmerksam"
		_:
			return "Niedrig"


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
