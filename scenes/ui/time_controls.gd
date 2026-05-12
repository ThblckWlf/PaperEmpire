extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var pauseButton: Button = $MarginContainer/HBoxContainer/PauseButton as Button
@onready var normalButton: Button = $MarginContainer/HBoxContainer/NormalButton as Button
@onready var fastButton: Button = $MarginContainer/HBoxContainer/FastButton as Button
@onready var veryFastButton: Button = $MarginContainer/HBoxContainer/VeryFastButton as Button

var eventBus: EventBus


func _ready() -> void:
	pauseButton.pressed.connect(_requestPause)
	normalButton.pressed.connect(_requestNormal)
	fastButton.pressed.connect(_requestFast)
	veryFastButton.pressed.connect(_requestVeryFast)
	_applyAssetTheme()


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus


func setCurrentSpeed(speed: int) -> void:
	pauseButton.button_pressed = speed == GameSpeed.Value.Paused
	normalButton.button_pressed = speed == GameSpeed.Value.Normal
	fastButton.button_pressed = speed == GameSpeed.Value.Fast
	veryFastButton.button_pressed = speed == GameSpeed.Value.VeryFast


func _requestPause() -> void:
	_requestSpeedCommand(CommandType.PAUSE_GAME, {})


func _requestNormal() -> void:
	_requestSpeedCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Normal,
	})


func _requestFast() -> void:
	_requestSpeedCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.Fast,
	})


func _requestVeryFast() -> void:
	_requestSpeedCommand(CommandType.SET_GAME_SPEED, {
		"speed": GameSpeed.Value.VeryFast,
	})


func _requestSpeedCommand(commandName: StringName, payload: Dictionary) -> void:
	if eventBus == null:
		return

	eventBus.requestCommand(commandName, payload)


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyTopBarPanel(self)
	var buttonRow := pauseButton.get_parent() as HBoxContainer
	if buttonRow != null:
		buttonRow.add_theme_constant_override("separation", 14)
		buttonRow.alignment = BoxContainer.ALIGNMENT_CENTER
	_applyTimeButton(pauseButton, UI_ASSET_THEME.TIME_PAUSE_PATH, "Pause")
	_applyTimeButton(normalButton, UI_ASSET_THEME.TIME_SPEED_1_PATH, "Normal (1x)")
	_applyTimeButton(fastButton, UI_ASSET_THEME.TIME_SPEED_2_PATH, "Schnell (2x)")
	_applyTimeButton(veryFastButton, UI_ASSET_THEME.TIME_SPEED_4_PATH, "Sehr schnell (4x)")


func _applyTimeButton(button: Button, texturePath: String, tooltipText: String) -> void:
	UI_ASSET_THEME.applyTextButton(button, false, false)
	UI_ASSET_THEME.applyButtonIcon(button, texturePath, tooltipText, 36)
	button.text = ""
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(96.0, 60.0)
