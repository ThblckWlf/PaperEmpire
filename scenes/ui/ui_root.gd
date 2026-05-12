extends CanvasLayer


signal newRunRequested(startCountryId: String)
signal loadGameRequested(slotId: String)
signal returnToMainMenuRequested
signal quitGameRequested
signal gameplayVisibilityChanged(isVisible: bool)

const RUN_STATE_VIEW := preload("res://src/core/view/run_state_view.gd")
const SETTINGS_PANEL_SCRIPT := preload("res://scenes/ui/settings_panel.gd")
const DEBUG_ERROR_OVERLAY_SCRIPT := preload("res://scenes/ui/debug_error_overlay.gd")
const GAME_OVER_MODAL_SCRIPT := preload("res://scenes/ui/game_over_modal.gd")
const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/MainMenu.tscn")

@onready var rootControl: Control = $Root as Control
@onready var topBar = $Root/TopBar
@onready var leftPanel = $Root/LeftPanel
@onready var rightPanel = $Root/RightPanel
@onready var bottomBar = $Root/BottomBar
@onready var modalLayer: Control = $Root/ModalLayer as Control
@onready var escMenu = $Root/ModalLayer/EscMenu
@onready var upgradeModal = $Root/ModalLayer/UpgradeModal

var gameManager: GameManager
var eventBus: EventBus
var settingsManager
var saveManager: SaveManager
var speedBeforePause: int = GameSpeed.Value.Normal
var settingsPanel: PanelContainer
var debugErrorOverlay: PanelContainer
var gameOverModal: PanelContainer
var mainMenu: Control
var gameplayVisible: bool = true


func _ready() -> void:
	_applyLayout()
	escMenu.resumeRequested.connect(_resumeFromEscMenu)
	escMenu.saveRequested.connect(_saveFromEscMenu)
	escMenu.loadRequested.connect(_loadFromEscMenu)
	escMenu.settingsRequested.connect(_openSettingsPanel)
	escMenu.returnToMainMenuRequested.connect(_handleReturnToMainMenuRequested)
	escMenu.quitGameRequested.connect(_handleQuitGameRequested)
	_ensureMainMenu()
	_ensureSettingsPanel()
	_ensureDebugErrorOverlay()
	_ensureGameOverModal()
	upgradeModal.visible = false
	gameOverModal.visible = false
	settingsPanel.visible = false
	modalLayer.visible = false


func _input(event: InputEvent) -> void:
	if not gameplayVisible or modalLayer.visible:
		return
	if _isTextFieldFocused():
		return
	if eventBus == null:
		return

	# Intercept Tab in _input so it routes to army cycling instead of UI focus traversal.
	if event.is_action_pressed(INPUT_ACTIONS.ACTION_PREVIOUS_ARMY, false, true):
		eventBus.requestCommand(CommandType.SELECT_PREVIOUS_PLAYER_ARMY)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(INPUT_ACTIONS.ACTION_NEXT_ARMY, false, true):
		eventBus.requestCommand(CommandType.SELECT_NEXT_PLAYER_ARMY)
		get_viewport().set_input_as_handled()


func _isTextFieldFocused() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var focusOwner := viewport.gui_get_focus_owner()
	return focusOwner is LineEdit or focusOwner is TextEdit or focusOwner is SpinBox


func _unhandled_input(event: InputEvent) -> void:
	var keyEvent := event as InputEventKey
	if keyEvent == null or not keyEvent.pressed or keyEvent.echo:
		return

	if event.is_action_pressed(INPUT_ACTIONS.ACTION_OPEN_MENU):
		if mainMenu != null and mainMenu.visible:
			if bool(mainMenu.call("closeOpenPanel")):
				get_viewport().set_input_as_handled()
		elif not gameplayVisible:
			pass
		elif gameOverModal != null and gameOverModal.visible:
			pass
		elif upgradeModal.visible:
			pass
		elif settingsPanel != null and settingsPanel.visible:
			_closeSettingsPanel()
		elif modalLayer.visible:
			_resumeFromEscMenu()
		else:
			_openEscMenu()
		get_viewport().set_input_as_handled()
	elif not modalLayer.visible:
		_handleSpeedHotkey(event)


