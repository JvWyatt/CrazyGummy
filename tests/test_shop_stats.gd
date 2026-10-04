extends SceneTree
# Regresión de tiendas sin dependencias de addons.
# Ejecutar con un XDG_DATA_HOME aislado para no tocar la partida del jugador:
# XDG_DATA_HOME=/tmp/crazyfruit-tests godot --headless --path . --script tests/test_shop_stats.gd

var stats: Node
var save: Node
var game: Node
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _near(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) < 0.000000001, message + ": %s != %s" % [actual, expected])

func _reset() -> void:
	save.save_data["prestige_levels"] = {}
	game.run_equipped_knife = "weapon_fist"
	stats.reset_run_stats()

func _run() -> void:
	stats = root.get_node("StatsManager")
	save = root.get_node("SaveManager")
	game = root.get_node("GameManager")
	_reset()
	var market: Control = load("res://scenes/ui/RunUpgradeModal.tscn").instantiate()
	root.add_child(market)
	_check(market._upgrade_effect_text("damage") == "+1.0 Daño", "Mercado muestra el valor real de la mejora")
	_near(stats.get_final_damage(), 5.0, "Daño inicial")
	for expected: float in [6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.1, 13.31]:
		stats.buy_run_upgrade("damage")
		_near(stats.get_final_damage(), expected, "Mínimo solo debajo de 10 y precisión acumulada")
	_check(market._upgrade_effect_text("damage") == "+10.0% Daño", "Mercado muestra solo el porcentaje tras el umbral")
	_check(market._upgrade_effect_text("luck") == "+0.777 p.p. Jackpot", "Jackpot del mercado conserva sus tres decimales visuales")

	_reset()
	stats.card_damage_multiplier = 1.99
	stats.invalidate_stat_cache()
	stats.buy_run_upgrade("damage")
	_near(stats.get_final_damage(), 10.95, "Compra que cruza el umbral")
	stats.buy_run_upgrade("damage")
	_near(stats.get_final_damage(), 12.045, "Porcentaje tras cruzar el umbral")

	_reset()
	stats.card_damage_multiplier = 0.5
	stats.invalidate_stat_cache()
	stats.buy_run_upgrade("damage")
	_near(stats.get_final_damage(), 3.5, "Mínimo exacto aun con modificadores")

	_reset()
	stats.card_money_multiplier = 2.513
	stats.card_energy_multiplier = 0.02513
	stats.card_launch_rate_multiplier = 2.513
	stats.invalidate_stat_cache()
	for key: String in ["money", "energy_max", "launch_rate"]:
		stats.buy_run_upgrade(key)
	_near(stats.get_final_money_multiplier(), 2.7643, "Dinero sobre valor real")
	_near(stats.get_final_max_energy(), 2.7643, "Resistencia sobre valor real")
	_near(stats.get_final_launch_rate(), 2.7643, "Frecuencia sobre valor real")
	for key: String in ["money", "energy_max", "launch_rate"]:
		stats.buy_run_upgrade(key)
	_near(stats.get_final_money_multiplier(), 3.04073, "Dinero conserva decimales entre compras")
	_near(stats.get_final_max_energy(), 3.04073, "Resistencia conserva decimales entre compras")
	_near(stats.get_final_launch_rate(), 3.04073, "Frecuencia conserva decimales entre compras")

	_reset()
	stats.buy_run_upgrade("luck")
	stats.buy_run_upgrade("luck")
	_near(stats.get_final_jackpot_bonus(), 0.01554, "Jackpot suma puntos porcentuales configurados")

	_reset()
	save.save_data["prestige_points"] = 10000.0
	var shop: Control = load("res://scenes/ui/PrestigeShopModal.tscn").instantiate()
	root.add_child(shop)
	# Contaminar todas las estadísticas de la run y sus cachés antes de perder.
	for key: String in ["damage", "energy_max", "money", "luck", "launch_rate"]:
		stats.buy_run_upgrade(key)
	stats.apply_card_upgrade("test", "multi", [
		{"type": "damage", "value": 1.0}, {"type": "energy_max", "value": 1.0},
		{"type": "money", "value": 1.0}, {"type": "jackpot", "value": 0.1},
		{"type": "launch_rate", "value": 1.0}
	])
	var knife_ids: Array[String] = stats.get_sorted_knife_ids()
	game.run_equipped_knife = knife_ids.back()
	stats.invalidate_stat_cache()
	stats.get_final_damage()
	stats.get_final_max_energy()
	stats.get_final_money_multiplier()
	stats.get_final_jackpot_bonus()
	stats.get_final_launch_rate()
	game.end_run_failed()
	shop.open_modal()
	var expected_base: Dictionary = {"experience": 5.0, "expert_hand": 100.0, "good_provider": 1.0, "good_fortune": 0.0, "launch_speed": 1.0}
	var bonuses: Dictionary = {"experience": 0.2, "expert_hand": 0.2, "good_provider": 0.2, "good_fortune": 0.0777, "launch_speed": 0.25}
	var base_labels: Dictionary = {"experience": "Daño: 5.0", "expert_hand": "Resistencia: 100.0", "good_provider": "Dinero: x1.0", "good_fortune": "Jackpot: 0.00%", "launch_speed": "Velocidad: 1.0 frutas/s"}
	var purchased_labels: Dictionary = {"experience": "Daño: 6.0", "expert_hand": "Resistencia: 120.0", "good_provider": "Dinero: x1.2", "good_fortune": "Jackpot: 7.77%", "launch_speed": "Velocidad: 1.3 frutas/s"}
	for key: String in expected_base:
		_near(stats.get_permanent_stat(key), expected_base[key], "Prestigio sin restos temporales: " + key)
		var card: Node = shop._upgrade_cards[key]
		var before_text: String = card.current_stat_label.text
		_check(before_text == base_labels[key], "Valor visual base tras perder: " + key)
		_check(stats.buy_prestige_upgrade(key), "Compra permanente: " + key)
		var expected: float = expected_base[key] * (1.0 + bonuses[key]) if key != "good_fortune" else bonuses[key]
		_near(stats.get_permanent_stat(key), expected, "Efecto permanente exacto: " + key)
		_check(card.current_stat_label.text != before_text, "Tarjeta actualizada en el mismo momento: " + key)
		_check(card.current_stat_label.text == purchased_labels[key], "Valor visual exacto tras comprar: " + key)
		_check(shop._upgrade_cards[key] == card, "Se actualiza la tarjeta existente: " + key)
		_check(stats.buy_prestige_upgrade(key), "Segunda compra permanente: " + key)
		expected = expected * (1.0 + bonuses[key]) if key != "good_fortune" else 2.0 * bonuses[key]
		_near(stats.get_permanent_stat(key), expected, "Porcentaje permanente repetido: " + key)

	game.start_new_run()
	_near(stats.get_final_damage(), stats.get_permanent_stat("experience"), "Nueva run coincide con daño mostrado en prestigio")
	_near(stats.get_final_max_energy(), stats.get_permanent_stat("expert_hand"), "Nueva run coincide con resistencia permanente")
	_near(stats.get_final_money_multiplier(), stats.get_permanent_stat("good_provider"), "Nueva run coincide con dinero permanente")
	_near(stats.get_final_jackpot_bonus(), stats.get_permanent_stat("good_fortune"), "Nueva run coincide con jackpot permanente")
	_near(stats.get_final_launch_rate(), stats.get_permanent_stat("launch_speed"), "Nueva run coincide con frecuencia permanente")
	# Las características de armas/frutas ya no incorporan coste ni jackpot.
	var expected_cost: float = stats.balance.base_energy_cost * stats.balance.resistance_cost_multiplier
	var expected_chance: float = stats.get_final_jackpot_bonus()
	for knife_id: String in stats.get_sorted_knife_ids():
		game.run_equipped_knife = knife_id
		stats.invalidate_stat_cache()
		_near(stats.get_final_energy_cost(), expected_cost, "Todas las armas consumen la resistencia global: " + knife_id)
		_near(stats.get_final_jackpot_bonus(), expected_chance, "Cambiar arma no cambia el jackpot global")
	stats.apply_card_upgrade("cost_test", "energy_cost", -0.12, "Corte Eficiente")
	for knife_id: String in stats.get_sorted_knife_ids():
		game.run_equipped_knife = knife_id
		stats.invalidate_stat_cache()
		_near(stats.get_final_energy_cost(), expected_cost * 0.88, "Bonificación global igual para todas las armas")
	shop.queue_free()
	market.queue_free()
	# Detener el sonido de derrota antes de cerrar el servidor de audio.
	for child: Node in root.get_node("SoundManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await process_frame
	await process_frame
	print("Tiendas: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
