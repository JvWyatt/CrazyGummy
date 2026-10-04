extends SceneTree
## Pruebas de interacción táctil REAL: se envían eventos por la entrada del juego
## (toque + su ratón emulado, igual que en un móvil) en lugar de llamar a los
## manejadores a mano. Ejecutar con XDG_DATA_HOME aislado, como test_shop_stats.gd.
##
## Cubre lo que fallaba en móvil:
##   - el reverso de la carta NO alternaba al tocar el área del texto;
##   - las listas con scroll no se desplazaban si el dedo empezaba sobre un botón
##     o una tarjeta (hijos con MOUSE_FILTER_STOP);
##   - y que arreglarlo NO rompa el toque normal de los botones ni el arrastre de
##     las barras de desplazamiento.
##
## Igual que en el juego, la entrada entra por la ventana real (push_input con
## coordenadas locales: el escalado de estirado solo existe en escritorio).

var failures: int = 0
var checks: int = 0

var _host: SubViewport

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _settle(frames: int = 6) -> void:
	for frame in frames:
		await process_frame

# Espera a que termine el giro de la carta (si no, el siguiente toque se
# ignoraría porque el widget está en mitad de la vuelta).
func _wait_flip(card) -> void:
	for frame in 240:
		if not card._flipping:
			break
		await process_frame
	await _settle(2)

# ---------------------------------------------------------------------------
# Simulación de un dedo: el toque real y el ratón emulado que genera Godot con
# emulate_mouse_from_touch (este segundo es el que activa los Button).
# ---------------------------------------------------------------------------

func _push(event: InputEvent) -> void:
	_host.push_input(event, true)

