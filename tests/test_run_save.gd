extends SceneTree
## Guardar y salir / Continuar la partida en curso.
## Validación de los escenarios clave: guardado desde pausa y mercado,
## continuar varias veces, recarga tras cerrar el juego, derrota real que
## invalida, confirmación antes de sobrescribir con Nueva Partida y progreso
## permanente intacto. Ejecutar con XDG_DATA_HOME aislado, como test_shop_stats.gd.

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
	for frame in 6:
		await process_frame

func _run() -> void:
	var save: Node = root.get_node("SaveManager")
	var game: Node = root.get_node("GameManager")
	var stats: Node = root.get_node("StatsManager")
	var recipes: Script = load("res://scripts/models/RecipeDatabase.gd")
	if not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/"):
		_check(false, "Esta prueba necesita XDG_DATA_HOME aislado bajo /tmp")
		quit(1)
		return
	DirAccess.remove_absolute(save.SAVE_FILE_PATH)
	save.reset_save()
	_check(not save.has_active_run(), "Tras un reset no hay partida guardada para continuar")

	# --- 1) Guardar y salir desde PAUSA y continuar ---------------------------
	game.start_new_run()
	game.run_money = 1000000.0
	stats.buy_run_upgrade("damage")
	stats.apply_card_upgrade(String(CardDatabase.ALL_CARDS[0]["id"]), "money", 0.25, "Test Card")
	game.register_gummy_produced(recipes.get_recipe_data("bear_classic"), 10.0, false)
	var money_before: float = game.run_money
	var damage_before: float = stats.get_final_damage()
	game.current_energy = 37.5
	game.round_time_left = 42.0
	game.pause_turn()
	save.save_active_run(game.capture_run_state())
	_check(save.has_active_run(), "Guardar desde pausa persiste la run")
	game.abandon_run_to_menu()
	_check(game.current_state == game.GameState.MENU, "Abandonar al menú no termina la run")
	_check(game._run_has_ended == false, "Abandonar no cuenta como derrota (no run_ended)")
	_check(game.restore_run_state(save.get_active_run_snapshot()), "La instantánea de pausa es válida")
	_check(game.run_money == money_before, "El dinero se restaura exacto")
	_check(game.current_energy == 37.5, "La resistencia se restaura sin recargarse")
	_check(game.round_time_left == 42.0, "El tiempo de ronda se restaura")
	_check(stats.run_upgrade_levels["damage"] == 1, "La mejora comprada se restaura")
	_check(stats.card_money_multiplier == 1.25, "El multiplicador del comodín se restaura")
	_check(stats.active_cards.size() == 1, "El comodín activo se restaura")
	_check(is_equal_approx(stats.get_final_damage(), damage_before), "El daño final coincide tras restaurar")
	_check(game.current_state == game.GameState.PLAYING, "Restaura al estado de juego")
	game.resume_turn()
	_check(game.is_round_active, "Continuar reactiva la ronda activa")

	# --- 2) Guardar y salir desde el MERCADO (entre pedidos) ------------------
	game.end_run_failed()
	_check(not save.has_active_run(), "La derrota real invalida la partida guardada")
	game.start_new_run()
	game.run_money = 2000.0
	game.current_order = 3
	game.order_target = game.get_order_target_for(3)
	game.order_progress = game.order_target
	game.daily_goal_reached = true
	game.current_state = game.GameState.ORDER_CLEARED_CARD_SELECT
	game.pause_turn()
	save.save_active_run(game.capture_run_state())
	game.abandon_run_to_menu()
	_check(save.has_active_run(), "Guardar desde el mercado persiste la run")
	_check(game.restore_run_state(save.get_active_run_snapshot()), "La instantánea de mercado es válida")
	_check(game.current_state == game.GameState.ORDER_CLEARED_CARD_SELECT, "Restaura al estado de mercado")
	_check(game.current_order == 3, "Restaura el día del mercado")
	_check(not game.is_round_active, "En el mercado la ronda sigue pausada")

	# --- 3) Continuar varias veces no altera la run ---------------------------
	for i in 4:
		save.save_active_run(game.capture_run_state())
		game.abandon_run_to_menu()
		_check(save.has_active_run(), "La run sigue guardada tras abandono repetido")
		_check(game.restore_run_state(save.get_active_run_snapshot()), "Continuar por enésima vez funciona")
		_check(game.run_money == 2000.0, "Continuar varias veces no duplica el dinero")

	# --- 4) Cerrar el juego y reabrir: el archivo conserva la run -------------
	save.save_to_disk()
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save.SAVE_FILE_PATH))
	_check(disk.active_run is Dictionary and not disk.active_run.is_empty(), "El JSON en disco contiene la run")
	_check(int(disk.active_run.current_order) == 3, "El JSON conserva el día exacto")
	# Reload limpio: defaults sin run + load_data() debe rellenarla entera (el
	# merge carga active_run al completo, sin descartarla por sub-claves).
	var pristine_defaults: Dictionary = save.save_data.duplicate(true)
	pristine_defaults["active_run"] = {}
	save.save_data = pristine_defaults
	save.load_data()
	_check(save.has_active_run(), "Reload conserva la run (el merge no la descarta)")
	_check(int(save.get_active_run_snapshot().get("current_order", 0)) == 3, "Reload restaura el día")

	# --- 5) Derrota real: imposible continuar ---------------------------------
	game.restore_run_state(save.get_active_run_snapshot())
	game.end_run_failed()
	_check(not save.has_active_run(), "Perder el día invalida la run guardada")
	var disk_after_loss: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save.SAVE_FILE_PATH))
	_check(disk_after_loss.active_run is Dictionary and disk_after_loss.active_run.is_empty(), "La derrota limpia la run del archivo")
	_check(not game.restore_run_state(save.get_active_run_snapshot()), "No se puede continuar una run ya perdida")

	# --- 6) Instantánea corrupta se descarta sola -----------------------------
	save.save_data["active_run"] = {"current_order": 1}
	save.save_to_disk()
	_check(save.has_active_run(), "La run malformada está presente")
	_check(not game.restore_run_state(save.get_active_run_snapshot()), "Restaurar una run corrupta falla")
	_check(not save.has_active_run(), "La run corrupta se invalida y borra")
	_check(not game.restore_run_state({}), "Una instantánea vacía se rechaza")

	# --- 7) Migración: v3 sella la versión y no toca la run guardada ----------
	var converter: Script = load("res://scripts/models/SaveMigration.gd")
	var legacy: Dictionary = converter.migrate({"version": 2, "total_gummies_produced": 5})
	_check(legacy.version == converter.CURRENT_VERSION and converter.CURRENT_VERSION == 3, "El esquema se actualiza a v3")
	var keep: Dictionary = converter.migrate({"version": 3, "active_run": {"a": 1}})
	_check(keep.active_run == {"a": 1}, "La migración conserva la run guardada")

	# --- 8) Nueva partida: confirmar antes de sobrescribir --------------------
	game.start_new_run()
	game.run_money = 500.0
	save.save_active_run(game.capture_run_state())
	game.abandon_run_to_menu()
	_check(save.has_active_run(), "Hay partida guardada para el menú")
	save.save_data["prestige_points"] = 123.5
	save.save_data["prestige_levels"]["experience"] = 4
	var host := SubViewport.new()
	host.size = Vector2i(720, 1280)
	root.add_child(host)
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	host.add_child(menu)
	await _settle()
	await _refresh_menu_button(menu)
	_check(menu.get_node("CenterVBox/ButtonsVBox/ContinueButton").visible, "El menú muestra Continuar con run guardada")
	var continue_label: String = menu.get_node("CenterVBox/ButtonsVBox/ContinueButton").text
	_check(continue_label.contains("DÍA 1"), "El botón Continuar indica el día de la run: " + continue_label)
	var starts := {"value": 0}
	menu.start_game_requested.connect(func(): starts.value += 1)
	menu._on_play_pressed()
	_check(menu.get_node("NewRunConfirmDialog").visible, "Jugar con run guardada abre la confirmación")
	_check(starts.value == 0, "No arranca nueva partida hasta confirmar")
	# Cancelar: la run queda intacta.
	menu.get_node("NewRunConfirmDialog/Card/VBox/ButtonsHBox/CancelButton").pressed.emit()
	_check(save.has_active_run(), "Cancelar conserva la partida guardada")
	_check(starts.value == 0, "Cancelar no arranca una nueva partida")
	# Confirmar: se invalida la run y se arranca.
	menu._on_play_pressed()
	menu.get_node("NewRunConfirmDialog/Card/VBox/ButtonsHBox/OkButton").pressed.emit()
	_check(not save.has_active_run(), "Confirmar borra la partida guardada")
	_check(starts.value == 1, "Confirmar arranca la nueva partida")

	# --- 9) El progreso PERMANENTE nunca se toca ------------------------------
	_check(save.save_data.prestige_points == 123.5, "El saldo permanente intacto tras continuar/confirmar")
	_check(save.save_data.prestige_levels.experience == 4, "El nivel de prestigio intacto")
	game.end_run_failed()
	_check(save.get_prestige_points() == 123.5, "La derrota no borra el progreso permanente")
	# Reset limpio: también descarta la run guardada.
	game.start_new_run()
	save.save_active_run(game.capture_run_state())
	save.reset_save()
	_check(not save.has_active_run(), "El reinicio de progreso también borra la run guardada")

	menu.queue_free()
	host.queue_free()
	await _settle()
	print("Guardado de partida: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)

# Espejo del refresco por visibilidad del menú (NOTIFICATION_VISIBILITY_CHANGED
# no se dispara al instanciar la escena encima de un SubViewport).
func _refresh_menu_button(menu: Control) -> void:
	menu._refresh_continue_button()