extends PanelContainer


var messageLabel: Label
var lastMessage: String = ""


func _ready() -> void:
	_buildOverlay()
	visible = false


func showDebugError(message: String) -> void:
	lastMessage = message
	messageLabel.text = message
	visible = true


func clear() -> void:
	lastMessage = ""
	messageLabel.text = ""
	visible = false


func getLastMessage() -> String:
	return lastMessage


func _buildOverlay() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	messageLabel = Label.new()
	messageLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(messageLabel)