func configure(
	newGameManager: GameManager,
	newEventBus: EventBus,
	newSettingsManager = null,
	newSaveManager: SaveManager = null
) -> void:
	_disconnectEventBus()
	_disconnectSettingsManager()
	gameManager = newGameManager
	eventBus = newEventBus
	settingsManager = newSettingsManager
	saveManager = newSaveManager
	bottomBar.configure(eventBus)
	leftPanel.configure(eventBus)
	rightPanel.configure(eventBus)
	upgradeModal.configure(eventBus)
	if mainMenu != null:
		mainMenu.call("configure", gameManager, eventBus, settingsManager, saveManager)
	_connectEventBus()
	_connectSettingsManager()
	_refreshSettingsPanel()
	_refreshAll()


func isEscMenuOpen() -> bool:
	return modalLayer.visible and escMenu.visible


func _refreshAll() -> void:
	if gameManager == null:
		return

	var runState := gameManager.getCurrentRunState()
	if runState == null:
		return

	topBar.setData(RUN_STATE_VIEW.createTopBarData(runState))
	leftPanel.setData(RUN_STATE_VIEW.createArmyPanelData(runState, gameManager.getSelectedArmyId(), gameManager.getSelectedCountryId()))
	rightPanel.setData(RUN_STATE_VIEW.createCountryPanelData(runState, gameManager.getSelectedCountryId(), gameManager.getSelectedArmyId()))
	bottomBar.setCurrentSpeed(int(runState.speed))
	if mainMenu != null and mainMenu.visible:
		mainMenu.call("refreshSaveStatus")
	_refreshSettingsPanel()


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	match eventName:
		EventType.GAME_OVER_TRIGGERED:
			_openGameOverModal(payload)
		EventType.UPGRADE_CHOICE_OPENED:
			_openUpgradeModal(payload)
		EventType.UPGRADE_CHOSEN:
			_closeUpgradeModal()
			_refreshAll()
		EventType.RUN_STARTED, EventType.RUN_RESET:
			_closeGameOverModal()
			_refreshAll()
		EventType.RUN_WON, EventType.RUN_LOST, EventType.COUNTRY_SELECTED, EventType.ARMY_SELECTED, EventType.ARMY_MOVE_STARTED, EventType.ARMY_MOVED, EventType.UNITS_RECRUITED, EventType.ARMY_UPDATED, EventType.ARMY_CREATED, EventType.BATTLE_STARTED, EventType.BATTLE_ENDED, EventType.COUNTRY_CONQUERED, EventType.META_PROGRESS_CHANGED, EventType.META_UPGRADE_PURCHASED, EventType.CROWNS_AWARDED, EventType.CROWNS_REWARDED, EventType.THREAT_CHANGED, EventType.WORLD_REACTION_UPDATED, EventType.GAME_SPEED_CHANGED, EventType.MONTH_TICK, EventType.NOT_ENOUGH_GOLD, EventType.INVALID_ATTACK:
			_refreshAll()


func _openEscMenu() -> void:
	if not gameplayVisible:
		return
	if gameOverModal != null and gameOverModal.visible:
		return
	if upgradeModal.visible:
		return

	if gameManager != null and gameManager.getCurrentRunState() != null:
		var currentSpeed := int(gameManager.getCurrentRunState().speed)
		if currentSpeed != GameSpeed.Value.Paused:
			speedBeforePause = currentSpeed

	if eventBus != null:
		eventBus.requestCommand(CommandType.PAUSE_GAME)
	escMenu.visible = true
	modalLayer.visible = true
	_refreshAll()


