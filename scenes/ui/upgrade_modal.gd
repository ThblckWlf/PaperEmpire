extends PanelContainer


const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

@onready var titleLabel: Label = $MarginContainer/VBoxContainer/TitleLabel as Label
@onready var choiceRow: HBoxContainer = $MarginContainer/VBoxContainer/ChoiceRow as HBoxContainer
@onready var choiceButtons: Array[Button] = [
	$MarginContainer/VBoxContainer/ChoiceRow/ChoiceButton1 as Button,
	$MarginContainer/VBoxContainer/ChoiceRow/ChoiceButton2 as Button,
	$MarginContainer/VBoxContainer/ChoiceRow/ChoiceButton3 as Button,
]

var eventBus: EventBus
var choiceIds: Array[StringName] = []


func _ready() -> void:
	_applyAssetTheme()
	for index in range(choiceButtons.size()):
		choiceButtons[index].pressed.connect(_onChoicePressed.bind(index))


func configure(newEventBus: EventBus) -> void:
	eventBus = newEventBus


func setData(data: Dictionary) -> void:
	titleLabel.text = "Choose Upgrade"
	choiceIds.clear()
	var choices: Array = data.get("choices", [])
	for index in range(choiceButtons.size()):
		var button := choiceButtons[index]
		if index >= choices.size() or not (choices[index] is Dictionary):
			button.disabled = true
			button.visible = false
			_setChoiceView(button, {}, true)
			continue

		var upgrade := choices[index] as Dictionary
		choiceIds.append(StringName(str(upgrade.get("id", ""))))
		button.visible = true
		button.disabled = false
		button.tooltip_text = str(upgrade.get("rarity", "common")).capitalize()
		UI_ASSET_THEME.applyUpgradeChoiceCardButton(button)
		_setChoiceView(button, upgrade, false)


func _onChoicePressed(index: int) -> void:
	if eventBus == null or index < 0 or index >= choiceIds.size():
		return

	eventBus.requestCommand(CommandType.CHOOSE_UPGRADE, {
		"upgradeId": str(choiceIds[index]),
	})


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_MODAL_PATH, 42.0, 14.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 24)
	choiceRow.add_theme_constant_override("separation", 16)
	choiceRow.alignment = BoxContainer.ALIGNMENT_CENTER
	choiceRow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choiceRow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for button in choiceButtons:
		UI_ASSET_THEME.applyUpgradeChoiceCardButton(button)
		button.custom_minimum_size = Vector2(260.0, 420.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_ensureChoiceView(button)


func _ensureChoiceView(button: Button) -> Dictionary:
	var background := button.get_node_or_null("CardBackground") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "CardBackground"
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.offset_left = 0.0
		background.offset_top = 0.0
		background.offset_right = 0.0
		background.offset_bottom = 0.0
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(background)
		button.move_child(background, 0)
	background.texture = UI_ASSET_THEME.loadTexture(UI_ASSET_THEME.UPGRADE_CHOICE_CARD_PATH)

	var content := button.get_node_or_null("Content") as MarginContainer
	if content == null:
		content = MarginContainer.new()
		content.name = "Content"
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 30.0
		content.offset_top = 58.0
		content.offset_right = -30.0
		content.offset_bottom = -58.0
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)

	var column := content.get_node_or_null("Column") as VBoxContainer
	if column == null:
		column = VBoxContainer.new()
		column.name = "Column"
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.add_theme_constant_override("separation", 8)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(column)

	var icon := column.get_node_or_null("Icon") as TextureRect
	if icon == null:
		icon = UI_ASSET_THEME.makeIcon(UI_ASSET_THEME.ICON_CONFIRM_PATH, Vector2(98.0, 98.0))
		icon.name = "Icon"
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(icon)

	var spacer := column.get_node_or_null("TitleSpacer") as Control
	if spacer == null:
		spacer = Control.new()
		spacer.name = "TitleSpacer"
		spacer.custom_minimum_size = Vector2(0.0, 20.0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(spacer)

	var nameLabel := column.get_node_or_null("NameLabel") as Label
	if nameLabel == null:
		nameLabel = Label.new()
		nameLabel.name = "NameLabel"
		nameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nameLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nameLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nameLabel.custom_minimum_size = Vector2(0.0, 52.0)
		nameLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(nameLabel)

	var descriptionLabel := column.get_node_or_null("DescriptionLabel") as Label
	if descriptionLabel == null:
		descriptionLabel = Label.new()
		descriptionLabel.name = "DescriptionLabel"
		descriptionLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		descriptionLabel.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		descriptionLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descriptionLabel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		descriptionLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(descriptionLabel)

	UI_ASSET_THEME.applyTitleLabel(nameLabel, 18)
	UI_ASSET_THEME.applyLabel(descriptionLabel, 14)
	return {
		"icon": icon,
		"nameLabel": nameLabel,
		"descriptionLabel": descriptionLabel,
	}


func _setChoiceView(button: Button, upgrade: Dictionary, isEmpty: bool) -> void:
	var view := _ensureChoiceView(button)
	var icon := view.get("icon", null) as TextureRect
	var nameLabel := view.get("nameLabel", null) as Label
	var descriptionLabel := view.get("descriptionLabel", null) as Label
	if icon != null:
		icon.texture = UI_ASSET_THEME.loadTexture(UI_ASSET_THEME.iconForUpgradeEffect(str(upgrade.get("effectType", ""))))
		icon.visible = not isEmpty
	if nameLabel != null:
		nameLabel.text = "" if isEmpty else str(upgrade.get("name", "Upgrade"))
	if descriptionLabel != null:
		descriptionLabel.text = "" if isEmpty else str(upgrade.get("description", ""))
