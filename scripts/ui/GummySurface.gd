@tool
extends Control
## Reflejo estático ligero; no captura input ni procesa frames.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 70 or size.y < 40:
		return
	var shine := Color(0.94, 0.84, 1.0, 0.16)
	draw_line(Vector2(8, -8), Vector2(size.x - 8, -8), shine, 2, true)
	draw_circle(Vector2(size.x + 5, 2), 2, shine)
	draw_circle(Vector2(size.x, 8), 1, shine)
