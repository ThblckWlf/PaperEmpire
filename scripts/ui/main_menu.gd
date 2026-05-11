extends Control
class_name MainMenu


signal newRunRequested(startCountryId: String)
signal loadGameRequested(slotId: String)
signal quitGameRequested

const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")
const SAVE_FORMAT := preload("res://src/save/save_format.gd")
const SHOP_PANEL_SCRIPT := preload("res://scenes/ui/shop_panel.gd")
const SETTINGS_PANEL_SCRIPT := preload("res://scenes/ui/settings_panel.gd")

const MANUAL_SLOT_ID: String = "manual_1"
const PAPER_BACKGROUND_PATH: String = "res://assets/map/backgrounds/paperBackgroundMenuDesk.png"
const PANEL_LARGE_PATH: String = "res://assets/ui/panels/panelLarge.9.png"
const PANEL_SMALL_PATH: String = "res://assets/ui/panels/panelSmall.9.png"
const PANEL_MODAL_PATH: String = "res://assets/ui/panels/panelModalLarge.9.png"
const BUTTON_DEFAULT_PATH: String = "res://assets/ui/buttons/buttonDefault.png"
const BUTTON_DEFAULT_HOVER_PATH: String = "res://assets/ui/buttons/buttonDefaultHover.png"
const BUTTON_DEFAULT_PRESSED_PATH: String = "res://assets/ui/buttons/buttonDefaultPressed.png"
const BUTTON_DEFAULT_DISABLED_PATH: String = "res://assets/ui/buttons/buttonDefaultDisabled.png"
const BUTTON_DANGER_PATH: String = "res://assets/ui/buttons/buttonDanger.png"
const BUTTON_DANGER_HOVER_PATH: String = "res://assets/ui/buttons/buttonDangerHover.png"
const BUTTON_DANGER_PRESSED_PATH: String = "res://assets/ui/buttons/buttonDangerPressed.png"
const BUTTON_DANGER_DISABLED_PATH: String = "res://assets/ui/buttons/buttonDangerDisabled.png"
const DIVIDER_TEXTURE_PATH: String = "res://assets/ui/decor/dividerHorizontal.png"
const CORNER_TEXTURE_PATH: String = "res://assets/ui/decor/inkCornerMark.png"
const INK_COLOR: Color = Color("#211d17")
const SOFT_INK_COLOR: Color = Color("#3c3326")
const MUTED_LABEL_COLOR: Color = Color("#4d422f")
const DISABLED_INK_COLOR: Color = Color("#645b4b")

@export var unlockAgeRunButton: bool = false

@onready var background: TextureRect = $Background as TextureRect
@onready var safeArea: Control = $SafeArea as Control
@onready var titlePanel: PanelContainer = $SafeArea/TitlePanel as PanelContainer
@onready var mainMenuPanel: PanelContainer = $SafeArea/MainMenuPanel as PanelContainer
@onready var infoPanel: PanelContainer = $SafeArea/InfoPanel as PanelContainer
@onready var buttonList: VBoxContainer = $SafeArea/MainMenuPanel/MarginContainer/ButtonList as VBoxContainer
@onready var continueRunButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/ContinueRunButton as Button
@onready var newRunButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/NewRunButton as Button
@onready var shopButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/ShopButton as Button
@onready var howToPlayButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/HowToPlayButton as Button
@onready var settingsButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/SettingsButton as Button
@onready var loadGameButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/LoadGameButton as Button
@onready var creditsButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/CreditsButton as Button
@onready var quitButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/QuitButton as Button
@onready var startAgeRunHiddenButton: Button = $SafeArea/MainMenuPanel/MarginContainer/ButtonList/StartAgeRunHiddenButton as Button
@onready var versionLabel: Label = $SafeArea/InfoPanel/MarginContainer/InfoContent/VersionLabel as Label
@onready var saveStatusLabel: Label = $SafeArea/InfoPanel/MarginContainer/InfoContent/SaveStatusLabel as Label
@onready var hintLabel: Label = $SafeArea/InfoPanel/MarginContainer/InfoContent/HintLabel as Label
@onready var modalLayer: Control = $SafeArea/ModalLayer as Control
@onready var modalDim: ColorRect = $SafeArea/ModalLayer/Dim as ColorRect
@onready var modalPanel: PanelContainer = $SafeArea/ModalLayer/ModalPanel as PanelContainer
@onready var modalTitleLabel: Label = $SafeArea/ModalLayer/ModalPanel/MarginContainer/ModalContent/ModalTitleLabel as Label
@onready var modalBodyLabel: Label = $SafeArea/ModalLayer/ModalPanel/MarginContainer/ModalContent/ModalBodyLabel as Label
@onready var primaryModalButton: Button = $SafeArea/ModalLayer/ModalPanel/MarginContainer/ModalContent/ModalButtons/PrimaryModalButton as Button
@onready var closeModalButton: Button = $SafeArea/ModalLayer/ModalPanel/MarginContainer/ModalContent/ModalButtons/CloseModalButton as Button
@onready var divider: TextureRect = $SafeArea/InfoPanel/MarginContainer/InfoContent/Divider as TextureRect
@onready var cornerTopLeft: TextureRect = $SafeArea/CornerTopLeft as TextureRect
@onready var cornerBottomRight: TextureRect = $SafeArea/CornerBottomRight as TextureRect

