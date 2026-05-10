extends PanelContainer


signal settingChanged(settingKey: StringName, value: Variant)
signal closeRequested

var masterSlider: HSlider
var musicSlider: HSlider
var sfxSlider: HSlider
var uiScaleSlider: HSlider
var fullscreenCheck: CheckBox
var isUpdating: bool = false


func _ready() -> void:
	_buildPanel()


func setData(data: Dictionary) -> void:
	isUpdating = true
	masterSlider.value = float(data.get("masterVolume", 1.0))
	musicSlider.value = float(data.get("musicVolume", 0.8))
	sfxSlider.value = float(data.get("sfxVolume", 0.8))
	uiScaleSlider.value = float(data.get("uiScale", 1.0))
	fullscreenCheck.button_pressed = str(data.get("windowMode", "windowed")) == "fullscreen"
	isUpdating = false


func _buildPanel() -> void:
	custom_minimum_size = Vector2(420.0, 300.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)

	var title := Label.new()
	title.text = "Settings"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var closeButton := Button.new()
	closeButton.text = "Close"
	closeButton.pressed.connect(_onClosePressed)
	header.add_child(closeButton)

	masterSlider = _addSliderRow(column, "Master", &"masterVolume", 0.0, 1.0, 0.05)
	musicSlider = _addSliderRow(column, "Music", &"musicVolume", 0.0, 1.0, 0.05)
	sfxSlider = _addSliderRow(column, "SFX", &"sfxVolume", 0.0, 1.0, 0.05)
	uiScaleSlider = _addSliderRow(column, "UI Scale", &"uiScale", 0.8, 1.4, 0.1)

	fullscreenCheck = CheckBox.new()
	fullscreenCheck.text = "Fullscreen"
	fullscreenCheck.toggled.connect(_onFullscreenToggled)
	column.add_child(fullscreenCheck)


func _addSliderRow(
	parent: VBoxContainer,
	labelText: String,
	settingKey: StringName,
	minValue: float,
	maxValue: float,
	stepValue: float
) -> HSlider:
	var row := HBoxContainer.new()
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
	return slider


func _onSliderChanged(value: float, settingKey: StringName) -> void:
	if isUpdating:
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
	closeRequested.emit()
