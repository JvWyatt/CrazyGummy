extends Node
# ============================================================================
# GameManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Controla el estado de LA PARTIDA ACTUAL ("el negocio"): dinero de la
# partida, día/pedido actual, energía actual, y qué frutas y armas se han
# desbloqueado/equipado SOLO durante este negocio (se reinician si el negocio
# quiebra). Para el progreso PERMANENTE (prestigio, reputación, desbloqueos
# históricos) revisa SaveManager.gd en su lugar.
#
# La ronda dura como máximo get_round_time() (límite FIJO no mejorable): si
# se agota el tiempo, pasa lo mismo que si se agota la resistencia (se valida
# si se cumplió el objetivo). No existe mejora que lo modifique.
# Otros scripts escuchan las señales de aquí (money_changed, energy_changed,
# etc.) para actualizar la interfaz (HUD.gd) sin tener que consultar estas
# variables todo el tiempo.
# ============================================================================

signal money_changed(current_money: float)
signal order_progress_changed(progress: float, target: float)
signal order_completed(order_num: int)
# Se emite UNA sola vez al cruzar la cuota del día: a partir de ahí el resto del
# dinero del día es ganancia extra (fase de BONUS). Llega el bonus ya calculado
# (el dinero generado por encima de la cuota en ese instante).
signal order_goal_reached(bonus: float)
signal energy_changed(current_energy: float, max_energy: float)
signal round_time_changed(time_left: float)
signal run_started
signal run_ended(summary: Dictionary)
signal fruit_destroyed_event(fruit_data: FruitData, reward: float, is_jackpot: bool)
signal run_knife_equipped(knife_id: String)
signal streak_changed(current_streak: int, multiplier: float)
signal streak_milestone(milestone: int)
signal streak_broken

# Cuánto dinero hay que ganar para completar cada día/pedido (pedido 1, 2, 3...).
# NO es una tabla fija: los días son infinitos y la cuota se calcula con una
# fórmula geométrica sencilla (ver get_order_target_for). El día 1 es de regalo
# (objetivo $0: basta con terminar la ronda) y desde el día 2 la cuota arranca
# en balance.base_order_target y crece × order_target_growth por día: día 100
# ≈ $10 × 1.21^98 ≈ $1.30B. Cada día es alcanzable con la fruta/arma del día
# anterior y deja un excedente para comprar mejoras.
# Los valores de la cuota, la duración de la ronda (round_time_seconds) y el
# día de victoria (win_day) se editan VISUALMENTE en res://data/balance.tres
# (recurso BalanceData), igual que el resto del balance del juego.

# OBJETIVO DEL JUEGO: llegar a balance.win_day (día 100 por defecto). Al
# completarlo se muestran los créditos (con un "Continuar" para seguir
# haciendo récords). La cuota crece de forma geométrica: día 1 = $0 (regalo) y
# día N = base × growth^(N-2). Como el juego es de días infinitos, no existe
# una tabla: la fórmula cubre todos los días.

# Estados posibles de la partida: qué pantalla/momento del flujo estamos.
enum GameState {
	MENU,
	PLAYING,
	ORDER_CLEARED_CARD_SELECT,
	RUN_UPGRADES_OPEN,
	STATS_OPEN,
	RESULTS
}

var current_state: GameState = GameState.MENU

# --- Estado del negocio actual (se resetea en start_new_run) ---
var current_order: int = 1        # Pedido/día actual (1, 2, 3...)
var order_target: float = 0.0                      # Dinero necesario para completar el pedido actual
var order_progress: float = 0.0   # Dinero ganado hasta ahora en este pedido
# La cuota del día ya se ha alcanzado AL MENOS una vez en esta ronda. Desde ese
# momento todo el dinero que se genere es ganancia extra (BONUS). Se reinicia en
# cada día nuevo (advance_to_next_order) y en cada negocio (start_new_run).
var daily_goal_reached: bool = false
var run_money: float = 0.0        # Dinero disponible para gastar en la tienda (se resetea cada negocio)

