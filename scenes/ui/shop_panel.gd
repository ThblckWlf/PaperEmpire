extends PanelContainer


signal purchaseRequested(upgradeId: StringName)
signal closeRequested

const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

const INK_COLOR: Color = Color("#211d17")
const DISABLED_INK_COLOR: Color = Color("#655d4f")
const PARCHMENT_COLOR: Color = Color("#d8bd7c")
const BUTTON_COLOR: Color = Color("#c99e55")
const BUTTON_HOVER_COLOR: Color = Color("#d8af64")
const BUTTON_PRESSED_COLOR: Color = Color("#ae8441")

var crownLabel: Label
var rowContainer: VBoxContainer
var closeButton: Button
var rowButtons: Array[Button] = []
var rowIds: Array[StringName] = []


func _ready() -> void:
	_buildPanel()
	_applyReadableTheme()


func setData(data: Dictionary) -> void:
	crownLabel.text = "Crowns: %d" % int(data.get("crowns", 0))
	rowIds.clear()

	var rows: Array = data.get("rows", [])
	_ensureRowButtons(rows.size())
	for index in range(rowButtons.size()):
		var button := rowButtons[index]
		if index >= rows.size() or not (rows[index] is Dictionary):
			button.visible = false
			button.disabled = true
			button.text = "-"
			continue

		var row := rows[index] as Dictionary
		rowIds.append(StringName(str(row.get("id", ""))))
		var level := int(row.get("level", 0))
		var maxLevel := int(row.get("maxLevel", 1))
		var cost := int(row.get("cost", 0))
		var suffix := "Cost: %d" % cost
		if level >= maxLevel:
			suffix = "Max"
		button.text = "%s  %d/%d  %s\n%s" % [
			str(row.get("name", "Upgrade")),
			level,
			maxLevel,
			suffix,
			str(row.get("description", "")),
		]
		UI_ASSET_THEME.applyButtonIcon(button, UI_ASSET_THEME.iconForUpgradeEffect(str(row.get("effectType", ""))), str(row.get("name", "Upgrade")), 34)
		button.visible = true
		button.disabled = not bool(row.get("canPurchase", false))


func _buildPanel() -> void:
	custom_minimum_size = Vector2(520.0, 460.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var mainColumn := VBoxContainer.new()
	mainColumn.add_theme_constant_override("separation", 10)
	margin.add_child(mainColumn)

	var header := HBoxContainer.new()
	mainColumn.add_child(header)

	var titleLabel := Label.new()
	titleLabel.text = "Shop"
	titleLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titleLabel)

	closeButton = Button.new()
	closeButton.text = "Back"
	closeButton.custom_minimum_size = Vector2(96.0, 40.0)
	closeButton.clip_text = true
	closeButton.pressed.connect(_onClosePressed)
	header.add_child(closeButton)

	var crownRow := HBoxContainer.new()
	crownRow.add_theme_constant_override("separation", 8)
	mainColumn.add_child(crownRow)

	var crownIcon := UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.ICON_CROWN_PATH, Vector2(28.0, 28.0))
	crownRow.add_child(crownIcon)

	crownLabel = Label.new()
	crownLabel.text = "Crowns: 0"
	crownRow.add_child(crownLabel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mainColumn.add_child(scroll)

	rowContainer = VBoxContainer.new()
	rowContainer.add_theme_constant_override("separation", 8)
	rowContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rowContainer)


func _ensureRowButtons(requiredCount: int) -> void:
	while rowButtons.size() < requiredCount:
		var button := Button.new()
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0.0, 78.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index := rowButtons.size()
		button.pressed.connect(_onRowPressed.bind(index))
		rowContainer.add_child(button)
		_applyButtonStyle(button)
		rowButtons.append(button)


func _onRowPressed(index: int) -> void:
	if index < 0 or index >= rowIds.size():
		return

	purchaseRequested.emit(rowIds[index])


func _onClosePressed() -> void:
	closeRequested.emit()


func _applyReadableTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_MODAL_PATH, 42.0, 14.0)
	_applyReadableThemeRecursive(self)


func _applyReadableThemeRecursive(root: Node) -> void:
	for child in root.get_children():
		var label := child as Label
		if label != null:
			_applyLabelStyle(label)

		var button := child as Button
		if button != null:
			_applyButtonStyle(button)

		_applyReadableThemeRecursive(child)


func _applyLabelStyle(label: Label) -> void:
	label.add_theme_color_override("font_color", INK_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.96, 0.88, 0.68, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	if label.text == "Shop":
		label.add_theme_font_size_override("font_size", 24)
	elif not label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", 18)


func _applyButtonStyle(button: Button) -> void:
	if button == closeButton:
		UI_ASSET_THEME.applyTextButton(button, false, true)
		UI_ASSET_THEME.applyButtonIcon(button, UI_ASSET_THEME.ICON_BACK_PATH, "Back", 24)
	else:
		UI_ASSET_THEME.applyListButton(button)


func _panelStyle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT_COLOR
	style.border_color = INK_COLOR
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _buttonStyle(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK_COLOR
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
