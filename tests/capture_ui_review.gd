extends SceneTree
## Revisión artística renderizada del Main real, con fixtures solo en memoria.
## Ejecutar con XDG_DATA_HOME aislado, SIN --headless. Capturas en /tmp/opencode.
## Complementa test_ui_layout: objetos 3D, Bonus, rarezas y estados de colección.

var host: SubViewport
var main: Node
var resolution: Vector2i

func _initialize() -> void:
	_run.call_deferred()

func _capture(name: String) -> void:
	await create_timer(0.55).timeout
	await RenderingServer.frame_post_draw
	var path := "/tmp/opencode/Review_%s_%dx%d.png" % [name, resolution.x, resolution.y]
	var error := host.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("No se pudo guardar captura: " + path)
		quit(1)

func _run() -> void:
	var game := root.get_node("GameManager")
	var save := root.get_node("SaveManager")
	var recipes: GDScript = load("res://scripts/models/RecipeDatabase.gd")
	for dimensions: Vector2i in [Vector2i(720, 960), Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280)]:
		resolution = dimensions
		host = SubViewport.new()
		host.size = resolution
		host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(host)
		main = load("res://scenes/Main.tscn").instantiate()
		host.add_child(main)
		await _capture("Menu")
		main.main_menu._on_settings_pressed()
		await _capture("Settings")
		main.main_menu._on_settings_closed()
		main.main_menu.start_game_requested.emit()
		main.block_spawner.disable_spawning()
		game.pause_turn()
		game.run_money = 1.234e24
		game.current_order = 25
		game.order_target = 5.0e23
		game.order_progress = 3.0e23
		main.hud._on_order_progress_changed(game.order_progress, game.order_target)
		# Paleta independiente de recetas: siete colores sobre el fondo real.
		var world: Node3D = main._projectile3d_viewport.get_child(0)
		var colors := [Color.RED, Color("#168cff"), Color("#37b75a"), Color("#63ebd1"), Color.YELLOW, Color("#ff86ba"), Color("#9954ed")]
		for index in colors.size():
			var visual: Projectile3D = load("res://scenes/game/Projectile3D.tscn").instantiate()
			world.add_child(visual)
			visual.setup_block(recipes.get_recipe_data("bear_classic"), false)
			visual.get_node("GummyVisual").set_color(colors[index])
			visual.set_pos2d(Vector2(resolution.x * (0.22 + (index % 3) * 0.28), resolution.y * (0.43 + (index / 3) * 0.11)))
			visual.set_process(false)
		var candy: Projectile3D = load("res://scenes/game/Projectile3D.tscn").instantiate()
		world.add_child(candy)
		candy.setup_obstacle(35)
		candy.set_pos2d(Vector2(resolution.x * 0.76, resolution.y * 0.73))
		candy.set_process(false)
		main.hud.streak_ring.set_streak(0.7, 87)
		await _capture("Gameplay")
		game.daily_goal_reached = true
		game.order_progress = game.order_target + 1.5e23
		main.hud._on_order_progress_changed(game.order_progress, game.order_target)
		await _capture("Bonus")
		main.hud._on_achievement_unlocked("fixture", {"name": "Una dulce recompensa extraordinaria"})
		await _capture("Toast")
		main.hud._on_pause_button_pressed()
		await _capture("Pause")
		main.hud.pause_panel.hide()
		main.stats_modal.open_modal()
		await _capture("Stats")
		main.stats_modal.hide()
		game.unlock_tool_this_run("tool_confectioner_knife")
		game.unlock_tool_this_run("tool_confectioner_hatchet")
		main.run_upgrade_modal.open_modal(25)
		await _capture("Market")
		main.run_upgrade_modal.get_node("Panel/VBox/TabContainer").current_tab = 2
		await _capture("ToolStates")
		main.run_upgrade_modal.hide()
		main.game_world.hide()
		main.hud.hide()
		main.projectile3d_layer.hide()
		main.main_menu.show()
		var rarity_ids: Array = []
		for rarity in CardDatabase.RARITIES:
			for card in CardDatabase.ALL_CARDS:
				if card["rarity"] == rarity:
					rarity_ids.append(card["id"])
					break
		main.cards_modal.open_discovered_cards()
		main.cards_modal._refresh_cards(rarity_ids)
		await _capture("Rarities")
		main.cards_modal.hide()
		save.save_data["prestige_points"] = 123456789.0
		main.prestige_shop_modal.open_modal()
		await _capture("Prestige")
		main.prestige_shop_modal.hide()
		save.save_data["best_clients_in_day"] = 87
		save.save_data["total_gummies_produced"] = 1.234e24
		main.progress_modal.open_modal()
		await _capture("Progress")
		main.progress_modal.hide()
		# Fixture de acceso a la lista completa, sin cambiar sus condiciones reales.
		if not "centenario" in save.save_data["achievements"]["unlocked"]:
			save.save_data["achievements"]["unlocked"].append("centenario")
		main.achievements_modal.open_modal()
		await _capture("Achievements")
		main.achievements_modal.hide()
		main.credits_modal.open_modal(100)
		await _capture("Credits")
		main.queue_free()
		host.queue_free()
		await process_frame
	print("Revisión renderizada: Main real, 14 estados × 4 resoluciones; /tmp/opencode/Review_*.png")
	quit()