var gameManager: GameManager
var eventBus: EventBus
var settingsManager
var saveManager: SaveManager
var shopPanel: PanelContainer
var settingsPanel: PanelContainer
var modalPrimaryAction: Callable = Callable()
var textureCache: Dictionary = {}


func _ready() -> void:
	INPUT_ACTIONS.ensureDefaultActions()
	_applyLayout()
	_applyTheme()
	_connectButtons()
	_refreshStaticLabels()
	refreshSaveStatus()
	modalLayer.visible = false
	startAgeRunHiddenButton.visible = unlockAgeRunButton
	startAgeRunHiddenButton.disabled = not unlockAgeRunButton
	_focusFirstMenuButton()


func _unhandled_input(event: InputEvent) -> void:
	var keyEvent := event as InputEventKey
	if keyEvent == null or not keyEvent.pressed or keyEvent.echo:
		return

	if event.is_action_pressed(INPUT_ACTIONS.ACTION_OPEN_MENU):
		if modalLayer.visible:
			_closeModal()
			get_viewport().set_input_as_handled()


func configure(
	newGameManager: GameManager,
	newEventBus: EventBus,
	newSettingsManager = null,
	newSaveManager: SaveManager = null
) -> void:
	gameManager = newGameManager
	eventBus = newEventBus
	settingsManager = newSettingsManager
	saveManager = newSaveManager
	if is_node_ready():
		refreshSaveStatus()
		_refreshShopPanel()
		_refreshSettingsPanel()


func refreshSaveStatus() -> void:
	if not is_node_ready():
		return

	var hasRunSave := _hasValidRunSave()
	continueRunButton.disabled = not hasRunSave
	loadGameButton.disabled = not hasRunSave
	if hasRunSave:
		saveStatusLabel.text = "Manual save found"
		hintLabel.text = "Continue restores the last manual run."
	else:
		saveStatusLabel.text = "No save found"
		hintLabel.text = "New Run uses the current Paperland placeholder."


func closeOpenPanel() -> bool:
	if not is_node_ready() or not modalLayer.visible:
		return false

	_closeModal()
	return true


func openCountrySelectionPlaceholder() -> void:
	_showTextModal(
		"Choose Start Country",
		"Country selection is still a placeholder.\n\nFor now, start the normal prototype run from Paperland.",
		"Start Paperland",
		Callable(self, "_requestDefaultNewRun")
	)


func openShopPlaceholder() -> void:
	_ensureShopPanel()
	_hideTextModalPanel()
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false
	shopPanel.visible = true
	modalLayer.visible = true
	_refreshShopPanel()


func openSettingsPlaceholder() -> void:
	_ensureSettingsPanel()
	_hideTextModalPanel()
	if shopPanel != null:
		shopPanel.visible = false
	settingsPanel.visible = true
	modalLayer.visible = true
	_refreshSettingsPanel()


