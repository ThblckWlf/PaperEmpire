extends PanelContainer


signal settingChanged(settingKey: StringName, value: Variant)
signal closeRequested

const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

const INK_COLOR: Color = Color("#211d17")
const MUTED_INK_COLOR: Color = Color("#4d422f")
const DISABLED_INK_COLOR: Color = Color("#655d4f")
const PARCHMENT_COLOR: Color = Color("#d8bd7c")
const BUTTON_COLOR: Color = Color("#c99e55")
const BUTTON_HOVER_COLOR: Color = Color("#d8af64")
const BUTTON_PRESSED_COLOR: Color = Color("#ae8441")

var masterSlider: HSlider
var musicSlider: HSlider
var sfxSlider: HSlider
var uiScaleSlider: HSlider
var uiScaleValueLabel: Label
var fullscreenCheck: CheckBox
var closeButton: Button
var acceptButton: Button
var isUpdating: bool = false
var committedUiScale: float = 1.0
var pendingUiScaleChanged: bool = false


func _ready() -> void:
	_buildPanel()
	_applyReadableTheme()


func setData(data: Dictionary) -> void:
	isUpdating = true
	masterSlider.value = float(data.get("masterVolume", 1.0))
	musicSlider.value = float(data.get("musicVolume", 0.8))
	sfxSlider.value = float(data.get("sfxVolume", 0.8))
	committedUiScale = float(data.get("uiScale", 1.0))
	if not pendingUiScaleChanged:
		uiScaleSlider.value = committedUiScale
	fullscreenCheck.button_pressed = str(data.get("windowMode", "windowed")) == "fullscreen"
	isUpdating = false
	_updateUiScaleValueLabel()
	_refreshAcceptButton()


func discardPendingChanges() -> void:
	pendingUiScaleChanged = false
	isUpdating = true
	uiScaleSlider.value = committedUiScale
	isUpdating = false
	_updateUiScaleValueLabel()
	_refreshAcceptButton()


func _buildPanel() -> void:
	custom_minimum_size = Vector2(460.0, 340.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "Settings"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	masterSlider = _addSliderRow(column, "Master", &"masterVolume", 0.0, 1.0, 0.05)
	musicSlider = _addSliderRow(column, "Music", &"musicVolume", 0.0, 1.0, 0.05)
	sfxSlider = _addSliderRow(column, "SFX", &"sfxVolume", 0.0, 1.0, 0.05)
	uiScaleSlider = _addSliderRow(column, "UI Scale", &"uiScale", 0.8, 1.4, 0.1, true)

	fullscreenCheck = CheckBox.new()
	fullscreenCheck.text = "Fullscreen"
	fullscreenCheck.toggled.connect(_onFullscreenToggled)
	column.add_child(fullscreenCheck)

	var actionRow := HBoxContainer.new()
	actionRow.alignment = BoxContainer.ALIGNMENT_END
	actionRow.add_theme_constant_override("separation", 10)
	column.add_child(actionRow)

	closeButton = Button.new()
	closeButton.text = "Back"
	closeButton.custom_minimum_size = Vector2(96.0, 40.0)
	closeButton.clip_text = true
	closeButton.pressed.connect(_onClosePressed)
	actionRow.add_child(closeButton)

	acceptButton = Button.new()
	acceptButton.text = "Accept"
	acceptButton.custom_minimum_size = Vector2(116.0, 40.0)
	acceptButton.clip_text = true
	acceptButton.pressed.connect(_onAcceptPressed)
	actionRow.add_child(acceptButton)
	_refreshAcceptButton()


func _addSliderRow(
	parent: VBoxContainer,
	labelText: String,
	settingKey: StringName,
	minValue: float,
	maxValue: float,
	stepValue: float,
	showValueLabel: bool = false
) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var label := Label.new()
	label.text = labelText
	label.custom_minimum_size = Vector2(110.0, 0.0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = minValue
	slider.max_value = maxValue
	slider.step = stepValue
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_onSliderChanged.bind(settingKey))
	row.add_child(slider)

	if showValueLabel:
		uiScaleValueLabel = Label.new()
		uiScaleValueLabel.custom_minimum_size = Vector2(58.0, 0.0)
		uiScaleValueLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(uiScaleValueLabel)

	return slider


func _onSliderChanged(value: float, settingKey: StringName) -> void:
	if isUpdating:
		return

	if settingKey == &"uiScale":
		pendingUiScaleChanged = not is_equal_approx(float(value), committedUiScale)
		_updateUiScaleValueLabel()
		_refreshAcceptButton()
		return

	settingChanged.emit(settingKey, value)


func _onFullscreenToggled(enabled: bool) -> void:
	if isUpdating:
		return
	var mode := "windowed"
	if enabled:
		mode = "fullscreen"
	settingChanged.emit(&"windowMode", mode)


func _onClosePressed() -> void:
	discardPendingChanges()
	closeRequested.emit()


func _onAcceptPressed() -> void:
	if pendingUiScaleChanged:
		var acceptedScale := float(uiScaleSlider.value)
		committedUiScale = acceptedScale
		pendingUiScaleChanged = false
		_refreshAcceptButton()
		settingChanged.emit(&"uiScale", acceptedScale)
	closeRequested.emit()


func _updateUiScaleValueLabel() -> void:
	if uiScaleValueLabel == null:
		return

	uiScaleValueLabel.text = "%d%%" % int(round(float(uiScaleSlider.value) * 100.0))


func _refreshAcceptButton() -> void:
	if acceptButton == null:
		return

	acceptButton.disabled = not pendingUiScaleChanged


func _applyReadableTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_MODAL_PATH, 42.0, 14.0)
	_applyReadableThemeRecursive(self)
	UI_ASSET_THEME.applyButtonIcon(closeButton, UI_ASSET_THEME.ICON_BACK_PATH, "Back", 24)
	UI_ASSET_THEME.applyButtonIcon(acceptButton, UI_ASSET_THEME.ICON_CONFIRM_PATH, "Accept settings", 24)


func _applyReadableThemeRecursive(root: Node) -> void:
	for child in root.get_children():
		var label := child as Label
		if label != null:
			_applyLabelStyle(label)

		var button := child as Button
		if button != null:
			_applyButtonStyle(button)

		var checkBox := child as CheckBox
		if checkBox != null:
			UI_ASSET_THEME.applyCheckbox(checkBox)

		var slider := child as HSlider
		if slider != null:
			UI_ASSET_THEME.applySlider(slider)

		_applyReadableThemeRecursive(child)


func _applyLabelStyle(label: Label) -> void:
	label.add_theme_color_override("font_color", INK_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.96, 0.88, 0.68, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	if label.text == "Settings":
		label.add_theme_font_size_override("font_size", 24)
	elif not label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", 18)


func _applyButtonStyle(button: Button) -> void:
	UI_ASSET_THEME.applyTextButton(button, false, true)


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


func _sliderTrackStyle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = MUTED_INK_COLOR.lightened(0.34)
	style.border_color = INK_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _sliderFillStyle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#c39535")
	style.border_color = INK_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
