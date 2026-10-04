extends ScrollContainer
## Adds finger-drag scrolling so touch users can swipe shop/stats lists directly.
# Puramente de interfaz (scroll táctil), sin relación con el balance del juego.
#
# POR QUÉ SE ESCUCHA EN _input() Y NO EN _gui_input():
#   - _gui_input() solo recibe el gesto cuando el ScrollContainer está bajo el
#     dedo Y ningún hijo con MOUSE_FILTER_STOP (botones, tarjetas, filas) lo
#     intercepta antes. En móvil el dedo casi siempre empieza sobre uno de ellos,
#     así que el arrastre se perdía y la lista no se movía.
#   - _input() se ejecuta ANTES de la fase de interfaz y no depende del
#     mouse_filter de los hijos: el scroll funciona aunque el gesto empiece sobre
#     un botón o una tarjeta.
#   - Con la emulación de Godot, un toque además produce un ratón emulado
#     (device = DEVICE_ID_EMULATION), que es lo que activan los Button. Por eso
#     el mismo gesto se sigue en los dos idiomas; cuando ya es un arrastre de
#     scroll se marca el evento como tratado para que el botón que hubiera bajo
#     el dedo no se dispare al soltar el dedo.

# Píxeles que hay que mover antes de considerar que es arrastre y no un toque.
const DRAG_SLOP: float = 8.0
# Tolerancia para salirse del recuadro sin abandonar el gesto.
const LEAVE_TOLERANCE: float = 32.0

var _tracking: bool = false
var _scrolling: bool = false
var _pointer_id: int = 0
var _press_pos: Vector2 = Vector2.ZERO
var _last_pos: Vector2 = Vector2.ZERO
# Desplazamiento acumulado que aún no suma un píxel entero a las barras.
var _pending: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin(touch.index, touch.position)
		elif _tracking and touch.index == _pointer_id:
			if touch.canceled:
				_reset()
			else:
				_end()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_move(drag.index, drag.position)
	elif event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
		# Ratón emulado de un toque: mismo gesto, para que los Button no salten.
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_begin(0, mb.position)
		elif _tracking:
			_end()
	elif event is InputEventMouseMotion and event.device == InputEvent.DEVICE_ID_EMULATION:
		_move(0, (event as InputEventMouseMotion).position)

# Empieza a seguir un gesto nuevo si cae dentro del recuadro. Sobre una barra de
# desplazamiento no se hace nada: ese arrastre lo lleva la propia barra.
func _begin(pointer_id: int, viewport_pos: Vector2) -> void:
	if _tracking or not _is_inside(viewport_pos) or _is_over_scrollbar(viewport_pos):
		return
	_tracking = true
	_scrolling = false
	_pointer_id = pointer_id
	_press_pos = viewport_pos
	_last_pos = viewport_pos
	_pending = Vector2.ZERO

func _move(pointer_id: int, viewport_pos: Vector2) -> void:
	if not _tracking or pointer_id != _pointer_id:
		return
	if not _is_inside(viewport_pos):
		# El dedo se ha ido del recuadro: el gesto ya no es nuestro.
		_reset()
		return
	var delta: Vector2 = viewport_pos - _last_pos
	_last_pos = viewport_pos
	if not _scrolling:
		if _press_pos.distance_to(viewport_pos) <= DRAG_SLOP:
			return
		_scrolling = true
	_scroll_by(delta)
	if _scrolling:
		_consume()

func _end() -> void:
	var was_scrolling: bool = _scrolling
	_reset()
	if was_scrolling:
		_consume()

func _reset() -> void:
	_tracking = false
	_scrolling = false
	_pending = Vector2.ZERO

func _scroll_by(delta: Vector2) -> void:
	_pending -= delta
	var step_y: float = roundf(_pending.y)
	if not is_zero_approx(step_y):
		_pending.y -= step_y
		scroll_vertical += int(step_y)
	var step_x: float = roundf(_pending.x)
	if not is_zero_approx(step_x):
		_pending.x -= step_x
		scroll_horizontal += int(step_x)

func _is_inside(viewport_pos: Vector2) -> bool:
	var tolerance: Vector2 = Vector2.ONE * LEAVE_TOLERANCE
	return Rect2(global_position - tolerance, size + tolerance * 2.0).has_point(viewport_pos)

func _is_over_scrollbar(viewport_pos: Vector2) -> bool:
	for bar in [get_v_scroll_bar(), get_h_scroll_bar()]:
		if bar != null and bar.visible and bar.get_global_rect().has_point(viewport_pos):
			return true
	return false

func _consume() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
