extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

const THREAT_COLORS := {
	"low": Color(0.86, 0.86, 0.86, 1.0),
	"caution": Color(1.0, 0.82, 0.32, 1.0),
	"high": Color(1.0, 0.52, 0.24, 1.0),
	"critical": Color(1.0, 0.28, 0.24, 1.0),
	"coalition": Color(1.0, 0.08, 0.06, 1.0),
}
const TOP_BAR_FONT_SIZE: int = 17
const TOP_BAR_ICON_SIZE: Vector2 = Vector2(28.0, 28.0)
const TOP_BAR_LABEL_HEIGHT: float = 32.0
const TOP_BAR_VERTICAL_MARGIN: int = 6

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
	goldLabel.text = "Gold: %s (%s)" % [
		_formatNumber(int(data.get("gold", 0))),
		_formatMonthlyDelta(int(data.get("goldPerMonth", 0))),
	]
	foodLabel.text = "Nahrung: %s (%s)" % [
		_formatNumber(int(data.get("food", 0))),
		_formatMonthlyDelta(int(data.get("foodPerMonth", 0))),
	]
	var isFoodShortage := bool(data.get("isFoodShortage", false))
	var foodWarning := bool(data.get("foodWarning", false))
	foodLabel.modulate = Color(1.0, 0.28, 0.24, 1.0) if isFoodShortage else Color(1.0, 0.64, 0.22, 1.0) if foodWarning else Color.WHITE
	foodLabel.tooltip_text = "Einnahmen: +%s/Monat\nUnterhalt: -%s/Monat\nVersorgung: -%s Gold/Monat\nNegatives Monatsnetto verbraucht zuerst Vorrat. Danach wird fehlende Versorgung mit Gold bezahlt; Kampfkraft sinkt erst, wenn Gold nicht reicht." % [
		_formatNumber(int(data.get("foodIncomePerMonth", 0))),
		_formatNumber(int(data.get("foodUpkeepPerMonth", 0))),
		_formatNumber(int(data.get("emergencySupplyGoldPerMonth", 0))),
	]
	if isFoodShortage:
		foodLabel.tooltip_text += "\nUngedeckter Mangel: %s Nahrung/Monat. Kampfkraft: %d%%." % [
			_formatNumber(int(data.get("unfundedSupplyDeficit", 0))),
			int(round(float(data.get("combatPowerMultiplier", 1.0)) * 100.0)),
		]
	armyLabel.text = "Armee: %s" % _formatNumber(int(data.get("armyStrength", 0)))
	var threatState := str(data.get("threatState", "low"))
	threatLabel.text = "Bedrohung: %d%%" % int(data.get("threat", 0))
	threatLabel.modulate = THREAT_COLORS.get(threatState, THREAT_COLORS["low"])
	shortageLabel.text = ""
	shortageLabel.visible = false
	_setIconVisible("ShortageIcon", isFoodShortage or foodWarning)
	var shortageIcon := find_child("ShortageIcon", true, false) as TextureRect
	if shortageIcon != null:
		shortageIcon.tooltip_text = foodLabel.tooltip_text
	dateLabel.text = "Datum: %s" % str(data.get("dateText", "Y1 M1 W1"))


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
			marginContainer.add_theme_constant_override("margin_left", 64)
			marginContainer.add_theme_constant_override("margin_top", TOP_BAR_VERTICAL_MARGIN)
			marginContainer.add_theme_constant_override("margin_right", 64)
			marginContainer.add_theme_constant_override("margin_bottom", TOP_BAR_VERTICAL_MARGIN)
	_applySectionLayout(goldSection)
	_applySectionLayout(foodSection)
	_applySectionLayout(armySection)
	_applySectionLayout(threatSection)
	_applySectionLayout(dateSection)
	goldLabel.tooltip_text = "Wird monatlich durch eigene Länder produziert."
	foodLabel.tooltip_text = "Wird monatlich produziert und von Armeen verbraucht. Negatives Monatsnetto verbraucht Vorrat; danach zahlt Gold die Versorgung."
	armyLabel.tooltip_text = "Gesamtzahl deiner Einheiten."
	threatLabel.tooltip_text = "Steigt durch Zeit, Kriege, Eroberungen und große Armeen. Bei 100% greifen alle Nachbarn an."
	UI_ASSET_THEME.applyLabel(goldLabel, TOP_BAR_FONT_SIZE)
	UI_ASSET_THEME.applyLabel(foodLabel, TOP_BAR_FONT_SIZE)
	UI_ASSET_THEME.applyLabel(armyLabel, TOP_BAR_FONT_SIZE)
	UI_ASSET_THEME.applyLabel(threatLabel, TOP_BAR_FONT_SIZE)
	UI_ASSET_THEME.applyLabel(shortageLabel, TOP_BAR_FONT_SIZE)
	UI_ASSET_THEME.applyLabel(dateLabel, TOP_BAR_FONT_SIZE)
	_applySectionLabel(goldLabel)
	_applySectionLabel(foodLabel)
	_applySectionLabel(armyLabel)
	_applySectionLabel(threatLabel)
	_applySectionLabel(dateLabel, true)
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
	section.custom_minimum_size = Vector2.ZERO
	section.add_theme_constant_override("separation", 6)
	section.alignment = BoxContainer.ALIGNMENT_CENTER


func _applySectionLabel(label: Label, isCentered: bool = false) -> void:
	if label == null:
		return

	label.custom_minimum_size = Vector2(0.0, TOP_BAR_LABEL_HEIGHT)
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if isCentered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("line_spacing", 0)


func _ensureInlineIcon(iconName: String, beforeNode: Control, texturePath: String) -> void:
	var parent := beforeNode.get_parent() as Control
	if parent == null:
		return

	var icon := parent.get_node_or_null(iconName) as TextureRect
	if icon == null:
		icon = UI_ASSET_THEME.makeIcon(texturePath, TOP_BAR_ICON_SIZE)
		icon.name = iconName
		parent.add_child(icon)
		parent.move_child(icon, beforeNode.get_index())
	else:
		icon.texture = UI_ASSET_THEME.loadTexture(texturePath)
		icon.custom_minimum_size = TOP_BAR_ICON_SIZE
	icon.tooltip_text = beforeNode.tooltip_text


func _setIconVisible(iconName: String, visible: bool) -> void:
	var icon := find_child(iconName, true, false) as TextureRect
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
