extends CanvasLayer


const RUN_STATE_VIEW := preload("res://src/core/view/run_state_view.gd")

@onready var rootControl: Control = $Root as Control
@onready var topBar = $Root/TopBar
@onready var leftPanel = $Root/LeftPanel
@onready var rightPanel = $Root/RightPanel
@onready var bottomBar = $Root/BottomBar
@onready var modalLayer: Control = $Root/ModalLayer as Control
@onready var escMenu = $Root/ModalLayer/EscMenu

var gameManager: GameManager
var eventBus: EventBus
var speedBeforePause: int = GameSpeed.Value.Normal


func _ready() -> void:
	_applyLayout()
	escMenu.resumeRequested.connect(_resumeFromEscMenu)
	escMenu.quitToMenuRequested.connect(_handleQuitToMenuStub)
	modalLayer.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var keyEvent := event as InputEventKey
	if keyEvent == null or not keyEvent.pressed or keyEvent.echo:
		return

	if keyEvent.keycode == KEY_ESCAPE:
		if modalLayer.visible:
			_resumeFromEscMenu()
		else:
			_openEscMenu()
		get_viewport().set_input_as_handled()


func configure(newGameManager: GameManager, newEventBus: EventBus) -> void:
	_disconnectEventBus()
	gameManager = newGameManager
	eventBus = newEventBus
	bottomBar.configure(eventBus)
	_connectEventBus()
	_refreshAll()


func isEscMenuOpen() -> bool:
	return modalLayer.visible


func _refreshAll() -> void:
	if gameManager == null:
		return

	var runState := gameManager.getCurrentRunState()
	if runState == null:
		return

	topBar.setData(RUN_STATE_VIEW.createTopBarData(runState))
	leftPanel.setData(RUN_STATE_VIEW.createArmyPanelData(runState, gameManager.getSelectedArmyId()))
	rightPanel.setData(RUN_STATE_VIEW.createCountryPanelData(runState, gameManager.getSelectedCountryId()))
	bottomBar.setCurrentSpeed(int(runState.speed))


func _onGameEventRaised(eventName: StringName, _payload: Dictionary) -> void:
	match eventName:
		EventType.RUN_STARTED, EventType.RUN_RESET, EventType.COUNTRY_SELECTED, EventType.ARMY_SELECTED, EventType.ARMY_MOVE_STARTED, EventType.ARMY_MOVED, EventType.GAME_SPEED_CHANGED, EventType.MONTH_TICK:
			_refreshAll()


func _openEscMenu() -> void:
	if gameManager != null and gameManager.getCurrentRunState() != null:
		var currentSpeed := int(gameManager.getCurrentRunState().speed)
		if currentSpeed != GameSpeed.Value.Paused:
			speedBeforePause = currentSpeed

	if eventBus != null:
		eventBus.requestCommand(CommandType.PAUSE_GAME)
	modalLayer.visible = true
	_refreshAll()


func _resumeFromEscMenu() -> void:
	modalLayer.visible = false
	if eventBus != null:
		eventBus.requestCommand(CommandType.SET_GAME_SPEED, {
			"speed": speedBeforePause,
		})
	_refreshAll()


func _handleQuitToMenuStub() -> void:
	push_warning("Quit to menu is not implemented yet.")


func _connectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if not eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.connect(eventCallable)


func _disconnectEventBus() -> void:
	if eventBus == null:
		return

	var eventCallable := Callable(self, "_onGameEventRaised")
	if eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.disconnect(eventCallable)


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
	leftPanel.offset_bottom = -88.0

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
	escMenu.offset_top = -90.0
	escMenu.offset_right = 140.0
	escMenu.offset_bottom = 90.0
