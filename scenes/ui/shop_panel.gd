extends PanelContainer


signal purchaseRequested(upgradeId: StringName)
signal closeRequested

var crownLabel: Label
var rowContainer: VBoxContainer
var closeButton: Button
var rowButtons: Array[Button] = []
var rowIds: Array[StringName] = []


func _ready() -> void:
	_buildPanel()


func setData(data: Dictionary) -> void:
	crownLabel.text = "Crowns: %d" % int(data.get("crowns", 0))
	rowIds.clear()

	var rows: Array = data.get("rows", [])
	_ensureRowButtons(rows.size())
	for index in range(rowButtons.size()):
		var button := rowButtons[index]
		if index >= rows.size() or not (rows[index] is Dictionary):
			button.visible = false
			button.disabled = true
			button.text = "-"
			continue

		var row := rows[index] as Dictionary
		rowIds.append(StringName(str(row.get("id", ""))))
		var level := int(row.get("level", 0))
		var maxLevel := int(row.get("maxLevel", 1))
		var cost := int(row.get("cost", 0))
		var suffix := "Cost: %d" % cost
		if level >= maxLevel:
			suffix = "Max"
		button.text = "%s  %d/%d  %s\n%s" % [
			str(row.get("name", "Upgrade")),
			level,
			maxLevel,
			suffix,
			str(row.get("description", "")),
		]
		button.visible = true
		button.disabled = not bool(row.get("canPurchase", false))


func _buildPanel() -> void:
	custom_minimum_size = Vector2(520.0, 460.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var mainColumn := VBoxContainer.new()
	mainColumn.add_theme_constant_override("separation", 10)
	margin.add_child(mainColumn)

	var header := HBoxContainer.new()
	mainColumn.add_child(header)

	var titleLabel := Label.new()
	titleLabel.text = "Shop"
	titleLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titleLabel)

	closeButton = Button.new()
	closeButton.text = "Close"
	closeButton.pressed.connect(_onClosePressed)
	header.add_child(closeButton)

	crownLabel = Label.new()
	crownLabel.text = "Crowns: 0"
	mainColumn.add_child(crownLabel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mainColumn.add_child(scroll)

	rowContainer = VBoxContainer.new()
	rowContainer.add_theme_constant_override("separation", 8)
	rowContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rowContainer)


func _ensureRowButtons(requiredCount: int) -> void:
	while rowButtons.size() < requiredCount:
		var button := Button.new()
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index := rowButtons.size()
		button.pressed.connect(_onRowPressed.bind(index))
		rowContainer.add_child(button)
		rowButtons.append(button)


func _onRowPressed(index: int) -> void:
	if index < 0 or index >= rowIds.size():
		return

	purchaseRequested.emit(rowIds[index])


func _onClosePressed() -> void:
	closeRequested.emit()
