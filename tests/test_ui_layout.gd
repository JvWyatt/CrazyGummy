extends SceneTree
## Prueba de integración: contenido real, textos largos y distintas proporciones.
## Ejecutar con XDG_DATA_HOME aislado, como test_shop_stats.gd.

var failures: int = 0
var checks: int = 0

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

func _gesture(control: Control, end_position: Vector2, device: int = 0) -> void:
	var press := InputEventScreenTouch.new()
	press.device = device
	press.pressed = true
	press.position = Vector2(20, 20)
	control.gui_input.emit(press)
	var release := InputEventScreenTouch.new()
	release.device = device
	release.position = end_position
	control.gui_input.emit(release)

func _check_bounds(control: Control, bounds: Rect2, context: String) -> void:
	var rect: Rect2 = control.get_global_transform() * Rect2(Vector2.ZERO, control.size)
	_check(bounds.grow(2).encloses(rect), context + " fuera de pantalla: " + str(rect))

func _check_content(node: Node, context: String) -> void:
	if node is Control and not node.is_visible_in_tree():
		return
	if node is Label and node.get_parent() is Container:
		_check(node.size.x + 1 >= node.get_minimum_size().x, context + ": texto sin ancho " + str(node.get_path()))
		_check(node.size.y + 1 >= node.get_minimum_size().y, context + ": texto sin alto " + str(node.get_path()))
	if node is ScrollContainer:
		_check(node.get_h_scroll_bar().max_value <= node.size.x + 2, context + ": scroll horizontal inesperado")
	for child in node.get_children():
		if node is Container and not node is ScrollContainer and child is Control and child.is_visible_in_tree():
			var container_bounds: Rect2 = node.get_global_transform() * Rect2(Vector2.ZERO, node.size)
			_check_bounds(child, container_bounds, context + " " + str(child.get_path()))
		_check_content(child, context)

func _check_typography(node: Node, theme: Theme) -> void:
	if node is Label or node is Button or node is TabContainer or node is RichTextLabel:
		var font_key: StringName = &"normal_font" if node is RichTextLabel else &"font"
		var role: StringName = node.theme_type_variation if not node.theme_type_variation.is_empty() else StringName(node.get_class())
		_check(not node.has_theme_font_override(font_key), "Sin fuente local: " + str(node.get_path()))
		_check(not node.has_theme_font_size_override("font_size"), "Sin tamaño tipográfico local: " + str(node.get_path()))
		_check(node.get_theme_font(font_key) == theme.get_font(font_key, role), "Fuente heredada del rol global: " + str(node.get_path()))
	for child in node.get_children():
		_check_typography(child, theme)

