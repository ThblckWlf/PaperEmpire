extends PanelContainer


signal resumeRequested
signal quitToMenuRequested

@onready var resumeButton: Button = $MarginContainer/VBoxContainer/ResumeButton as Button
@onready var quitButton: Button = $MarginContainer/VBoxContainer/QuitButton as Button


func _ready() -> void:
	resumeButton.pressed.connect(_onResumePressed)
	quitButton.pressed.connect(_onQuitPressed)


func _onResumePressed() -> void:
	resumeRequested.emit()


func _onQuitPressed() -> void:
	quitToMenuRequested.emit()
