extends PanelContainer


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