var total_money_generated_run: float = 0.0
var total_fruits_cut_run: int = 0
var total_jackpots_run: int = 0
var total_golden_fruits_run: int = 0

# Duración máxima de cada ronda en segundos (balance.round_time_seconds,
# editable en res://data/balance.tres). Es un límite FIJO: no depende de
# mejoras (no se puede mejorar), solo se rellena en start_new_run/advance_to_next_order.
func get_round_time() -> float:
	return StatsManager.balance.round_time_seconds

# Día en el que el juego se considera completado (se muestran los créditos).
# Editable en res://data/balance.tres (campo win_day).
func get_win_day() -> int:
	return int(StatsManager.balance.win_day)

# Estado de la ronda actual: activa mientras se está jugando el día.
var is_round_active: bool = false
var current_energy: float = 100.0
var round_time_left: float = 0.0

func _process(delta: float) -> void:
	if not is_round_active or current_state != GameState.PLAYING:
		return
	round_time_left = maxf(0.0, round_time_left - delta)
	emit_signal("round_time_changed", round_time_left)
	if round_time_left <= 0.0:
		_end_round_and_validate()

# Fruits/knives bought during the current run only - reset on start_new_run(), like run upgrades and cards
var run_unlocked_fruits: Array[String] = ["strawberry"]
var run_unlocked_knives: Array[String] = ["weapon_fist"]
var run_equipped_knife: String = "weapon_fist"

# ----------------------------------------------------------------------------
# RACHA DE FRUTAS
# ----------------------------------------------------------------------------
# La racha sube de 1 por cada fruta cortada y se REINICIA a 0 si el jugador
# toca una piedra/obstáculo. El multiplicador de monedas aplicado corresponde
# al último hito alcanzado (y se queda en x2.00 tras superar 50).
var current_streak: int = 0
# Caché del multiplicador del mayor hito de racha alcanzado: se recalcula SOLO
# al CAMBIAR la racha (ver _refresh_streak_multiplier), para que
# get_streak_multiplier() haga O(1) en el hot path de cada corte.
var _streak_mult: float = 1.0

# --- Tracking de logros por día/negocio (se resetea) -----------------------
var _stones_hit_this_day: int = 0
# True cuando la "primera piedra gratis" del día ya se consumió (ver comodín
# raro first_stone_free). Se resetea al empezar cada día.
var _first_stone_consumed_this_day: bool = false
var _crits_this_day: int = 0
var _golden_fruits_this_day: int = 0
var _normal_fruits_this_day: int = 0
var _fruits_this_day_set: Dictionary = {}
var _upgrades_bought_this_run: int = 0
var _fist_cuts_this_run: int = 0
# Prestigio (reputación) ganado durante ESTE negocio: 1 ⭐ por día + bonus de
# comodines ACTIVOS. Se acumula en _on_day_completed y se muestra en el
# resumen final SIN sumarse de nuevo (ya se añadió a SaveManager día a día).
var prestige_earned_this_run: float = 0.0
# "Hachero Total": se marca al cambiar de arma y se evalúa al completar el día
# (la ventana cubre también la tienda entre días: ver _on_day_completed).
var _weapon_changed_this_day: bool = false

# Hitos de racha -> multiplicador de monedas. La racha empieza a otorgar
# multiplicador a partir de 10 frutas consecutivas; el multiplicador activo es
# el del mayor hito alcanzado (ver get_streak_multiplier). A partir de 1000,
# cada 1000 frutas adicionales suma +1.00 al multiplicador (2000 → ×3.50,
# 3000 → ×4.50...). NO existen incrementos intermedios fuera de estos hitos.
const STREAK_MILESTONES: Dictionary = {
	10: 1.10,
	50: 1.20,
	100: 1.30,
	250: 1.50,
	500: 2.00,
	1000: 2.50,
}

# Multiplicador según el número de frutas consecutivas cortadas: el del mayor
# hito alcanzado MÁS el bonus ADITIVO acumulado por comodines de racha.
func get_streak_multiplier() -> float:
	return maxf(_streak_mult, 1.0) + StatsManager.get_streak_bonus()