func _connectButtons() -> void:
	continueRunButton.pressed.connect(_onContinueRunPressed)
	newRunButton.pressed.connect(openCountrySelectionPlaceholder)
	shopButton.pressed.connect(openShopPlaceholder)
	howToPlayButton.pressed.connect(_onHowToPlayPressed)
	settingsButton.pressed.connect(openSettingsPlaceholder)
	loadGameButton.pressed.connect(_onLoadGamePressed)
	creditsButton.pressed.connect(_onCreditsPressed)
	quitButton.pressed.connect(_onQuitPressed)
	startAgeRunHiddenButton.pressed.connect(_onStartAgeRunPressed)
	primaryModalButton.pressed.connect(_onPrimaryModalPressed)
	closeModalButton.pressed.connect(_closeModal)


func _onContinueRunPressed() -> void:
	if not _hasValidRunSave():
		refreshSaveStatus()
		return
	loadGameRequested.emit(MANUAL_SLOT_ID)


func _onLoadGamePressed() -> void:
	if not _hasValidRunSave():
		refreshSaveStatus()
		return
	loadGameRequested.emit(MANUAL_SLOT_ID)


func _onHowToPlayPressed() -> void:
	_showTextModal(
		"How To Play",
		"Build armies in owned countries.\nMove them across neighboring borders.\nAttack when your army is ready.\nChoose upgrades after conquest.\nKeep global threat under control.",
		"",
		Callable()
	)


func _onCreditsPressed() -> void:
	_showTextModal(
		"Credits",
		"Paper Empire is an in-progress Godot 4 strategy roguelike prototype.",
		"",
		Callable()
	)


func _onStartAgeRunPressed() -> void:
	_showTextModal(
		"Start Age Run",
		"This debug-only placeholder is intentionally not connected to gameplay.",
		"",
		Callable()
	)


func _onQuitPressed() -> void:
	quitGameRequested.emit()


func _requestDefaultNewRun() -> void:
	_closeModal()
	newRunRequested.emit(str(NewRunFactory.DEFAULT_START_COUNTRY_ID))


func _onPrimaryModalPressed() -> void:
	if modalPrimaryAction.is_valid():
		modalPrimaryAction.call()
	else:
		_closeModal()


func _showTextModal(titleText: String, bodyText: String, primaryText: String, primaryAction: Callable) -> void:
	if shopPanel != null:
		shopPanel.visible = false
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false

	modalTitleLabel.text = titleText
	modalBodyLabel.text = bodyText
	modalPrimaryAction = primaryAction
	primaryModalButton.visible = primaryText != ""
	primaryModalButton.disabled = primaryText == ""
	primaryModalButton.text = primaryText
	modalPanel.visible = true
	modalLayer.visible = true
	if primaryModalButton.visible:
		primaryModalButton.grab_focus()
	else:
		closeModalButton.grab_focus()


func _hideTextModalPanel() -> void:
	modalPanel.visible = false
	modalPrimaryAction = Callable()


func _closeModal() -> void:
	_hideTextModalPanel()
	if shopPanel != null:
		shopPanel.visible = false
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false
	modalLayer.visible = false
	refreshSaveStatus()
	_focusFirstMenuButton()


func _discardSettingsPanelChanges() -> void:
	if settingsPanel != null and settingsPanel.has_method("discardPendingChanges"):
		settingsPanel.call("discardPendingChanges")


func _ensureShopPanel() -> void:
	if shopPanel != null:
		return

	shopPanel = SHOP_PANEL_SCRIPT.new() as PanelContainer
	shopPanel.name = "MainMenuShopPanel"
	shopPanel.visible = false
	modalLayer.add_child(shopPanel)
	shopPanel.set_anchors_preset(Control.PRESET_CENTER)
	shopPanel.offset_left = -330.0
	shopPanel.offset_top = -270.0
	shopPanel.offset_right = 330.0
	shopPanel.offset_bottom = 270.0
	shopPanel.purchaseRequested.connect(_purchaseMetaUpgrade)
	shopPanel.closeRequested.connect(_closeModal)
	_applyPanelStyle(shopPanel, PANEL_MODAL_PATH)
	_applyPaperControlTheme(shopPanel)


