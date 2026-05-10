extends CanvasLayer


const RUN_STATE_VIEW := preload("res://src/core/view/run_state_view.gd")
const SHOP_PANEL_SCRIPT := preload("res://scenes/ui/shop_panel.gd")
const SETTINGS_PANEL_SCRIPT := preload("res://scenes/ui/settings_panel.gd")
const DEBUG_ERROR_OVERLAY_SCRIPT := preload("res://scenes/ui/debug_error_overlay.gd")
const INPUT_ACTIONS := preload("res://src/core/input/input_actions.gd")

@onready var rootControl: Control = $Root as Control
@onready var topBar = $Root/TopBar
@onready var leftPanel = $Root/LeftPanel
@onready var miniGoalPanel = $Root/MiniGoalPanel
@onready var rightPanel = $Root/RightPanel
@onready var bottomBar = $Root/BottomBar
@onready var modalLayer: Control = $Root/ModalLayer as Control
@onready var escMenu = $Root/ModalLayer/EscMenu
@onready var upgradeModal = $Root/ModalLayer/UpgradeModal

var gameManager: GameManager
var eventBus: EventBus
var settingsManager
var speedBeforePause: int = GameSpeed.Value.Normal
var shopPanel: PanelContainer
var settingsPanel: PanelContainer
var debugErrorOverlay: PanelContainer


func _ready() -> void:
	_applyLayout()
	escMenu.resumeRequested.connect(_resumeFromEscMenu)
	escMenu.saveRequested.connect(_saveFromEscMenu)
	escMenu.loadRequested.connect(_loadFromEscMenu)
	escMenu.shopRequested.connect(_openShopPanel)
	escMenu.settingsRequested.connect(_openSettingsPanel)
	escMenu.quitToMenuRequested.connect(_handleQuitToMenuStub)
	_ensureShopPanel()
	_ensureSettingsPanel()
	_ensureDebugErrorOverlay()
	upgradeModal.visible = false
	shopPanel.visible = false
	settingsPanel.visible = false
	modalLayer.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var keyEvent := event as InputEventKey
	if keyEvent == null or not keyEvent.pressed or keyEvent.echo:
		return

	if event.is_action_pressed(INPUT_ACTIONS.ACTION_OPEN_MENU):
		if upgradeModal.visible:
			pass
		elif shopPanel != null and shopPanel.visible:
			_closeShopPanel()
		elif settingsPanel != null and settingsPanel.visible:
			_closeSettingsPanel()
		elif modalLayer.visible:
			_resumeFromEscMenu()
		else:
			_openEscMenu()
		get_viewport().set_input_as_handled()
	elif not modalLayer.visible:
		_handleSpeedHotkey(event)


func configure(newGameManager: GameManager, newEventBus: EventBus, newSettingsManager = null) -> void:
	_disconnectEventBus()
	_disconnectSettingsManager()
	gameManager = newGameManager
	eventBus = newEventBus
	settingsManager = newSettingsManager
	bottomBar.configure(eventBus)
	rightPanel.configure(eventBus)
	miniGoalPanel.configure(eventBus)
	upgradeModal.configure(eventBus)
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
	leftPanel.setData(RUN_STATE_VIEW.createArmyPanelData(runState, gameManager.getSelectedArmyId()))
	miniGoalPanel.setData(RUN_STATE_VIEW.createMiniGoalPanelData(runState))
	rightPanel.setData(RUN_STATE_VIEW.createCountryPanelData(runState, gameManager.getSelectedCountryId()))
	bottomBar.setCurrentSpeed(int(runState.speed))
	if shopPanel != null and shopPanel.visible:
		shopPanel.call("setData", gameManager.getShopPanelData())
	_refreshSettingsPanel()


func _onGameEventRaised(eventName: StringName, payload: Dictionary) -> void:
	match eventName:
		EventType.UPGRADE_CHOICE_OPENED:
			_openUpgradeModal(payload)
		EventType.UPGRADE_CHOSEN:
			_closeUpgradeModal()
			_refreshAll()
		EventType.RUN_STARTED, EventType.RUN_RESET, EventType.COUNTRY_SELECTED, EventType.ARMY_SELECTED, EventType.ARMY_MOVE_STARTED, EventType.ARMY_MOVED, EventType.UNITS_RECRUITED, EventType.ARMY_CREATED, EventType.BATTLE_STARTED, EventType.BATTLE_ENDED, EventType.COUNTRY_CONQUERED, EventType.MINI_GOAL_REWARD_CLAIMED, EventType.META_PROGRESS_CHANGED, EventType.META_UPGRADE_PURCHASED, EventType.CROWNS_REWARDED, EventType.THREAT_CHANGED, EventType.WORLD_REACTION_UPDATED, EventType.GAME_SPEED_CHANGED, EventType.MONTH_TICK:
			_refreshAll()


func _openEscMenu() -> void:
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
	if shopPanel != null:
		shopPanel.visible = false
	if settingsPanel != null:
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
	modalLayer.visible = false
	_refreshAll()


func _handleQuitToMenuStub() -> void:
	push_warning("Quit to menu is not implemented yet.")