# Recalcula _streak_mult recorriendo los hitos de racha. Solo se llama cuando
# cambia la racha (incremento, ruptura o reseteo de día), no en cada corte.
func _refresh_streak_multiplier() -> void:
	var mult: float = 1.0
	for m in STREAK_MILESTONES:
		if current_streak >= int(m):
			mult = STREAK_MILESTONES[m]
	# A partir del último hito (1000), cada 1000 frutas adicionales suma +1.00.
	var last_m: int = 1000
	if current_streak >= last_m:
		var bands: int = int((current_streak - last_m) / 1000)
		mult = float(STREAK_MILESTONES[1000]) + float(bands) * 1.0
	_streak_mult = mult

# Incrementa la racha al cortar una fruta (llamado desde register_fruit_cut).
func _increment_streak() -> void:
	var next_streak: int = current_streak + 1
	# Es un hito si está en la tabla fija (10..500 en el rango 1000) o si es un
	# múltiplo de 1000 por encima del último hito (2000, 3000...).
	var reached_milestone: bool = STREAK_MILESTONES.has(next_streak) or (next_streak > 1000 and next_streak % 1000 == 0)
	current_streak = next_streak
	_refresh_streak_multiplier()
	var mult: float = get_streak_multiplier()
	emit_signal("streak_changed", current_streak, mult)
	if reached_milestone:
		emit_signal("streak_milestone", next_streak)
	if current_streak > AchievementManager.get_metric("max_streak"):
		AchievementManager.set_metric("max_streak", current_streak)
	if current_streak == 15:
		AchievementManager.set_flag("blind_streak")

# Reinicia la racha a 0 y el multiplicador a x1.00 (al tocar una piedra).
func break_streak() -> void:
	if current_streak != 0:
		current_streak = 0
		_refresh_streak_multiplier()
		emit_signal("streak_changed", 0, 1.0)
		emit_signal("streak_broken")
		AchievementManager.record_metric("streak_broke", 1)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_order_target_for(order_num: int) -> float:
	# Día 1 es de regalo: objetivo $0, se completa con terminar la ronda.
	# Desde el día 2 la cuota arranca en balance.base_order_target y crece
	# × order_target_growth por día:
	# día N = base_order_target × order_target_growth^(N-2).
	if order_num <= 1:
		return 0.0
	var base: float = StatsManager.balance.base_order_target * pow(StatsManager.balance.order_target_growth, order_num - 2)
	return base * StatsManager.get_order_target_multiplier()

# Dinero generado por encima de la cuota del día: la ganancia extra (BONUS) que
# se lleva el jugador si sigue cortando fruta después de cumplir el objetivo.
func get_order_bonus() -> float:
	return maxf(0.0, order_progress - order_target)

# Empieza un negocio nuevo desde cero: reinicia dinero, pedido, energía y
# TAMBIÉN las frutas/armas desbloqueadas de la partida anterior (solo el
# progreso permanente en SaveManager sobrevive a esto).
func start_new_run() -> void:
	StatsManager.reset_run_stats()
	current_order = 1
	order_target = get_order_target_for(current_order)
	order_progress = 0.0
	daily_goal_reached = false
	run_money = 0.0
	total_money_generated_run = 0.0
	total_fruits_cut_run = 0
	total_jackpots_run = 0
	total_golden_fruits_run = 0
	current_energy = StatsManager.get_final_max_energy()
	current_state = GameState.PLAYING
	run_unlocked_fruits = ["strawberry"]
	run_unlocked_knives = ["weapon_fist"]
	run_equipped_knife = "weapon_fist"
	StatsManager.invalidate_stat_cache()
	current_streak = 0
	_refresh_streak_multiplier()
	_stones_hit_this_day = 0
	_first_stone_consumed_this_day = false
	_crits_this_day = 0
	_golden_fruits_this_day = 0
	_normal_fruits_this_day = 0
	_fruits_this_day_set = {}
	_upgrades_bought_this_run = 0
	_fist_cuts_this_run = 0
	prestige_earned_this_run = 0.0
	_weapon_changed_this_day = false
	emit_signal("streak_changed", 0, 1.0)
	emit_signal("run_knife_equipped", run_equipped_knife)
	SaveManager.record_day_started()
	
	round_time_left = get_round_time()
	emit_signal("round_time_changed", round_time_left)
	emit_signal("run_started")
	emit_signal("money_changed", run_money)
	emit_signal("order_progress_changed", order_progress, order_target)
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())

	is_round_active = true

