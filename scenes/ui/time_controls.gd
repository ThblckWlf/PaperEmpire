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
	_applyTimeButton(pauseButton, UI_ASSET_THEME.TIME_PAUSE_PATH, "Pause")
	_applyTimeButton(normalButton, UI_ASSET_THEME.TIME_SPEED_1_PATH, "Normal speed")
	_applyTimeButton(fastButton, UI_ASSET_THEME.TIME_SPEED_2_PATH, "Fast speed")
	_applyTimeButton(veryFastButton, UI_ASSET_THEME.TIME_SPEED_4_PATH, "Very fast speed")


func _applyTimeButton(button: Button, texturePath: String, tooltipText: String) -> void:
	UI_ASSET_THEME.applyTextButton(button, false, true)
	UI_ASSET_THEME.applyButtonIcon(button, texturePath, tooltipText, 24)
	button.custom_minimum_size = Vector2(88.0, 40.0)
