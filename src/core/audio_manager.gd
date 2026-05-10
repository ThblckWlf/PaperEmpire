extends Node
class_name AudioManager


const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"

const SOUND_UI_CLICK: StringName = &"uiClick"
const SOUND_BATTLE_START: StringName = &"battleStart"
const SOUND_COUNTRY_CONQUERED: StringName = &"countryConquered"
const SOUND_MISSILE_LAUNCH: StringName = &"missileLaunch"
const SOUND_EXPLOSION: StringName = &"explosion"

const SAMPLE_RATE: int = 22050
const STUB_PLAYER_PREFIX: String = "AudioStub"

var eventBus: EventBus
var stubStreams: Dictionary = {}


func _ready() -> void:
	ensureAudioBuses()


func _exit_tree() -> void:
	_disconnectEventBus()
	stopAllStubs()


func configure(newEventBus: EventBus) -> void:
	_disconnectEventBus()
	eventBus = newEventBus
	_connectEventBus()
	ensureAudioBuses()


func ensureAudioBuses() -> void:
	_ensureBus(BUS_MUSIC)
	_ensureBus(BUS_SFX)
	_ensureBus(BUS_UI)


func playSfx(soundId: StringName) -> void:
	_playStub(soundId, BUS_SFX)


func playUiSfx(soundId: StringName = SOUND_UI_CLICK) -> void:
	_playStub(soundId, BUS_UI)


func playMusic(_musicId: StringName) -> void:
	# Music assets are intentionally not part of Phase 18.
	pass


func stopMusic() -> void:
	pass


func setMasterVolume(linearVolume: float) -> void:
	setBusVolume(BUS_MASTER, linearVolume)


func setMusicVolume(linearVolume: float) -> void:
	setBusVolume(BUS_MUSIC, linearVolume)


func setSfxVolume(linearVolume: float) -> void:
	setBusVolume(BUS_SFX, linearVolume)


func setUiVolume(linearVolume: float) -> void:
	setBusVolume(BUS_UI, linearVolume)


func setBusVolume(busName: String, linearVolume: float) -> void:
	var busIndex := AudioServer.get_bus_index(busName)
	if busIndex < 0:
		return

	AudioServer.set_bus_volume_db(busIndex, _linearToDb(linearVolume))


func setBusMuted(busName: String, muted: bool) -> void:
	var busIndex := AudioServer.get_bus_index(busName)
	if busIndex < 0:
		return

	AudioServer.set_bus_mute(busIndex, muted)


func stopAllStubs() -> void:
	for child in get_children():
		var player := child as AudioStreamPlayer
		if player == null or not str(player.name).begins_with(STUB_PLAYER_PREFIX):
			continue

		player.stop()
		player.stream = null
		player.free()
	stubStreams.clear()


func getActiveStubPlayerCount() -> int:
	var count := 0
	for child in get_children():
		if child is AudioStreamPlayer and str(child.name).begins_with(STUB_PLAYER_PREFIX):
			count += 1
	return count


func _onCommandRequested(_commandName: StringName, _payload: Dictionary) -> void:
	playUiSfx()


func _onGameEventRaised(eventName: StringName, _payload: Dictionary) -> void:
	match eventName:
		EventType.BATTLE_STARTED:
			playSfx(SOUND_BATTLE_START)
		EventType.COUNTRY_CONQUERED:
			playSfx(SOUND_COUNTRY_CONQUERED)
		EventType.MISSILE_LAUNCHED:
			playSfx(SOUND_MISSILE_LAUNCH)


func _playStub(soundId: StringName, busName: String) -> void:
	ensureAudioBuses()
	var stream := _streamForSound(soundId)
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.name = "%s_%s" % [STUB_PLAYER_PREFIX, str(soundId)]
	player.bus = busName
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	if DisplayServer.get_name() != "headless":
		player.play()


func _streamForSound(soundId: StringName) -> AudioStreamWAV:
	if stubStreams.has(soundId):
		return stubStreams[soundId] as AudioStreamWAV

	var frequency := 440.0
	var duration := 0.08
	var volume := 0.22
	match soundId:
		SOUND_UI_CLICK:
			frequency = 880.0
			duration = 0.035
			volume = 0.12
		SOUND_BATTLE_START:
			frequency = 180.0
			duration = 0.16
			volume = 0.2
		SOUND_COUNTRY_CONQUERED:
			frequency = 660.0
			duration = 0.18
			volume = 0.18
		SOUND_MISSILE_LAUNCH:
			frequency = 320.0
			duration = 0.2
			volume = 0.16
		SOUND_EXPLOSION:
			frequency = 90.0
			duration = 0.24
			volume = 0.28

	var stream := _createToneStream(frequency, duration, volume)
	stubStreams[soundId] = stream
	return stream


func _createToneStream(frequency: float, durationSeconds: float, volume: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var sampleCount := int(float(SAMPLE_RATE) * durationSeconds)
	for sampleIndex in range(sampleCount):
		var progress := float(sampleIndex) / maxf(float(sampleCount), 1.0)
		var envelope := 1.0 - progress
		var sampleValue := sin(TAU * frequency * float(sampleIndex) / float(SAMPLE_RATE)) * volume * envelope
		var packedSample := int(clampf(sampleValue, -1.0, 1.0) * 32767.0)
		if packedSample < 0:
			packedSample += 65536
		data.append(packedSample & 0xff)
		data.append((packedSample >> 8) & 0xff)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _ensureBus(busName: String) -> void:
	if AudioServer.get_bus_index(busName) >= 0:
		return

	var busIndex := AudioServer.get_bus_count()
	AudioServer.add_bus(busIndex)
	AudioServer.set_bus_name(busIndex, busName)
	AudioServer.set_bus_send(busIndex, BUS_MASTER)


func _linearToDb(linearVolume: float) -> float:
	var clampedVolume := clampf(linearVolume, 0.0, 1.0)
	if clampedVolume <= 0.001:
		return -80.0
	return linear_to_db(clampedVolume)


func _connectEventBus() -> void:
	if eventBus == null:
		return

	var commandCallable := Callable(self, "_onCommandRequested")
	if not eventBus.commandRequested.is_connected(commandCallable):
		eventBus.commandRequested.connect(commandCallable)

	var eventCallable := Callable(self, "_onGameEventRaised")
	if not eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.connect(eventCallable)


func _disconnectEventBus() -> void:
	if eventBus == null:
		return

	var commandCallable := Callable(self, "_onCommandRequested")
	if eventBus.commandRequested.is_connected(commandCallable):
		eventBus.commandRequested.disconnect(commandCallable)

	var eventCallable := Callable(self, "_onGameEventRaised")
	if eventBus.gameEventRaised.is_connected(eventCallable):
		eventBus.gameEventRaised.disconnect(eventCallable)