func pause_turn() -> void:
	is_round_active = false

func resume_turn() -> void:
	if current_state == GameState.PLAYING:
		is_round_active = true

func consume_energy(amount: float) -> bool:
	if current_energy < amount:
		current_energy = 0.0
		emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
		_end_round_and_validate()
		return false

	current_energy -= amount
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
	if current_energy <= 0.0:
		_end_round_and_validate()
	return true

# Penalización por golpear un obstáculo (piedra...): resta una fracción de la
# resistencia MÁXIMA. Devuelve cuánta resistencia se perdió realmente.
func penalize_resistance() -> float:
	var penalty: float = StatsManager.get_obstacle_resistance_penalty()
	var previous: float = current_energy
	current_energy = maxf(0.0, current_energy - penalty)
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
	if previous > 0.0 and current_energy <= 0.0:
		_end_round_and_validate()
	return previous - current_energy

# Se llama cada vez que un jugador corta una fruta con éxito. Calcula la
# recompensa final (aplicando el multiplicador de dinero) y actualiza el
# progreso del pedido y el dinero disponible en la tienda.
func register_fruit_cut(fruit_data: FruitData, base_reward: float, is_jackpot: bool, is_golden: bool = false) -> float:
	_increment_streak()
	var streak_mult: float = get_streak_multiplier()
	var final_reward: float = base_reward * StatsManager.get_final_money_multiplier() * streak_mult
	var target_unreached: bool = order_progress < order_target
	run_money += final_reward
	order_progress += final_reward
	# Logro "Rápido y Furioso": ALCANZAR la cuota del día faltando 5s o menos.
	if target_unreached and order_progress >= order_target and round_time_left <= 5.0:
		AchievementManager.set_flag("beat_day_rushed")
	# Fin de la fase de "llegar a la cuota": a partir de aquí todo el dinero del
	# día es ganancia extra. Se avisa UNA sola vez por día. El "> 0" cubre el día
	# 1, cuya cuota es $0 y por tanto ya está "cumplida" antes de cortar nada:
	# el bonus empieza con la primera fruta.
	if not daily_goal_reached and order_progress > 0.0 and order_progress >= order_target:
		daily_goal_reached = true
		emit_signal("order_goal_reached", get_order_bonus())
	total_money_generated_run += final_reward
	total_fruits_cut_run += 1
	if is_jackpot:
		total_jackpots_run += 1
	if is_golden:
		total_golden_fruits_run += 1

	# Logros: métricas globales y por fruta.
	AchievementManager.record_metric("fruits_cut", 1)
	AchievementManager.record_metric("money_total", final_reward)
	var fruit_id: String = str(fruit_data.id) if fruit_data else ""
	if fruit_id != "":
		AchievementManager.record_metric("cut_" + fruit_id, 1)
		_fruits_this_day_set[fruit_id] = true
	if is_jackpot:
		AchievementManager.record_metric("jackpots", 1)
		if is_golden:
			AchievementManager.set_flag("golden_jackpot")
	# "Fruta y Pan": dorada Y normal en el mismo día, en CUALQUIER orden.
	if is_golden:
		AchievementManager.record_metric("golden_fruits", 1)
		_golden_fruits_this_day += 1
		if _golden_fruits_this_day >= 2:
			AchievementManager.set_metric("golden_fruits_in_one_day", 2)
		if _normal_fruits_this_day > 0:
			AchievementManager.set_flag("golden_and_normal_day")
	else:
		_normal_fruits_this_day += 1
		if _golden_fruits_this_day > 0:
			AchievementManager.set_flag("golden_and_normal_day")
	# Logro "Origen": cortar 100 frutas con el Puño equipado en el negocio.
	if run_equipped_knife == "weapon_fist":
		_fist_cuts_this_run += 1
		if _fist_cuts_this_run >= 100:
			AchievementManager.set_flag("started_with_fist")

	emit_signal("money_changed", run_money)
	emit_signal("order_progress_changed", order_progress, order_target)
	emit_signal("fruit_destroyed_event", fruit_data, final_reward, is_jackpot)

	return final_reward

