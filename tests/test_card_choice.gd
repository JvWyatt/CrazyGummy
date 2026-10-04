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
	main.fruit_spawner.disable_spawning()
	game.run_money = 100000.0
	var market: Control = main.run_upgrade_modal
	var selection: Control = main.card_selection_modal
	var fruit_database: Script = load("res://scripts/models/FruitDatabase.gd")
	var fruit_count: int = fruit_database.get_sorted_fruit_ids().size()
	for frame in range(120):
		if market._upgrade_rows.size() == stats.run_upgrade_definitions.size() and market._fruit_rows.size() == fruit_count and market._weapon_rows.size() == stats.knives_db.size():
			break
		await process_frame
	_check(market._fruit_rows.size() == fruit_count, "Mercado preparado gradualmente antes de elegir")
	var upgrade_card: Node = market._upgrade_rows["damage"]["card"]
	var fruit_card: Node = market._fruit_rows["banana"]["card"]
	var knife_ids: Array = stats.get_sorted_knife_ids()
	var weapon_card: Node = market._weapon_rows[knife_ids[1]]["card"]
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
	_check(market._fruit_rows["banana"]["card"] == fruit_card, "Elegir reutiliza las tarjetas de frutas")
	_check(market._weapon_rows[knife_ids[1]]["card"] == weapon_card, "Elegir reutiliza las tarjetas de armas")
	print("Elegir → mercado: %.3f ms" % elapsed)

	# Los widgets conservados deben consultar precios actualizados, no closures viejas.
	stats.card_fruit_price_multiplier = 0.5
	stats.card_weapon_price_multiplier = 0.5
	stats.invalidate_stat_cache()
	market.open_modal(2)
	var fruit_price: int = stats.get_fruit_price(fruit_database.get_fruit_data("banana").price)
	var weapon_price: int = stats.get_weapon_price(stats.knives_db[knife_ids[1]].price)
	_check(market._fruit_rows["banana"]["price"] == fruit_price, "Precio de fruta refleja el descuento en el mercado reutilizado")
	var previous_money: float = game.run_money
	fruit_card.action_button.pressed.emit()
	_check(game.run_money == previous_money - fruit_price and game.is_fruit_unlocked_this_run("banana"), "Comprar fruta usa el precio actualizado una sola vez")
	previous_money = game.run_money
	weapon_card.action_button.pressed.emit()
	_check(game.run_money == previous_money - weapon_price and game.run_equipped_knife == knife_ids[1], "Comprar arma usa el precio actualizado y la equipa")
	_check(market._weapon_rows[knife_ids[1]]["card"] == weapon_card, "Comprar arma actualiza el mismo widget")

	market.hide()
	selection.open_modal(2)
	for frame in range(8):
		await process_frame
	widget = selection.cards_container.get_child(0)
	widget._front.get_node("Column/ChooseButton").pressed.emit()
	_check(stats.active_cards.size() == 2, "El siguiente día permite elegir otro comodín")
	game.start_new_run()
	main.fruit_spawner.disable_spawning()
	market.open_modal()
	_check(market._upgrade_rows["damage"]["subtitle_lbl"].text == "Nivel 0", "Nueva partida reinicia niveles en las tarjetas existentes")
	_check(fruit_card.is_locked and weapon_card.is_locked, "Nueva partida actualiza bloqueos y disponibilidad")
	main.queue_free()
	await process_frame
	await process_frame
	print("Selección de comodín: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
