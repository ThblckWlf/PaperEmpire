extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

var messageLabel: Label
var lastMessage: String = ""
var pulseTween: Tween


func _ready() -> void:
	_buildOverlay()
	visible = false


func showDebugError(message: String) -> void:
	lastMessage = message
	messageLabel.text = message
	visible = true
	_flashNotice()


func clear() -> void:
	lastMessage = ""
	messageLabel.text = ""
	visible = false


func getLastMessage() -> String:
	return lastMessage


func _buildOverlay() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(540.0, 76.0)
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_WARNING_PATH, 38.0, 14.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var warningIcon := UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.ICON_WARNING_PATH, Vector2(42.0, 42.0))
	row.add_child(warningIcon)

	messageLabel = Label.new()
	messageLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	messageLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messageLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_ASSET_THEME.applyTitleLabel(messageLabel, 21)
	messageLabel.add_theme_color_override("font_color", Color("#421a12"))
	messageLabel.add_theme_color_override("font_shadow_color", Color(0.95, 0.68, 0.32, 0.55))
	messageLabel.add_theme_constant_override("shadow_offset_x", 2)
	messageLabel.add_theme_constant_override("shadow_offset_y", 2)
	row.add_child(messageLabel)


func _flashNotice() -> void:
	if pulseTween != null and pulseTween.is_running():
		pulseTween.kill()

	modulate = Color("#fff0c2")
	pulseTween = create_tween()
	pulseTween.set_trans(Tween.TRANS_QUAD)
	pulseTween.set_ease(Tween.EASE_OUT)
	pulseTween.tween_property(self, "modulate", Color.WHITE, 0.25)