func _finger_down(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_EMULATION
	motion.position = point
	_push(motion)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	_push(touch)
	var mb := InputEventMouseButton.new()
	mb.device = InputEvent.DEVICE_ID_EMULATION
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.position = point
	mb.pressed = true
	_push(mb)

func _finger_move(from: Vector2, to: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_EMULATION
	motion.position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	_push(motion)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = to
	drag.relative = to - from
	_push(drag)

func _finger_up(point: Vector2) -> void:
	var mb := InputEventMouseButton.new()
	mb.device = InputEvent.DEVICE_ID_EMULATION
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.position = point
	mb.pressed = false
	_push(mb)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = false
	_push(touch)

func _tap(point: Vector2) -> void:
	_finger_down(point)
	_finger_up(point)

func _drag_finger(from: Vector2, to: Vector2, steps: int = 6) -> void:
	_finger_down(from)
	var previous: Vector2 = from
	for step in range(1, steps + 1):
		var point: Vector2 = from.lerp(to, float(step) / float(steps))
		_finger_move(previous, point)
		previous = point
	_finger_up(to)

func _run() -> void:
	var game: Node = root.get_node("GameManager")
	game.start_new_run()
	game.run_money = 123456789.0

	_host = SubViewport.new()
	_host.size = Vector2i(720, 1280)
	_host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_host)
	await _settle()

	await _test_card_back_tap()
	await _test_scroll_over_stop_child()
	await _test_taps_still_work()
	await _test_scrollbar_drag_still_works()
	await _test_modal_scrolls_use_touch_script()

	print("Toque: %d comprobaciones, %d fallos" % [checks, failures])
	quit()

# ---------------------------------------------------------------------------
# 1. La carta gira al tocar CUALQUIER punto, incluido el texto del reverso.
# ---------------------------------------------------------------------------

func _test_card_back_tap() -> void:
	var modal: Control = load("res://scenes/ui/CardSelectionModal.tscn").instantiate()
	_host.add_child(modal)
	modal.open_modal(1)
	await _settle(12)

	var cards_hbox: HBoxContainer = modal.get_node("Panel/VBox/CardsHBox")
	var card = cards_hbox.get_child(0)
	_check(card != null, "La pantalla de elección crea cartas")
	var frame: Control = card._back.get_node("Column/CardFrame")
	var text_scroll: Control = frame.get_node("Overlay/TextScroll")
	_check(frame.mouse_filter != Control.MOUSE_FILTER_IGNORE, "El marco de la carta recibe toques")
	_check(text_scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"El texto del reverso deja los toques al marco (coordenadas coherentes)")
	_check(card._front.visible and not card._back.visible, "La carta empieza mostrando el anverso")

	# Anverso: toque en mitad del arte.
	_tap(card._front.get_global_rect().get_center())
	await _wait_flip(card)
	_check(card._showing_back, "Tocar el anverso gira la carta")

	# Reverso: toque en mitad del área de texto (el sitio que no funcionaba).
	var text_point: Vector2 = text_scroll.get_global_rect().get_center()
	_check(frame.get_global_rect().has_point(text_point), "El centro del texto cae dentro de la carta")
	_tap(text_point)
	await _wait_flip(card)
	_check(not card._showing_back, "Tocar el texto del reverso vuelve a girar la carta")

	# Alterna cada vez, sin quedarse a medias.
	_tap(text_point)
	await _wait_flip(card)
	_check(card._showing_back, "El reverso sigue alternando con toques sucesivos")
	_tap(text_point)
	await _wait_flip(card)
	_check(not card._showing_back, "La carta vuelve al anverso con el siguiente toque")

	# Un dedo que se desliza sobre la carta NO debe girarla.
	_drag_finger(text_point, text_point + Vector2(0, 90))
	await _wait_flip(card)
	_check(not card._showing_back, "Arrastrar sobre la carta no la gira")

	modal.queue_free()
	await _settle()

# ---------------------------------------------------------------------------
# 2. El arrastre desplaza la lista aunque el dedo empiece sobre un botón.
# ---------------------------------------------------------------------------

func _make_scrollable_list() -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.set_script(load("res://scripts/ui/TouchScrollContainer.gd"))
	scroll.position = Vector2(40, 40)
	scroll.size = Vector2(640, 600)
	scroll.custom_minimum_size = scroll.size
	_host.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var buttons: Array[Button] = []
	for index in range(8):
		var button := Button.new()
		button.text = "Fila %d" % index
		button.custom_minimum_size = Vector2(600, 120)
		button.focus_mode = Control.FOCUS_NONE
		list.add_child(button)
		buttons.append(button)
	await _settle(4)
	return {"scroll": scroll, "buttons": buttons, "fired": []}

func _test_scroll_over_stop_child() -> void:
	var built: Dictionary = await _make_scrollable_list()
	var scroll: ScrollContainer = built["scroll"]
	var buttons: Array = built["buttons"]
	var fired: Array = built["fired"]
	for button in buttons:
		(button as Button).pressed.connect(func(): fired.append((button as Button).text))
	await _settle(2)
	_check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "La lista desborda y tiene barra")

	# El dedo empieza sobre un botón (MOUSE_FILTER_STOP) y sube: la lista sube y
	# el botón NO se dispara.
	var start: Vector2 = (buttons[0] as Button).get_global_rect().get_center()
	var before: int = scroll.scroll_vertical
	_drag_finger(start, start - Vector2(0, 260))
	await _settle(4)
	_check(scroll.scroll_vertical > before,
		"El arrastre sobre un botón desplaza la lista (%d -> %d)" % [before, scroll.scroll_vertical])
	_check(fired.is_empty(), "Desplazar no dispara los botones que quedan bajo el dedo")

	# Y bajando de vuelta.
	var bottom_before: int = scroll.scroll_vertical
	_drag_finger(start, start + Vector2(0, 260))
	await _settle(4)
	_check(scroll.scroll_vertical < bottom_before,
		"El arrastre hacia abajo también desplaza (%d -> %d)" % [bottom_before, scroll.scroll_vertical])

	scroll.queue_free()
	await _settle()

# ---------------------------------------------------------------------------
# 3. Un toque limpio sigue activando el botón.
# ---------------------------------------------------------------------------

