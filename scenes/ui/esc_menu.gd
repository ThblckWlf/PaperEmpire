extends PanelContainer


signal resumeRequested
signal saveRequested
signal loadRequested
signal quitToMenuRequested

@onready var buttonContainer: VBoxContainer = $MarginContainer/VBoxContainer as VBoxContainer
@onready var resumeButton: Button = $MarginContainer/VBoxContainer/ResumeButton as Button
@onready var quitButton: Button = $MarginContainer/VBoxContainer/QuitButton as Button

var saveButton: Button
var loadButton: Button


func _ready() -> void:
	_ensureManualSaveButtons()
	resumeButton.pressed.connect(_onResumePressed)
	saveButton.pressed.connect(_onSavePressed)
	loadButton.pressed.connect(_onLoadPressed)
	quitButton.pressed.connect(_onQuitPressed)


func _onResumePressed() -> void:
	resumeRequested.emit()


func _onSavePressed() -> void:
	saveRequested.emit()


func _onLoadPressed() -> void:
	loadRequested.emit()


func _onQuitPressed() -> void:
	quitToMenuRequested.emit()


func _ensureManualSaveButtons() -> void:
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
