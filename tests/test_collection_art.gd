extends SceneTree
## Integración: las 30 ilustraciones conservan azul, alpha exterior, presencia y UX.
## -- --capture genera páginas renderizadas del mercado en las cuatro resoluciones.

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _settle() -> void:
	for frame in 12:
		await process_frame

func _run() -> void:
	var game := root.get_node("GameManager")
	var stats := root.get_node("StatsManager")
	var recipes: Script = load("res://scripts/models/RecipeDatabase.gd")
	var art: Script = load("res://scripts/ui/CollectionArt.gd")
	var ids: Array = recipes.get_sorted_recipe_ids() + stats.get_sorted_tool_ids()
	_check(ids.size() == 30 and art.TEXTURES.size() == ids.size(), "Arte completo para20 recetas y10 herramientas")
	for id: String in ids:
		var texture: Texture2D = art.texture_for(id)
		_check(texture != null, "Ilustración para " + id)
		if texture == null:
			continue
		_check(texture == art.texture_for(id), "Se reutiliza la misma textura: " + id)
		_check(texture.resource_path.get_file() == id + ".png", "Ruta ligada al ID canónico: " + id)
		var image: Image = texture.get_image()
		_check(maxi(image.get_width(), image.get_height()) <= 512, "Textura UI optimizada: " + id)
		_check(image.get_pixel(0, 0).a == 0.0 and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a == 0.0, "Sin rectángulo gris exterior: " + id)
		var blue: Color = image.get_pixel(image.get_width() / 2, int(image.get_height() * 0.04))
		_check(blue.a > 0.98 and blue.b > blue.r + 0.1, "La placa azul permanece opaca: " + id)
	game.start_new_run()
	game.set_process(false)
	game.run_money = 1.234e24
	for id: String in recipes.get_sorted_recipe_ids():
		game.unlock_recipe_this_run(id)
	for id: String in stats.get_sorted_tool_ids():
		game.unlock_tool_this_run(id)
	var host := SubViewport.new()
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.size = Vector2i(720, 1280)
	root.add_child(host)
	var market: Control = load("res://scenes/ui/RunUpgradeModal.tscn").instantiate()
	host.add_child(market)
	market.open_modal(100)
	await _settle()
	for resolution: Vector2i in [Vector2i(720, 960), Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280)]:
		host.size = resolution
		for tab in [1, 2]:
			var tabs: TabContainer = market.get_node("Panel/VBox/TabContainer")
			tabs.current_tab = tab
			await _settle()
			var scroll: ScrollContainer = tabs.get_current_tab_control()
			var grid: Container = scroll.get_node("ItemsGrid")
			for card in grid.get_children():
				var id: String = card.get_meta("item_id")
				var front: Control = card.get_node("Column/Face/Front")
				var texture: TextureRect = card.get_node("Column/Face/Front/ArtBox/ArtTexture")
				_check(texture.texture == art.texture_for(id) and texture.visible, "Arte correcto y visible: " + id)
				_check(texture.size.x >= card.size.x * 0.75 and texture.size.y >= card.size.y * 0.4, "Zona artística dominante: " + id + " " + str(resolution))
				_check(absf(texture.size.x - texture.size.y) <= 1.0, "Frente cuadrado solo con el arte: " + id)
				_check(front.get_node_or_null("FrontName") == null, "El frente no muestra el nombre: " + id)
				var front_text: bool = false
				for child in front.get_children():
					if child is Label and child.visible:
						front_text = true
				_check(not front_text, "Frente puramente visual, sin texto informativo: " + id)
				_check(card.get_node("Column/Face/Back/ActionButton") == card.action_button, "La acción vive en el reverso: " + id)
				_check(card.action_button.size.y >= 48, "Acción conserva target táctil: " + id)
				var shared: Texture2D = texture.texture
				card.set_locked(true)
				_check(not texture.visible and card.get_node("Column/Face/LockBadge").visible, "Bloqueo conserva sus indicadores sin revelar arte: " + id)
				card.set_locked(false)
				_check(texture.texture == shared and texture.visible, "Desbloquear reutiliza el arte: " + id)
			if "--capture" in OS.get_cmdline_user_args():
				var max_scroll: int = maxi(int(scroll.get_v_scroll_bar().max_value - scroll.size.y), 0)
				var step: int = maxi(int(scroll.size.y * 0.8), 1)
				var page: int = 0
				for offset in range(0, max_scroll + step, step):
					scroll.scroll_vertical = mini(offset, max_scroll)
					await _settle()
					await RenderingServer.frame_post_draw
					var path := "/tmp/opencode/Collection_%s_%dx%d_%d.png" % ["Recetas" if tab == 1 else "Herramientas", resolution.x, resolution.y, page]
					_check(host.get_texture().get_image().save_png(path) == OK, "Captura: " + path)
					page += 1
			scroll.scroll_vertical = 0
		print("Ilustraciones comprobadas: ", resolution)
	# El TextureRect grande no debe interceptar el toque real ni el arrastre.
	await _settle()
	var first_card: Control = market._tool_rows[stats.get_sorted_tool_ids()[0]]["card"]
	var art_rect: TextureRect = first_card.get_node("Column/Face/Front/ArtBox/ArtTexture")
	var point: Vector2 = art_rect.get_global_rect().get_center()
	_touch(host, point, true)
	_touch(host, point, false)
	await create_timer(0.35).timeout
	_check(first_card.get_node("Column/Face/Back").visible, "Tocar la ilustración grande muestra el reverso")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		_check(host.get_texture().get_image().save_png("/tmp/opencode/Collection_Flip.png") == OK, "Captura del reverso")
	_touch(host, point, true)
	_touch(host, point, false)
	await create_timer(0.35).timeout
	_check(first_card.get_node("Column/Face/Front").visible, "El reverso sigue alternando con toque real")
	_touch(host, point, true)
	var drag := InputEventScreenDrag.new()
	drag.position = point + Vector2(0, 48)
	drag.relative = Vector2(0, 48)
	host.push_input(drag, true)
	_touch(host, drag.position, false)
	await create_timer(0.35).timeout
	_check(first_card.get_node("Column/Face/Front").visible, "Arrastrar sobre el arte no voltea la tarjeta")
	# Comprables veladas: voltean para mostrar precio; las de cadena bloqueada no.
	game.start_new_run()
	game.run_money = 999999.0
	market._rebuild_ui()
	await _settle()
	var fresh_ids: Array = recipes.get_sorted_recipe_ids()
	var buyable: Control = market._recipe_rows[str(fresh_ids[1])]["card"]
	var blocked: Control = market._recipe_rows[str(fresh_ids[2])]["card"]
	_check(buyable.is_locked and not buyable.get_node("Column/Face/Back").visible, "La comprable nace velada en el frente")
	_tap(buyable.get_node("Column/Face"))
	await create_timer(0.35).timeout
	_check(buyable.get_node("Column/Face/Back").visible, "La comprable velada voltea para mostrar su precio")
	_check(buyable.action_button.text == "$" + (root.get_node("UiTheme") as Node).call("format_money", float(market._recipe_rows[str(fresh_ids[1])]["price"])), "El reverso comprable ofrece su precio")
	_check(buyable.get_node("Column/Face/Front/ArtBox/ArtTexture").texture == null or not buyable.get_node("Column/Face/Front/ArtBox/ArtTexture").visible, "El frente comprable no revela la ilustración sin comprar")
	_tap(blocked.get_node("Column/Face"))
	await create_timer(0.35).timeout
	_check(not blocked.get_node("Column/Face/Back").visible, "La bloqueada de cadena no revela su reverso")
	market.queue_free()
	host.queue_free()
	await _settle()
	print("Colección ilustrada: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)

func _touch(host: SubViewport, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	host.push_input(event, true)

# Toca directamente el gui_input del control (sin depender de que esté visible
# o tenga posición válida en el viewport, como usa test_ui_layout).
func _tap(control: Control) -> void:
	var press := InputEventScreenTouch.new()
	press.device = 0
	press.pressed = true
	press.position = Vector2(20, 20)
	control.gui_input.emit(press)
	var release := InputEventScreenTouch.new()
	release.device = 0
	release.position = Vector2(20, 20)
	control.gui_input.emit(release)
