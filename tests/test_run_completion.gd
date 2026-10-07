extends SceneTree
## Cierre real desde créditos, pausa y derrota. Usar XDG_DATA_HOME aislado.

var checks := 0
var failures := 0
var summaries: Array[Dictionary] = []
var main: Node
var game: Node
var save: Node

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _start() -> void:
	main._show_main_menu()
	main.main_menu.start_game_requested.emit()
	main.block_spawner.disable_spawning()
	_check(game.completed_orders_run == 0 and not game.has_won_run(), "Nuevo negocio reinicia éxito y días completos")

func _complete(day: int) -> void:
	game.current_order = day
	game.order_target = game.get_order_target_for(day)
	game.order_progress = game.order_target
	game.run_money = game.order_target + 100.0
	game._end_round_and_validate()

func _expect_end(completed: int, successful: bool, reason: String, bankrupt_before: float) -> void:
	var summary: Dictionary = summaries[-1]
	_check(summary.completed_orders == completed, "Registra todos los días completos: %d" % completed)
	_check(summary.successful == successful and summary.end_reason == reason, "Resultado y motivo correctos")
	_check(not game.is_round_active and game.current_state == game.GameState.RESULTS, "Run cerrada en resultados")
	_check(main.results_modal.visible and not main.credits_modal.visible and not main.card_selection_modal.visible and not main.run_upgrade_modal.visible, "Resultados sin otros modales activos")
	var title: String = main.results_modal.title_label.text
	_check(title == ("🏆 NEGOCIO EXITOSO" if successful else ("NEGOCIO EN QUIEBRA" if reason == "failed" else "NEGOCIO FINALIZADO")), "Título distingue éxito, cierre y quiebra")
	var achievements := root.get_node("AchievementManager")
	var expected_bankrupt: float = bankrupt_before + (1 if reason == "failed" and not successful else 0)
	_check(achievements.get_metric("runs_bankrupt") == expected_bankrupt, "Solo quiebra real antes de victoria suma quiebras")
	var events := summaries.size()
	var gummies: int = save.save_data.total_gummies_produced
	var prestige: float = save.get_prestige_points()
	game.end_run()
	game.end_run_failed()
	_check(summaries.size() == events and save.save_data.total_gummies_produced == gummies and save.get_prestige_points() == prestige, "Doble cierre no duplica estadísticas ni reputación")
	save.load_data()
	_check(save.save_data.high_score_order >= completed and save.save_data.best_clients_in_day >= completed and save.save_data.total_gummies_produced == gummies, "Récord y producción persisten en disco")
	main.results_modal.continue_btn.pressed.emit()
	_check(main.main_menu.visible and not main.results_modal.visible, "Continuar resultados vuelve al menú")

func _run() -> void:
	game = root.get_node("GameManager")
	save = root.get_node("SaveManager")
	root.get_node("SoundManager").is_sound_enabled = false
	game.set_process(false)
	game.run_ended.connect(func(summary: Dictionary): summaries.append(summary))
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var achievements := root.get_node("AchievementManager")
	var bankrupt_before: float = achievements.get_metric("runs_bankrupt")

	# Salir justo en los créditos cuenta el día 100, no 99, y toda la producción.
	_start()
	var initial_gummies: int = save.save_data.total_gummies_produced
	game.total_gummies_produced_run = 7
	_complete(100)
	_check(main.credits_modal.visible and game.completed_orders_run == 100, "Completar día 100 abre créditos y marca éxito")
	var prestige_after_day: float = save.get_prestige_points()
	main.credits_modal.exit_btn.pressed.emit()
	_expect_end(100, true, "quit", bankrupt_before)
	_check(save.save_data.total_gummies_produced == initial_gummies + 7 and save.get_prestige_points() == prestige_after_day, "Salida de créditos registra producción sin reputación doble")
	main.progress_modal.open_modal()
	_check(save.save_data.best_clients_in_day >= 100, "Progreso reconoce los 100 días")

	# Continuar conserva la run; perder el día 101 sigue siendo negocio exitoso.
	_start()
	_complete(100)
	var events_before := summaries.size()
	main.credits_modal.continue_btn.pressed.emit()
	_check(summaries.size() == events_before and main.card_selection_modal.visible, "Continuar créditos no termina la run")
	main.card_selection_modal._on_card_selected(CardDatabase.ALL_CARDS[0])
	main.run_upgrade_modal.continue_button.pressed.emit()
	main.block_spawner.disable_spawning()
	_check(game.current_order == 101, "Continúa al día 101")
	game.order_progress = 0.0
	game._end_round_and_validate()
	_expect_end(100, true, "failed", bankrupt_before)

	# Fin de día posterior sin repetir créditos; salir en plena ronda conserva 125.
	_start()
	_complete(125)
	_check(not main.credits_modal.visible and main.card_selection_modal.visible and main.card_selection_modal.current_completed_order == 125, "Día 125 conserva resumen del día real sin repetir créditos")
	main.card_selection_modal.hide()
	game.advance_to_next_order()
	main.hud._on_pause_button_pressed()
	main.hud._on_pause_quit_pressed()
	_check(main.hud.pause_confirm_dialog.visible, "Salir tras victoria abre confirmación")
	main.hud._on_quit_confirmed()
	_expect_end(125, true, "quit", bankrupt_before)

	# No basta estar jugando el día 100: es necesario haberlo completado.
	_start()
	_complete(99)
	main.card_selection_modal.hide()
	game.advance_to_next_order()
	game.order_progress = 0.0
	game._end_round_and_validate()
	_expect_end(99, false, "failed", bankrupt_before)
	bankrupt_before = achievements.get_metric("runs_bankrupt")

	_start()
	_complete(41)
	main.card_selection_modal.hide()
	game.advance_to_next_order()
	main.hud._on_quit_confirmed()
	_expect_end(41, false, "quit", bankrupt_before)

	# Impuesto impagable después de victoria también usa el cierre exitoso.
	_start()
	_complete(100)
	game.run_money = 0.0
	main.credits_modal.continue_btn.pressed.emit()
	_expect_end(100, true, "failed", bankrupt_before)
	main.queue_free()
	await process_frame
	print("Cierre de negocio: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
