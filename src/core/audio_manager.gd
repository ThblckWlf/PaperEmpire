extends Node
class_name AudioManager


func playSfx(_soundId: StringName) -> void:
	# TODO: Route SFX playback through configured audio buses in a later audio step.
	pass


func playMusic(_musicId: StringName) -> void:
	# TODO: Start or crossfade music once music assets and buses exist.
	pass


func stopMusic() -> void:
	# TODO: Stop active music playback once AudioStreamPlayer nodes are introduced.
	pass


func setMasterVolume(_linearVolume: float) -> void:
	# TODO: Apply volume settings through Godot audio buses in a later settings step.
	pass