func spend_run_money(amount: float) -> bool:
	if run_money >= amount:
		run_money -= amount
		emit_signal("money_changed", run_money)
		return true
	return false

# --- Frutas y armas desbloqueadas SOLO en este negocio ---
# (se pierden al quebrar; ver run_unlocked_fruits/run_unlocked_knives arriba)
func is_fruit_unlocked_this_run(fruit_id: String) -> bool:
	return fruit_id in run_unlocked_fruits

func unlock_fruit_this_run(fruit_id: String) -> void:
	if not (fruit_id in run_unlocked_fruits):
		run_unlocked_fruits.append(fruit_id)
		SaveManager.unlock_fruit(fruit_id) # keeps lifetime discovery record for Progress stats
		AchievementManager.set_metric("fruits_unlocked", SaveManager.get_unlocked_fruits().size())

func is_knife_unlocked_this_run(knife_id: String) -> bool:
	return knife_id in run_unlocked_knives

func unlock_knife_this_run(knife_id: String) -> void:
	if not (knife_id in run_unlocked_knives):
		run_unlocked_knives.append(knife_id)
		SaveManager.unlock_knife(knife_id) # keeps lifetime discovery record for Progress stats
		AchievementManager.set_metric("knives_owned", SaveManager.get_unlocked_knives().size())

func set_equipped_knife_this_run(knife_id: String) -> void:
	# Equipar el MISMO arma no cuenta como cambio para "Hachero Total".
	if knife_id != run_equipped_knife:
		_weapon_changed_this_day = true
	run_equipped_knife = knife_id
	StatsManager.invalidate_stat_cache()
	if knife_id == "weapon_chainsaw":
		AchievementManager.set_flag("used_chainsaw")
	emit_signal("run_knife_equipped", knife_id)

func _end_round_and_validate() -> void:
	is_round_active = false
	if order_progress >= order_target:
		# Objective met - round won, continue to comodines/shop
		current_state = GameState.ORDER_CLEARED_CARD_SELECT
		SoundManager.play_victory()
		_on_day_completed()
		emit_signal("order_completed", current_order)
	else:
		# Objective not met - round lost, business ends
		end_run_failed()

# Registra los logros ligados a completar un día (días, perfecto, estilo).
func _on_day_completed() -> void:
	# Se genera 1 ⭐ de reputación por cada día completado (economía prestigio).
	# Solo los comodines ACTIVOS pueden aumentar la reputación diaria (+bonus);
	# el final del negocio NO vuelve a otorgar puntos (ver end_run_failed).
	var day_prestige: float = 1.0 + StatsManager.get_prestige_per_day_bonus()
	SaveManager.add_prestige_points(day_prestige)
	prestige_earned_this_run += day_prestige
	AchievementManager.record_metric("prestige_earned", day_prestige)
	AchievementManager.set_metric("best_day", maxf(AchievementManager.get_metric("best_day"), current_order))
	AchievementManager.record_metric("days_completed_total", 1)
	if _stones_hit_this_day == 0:
		AchievementManager.record_metric("clean_days", 1)
	# Logros por arma equipada al completar el día.
	match run_equipped_knife:
		"weapon_fist":
			AchievementManager.set_flag("day_with_fist")
		"weapon_fork":
			AchievementManager.set_flag("day_with_fork")
		"weapon_knife":
			AchievementManager.set_flag("day_with_knife")
		"weapon_axe":
			AchievementManager.set_flag("day_with_axe")
		"weapon_sword":
			AchievementManager.set_flag("day_with_sword")
		"weapon_chainsaw":
			AchievementManager.set_flag("day_with_top_knife")
	# Logros de día perfecto por estilo.
	# "Deuda Cero": terminar el día con la energía EXACTAMENTE en 0.
	if current_energy <= 0.0:
		AchievementManager.set_flag("day_finished_empty")
	if _fresa_and_naranja_today():
		AchievementManager.set_flag("fresa_y_naranja_day")
	# "Hachero Total": día completado sin cambiar de arma. La ventana va de fin
	# de día a fin de día, asi que cambiar en la tienda cuenta para el día que
	# empieza (por eso el reset es AQUÍ y no en advance_to_next_order).
	if not _weapon_changed_this_day:
		AchievementManager.set_flag("day_unchanged_weapon")
	_weapon_changed_this_day = false
	# "Astuta Economía": superar un día (a partir del 2º, cuando la tienda ya
	# pudo usarse) sin haber comprado NINGUNA mejora del mercado en el negocio.
	if _upgrades_bought_this_run == 0 and current_order >= 2:
		AchievementManager.set_flag("no_prestige_spent_run")

