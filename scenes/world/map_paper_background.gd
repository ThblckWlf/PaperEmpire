extends Node2D
class_name MapPaperBackground


# Visual-only backing for the real-country world map.
const WORLD_MAP_TEXTURE: Texture2D = preload("res://assets/map/backgrounds/worldMapPaper.png")
const MAP_RECT := Rect2(Vector2.ZERO, Vector2(4096.0, 2304.0))


func _ready() -> void:
	z_index = -100
	queue_redraw()


func _draw() -> void:
	if WORLD_MAP_TEXTURE != null:
		draw_texture(WORLD_MAP_TEXTURE, MAP_RECT.position)
	else:
		draw_rect(MAP_RECT, Color("#F3E8C9"), true)