func _run() -> void:
	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	game.start_new_run()
	game.run_money = 123456789.0
	save.save_data["prestige_points"] = 123456789.0
	save.save_data["best_clients_in_day"] = 87
	var scenes: Array[Control] = []
	var host := SubViewport.new()
	host.size = Vector2i(720, 1280)
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	for name in ["MainMenu", "HUD", "RunUpgradeModal", "PrestigeShopModal", "StatsModal", "ProgressModal", "CardsModal", "AchievementsModal", "ResultsModal", "CardSelectionModal", "CreditsModal", "ConfirmDialog"]:
		var scene: Control = load("res://scenes/ui/" + name + ".tscn").instantiate()
		host.add_child(scene)
		scenes.append(scene)
		match name:
			"RunUpgradeModal": scene.open_modal(100)
			"PrestigeShopModal", "StatsModal", "ProgressModal", "AchievementsModal": scene.open_modal()
			"CardsModal":
				scene.open_discovered_cards()
				scene._refresh_cards([CardDatabase.ALL_CARDS[0]["id"], CardDatabase.ALL_CARDS[1]["id"]])
			"ResultsModal": scene.open_modal({"money_generated": 123456789.0, "earned_prestige": 123456.0})
			"CardSelectionModal": scene.open_modal(99)
			"ConfirmDialog": scene.open("RENUNCIAR AL NEGOCIO", "¿Seguro que quieres renunciar a este negocio?\nPerderás el progreso del día actual.", "RENUNCIAR", "CONTINUAR JUGANDO")
			"CreditsModal": scene.visible = true
	await _settle()
	var theme: Theme = load("res://themes/ui01_theme.tres")
	for scene in scenes:
		_check_typography(scene, theme)
	var upgrade_card: Control = scenes[2]._upgrade_rows["damage"]["card"]
	var before_stat: String = upgrade_card.current_stat_label.text
	var before_money: float = game.run_money
	upgrade_card.action_button.pressed.emit()
	_check(game.run_money < before_money, "Comprar desde la tarjeta descuenta el precio")
	_check(upgrade_card.current_stat_label.text != before_stat, "La compra actualiza el valor mostrado sin reconstruir la tarjeta")
	# Un arrastre para navegar no debe voltear una fruta; un toque sí.
	var fruit_card: Control = scenes[2].get_node("Panel/VBox/TabContainer/Frutería/ItemsGrid").get_child(0)
	_gesture(fruit_card.get_node("Column/Face"), Vector2(20, 100))
	_check(not fruit_card.get_node("Column/Face/Back").visible, "Arrastrar no voltea la colección")
	_gesture(fruit_card.get_node("Column/Face"), Vector2(20, 20))
	await create_timer(0.35).timeout
	_check(fruit_card.get_node("Column/Face/Back").visible, "Tocar muestra los datos de la fruta")
	_check(fruit_card.get_node("Column/Face/Front/ArtBox/ArtTexture").texture == null, "La frutería utiliza emojis provisionales")
	for card in scenes[2].get_node("Panel/VBox/TabContainer/Armas/ItemsGrid").get_children():
		if card.is_queued_for_deletion():
			continue
		if card.is_locked:
			_check(card.get_node("Column/Face/LockBadge").text == "🔒\nPOR DESCUBRIR", "Bloqueo sin nombres que revelen contenido")
	for widget in scenes[9].get_node("Panel/VBox/CardsHBox").get_children():
		_check(widget._art_container.get_node_or_null("Caption") == null, "El frontal de selección no muestra un panel de nombre")
	var thumb: Control = scenes[6].get_node("Panel/VBox/ScrollContainer/CardsGrid").get_child(0)
	var preview_count := {"value": 0}
	thumb.previewed.connect(func(_data): preview_count["value"] += 1)
	var thumb_frame: Control = thumb._front.get_node("Column/CardFrame")
	_gesture(thumb_frame, Vector2(20, 100))
	_check(preview_count["value"] == 0, "Arrastrar no abre el detalle de comodines")
	_gesture(thumb_frame, Vector2(20, 20))
	_gesture(thumb_frame, Vector2(20, 20), InputEvent.DEVICE_ID_EMULATION)
	_check(preview_count["value"] == 1, "Un toque abre exactamente un detalle, sin duplicación emulada")
	_check(thumb.tooltip_text.contains(CardDatabase.ALL_CARDS[0]["desc"]), "PC dispone de descripción al hacer hover")
	# El borde de rareza va PEGADO a la carta en la galería: la celda reparte el
	# ancho sobrante, pero el marco se ceñe a la carta y la ilustración llena su
	# hueco interior (si no, el marco crece y el aire lo separa del dibujo).
	_check(thumb.size.x > thumb._card_width + 1.0, "La celda de la rejilla es más ancha que la miniatura")
	_check(absf(thumb_frame.size.x - thumb._card_box().x) <= 1.0, "El marco de rareza no se estira hasta la celda")
	_check(absf(thumb_frame.size.y - thumb._card_box().y) <= 1.0, "El marco de rareza mantiene la proporción de la carta")
	_check(absf(thumb_frame.position.x + thumb_frame.size.x * 0.5 - thumb.size.x * 0.5) <= 1.0, "La miniatura queda centrada en su celda")
	_check(absf(thumb_frame.get_node("ArtPanel").size.x - thumb._art_size().x) <= 1.0, "La ilustración llena el hueco interior del marco")
	var hover_tip: Control = thumb._make_custom_tooltip(thumb.tooltip_text)
	host.add_child(hover_tip)
	_check(hover_tip.get_node("Text").text == thumb.tooltip_text, "Hover y toque comparten el mismo tooltip de texto")
	_check(hover_tip.get_node_or_null("DetailBackButton") == null, "Tooltip sin botones ni pestañas")
	hover_tip.queue_free()
	thumb.flip()
	_check(not thumb._showing_back and thumb._back.get_child_count() == 0, "Las galerías no crean ni giran un reverso")
	await _settle()
	_check(scenes[6].get_node("CardTooltip/Text").text.contains(CardDatabase.ALL_CARDS[0]["desc"]), "El toque usa un tooltip de texto")
	_check(scenes[6].get_node_or_null("DetailLayer") == null, "No existe una ventana de detalle de comodines")
	scenes[6]._close_detail()
	var safe_layout := Node.new()
	safe_layout.set_script(load("res://scripts/ui/SafeAreaLayout.gd"))
	var safe_targets: Array[NodePath] = [NodePath("../HUD/TopContainer"), NodePath("../HUD/BottomContainer")]
	safe_layout.targets = safe_targets
	safe_layout.preview_insets = Vector4(0, 48, 0, 32)
	host.add_child(safe_layout)
	for resolution: Vector2i in [Vector2i(720, 960), Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280)]:
		host.size = resolution
		await _settle()
		var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
		for scene in scenes:
			var context := scene.name + " " + str(resolution)
			var panel: Control = scene.get_node_or_null("Panel")
			if panel:
				_check_bounds(panel, bounds, context)
				_check(absf(panel.position.y + panel.size.y * 0.5 - resolution.y * 0.5) <= 2.0, context + ": modal centrado")
				if scene.name in ["CardsModal", "ProgressModal", "ResultsModal"]:
					_check(panel.size.y < resolution.y * 0.8, context + ": modal compacto")
			_check_content(scene, context)
			if scene.name == "MainMenu":
				_check_bounds(scene.get_node("CenterVBox"), bounds, context)
			if scene.name == "HUD":
				_check_bounds(scene.get_node("TopContainer"), bounds, context)
				_check_bounds(scene.get_node("BottomContainer"), bounds, context)
				_check(scene.get_node("TopContainer").offset_top == 80.0, "Área segura superior sin acumulación")
				_check(scene.get_node("BottomContainer").offset_bottom == -57.0, "Área segura inferior sin acumulación")
				var telemetry: Control = scene.get_node("TopContainer/VBox/Telemetry")
				var ring: Control = telemetry.get_node("StreakRing")
				var rate: Control = telemetry.get_node("RatePanel")
				_check(absf(ring.position.x - (telemetry.size.x - rate.position.x - rate.size.x)) <= 2.0, "Racha y frutas/s tienen extremos equilibrados")
		# Comprueba también las pestañas que nacen ocultas.
		var market: Control = scenes[2]
		market.get_node("Panel/VBox/TabContainer").current_tab = 0
		await _settle()
		var market_height: float = market.get_node("Panel").size.y
		for tab in 3:
			market.get_node("Panel/VBox/TabContainer").current_tab = tab
			await _settle()
			_check(absf(market.get_node("Panel").size.y - market_height) <= 1.0, "El mercado mantiene su altura al cambiar a la pestaña " + str(tab))
			if tab > 0:
				var active_scroll: Control = market.get_node("Panel/VBox/TabContainer").get_current_tab_control()
				var original_sides: Array[Dictionary] = []
				for card in active_scroll.get_node("ItemsGrid").get_children():
					if not card.is_queued_for_deletion():
						original_sides.append({"card": card, "front": card.get_node("Column/Face/Front").visible, "back": card.get_node("Column/Face/Back").visible})
						card.get_node("Column/Face/Front").hide()
						card.get_node("Column/Face/Back").show()
				await _settle()
				for card in active_scroll.get_node("ItemsGrid").get_children():
					if card.is_queued_for_deletion():
						continue
					_check(absf(card.size.x - card.size.y) <= 1.0, "Tarjeta de colección cuadrada 1:1")
					var face: Control = card.get_node("Column/Face")
					_check(card.get_node("Column/Face/Back").get_combined_minimum_size().y <= face.size.y + 1.0, "El nombre y los datos caben en la tarjeta cuadrada")
					for side in ["Front", "Back"]:
						var content: Control = face.get_node(side)
						if content.visible:
							_check_bounds(content, face.get_global_transform() * Rect2(Vector2.ZERO, face.size), "Datos dentro de la tarjeta cuadrada")
				for original in original_sides:
					original["card"].get_node("Column/Face/Front").visible = original["front"]
					original["card"].get_node("Column/Face/Back").visible = original["back"]
				await _settle()
			_check_content(market, "Mercado pestaña " + str(tab) + " " + str(resolution))
		var selection: Control = scenes[9]
		for widget in selection.get_node("Panel/VBox/CardsHBox").get_children():
			widget.flip()
		await create_timer(0.35).timeout
		_check_content(selection, "Reversos de selección " + str(resolution))
		var gallery: Control = scenes[6]
		gallery._open_detail(CardDatabase.ALL_CARDS.back())
		await _settle()
		_check(gallery.get_node("CardTooltip/Text").text.ends_with(CardDatabase.ALL_CARDS.back()["desc"]), "El toque muestra únicamente texto descriptivo")
		_check_bounds(gallery.get_node("CardTooltip"), bounds, "Tooltip dentro de pantalla")
		_check_content(gallery, "Detalle de comodín " + str(resolution))
		gallery._close_detail()
		var menu: Control = scenes[0]
		menu._on_settings_pressed()
		await _settle()
		_check_content(menu, "Ajustes de menú " + str(resolution))
		_check_bounds(menu.get_node("SettingsPanel/SettingsCard"), bounds, "Ajustes de menú")
		menu._on_settings_closed()
		var hud: Control = scenes[1]
		hud._on_pause_button_pressed()
		await _settle()
		_check_content(hud, "Pausa " + str(resolution))
		_check_bounds(hud.get_node("PausePanel/Card"), bounds, "Pausa")
		hud._on_settings_button_pressed()
		await _settle()
		_check_content(hud, "Ajustes de pausa " + str(resolution))
		hud._on_continue_pressed()
		var capture_directory: String = "/tmp/opencode"
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--capture-dir="):
				capture_directory = argument.trim_prefix("--capture-dir=")
		if "--capture" in OS.get_cmdline_user_args() and (capture_directory == "/tmp/opencode" or resolution == Vector2i(720, 1280)):
			for scene in scenes:
				scene.visible = false
			for scene in scenes:
				scene.visible = true
				if scene == market:
					var tab_names := ["Mejoras", "Frutas", "Armas"]
					for tab in 3:
						market.get_node("Panel/VBox/TabContainer").current_tab = tab
						await _settle()
						await RenderingServer.frame_post_draw
						host.get_texture().get_image().save_png("%s/Mercado%s_%dx%d.png" % [capture_directory, tab_names[tab], resolution.x, resolution.y])
					market.get_node("Panel/VBox/TabContainer").current_tab = 0
				await create_timer(0.5).timeout
				await RenderingServer.frame_post_draw
				host.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [capture_directory, scene.name, resolution.x, resolution.y])
				scene.visible = false
			for scene in scenes:
				scene.visible = true
		print("Layout comprobado: ", resolution)
	for scene in scenes:
		scene.queue_free()
	safe_layout.queue_free()
	host.queue_free()
	for player in root.get_node("SoundManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	await _settle()
	print("UI: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