func _test_taps_still_work() -> void:
	var built: Dictionary = await _make_scrollable_list()
	var buttons: Array = built["buttons"]
	var fired: Array = built["fired"]
	for button in buttons:
		(button as Button).pressed.connect(func(): fired.append((button as Button).text))
	await _settle(2)

	_tap((buttons[0] as Button).get_global_rect().get_center())
	await _settle(4)
	_check(fired.size() == 1 and str(fired[0]) == "Fila 0",
		"Un toque limpio sigue pulsando el botón (%s)" % str(fired))

	# Un dedo que se mueve menos que el umbral de arrastre sigue siendo un toque.
	var center: Vector2 = (buttons[1] as Button).get_global_rect().get_center()
	_finger_down(center)
	_finger_move(center, center + Vector2(3, 4))
	_finger_up(center + Vector2(3, 4))
	await _settle(4)
	_check(fired.size() == 2, "Un micro-deslizamiento no se confunde con scroll (%s)" % str(fired))

	(built["scroll"] as Node).queue_free()
	await _settle()

# ---------------------------------------------------------------------------
# 4. El arrastre de la barra de desplazamiento sigue siendo de la barra.
# ---------------------------------------------------------------------------

func _test_scrollbar_drag_still_works() -> void:
	var built: Dictionary = await _make_scrollable_list()
	var scroll: ScrollContainer = built["scroll"]
	await _settle(2)

	var bar: VScrollBar = scroll.get_v_scroll_bar()
	_check(bar.visible, "La barra vertical está visible")
	var grab: Vector2 = bar.get_global_rect().get_center()
	_drag_finger(grab, grab + Vector2(0, 200))
	await _settle(4)
	_check(bar.value > 0.0, "Arrastrar la barra sigue moviendo la barra (%.1f)" % bar.value)
	_check(scroll.scroll_vertical > 0, "La barra mueve el scroll del contenedor")

	scroll.queue_free()
	await _settle()

# ---------------------------------------------------------------------------
# 5. Todos los modales con lista tienen scroll táctil.
# ---------------------------------------------------------------------------

func _test_modal_scrolls_use_touch_script() -> void:
	var expected := {
		"res://scenes/ui/CardsModal.tscn": ["Panel/VBox/ScrollContainer"],
		"res://scenes/ui/PrestigeShopModal.tscn": ["Panel/VBox/ScrollContainer"],
		"res://scenes/ui/RunUpgradeModal.tscn": [
			"Panel/VBox/TabContainer/Mejoras",
			"Panel/VBox/TabContainer/Frutería",
			"Panel/VBox/TabContainer/Armas",
		],
		"res://scenes/ui/StatsModal.tscn": ["Panel/VBox/ScrollContainer"],
		"res://scenes/ui/ProgressModal.tscn": ["Panel/VBox/ScrollContainer"],
	}
	var touch_script: GDScript = load("res://scripts/ui/TouchScrollContainer.gd")
	for path: String in expected:
		var scene: Node = (load(path) as PackedScene).instantiate()
		for node_path: String in expected[path]:
			var scroll: Control = scene.get_node_or_null(NodePath(node_path))
			_check(scroll != null and scroll is ScrollContainer, "%s (%s): existe la lista desplazable" % [path, node_path])
			_check(scroll != null and scroll.get_script() == touch_script,
				"%s (%s): la lista tiene scroll táctil" % [path, node_path])
		scene.free()
	# AchievementsModal arma su lista en código: el script debe poder adjuntarse
	# en caliente y seguir recibiendo la entrada.
	var dynamic_scroll := ScrollContainer.new()
	dynamic_scroll.set_script(touch_script)
	_check(dynamic_scroll.get_script() == touch_script, "El script también se adjunta en caliente (AchievementsModal)")
	_check(dynamic_scroll.has_method("_input"), "El script adjunto en caliente recibe la entrada")
	dynamic_scroll.free()
	await _settle()