func _fresa_and_naranja_today() -> bool:
	return _fruits_this_day_set.has("strawberry") and _fruits_this_day_set.has("orange")

func advance_to_next_order() -> void:
	current_energy = StatsManager.get_final_max_energy()
	emit_signal("energy_changed", current_energy, StatsManager.get_final_max_energy())
	current_order += 1
	if current_order > get_win_day():
		AchievementManager.set_flag("surpassed_day_100")
	order_target = get_order_target_for(current_order)
	order_progress = 0.0
	# Cada día arranca con la meta pendiente: el bonus vuelve a estar "por ganar".
	daily_goal_reached = false
	current_state = GameState.PLAYING
	_stones_hit_this_day = 0
	_first_stone_consumed_this_day = false
	_crits_this_day = 0
	_golden_fruits_this_day = 0
	_normal_fruits_this_day = 0
	_fruits_this_day_set = {}
	# La racha se reinicia a 0 al empezar cada día nuevo, A MENOS que el jugador
	# tenga un comodín mítico que la conserve entre días. La piedra SIEMPRE la
	# rompe dentro del mismo día (ver SwipeController).
	if not StatsManager.has_streak_keep():
		current_streak = 0
		_refresh_streak_multiplier()
	emit_signal("streak_changed", current_streak, get_streak_multiplier())
	
	round_time_left = get_round_time()
	emit_signal("round_time_changed", round_time_left)
	emit_signal("order_progress_changed", order_progress, order_target)
	is_round_active = true

func end_run_failed() -> void:
	is_round_active = false
	current_state = GameState.RESULTS
	SoundManager.play_game_over()

	# La reputación de ESTE negocio ya se concedió día a día en _on_day_completed
	# (1 ⭐ por día + bonus de comodines activos): NO se vuelve a sumar aquí para
	# evitar duplicar los mismos puntos (antes esta fórmula los contaba 2×).
	var completed_orders_count: int = current_order - 1
	var earned_prestige: float = prestige_earned_this_run

	SaveManager.record_run_stats(completed_orders_count, total_fruits_cut_run)

	# Logros ligados al final del negocio.
	AchievementManager.record_metric("runs_bankrupt", 1)
	AchievementManager.set_metric("run_money_total", maxf(AchievementManager.get_metric("run_money_total"), total_money_generated_run))

	var summary: Dictionary = {
		"completed_orders": completed_orders_count,
		"money_generated": total_money_generated_run,
		"fruits_cut": total_fruits_cut_run,
		"jackpots": total_jackpots_run,
		"golden_fruits": total_golden_fruits_run,
		"best_order": current_order,
		"earned_prestige": earned_prestige,
		"total_prestige": SaveManager.get_prestige_points()
	}

	emit_signal("run_ended", summary)

func get_unlocked_fruits_for_current_order() -> Array[String]:
	var available: Array[String] = []
	for fruit_id in run_unlocked_fruits:
		available.append(str(fruit_id))
	return available
