extends SceneTree
## Identidad visible, descubrimientos históricos y flujo de partida Crazy Gummy.
## Ejecutar con XDG_DATA_HOME aislado: este test escribe y recarga su propio save.

var failures: int = 0
var checks: int = 0
var _legacy_words := RegEx.new()

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _check_text(text: String, context: String) -> void:
	_check(_legacy_words.search(text) == null, "Texto heredado en " + context + ": " + text)

func _check_controls(node: Node) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		_check_text(node.text, str(node.get_path()))
	if node is Control:
		_check_text(node.tooltip_text, str(node.get_path()) + " tooltip")
	if node is TabContainer:
		for index in node.get_tab_count():
			_check_text(node.get_tab_title(index), str(node.get_path()) + " pestaña")
	for child in node.get_children():
		_check_controls(child)

func _settle() -> void:
	for frame in 12:
		await process_frame

func _run() -> void:
	_legacy_words.compile("(?i)\\b(recipes?|frutas?|frutal|cosecha|cortar|corta|corte|cortes|slice|cut|fresa|banana|melocotón|cereza|naranja|manzana|pera|kiwi|mango|limón|sandía|melón|piña|papaya|coco|aguacate|pitahaya|guayaba|membrillo|calabaza|daño|vida|energía|piedras?)\\b")
	var save: Node = root.get_node("SaveManager")
	var stats: Node = root.get_node("StatsManager")
	var game: Node = root.get_node("GameManager")
	var achievements: Node = root.get_node("AchievementManager")
	root.get_node("SoundManager").is_sound_enabled = false
	game.set_process(false)
	save.reset_save()
	_check(CardDatabase.ALL_CARDS.size() == 108, "Se conservan los 108 comodines")
	_check(achievements.DEFINITIONS.size() == 121, "Se conservan los 121 logros")
	var ids: Array[String] = []
	for card in CardDatabase.ALL_CARDS:
		_check(not ids.has(card.id), "ID único de comodín: " + card.id)
		ids.append(card.id)
		_check_text(card.title, card.id)
		_check_text(card.desc, card.id)
	for definition in achievements.DEFINITIONS:
		_check_text(definition.name, definition.id)
		_check_text(definition.desc, definition.id)
	var database: Script = load("res://scripts/models/RecipeDatabase.gd")
	var recipe_ids: Array[String] = database.get_sorted_recipe_ids()
	_check(recipe_ids.size() == 20, "Se conservan las 20 recetas")
	for id in recipe_ids:
		_check_text(database.get_recipe_data(id).display_name, id)
	var renamed: Dictionary = {
		"card_impacto_ligero": "Impacto Ligero", "card_cubo_frágil": "Cubo Frágil",
		"card_gelatina_dorada": "Gelatina Dorada", "card_impacto_colosal": "Impacto Colosal"
	}
	# Simula descubrimientos y logros de una partida anterior a la migración.
	save.save_data["discovered_cards"] = renamed.keys()
	save.save_data["achievements"]["unlocked"] = ["aprendiz_de_gelatina", "osito_preferido"]
	save.save_to_disk()
	save.save_data["discovered_cards"] = []
	save.save_data["achievements"]["unlocked"] = []
	save.load_data()
	_check(save.get_discovered_cards().size() == renamed.size(), "Carga conserva descubrimientos históricos")
	_check(achievements.is_unlocked("osito_preferido"), "Carga conserva IDs de logros históricos")
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.cards_modal.open_discovered_cards()
	var thumbnails: Array[Node] = main.cards_modal.cards_grid.get_children()
	_check(thumbnails.size() == renamed.size(), "Galería encuentra todas las cartas históricas")
	for thumbnail in thumbnails:
		_check(thumbnail._data.title == renamed[thumbnail._data.id], "Galería presenta el nombre nuevo del ID guardado")
	main.cards_modal.hide()
	# Navegación real de Main; la prueba controla el reloj y las apariciones.
	main.main_menu.start_game_requested.emit()
	main.block_spawner.disable_spawning()
	_check(main.game_world.visible and main.hud.visible and not main.main_menu.visible, "Jugar abre gameplay y HUD")
	var cube: Node = load("res://scenes/game/GummyBlock.tscn").instantiate()
	main.block_spawner.add_child(cube)
	cube.setup(database.create_block_recipe("bear_classic"))
	var hp: float = cube.current_hp
	cube.take_damage(stats.get_final_damage(), false)
	_check(cube.current_hp == hp - 5.0, "Potencia conserva reducción de dureza exacta")
	cube.take_damage(hp, false)
	_check(cube.is_dying and game.total_gummies_produced_run == 1 and game.run_money > 0.0, "Ruptura produce una gomita y recompensa")
	_check(game.current_streak == 1, "Racha cuenta gomitas producidas, no golpes")
	# Hitos y bonus mantienen sus valores existentes.
	for index in 9:
		game.register_gummy_produced(database.get_recipe_data("bear_classic"), 1.0, false)
	_check(game.current_streak == 10 and is_equal_approx(game.get_streak_multiplier(), 1.1), "Hito de 10 conserva x1.10")
	game.break_streak()
	_check(game.current_streak == 0 and game.get_streak_multiplier() == 1.0, "Ruptura de racha conserva reinicio")
	var golden: Node = load("res://scenes/game/GummyBlock.tscn").instantiate()
	main.block_spawner.add_child(golden)
	golden.setup(database.create_block_recipe("bear_classic"))
	golden.is_golden = true
	var before: float = game.run_money
	golden.take_damage(golden.current_hp, false)
	_check(is_equal_approx(game.run_money - before, 4.0), "Dorada conserva máximo x Jackpot x2 extra")
	_check(game.total_golden_gummies_run == 1 and game.total_jackpots_run >= 1, "Dorada conserva contadores y Jackpot garantizado")
	game.pause_turn()
	main._on_open_stats_requested()
	_check(main.stats_modal.visible and not game.is_round_active, "Datos abre modal pausado")
	main.stats_modal._on_close_pressed()
	_check(game.is_round_active, "Cerrar Datos reanuda")
	# Fin de día con meta cumplida: reputación, resumen, comodín y mercado.
	game.round_time_left = 0.0
	game._process(0.0)
	_check(main.card_selection_modal.visible and save.get_prestige_points() == 1.0, "Fin de día conserva reputación y elección")
	await _settle()
	main.card_selection_modal._on_card_selected(CardDatabase.ALL_CARDS[0])
	_check(main.run_upgrade_modal.visible and stats.active_cards.size() == 1, "Elegir abre mercado y aplica un solo efecto")
	game.run_money = 1000.0
	main.run_upgrade_modal.open_modal(1)
	main.run_upgrade_modal._recipe_rows["ring"].buy_btn.pressed.emit()
	_check(game.is_recipe_unlocked_this_run("ring"), "Adquirir receta conserva desbloqueo")
	_check(main.run_upgrade_modal.get_node("Panel/VBox/TabContainer").get_tab_title(1) == "Recetas", "Título visible independiente de ruta histórica")
	main.run_upgrade_modal._on_continue_pressed()
	main.block_spawner.disable_spawning()
	_check(game.current_order == 2 and game.is_round_active, "Continuar conserva avance de día")
	# Cubre textos construidos y controles de todas las pantallas principales.
	main.progress_modal.open_modal()
	main.prestige_shop_modal.open_modal()
	main.achievements_modal.open_modal()
	await _settle()
	_check_controls(main)
	main.progress_modal.hide()
	main.prestige_shop_modal.hide()
	main.achievements_modal.hide()
	game.end_run_failed()
	_check(main.results_modal.visible, "Derrota abre resultados")
	_check_controls(main.results_modal)
	main.results_modal.return_to_menu_requested.emit()
	_check(main.main_menu.visible and not main.game_world.visible, "Resultados vuelve al menú")
	main.main_menu.start_game_requested.emit()
	main.block_spawner.disable_spawning()
	_check(not game.is_recipe_unlocked_this_run("ring") and stats.active_cards.is_empty(), "Nuevo negocio reinicia recetas y comodines temporales")
	_check(save.get_unlocked_recipes().has("ring") and save.get_discovered_cards().has("card_impacto_ligero"), "Descubrimientos históricos sobreviven al reinicio")
	game.current_order = game.get_win_day()
	game.order_target = game.get_order_target_for(game.current_order)
	game.order_progress = game.order_target
	game.run_money = game.order_target
	game.round_time_left = 0.0
	game._process(0.0)
	_check(main.credits_modal.visible, "Completar la meta final abre créditos")
	main.credits_modal.continue_btn.pressed.emit()
	_check(main.card_selection_modal.visible and not main.credits_modal.visible, "Continuar desde créditos retoma resumen y comodines")
	main.card_selection_modal._on_card_selected(CardDatabase.ALL_CARDS[0])
	main.run_upgrade_modal.continue_button.pressed.emit()
	main.block_spawner.disable_spawning()
	_check(game.current_order == 101, "Tras créditos se puede jugar el día 101")
	_check_controls(main.credits_modal)
	main.queue_free()
	await _settle()
	print("Migración Crazy Gummy: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
