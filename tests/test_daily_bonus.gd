extends SceneTree
## Fase de BONUS: al cruzar la cuota del día el resto del dinero es ganancia
## extra, el HUD lo dice (rótulo + barra dorados) y se celebra con confeti.
## Ejecutar con XDG_DATA_HOME aislado, como test_shop_stats.gd.

var failures: int = 0
var checks: int = 0
var goal_events: int = 0
var goal_bonus: float = -1.0

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

func _on_goal_reached(bonus: float) -> void:
	goal_events += 1
	goal_bonus = bonus

func _reset_events() -> void:
	goal_events = 0
	goal_bonus = -1.0

func _money_label(hud: Control) -> Label:
	return hud.get_node("TopContainer/VBox/MoneyBar").get_child(0) as Label

func _money_bar(hud: Control) -> ProgressBar:
	return hud.get_node("TopContainer/VBox/MoneyBar") as ProgressBar

func _day_label(hud: Control) -> Label:
	return hud.get_node("TopContainer/VBox/TopHBox/DayLabel") as Label

func _run() -> void:
	var game := root.get_node("GameManager")
	var host := SubViewport.new()
	host.size = Vector2i(720, 1280)
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	host.add_child(main)
	var hud: Control = main.get_node("GameWorld/HUDLayer/HUD")
	var celebration: Node2D = main.get_node("GoalCelebration")
	await _settle()
	main.main_menu.start_game_requested.emit()
	game.order_goal_reached.connect(_on_goal_reached)

	var fruit := FruitData.new()
	fruit.id = "test_fruit"

	# --- Día 1 (cuota $0): el bonus arranca con la primera fruta --------------
	_reset_events()
	_check(not game.daily_goal_reached, "El día empieza con la meta pendiente")
	_check(game.get_order_bonus() == 0.0, "Sin cuota cumplida no hay bonus")

	var reward: float = game.register_fruit_cut(fruit, 5.0, false)
	_check(game.daily_goal_reached, "Día 1: la primera fruta cumple la cuota ($0)")
	_check(goal_events == 1, "Día 1: se avisa UNA vez (emitidos %d)" % goal_events)
	_check(is_equal_approx(goal_bonus, reward), "Día 1: el bonus es la ganancia extra (%f vs %f)" % [goal_bonus, reward])
	_check(is_equal_approx(game.get_order_bonus(), reward), "get_order_bonus() coincide con el total")

	# El HUD queda en modo BONUS: barra llena, rótulo dorado y confeti dorado.
	_check(_money_label(hud).text.contains("BONUS"), "El rótulo de dinero indica BONUS: " + _money_label(hud).text)
	_check(is_equal_approx(_money_label(hud).modulate.r, UiTheme.COLOR_ACCENT.r) and is_equal_approx(_money_label(hud).modulate.g, UiTheme.COLOR_ACCENT.g), "El rótulo de dinero se pinta de dorado")
	_check(_day_label(hud).text.contains("BONUS"), "El rótulo del día indica BONUS: " + _day_label(hud).text)
	_check(is_equal_approx(_money_bar(hud).value, _money_bar(hud).max_value), "La barra del día se queda llena en fase BONUS")
	_check(is_equal_approx(_money_bar(hud).modulate.g, UiTheme.COLOR_ACCENT.g), "La barra del día se pinta de dorada")
	var golden: Array[Node] = []
	for child in celebration.get_children():
		if child is CPUParticles2D:
			golden.append(child)
	_check(golden.size() == 1, "Se lanza un único confeti dorado (encontrados %d)" % golden.size())
	if golden.size() == 1:
		var particles := golden[0] as CPUParticles2D
		_check(not particles.one_shot and particles.emitting, "La lluvia sigue activa durante la fase BONUS")
		_check(celebration.z_index > main.get_node("Background").z_index, "La lluvia queda delante del fondo oscuro")
		_check(celebration.z_index < main.get_node("GameWorld").z_index and celebration.z_index < main.get_node("Fruit3DLayer").z_index, "La lluvia queda detrás del gameplay 2D y 3D")
		_check(particles.texture != null and particles.preprocess > 0.0, "La lluvia tiene confeti visible desde el inicio")
		_check(particles.explosiveness <= 0.1, "El confeti dorado cae suave, sin explotar")
		_check(particles.color_ramp != null and particles.color_ramp.colors[1].is_equal_approx(UiTheme.COLOR_ACCENT), "El confeti usa la rampa dorada del tema")
		_check(particles.amount <= 80, "El confeti dorado es discreto para móvil (%d partículas)" % particles.amount)

	# Seguir cortando acumula bonus sin volver a avisar.
	var before: float = game.get_order_bonus()
	game.register_fruit_cut(fruit, 3.0, false)
	_check(goal_events == 1, "El aviso no se repite con más frutas (emitidos %d)" % goal_events)
	_check(game.get_order_bonus() > before, "El bonus crece con cada fruta posterior")
	_check(celebration.get_child_count() == 1, "Seguir cortando no duplica la lluvia")
	await create_timer(3.6).timeout
	_check(is_instance_valid(golden[0]), "La lluvia permanece más allá de la vida de sus primeras partículas")
	game.order_completed.emit(game.current_order)
	await _settle()
	_check(celebration.get_child_count() == 0, "Al terminar el día se elimina la lluvia")

	# --- Cambio de día: el bonus vuelve a estar "por ganar" -------------------
	_reset_events()
	game.advance_to_next_order()
	_check(not game.daily_goal_reached, "El día nuevo reinicia el estado de meta")
	_check(game.get_order_bonus() == 0.0, "El día nuevo empieza sin bonus")
	_check(goal_events == 0, "El cambio de día no lanza confeti")
	_check(not _money_label(hud).text.contains("BONUS"), "El HUD vuelve al rótulo normal: " + _money_label(hud).text)
	_check(not _day_label(hud).text.contains("BONUS"), "El HUD vuelve al día normal: " + _day_label(hud).text)
	_check(is_equal_approx(_money_bar(hud).value, 0.0), "La barra del día nuevo vuelve a cero")

	# --- Día 2: el cruce ocurre al alcanzar la cuota, con el bonus correcto ---
	var target: float = game.order_target
	_check(target > 0.0, "El día 2 tiene cuota positiva")
	var needed: float = target * 0.6
	game.register_fruit_cut(fruit, needed, false)
	_check(goal_events == 0, "Todavía no se ha cumplido la cuota (%d)" % goal_events)
	game.register_fruit_cut(fruit, needed, false)
	_check(game.daily_goal_reached, "Día 2: se cumple la cuota al superarla")
	_check(goal_events == 1, "Día 2: un único aviso")
	_check(is_equal_approx(goal_bonus, game.order_progress - target), "Día 2: el bonus es el exceso sobre la cuota")
	_check(goal_bonus > 0.0, "Día 2: el bonus es positivo")
	_check(_money_label(hud).text.contains("BONUS"), "El HUD vuelve a mostrar BONUS en el día 2")
	await _settle()
	game.end_run_failed()
	await _settle()
	_check(celebration.get_child_count() == 0, "Al terminar el negocio no queda lluvia pendiente")
	host.queue_free()
	await process_frame

	print("BONUS diario: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