func _resumeFromEscMenu() -> void:
	escMenu.visible = false
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false
	modalLayer.visible = false
	if eventBus != null:
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": speedBeforePause,
		})
	_refreshAll()


func _saveFromEscMenu() -> void:
	if eventBus != null:
		eventBus.requestCommand(CommandType.SAVE_GAME, {
			"slotId": "manual_1",
		})
	_refreshAll()


func _loadFromEscMenu() -> void:
	if eventBus != null:
		eventBus.requestCommand(CommandType.LOAD_GAME, {
			"slotId": "manual_1",
		})
	escMenu.visible = false
	if gameOverModal == null or not gameOverModal.visible:
		modalLayer.visible = false
	_refreshAll()


func _handleReturnToMainMenuRequested() -> void:
	returnToMainMenuRequested.emit()


func _handleQuitGameRequested() -> void:
	quitGameRequested.emit()


func setUiScale(uiScale: float) -> void:
	if rootControl == null:
		return

	var clampedScale := clampf(uiScale, 0.8, 1.4)
	rootControl.scale = Vector2(clampedScale, clampedScale)


func showMainMenu() -> void:
	_ensureMainMenu()
	escMenu.visible = false
	upgradeModal.visible = false
	if gameOverModal != null:
		gameOverModal.visible = false
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false
	modalLayer.visible = false
	mainMenu.visible = true
	mainMenu.call("refreshSaveStatus")
	_setGameplayVisible(false)


func showGameplay() -> void:
	if mainMenu != null:
		mainMenu.visible = false
	_setGameplayVisible(true)
	_refreshAll()


func isMainMenuVisible() -> bool:
	return mainMenu != null and mainMenu.visible


func _setGameplayVisible(isVisible: bool) -> void:
	if gameplayVisible == isVisible:
		return

	gameplayVisible = isVisible
	topBar.visible = isVisible
	leftPanel.visible = isVisible
	rightPanel.visible = isVisible
	bottomBar.visible = isVisible
	if not isVisible:
		modalLayer.visible = false
	gameplayVisibilityChanged.emit(isVisible)


func _ensureMainMenu() -> void:
	if mainMenu != null:
		return

	mainMenu = MAIN_MENU_SCENE.instantiate() as Control
	mainMenu.name = "MainMenu"
	rootControl.add_child(mainMenu)
	mainMenu.call("configure", gameManager, eventBus, settingsManager, saveManager)
	mainMenu.connect("newRunRequested", Callable(self, "_handleMainMenuNewRunRequested"))
	mainMenu.connect("loadGameRequested", Callable(self, "_handleMainMenuLoadGameRequested"))
	mainMenu.connect("quitGameRequested", Callable(self, "_handleQuitGameRequested"))


func _handleMainMenuNewRunRequested(startCountryId: String) -> void:
	newRunRequested.emit(startCountryId)


func _handleMainMenuLoadGameRequested(slotId: String) -> void:
	loadGameRequested.emit(slotId)


func _openSettingsPanel() -> void:
	_ensureSettingsPanel()
	escMenu.visible = false
	settingsPanel.visible = true
	modalLayer.visible = true
	_refreshSettingsPanel()


func _closeSettingsPanel() -> void:
	if settingsPanel == null:
		return

	_discardSettingsPanelChanges()
	settingsPanel.visible = false
	if not escMenu.visible and not upgradeModal.visible and (gameOverModal == null or not gameOverModal.visible):
		modalLayer.visible = false


func _changeSetting(settingKey: StringName, value: Variant) -> void:
	if settingsManager == null:
		return

	settingsManager.updateSetting(settingKey, value)
	_refreshSettingsPanel()


func _openUpgradeModal(data: Dictionary) -> void:
	escMenu.visible = false
	if gameOverModal != null:
		gameOverModal.visible = false
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false
	upgradeModal.visible = true
	upgradeModal.setData(data)
	modalLayer.visible = true
	_refreshAll()


