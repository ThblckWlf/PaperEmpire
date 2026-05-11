extends PanelContainer


signal resumeRequested
signal saveRequested
signal loadRequested
signal settingsRequested
signal returnToMainMenuRequested
signal quitGameRequested

@onready var buttonContainer: VBoxContainer = $MarginContainer/VBoxContainer as VBoxContainer
@onready var resumeButton: Button = $MarginContainer/VBoxContainer/ResumeButton as Button
@onready var quitButton: Button = $MarginContainer/VBoxContainer/QuitButton as Button

var saveButton: Button
var loadButton: Button
var settingsButton: Button
var returnToMainMenuButton: Button


func _ready() -> void:
	_ensurePauseButtons()
	resumeButton.pressed.connect(_onResumePressed)
	saveButton.pressed.connect(_onSavePressed)
	loadButton.pressed.connect(_onLoadPressed)
	settingsButton.pressed.connect(_onSettingsPressed)
	returnToMainMenuButton.pressed.connect(_onReturnToMainMenuPressed)
	quitButton.pressed.connect(_onQuitPressed)


func _onResumePressed() -> void:
	resumeRequested.emit()


func _onSavePressed() -> void:
	saveRequested.emit()


func _onLoadPressed() -> void:
	loadRequested.emit()


func _onSettingsPressed() -> void:
	settingsRequested.emit()


func _onReturnToMainMenuPressed() -> void:
	returnToMainMenuRequested.emit()


func _onQuitPressed() -> void:
	quitGameRequested.emit()


func _ensurePauseButtons() -> void:
	saveButton = buttonContainer.get_node_or_null("SaveButton") as Button
	if saveButton == null:
		saveButton = Button.new()
		saveButton.name = "SaveButton"
		saveButton.text = "Save"
		buttonContainer.add_child(saveButton)
		buttonContainer.move_child(saveButton, resumeButton.get_index() + 1)

	loadButton = buttonContainer.get_node_or_null("LoadButton") as Button
	if loadButton == null:
		loadButton = Button.new()
		loadButton.name = "LoadButton"
		loadButton.text = "Load"
		buttonContainer.add_child(loadButton)
		buttonContainer.move_child(loadButton, saveButton.get_index() + 1)

	settingsButton = buttonContainer.get_node_or_null("SettingsButton") as Button
	if settingsButton == null:
		settingsButton = Button.new()
		settingsButton.name = "SettingsButton"
		settingsButton.text = "Settings"
		buttonContainer.add_child(settingsButton)
		buttonContainer.move_child(settingsButton, loadButton.get_index() + 1)

	returnToMainMenuButton = buttonContainer.get_node_or_null("ReturnToMainMenuButton") as Button
	if returnToMainMenuButton == null:
		returnToMainMenuButton = Button.new()
		returnToMainMenuButton.name = "ReturnToMainMenuButton"
		returnToMainMenuButton.text = "Return to Main Menu"
		buttonContainer.add_child(returnToMainMenuButton)
		buttonContainer.move_child(returnToMainMenuButton, settingsButton.get_index() + 1)

	quitButton.text = "Quit Game"