func _ensureSettingsPanel() -> void:
	if settingsPanel != null:
		return

	settingsPanel = SETTINGS_PANEL_SCRIPT.new() as PanelContainer
	settingsPanel.name = "MainMenuSettingsPanel"
	settingsPanel.visible = false
	modalLayer.add_child(settingsPanel)
	settingsPanel.set_anchors_preset(Control.PRESET_CENTER)
	settingsPanel.offset_left = -240.0
	settingsPanel.offset_top = -170.0
	settingsPanel.offset_right = 240.0
	settingsPanel.offset_bottom = 170.0
	settingsPanel.settingChanged.connect(_changeSetting)
	settingsPanel.closeRequested.connect(_closeModal)
	_applyPanelStyle(settingsPanel, PANEL_MODAL_PATH)
	_applyPaperControlTheme(settingsPanel)


func _refreshShopPanel() -> void:
	if shopPanel == null or gameManager == null:
		return

	shopPanel.call("setData", gameManager.getShopPanelData())
	_applyPaperControlTheme(shopPanel)


func _refreshSettingsPanel() -> void:
	if settingsPanel == null or settingsManager == null:
		return

	settingsPanel.call("setData", settingsManager.getSettingsData())


func _purchaseMetaUpgrade(upgradeId: StringName) -> void:
	if eventBus != null:
		eventBus.requestCommand(CommandType.PURCHASE_META_UPGRADE, {
			"upgradeId": str(upgradeId),
		})
	_refreshShopPanel()


func _changeSetting(settingKey: StringName, value: Variant) -> void:
	if settingsManager == null:
		return

	settingsManager.updateSetting(settingKey, value)
	_refreshSettingsPanel()


func _hasValidRunSave() -> bool:
	if saveManager == null:
		return false
	if not saveManager.hasSave(MANUAL_SLOT_ID):
		return false

	var root := saveManager.loadGame(MANUAL_SLOT_ID)
	if root.is_empty():
		return false

	var runData: Dictionary = root.get(SAVE_FORMAT.RUN_STATE_KEY, {})
	return runData.size() > 1


func _refreshStaticLabels() -> void:
	versionLabel.text = "Version %s" % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))


