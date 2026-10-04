extends PanelContainer
## La misma presentación de texto para hover y toque, sin una ventana de detalle.

@export var preferred_width: float = 300.0
@export var edge_padding: float = 12.0
@export var anchor_gap: float = 10.0

var _anchor_rect: Rect2
var _bounds: Rect2

func _ready() -> void:
	$DismissTimer.timeout.connect(hide)

func set_text(text: String) -> void:
	$Text.text = text
	$Text.custom_minimum_size.x = preferred_width - get_theme_stylebox("panel").get_minimum_size().x
	reset_size()

func show_at(text: String, anchor_rect: Rect2, bounds: Rect2) -> void:
	_anchor_rect = anchor_rect
	_bounds = bounds.grow(-edge_padding)
	set_text(text)
	show()
	$DismissTimer.start()
	_place.call_deferred()

func _place() -> void:
	reset_size()
	var target := Vector2(_anchor_rect.position.x, _anchor_rect.end.y + anchor_gap)
	if target.y + size.y > _bounds.end.y:
		target.y = _anchor_rect.position.y - size.y - anchor_gap
	target.x = clampf(target.x, _bounds.position.x, maxf(_bounds.position.x, _bounds.end.x - size.x))
	target.y = clampf(target.y, _bounds.position.y, maxf(_bounds.position.y, _bounds.end.y - size.y))
	global_position = target
