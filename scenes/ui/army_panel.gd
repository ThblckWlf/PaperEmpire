extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var statusLabel: Label = $MarginContainer/VBoxContainer/RunLabel as Label
@onready var locationLabel: Label = $MarginContainer/VBoxContainer/LocationLabel as Label
@onready var targetLabel: Label = $MarginContainer/VBoxContainer/TargetLabel as Label
@onready var unitsLabel: Label = $MarginContainer/VBoxContainer/UnitsLabel as Label

var statusIcon: TextureRect


func _ready() -> void:
	_applyAssetTheme()


func setData(data: Dictionary) -> void:
	if not bool(data.get("hasArmy", false)):
		titleLabel.text = str(data.get("name", "No army selected"))
		statusLabel.text = "Status: -"
		locationLabel.text = "Location: -"
		targetLabel.text = "Target: -"
		unitsLabel.text = "Units: -"
		_setStatusIcon(UI_ASSET_THEME.ICON_ARMY_PATH)
		return

	titleLabel.text = str(data.get("name", "Army"))
	var statusText := str(data.get("status", "Unknown"))
	statusLabel.text = "Status: %s" % statusText
	locationLabel.text = "Location: %s" % str(data.get("location", "-"))
	targetLabel.text = "Target: %s" % str(data.get("target", "-"))
	unitsLabel.text = "Units:\n%s" % "\n".join(data.get("unitRows", []))
	_setStatusIcon(UI_ASSET_THEME.iconForArmyStatus(statusText))


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_LARGE_PATH, 38.0, 12.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 22)
	UI_ASSET_THEME.applyLabel(statusLabel, 17)
	UI_ASSET_THEME.applyLabel(locationLabel, 17)
	UI_ASSET_THEME.applyLabel(targetLabel, 17)
	UI_ASSET_THEME.applyLabel(unitsLabel, 17)
	statusIcon = _ensureStatusIcon()
	_setStatusIcon(UI_ASSET_THEME.ICON_ARMY_PATH)


func _ensureStatusIcon() -> TextureRect:
	var column := titleLabel.get_parent() as VBoxContainer
	if column == null:
		return null

	var icon := column.get_node_or_null("ArmyStatusIcon") as TextureRect
	if icon == null:
		icon = UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.ICON_ARMY_PATH, Vector2(44.0, 44.0))
		icon.name = "ArmyStatusIcon"
		column.add_child(icon)
		column.move_child(icon, titleLabel.get_index())
	return icon


func _setStatusIcon(texturePath: String) -> void:
	if statusIcon == null:
		statusIcon = _ensureStatusIcon()
	if statusIcon != null:
		statusIcon.texture = UI_ASSET_THEME.loadTexture(texturePath)