func _closeUpgradeModal() -> void:
	upgradeModal.visible = false
	if not escMenu.visible and (settingsPanel == null or not settingsPanel.visible) and (gameOverModal == null or not gameOverModal.visible):
		modalLayer.visible = false


func _openGameOverModal(data: Dictionary) -> void:
	_ensureGameOverModal()
	escMenu.visible = false
	upgradeModal.visible = false
	if settingsPanel != null:
		_discardSettingsPanelChanges()
		settingsPanel.visible = false
	gameOverModal.visible = true
	gameOverModal.call("setData", data)
	modalLayer.visible = true
	_refreshAll()


func _closeGameOverModal() -> void:
	if gameOverModal == null:
		return

	gameOverModal.visible = false
	if not escMenu.visible and not upgradeModal.visible and (settingsPanel == null or not settingsPanel.visible):
		modalLayer.visible = false


func _discardSettingsPanelChanges() -> void:
	if settingsPanel != null and settingsPanel.has_method("discardPendingChanges"):
		settingsPanel.call("discardPendingChanges")


func _ensureSettingsPanel() -> void:
	if settingsPanel != null:
		return

	settingsPanel = SETTINGS_PANEL_SCRIPT.new() as PanelContainer
	settingsPanel.name = "SettingsPanel"
	settingsPanel.visible = false
	modalLayer.add_child(settingsPanel)
	_positionSettingsPanel()
	settingsPanel.connect("settingChanged", Callable(self, "_changeSetting"))
	settingsPanel.connect("closeRequested", Callable(self, "_closeSettingsPanel"))


func _ensureGameOverModal() -> void:
	if gameOverModal != null:
		return

	gameOverModal = GAME_OVER_MODAL_SCRIPT.new() as PanelContainer
	gameOverModal.name = "GameOverModal"
	gameOverModal.visible = false
	modalLayer.add_child(gameOverModal)
	_positionGameOverModal()
	gameOverModal.connect("returnToMainMenuRequested", Callable(self, "_handleGameOverReturnToMainMenuRequested"))


func _positionSettingsPanel() -> void:
	if settingsPanel == null:
		return

	settingsPanel.set_anchors_preset(Control.PRESET_CENTER)
	settingsPanel.offset_left = -210.0
	settingsPanel.offset_top = -150.0
	settingsPanel.offset_right = 210.0
	settingsPanel.offset_bottom = 150.0


func _positionGameOverModal() -> void:
	if gameOverModal == null:
		return

	gameOverModal.set_anchors_preset(Control.PRESET_CENTER)
	gameOverModal.offset_left = -260.0
	gameOverModal.offset_top = -220.0
	gameOverModal.offset_right = 260.0
	gameOverModal.offset_bottom = 220.0


func _handleGameOverReturnToMainMenuRequested() -> void:
	_closeGameOverModal()
	returnToMainMenuRequested.emit()


func _ensureDebugErrorOverlay() -> void:
	if debugErrorOverlay != null:
		return

	debugErrorOverlay = DEBUG_ERROR_OVERLAY_SCRIPT.new() as PanelContainer
	debugErrorOverlay.name = "DebugErrorOverlay"
	rootControl.add_child(debugErrorOverlay)
	_positionDebugErrorOverlay()


func _positionDebugErrorOverlay() -> void:
	if debugErrorOverlay == null:
		return

	debugErrorOverlay.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	debugErrorOverlay.offset_left = 16.0
	debugErrorOverlay.offset_top = -64.0
	debugErrorOverlay.offset_right = 420.0
	debugErrorOverlay.offset_bottom = -16.0


func _refreshSettingsPanel() -> void:
	if settingsManager == null or settingsPanel == null or not settingsPanel.visible:
		return

	settingsPanel.call("setData", settingsManager.getSettingsData())