func _applyLayout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	safeArea.set_anchors_preset(Control.PRESET_FULL_RECT)
	safeArea.offset_left = 0.0
	safeArea.offset_top = 0.0
	safeArea.offset_right = 0.0
	safeArea.offset_bottom = 0.0

	titlePanel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	titlePanel.offset_left = 88.0
	titlePanel.offset_top = 70.0
	titlePanel.offset_right = 692.0
	titlePanel.offset_bottom = 224.0

	mainMenuPanel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	mainMenuPanel.offset_left = 112.0
	mainMenuPanel.offset_top = 272.0
	mainMenuPanel.offset_right = 612.0
	mainMenuPanel.offset_bottom = -72.0

	infoPanel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	infoPanel.offset_left = -610.0
	infoPanel.offset_top = -242.0
	infoPanel.offset_right = -86.0
	infoPanel.offset_bottom = -76.0

	cornerTopLeft.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cornerTopLeft.offset_left = 56.0
	cornerTopLeft.offset_top = 42.0
	cornerTopLeft.offset_right = 184.0
	cornerTopLeft.offset_bottom = 170.0

	cornerBottomRight.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cornerBottomRight.offset_left = -184.0
	cornerBottomRight.offset_top = -170.0
	cornerBottomRight.offset_right = -56.0
	cornerBottomRight.offset_bottom = -42.0
	cornerBottomRight.flip_h = true
	cornerBottomRight.flip_v = true

	modalLayer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modalLayer.offset_left = 0.0
	modalLayer.offset_top = 0.0
	modalLayer.offset_right = 0.0
	modalLayer.offset_bottom = 0.0
	modalLayer.mouse_filter = Control.MOUSE_FILTER_STOP

	modalDim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modalDim.offset_left = 0.0
	modalDim.offset_top = 0.0
	modalDim.offset_right = 0.0
	modalDim.offset_bottom = 0.0

	modalPanel.set_anchors_preset(Control.PRESET_CENTER)
	modalPanel.offset_left = -360.0
	modalPanel.offset_top = -210.0
	modalPanel.offset_right = 360.0
	modalPanel.offset_bottom = 210.0

	for button in _menuButtons():
		button.custom_minimum_size = Vector2(0.0, 58.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _applyTheme() -> void:
	background.texture = _loadTexture(PAPER_BACKGROUND_PATH)
	divider.texture = _loadTexture(DIVIDER_TEXTURE_PATH)
	cornerTopLeft.texture = _loadTexture(CORNER_TEXTURE_PATH)
	cornerBottomRight.texture = _loadTexture(CORNER_TEXTURE_PATH)

	_applyPanelStyle(titlePanel, PANEL_SMALL_PATH)
	_applyPanelStyle(mainMenuPanel, PANEL_LARGE_PATH)
	_applyPanelStyle(infoPanel, PANEL_SMALL_PATH)
	_applyPanelStyle(modalPanel, PANEL_MODAL_PATH)

	for button in _menuButtons():
		_applyButtonStyle(button, false, false)
	_applyButtonStyle(quitButton, true, false)
	_applyButtonStyle(primaryModalButton, false, false)
	_applyButtonStyle(closeModalButton, false, false)

	_applyPaperControlTheme(self)
	_applyTitleLabelStyle($SafeArea/TitlePanel/MarginContainer/TitleContent/GameTitleLabel as Label)
	_applyMutedLabelStyle($SafeArea/TitlePanel/MarginContainer/TitleContent/SubtitleLabel as Label)
	_applyMutedLabelStyle(hintLabel)
	_applyModalLabelStyle(modalBodyLabel)

	modalDim.color = Color(0.04, 0.035, 0.025, 0.55)


func _focusFirstMenuButton() -> void:
	if continueRunButton != null and not continueRunButton.disabled and continueRunButton.visible:
		continueRunButton.grab_focus()
	else:
		newRunButton.grab_focus()


func _applyPaperControlTheme(root: Node) -> void:
	for child in root.get_children():
		var label := child as Label
		if label != null:
			_applyBodyLabelStyle(label)

		var checkBox := child as CheckBox
		if checkBox != null:
			checkBox.add_theme_color_override("font_color", INK_COLOR)
			checkBox.add_theme_color_override("font_hover_color", INK_COLOR)
			checkBox.add_theme_color_override("font_pressed_color", INK_COLOR)
			checkBox.add_theme_color_override("font_hover_pressed_color", INK_COLOR)
			checkBox.add_theme_color_override("font_disabled_color", DISABLED_INK_COLOR)
			checkBox.add_theme_color_override("font_focus_color", INK_COLOR)
			checkBox.add_theme_font_size_override("font_size", 18)
		else:
			var button := child as Button
			if button != null:
				_applyButtonStyle(button, button == quitButton, not _isLargeButton(button))

		var slider := child as HSlider
		if slider != null:
			slider.add_theme_stylebox_override("slider", _sliderTrackStyle())
			slider.add_theme_stylebox_override("grabber_area", _sliderFillStyle())
			slider.add_theme_icon_override("grabber", _sliderGrabberTexture())
			slider.add_theme_icon_override("grabber_highlight", _sliderGrabberTexture())

		_applyPaperControlTheme(child)


func _applyBodyLabelStyle(label: Label) -> void:
	label.add_theme_color_override("font_color", INK_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.96, 0.88, 0.68, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	if not label.has_theme_font_size_override("font_size"):
		label.add_theme_font_size_override("font_size", 18)


func _applyTitleLabelStyle(label: Label) -> void:
	_applyBodyLabelStyle(label)
	label.add_theme_color_override("font_color", Color("#1b1711"))
	label.add_theme_color_override("font_shadow_color", Color(0.95, 0.83, 0.53, 0.65))


func _applyMutedLabelStyle(label: Label) -> void:
	_applyBodyLabelStyle(label)
	label.add_theme_color_override("font_color", MUTED_LABEL_COLOR)


func _applyModalLabelStyle(label: Label) -> void:
	_applyBodyLabelStyle(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)


func _loadTexture(path: String) -> Texture2D:
	if textureCache.has(path):
		return textureCache[path] as Texture2D

	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		push_warning("MainMenu could not load UI texture: %s" % path)
		return null

	textureCache[path] = texture
	return texture


func _applyPanelStyle(panel: PanelContainer, texturePath: String) -> void:
	var style := StyleBoxTexture.new()
	style.texture = _loadTexture(texturePath)
	style.texture_margin_left = 40.0
	style.texture_margin_top = 40.0
	style.texture_margin_right = 40.0
	style.texture_margin_bottom = 40.0
	style.content_margin_left = 18.0
	style.content_margin_top = 18.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", style)


func _applyButtonStyle(button: Button, danger: bool, compact: bool = false) -> void:
	var normalTexture: String = BUTTON_DANGER_PATH if danger else BUTTON_DEFAULT_PATH
	var hoverTexture: String = BUTTON_DANGER_HOVER_PATH if danger else BUTTON_DEFAULT_HOVER_PATH
	var pressedTexture: String = BUTTON_DANGER_PRESSED_PATH if danger else BUTTON_DEFAULT_PRESSED_PATH
	var disabledTexture: String = BUTTON_DANGER_DISABLED_PATH if danger else BUTTON_DEFAULT_DISABLED_PATH
	button.add_theme_stylebox_override("normal", _buttonStyle(normalTexture, compact))
	button.add_theme_stylebox_override("hover", _buttonStyle(hoverTexture, compact))
	button.add_theme_stylebox_override("pressed", _buttonStyle(pressedTexture, compact))
	button.add_theme_stylebox_override("disabled", _buttonStyle(disabledTexture, compact))
	button.add_theme_stylebox_override("focus", _focusStyle())
	button.add_theme_color_override("font_color", Color("#2e2920"))
	button.add_theme_color_override("font_hover_color", Color("#2e2920"))
	button.add_theme_color_override("font_pressed_color", Color("#2e2920"))
	button.add_theme_color_override("font_hover_pressed_color", Color("#2e2920"))
	button.add_theme_color_override("font_disabled_color", Color("#5c5548"))
	button.add_theme_color_override("font_focus_color", Color("#2e2920"))
	button.add_theme_font_size_override("font_size", 18 if compact else 23)
	button.clip_text = true


func _buttonStyle(texturePath: String, compact: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _loadTexture(texturePath)
	if compact:
		style.texture_margin_left = 24.0
		style.texture_margin_top = 18.0
		style.texture_margin_right = 24.0
		style.texture_margin_bottom = 18.0
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 5.0
		style.content_margin_bottom = 5.0
	else:
		style.texture_margin_left = 32.0
		style.texture_margin_top = 24.0
		style.texture_margin_right = 32.0
		style.texture_margin_bottom = 24.0
		style.content_margin_left = 20.0
		style.content_margin_right = 20.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
	return style


func _sliderTrackStyle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#8d7650")
	style.border_color = Color("#2e2920")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _sliderFillStyle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#c39535")
	style.border_color = Color("#2e2920")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _sliderGrabberTexture() -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(12.0, 12.0)
	for y in range(24):
		for x in range(24):
			var distance := center.distance_to(Vector2(float(x), float(y)))
			if distance <= 9.0:
				image.set_pixel(x, y, Color("#c39535"))
			if distance >= 8.0 and distance <= 10.0:
				image.set_pixel(x, y, Color("#2e2920"))
	return ImageTexture.create_from_image(image)


func _focusStyle() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color("#c39535")
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.expand_margin_left = 2.0
	style.expand_margin_top = 2.0
	style.expand_margin_right = 2.0
	style.expand_margin_bottom = 2.0
	return style


func _menuButtons() -> Array[Button]:
	return [
		continueRunButton,
		newRunButton,
		shopButton,
		howToPlayButton,
		settingsButton,
		loadGameButton,
		creditsButton,
		quitButton,
		startAgeRunHiddenButton,
	]


func _isLargeButton(button: Button) -> bool:
	return button == continueRunButton \
		or button == newRunButton \
		or button == shopButton \
		or button == howToPlayButton \
		or button == settingsButton \
		or button == loadGameButton \
		or button == creditsButton \
		or button == quitButton \
		or button == startAgeRunHiddenButton \
		or button == primaryModalButton \
		or button == closeModalButton
