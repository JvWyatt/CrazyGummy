extends SceneTree
# Regresión de selección y reutilización del mercado; ejecutar con datos aislados.

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	var game: Node = root.get_node("GameManager")
	var stats: Node = root.get_node("StatsManager")
	root.get_node("SoundManager").is_sound_enabled = false
	game.set_process(false)
	game.start_new_run()
	main.block_spawner.disable_spawning()
	game.run_money = 100000.0
	var market: Control = main.run_upgrade_modal
	var selection: Control = main.card_selection_modal
	var recipe_database: Script = load("res://scripts/models/RecipeDatabase.gd")
	var recipe_count: int = recipe_database.get_sorted_recipe_ids().size()
	for frame in range(120):
		if market._upgrade_rows.size() == stats.run_upgrade_definitions.size() and market._recipe_rows.size() == recipe_count and market._tool_rows.size() == stats.tools_db.size():
			break
		await process_frame
	_check(market._recipe_rows.size() == recipe_count, "Mercado preparado gradualmente antes de elegir")
	var upgrade_card: Node = market._upgrade_rows["damage"]["card"]
	var recipe_card: Node = market._recipe_rows["ring"]["card"]
	var tool_ids: Array = stats.get_sorted_tool_ids()
	var weapon_card: Node = market._tool_rows[tool_ids[1]]["card"]
	selection.open_modal(1)
	for frame in range(8):
		await process_frame
	var widget: Control = selection.cards_container.get_child(0)
	var button: Button = widget._front.get_node("Column/ChooseButton")
	var selected_id: String = widget._data["id"]
	var start := Time.get_ticks_usec()
	button.pressed.emit()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0
	_check(not selection.visible and market.visible, "Elegir cierra la selección y abre el mercado en la misma llamada")
	_check(stats.active_cards.size() == 1 and stats.active_cards[0]["id"] == selected_id, "Se aplica exactamente el comodín elegido")
	_check(main.stats_modal._stats_grid == null, "Elegir no construye la pantalla de estadísticas oculta")
	button.pressed.emit()
	_check(stats.active_cards.size() == 1, "Un segundo evento de Elegir no duplica el efecto")
	_check(market._upgrade_rows["damage"]["card"] == upgrade_card, "Elegir reutiliza la tarjeta de mejora")
	_check(market._recipe_rows["ring"]["card"] == recipe_card, "Elegir reutiliza las tarjetas de recetas")
	_check(market._tool_rows[tool_ids[1]]["card"] == weapon_card, "Elegir reutiliza las tarjetas de armas")
	print("Elegir → mercado: %.3f ms" % elapsed)

	# Los widgets conservados deben consultar precios actualizados, no closures viejas.
	stats.card_recipe_price_multiplier = 0.5
	stats.card_tool_price_multiplier = 0.5
	stats.invalidate_stat_cache()
	market.open_modal(2)
	var recipe_price: int = stats.get_recipe_price(recipe_database.get_recipe_data("ring").price)
	var tool_price: int = stats.get_tool_price(stats.tools_db[tool_ids[1]].price)
	_check(market._recipe_rows["ring"]["price"] == recipe_price, "Precio de receta refleja el descuento en el mercado reutilizado")
	var previous_money: float = game.run_money
	recipe_card.action_button.pressed.emit()
	_check(game.run_money == previous_money - recipe_price and game.is_recipe_unlocked_this_run("ring"), "Comprar receta usa el precio actualizado una sola vez")
	previous_money = game.run_money
	weapon_card.action_button.pressed.emit()
	_check(game.run_money == previous_money - tool_price and game.run_equipped_tool == tool_ids[1], "Comprar arma usa el precio actualizado y la equipa")
	_check(market._tool_rows[tool_ids[1]]["card"] == weapon_card, "Comprar arma actualiza el mismo widget")

	market.hide()
	selection.open_modal(2)
	for frame in range(8):
		await process_frame
	widget = selection.cards_container.get_child(0)
	widget._front.get_node("Column/ChooseButton").pressed.emit()
	_check(stats.active_cards.size() == 2, "El siguiente día permite elegir otro comodín")
	game.start_new_run()
	main.block_spawner.disable_spawning()
	market.open_modal()
	_check(market._upgrade_rows["damage"]["subtitle_lbl"].text == "Nivel 0", "Nueva partida reinicia niveles en las tarjetas existentes")
	_check(recipe_card.is_locked and weapon_card.is_locked, "Nueva partida actualiza bloqueos y disponibilidad")
	main.queue_free()
	await process_frame
	await process_frame
	print("Selección de comodín: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