func _handleSpeedHotkey(event: InputEvent) -> void:
	if eventBus == null:
		return

	if event.is_action_pressed(INPUT_ACTIONS.ACTION_PAUSE):
		eventBus.requestCommand(CommandType.PAUSE_GAME)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(INPUT_ACTIONS.ACTION_SPEED_NORMAL):
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.Normal,
		})
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(INPUT_ACTIONS.ACTION_SPEED_FAST):
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.Fast,
		})
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(INPUT_ACTIONS.ACTION_SPEED_VERY_FAST):
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": GameSpeed.Value.VeryFast,
		})
		get_viewport().set_input_as_handled()


func _showDebugError(message: String) -> void:
	if debugErrorOverlay == null:
		return

	debugErrorOverlay.call("showDebugError", message)


func _connectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if not eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.connect(eventCallable)

	var debugCallable := Callable(self, "_showDebugError")
	if not eventBus.debugErrorReported.is_connected(debugCallable):
		eventBus.debugErrorReported.connect(debugCallable)


func _disconnectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.disconnect(eventCallable)

	var debugCallable := Callable(self, "_showDebugError")
	if eventBus.debugErrorReported.is_connected(debugCallable):
		eventBus.debugErrorReported.disconnect(debugCallable)


func _connectSettingsManager() -> void:
	if settingsManager == null:
		return
	if not settingsManager.has_signal("settingsChanged"):
		return

	var changedCallable := Callable(self, "_onSettingsChanged")
	if not settingsManager.settingsChanged.is_connected(changedCallable):
		settingsManager.settingsChanged.connect(changedCallable)


func _disconnectSettingsManager() -> void:
	if settingsManager == null:
		return
	if not settingsManager.has_signal("settingsChanged"):
		return

	var changedCallable := Callable(self, "_onSettingsChanged")
	if settingsManager.settingsChanged.is_connected(changedCallable):
		settingsManager.settingsChanged.disconnect(changedCallable)


func _onSettingsChanged(_settingsData: Dictionary) -> void:
	_refreshSettingsPanel()


func _applyLayout() -> void:
	rootControl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rootControl.offset_left = 0.0
	rootControl.offset_top = 0.0
	rootControl.offset_right = 0.0
	rootControl.offset_bottom = 0.0
	rootControl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	topBar.anchor_left = 0.5
	topBar.anchor_top = 0.0
	topBar.anchor_right = 0.5
	topBar.anchor_bottom = 0.0
	topBar.offset_left = -880.0
	topBar.offset_top = 12.0
	topBar.offset_right = 880.0
	topBar.offset_bottom = 116.0

	leftPanel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	leftPanel.offset_left = 18.0
	leftPanel.offset_top = 130.0
	leftPanel.offset_right = 350.0
	leftPanel.offset_bottom = 560.0

	rightPanel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rightPanel.offset_left = -370.0
	rightPanel.offset_top = 130.0
	rightPanel.offset_right = -18.0
	rightPanel.offset_bottom = 500.0

	bottomBar.anchor_left = 0.5
	bottomBar.anchor_right = 0.5
	bottomBar.anchor_top = 1.0
	bottomBar.anchor_bottom = 1.0
	bottomBar.offset_left = -260.0
	bottomBar.offset_top = -96.0
	bottomBar.offset_right = 260.0
	bottomBar.offset_bottom = -18.0

	modalLayer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modalLayer.offset_left = 0.0
	modalLayer.offset_top = 0.0
	modalLayer.offset_right = 0.0
	modalLayer.offset_bottom = 0.0
	modalLayer.mouse_filter = Control.MOUSE_FILTER_STOP

	escMenu.set_anchors_preset(Control.PRESET_CENTER)
	escMenu.offset_left = -170.0
	escMenu.offset_top = -210.0
	escMenu.offset_right = 170.0
	escMenu.offset_bottom = 210.0

	upgradeModal.set_anchors_preset(Control.PRESET_CENTER)
	upgradeModal.offset_left = -520.0
	upgradeModal.offset_top = -320.0
	upgradeModal.offset_right = 520.0
	upgradeModal.offset_bottom = 320.0