func setUiScale(uiScale: float) -> void:
	if rootControl == null:
		return

	var clampedScale := clampf(uiScale, 0.8, 1.4)
	rootControl.scale = Vector2(clampedScale, clampedScale)


func _openShopPanel() -> void:
	_ensureShopPanel()
	escMenu.visible = false
	if settingsPanel != null:
		settingsPanel.visible = false
	shopPanel.visible = true
	modalLayer.visible = true
	if gameManager != null:
		shopPanel.call("setData", gameManager.getShopPanelData())


func _closeShopPanel() -> void:
	if shopPanel == null:
		return

	shopPanel.visible = false
	if not escMenu.visible and not upgradeModal.visible and (settingsPanel == null or not settingsPanel.visible):
		modalLayer.visible = false


func _purchaseMetaUpgrade(upgradeId: StringName) -> void:
	if eventBus != null:
		eventBus.requestCommand(CommandType.PURCHASE_META_UPGRADE, {
			"upgradeId": str(upgradeId),
		})
	if gameManager != null and shopPanel != null:
		shopPanel.call("setData", gameManager.getShopPanelData())


func _openSettingsPanel() -> void:
	_ensureSettingsPanel()
	escMenu.visible = false
	if shopPanel != null:
		shopPanel.visible = false
	settingsPanel.visible = true
	modalLayer.visible = true
	_refreshSettingsPanel()


func _closeSettingsPanel() -> void:
	if settingsPanel == null:
		return

	settingsPanel.visible = false
	if not escMenu.visible and not upgradeModal.visible and (shopPanel == null or not shopPanel.visible):
		modalLayer.visible = false


func _changeSetting(settingKey: StringName, value: Variant) -> void:
	if settingsManager == null:
		return

	settingsManager.updateSetting(settingKey, value)
	_refreshSettingsPanel()


func _openUpgradeModal(data: Dictionary) -> void:
	escMenu.visible = false
	if shopPanel != null:
		shopPanel.visible = false
	if settingsPanel != null:
		settingsPanel.visible = false
	upgradeModal.visible = true
	upgradeModal.setData(data)
	modalLayer.visible = true
	_refreshAll()


func _closeUpgradeModal() -> void:
	upgradeModal.visible = false
	if not escMenu.visible and (shopPanel == null or not shopPanel.visible) and (settingsPanel == null or not settingsPanel.visible):
		modalLayer.visible = false


func _ensureShopPanel() -> void:
	if shopPanel != null:
		return

	shopPanel = SHOP_PANEL_SCRIPT.new() as PanelContainer
	shopPanel.name = "ShopPanel"
	shopPanel.visible = false
	modalLayer.add_child(shopPanel)
	_positionShopPanel()
	shopPanel.connect("purchaseRequested", Callable(self, "_purchaseMetaUpgrade"))
	shopPanel.connect("closeRequested", Callable(self, "_closeShopPanel"))


func _positionShopPanel() -> void:
	if shopPanel == null:
		return

	shopPanel.set_anchors_preset(Control.PRESET_CENTER)
	shopPanel.offset_left = -260.0
	shopPanel.offset_top = -230.0
	shopPanel.offset_right = 260.0
	shopPanel.offset_bottom = 230.0


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


func _positionSettingsPanel() -> void:
	if settingsPanel == null:
		return

	settingsPanel.set_anchors_preset(Control.PRESET_CENTER)
	settingsPanel.offset_left = -210.0
	settingsPanel.offset_top = -150.0
	settingsPanel.offset_right = 210.0
	settingsPanel.offset_bottom = 150.0


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

	topBar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topBar.offset_left = 0.0
	topBar.offset_top = 0.0
	topBar.offset_right = 0.0
	topBar.offset_bottom = 56.0

	leftPanel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	leftPanel.offset_left = 16.0
	leftPanel.offset_top = 72.0
	leftPanel.offset_right = 296.0
	leftPanel.offset_bottom = -360.0

	miniGoalPanel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	miniGoalPanel.offset_left = 16.0
	miniGoalPanel.offset_top = -344.0
	miniGoalPanel.offset_right = 296.0
	miniGoalPanel.offset_bottom = -88.0

	rightPanel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	rightPanel.offset_left = -356.0
	rightPanel.offset_top = 72.0
	rightPanel.offset_right = -16.0
	rightPanel.offset_bottom = -88.0

	bottomBar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottomBar.offset_left = 0.0
	bottomBar.offset_top = -72.0
	bottomBar.offset_right = 0.0
	bottomBar.offset_bottom = 0.0

	modalLayer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modalLayer.offset_left = 0.0
	modalLayer.offset_top = 0.0
	modalLayer.offset_right = 0.0
	modalLayer.offset_bottom = 0.0
	modalLayer.mouse_filter = Control.MOUSE_FILTER_STOP

	escMenu.set_anchors_preset(Control.PRESET_CENTER)
	escMenu.offset_left = -140.0
	escMenu.offset_top = -130.0
	escMenu.offset_right = 140.0
	escMenu.offset_bottom = 130.0

	upgradeModal.set_anchors_preset(Control.PRESET_CENTER)
	upgradeModal.offset_left = -260.0
	upgradeModal.offset_top = -190.0
	upgradeModal.offset_right = 260.0
	upgradeModal.offset_bottom = 190.0
