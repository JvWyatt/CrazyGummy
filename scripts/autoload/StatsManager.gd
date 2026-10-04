extends Node
# ============================================================================
# StatsManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Aquí viven las FÓRMULAS y el estado efímero de balance del juego. Los NÚMEROS
# editables (armas, mejoras del mercado, prestigio y constantes globales) se
# cargan desde res://data/ (ver data/catalog.tres, que indexa data/knives/,
# data/run_upgrades/ y data/prestige/, y data/balance.tres), así que se pueden
# ajustar desde el inspector sin tocar código. Este archivo combina todo con las
# fórmulas "get_final_...()" para dar el valor final que usa el resto del juego.
# ============================================================================

signal stats_updated

# ----------------------------------------------------------------------------
# CONSTANTES DE BALANCE GLOBAL
# ----------------------------------------------------------------------------
# Todas estas cifras (gasto de resistencia, fruta dorada, rebalance de
# recompensas, daño crítico, frecuencias de lanzamiento, obstáculos y
# crecimiento de precios) se editan VISUALMENTE en res://data/balance.tres
# (recurso BalanceData). Aquí solo se carga con respaldo por defecto.
const BALANCE_PATH: String = "res://data/balance.tres"
var balance: BalanceData = BalanceData.new()

# ----------------------------------------------------------------------------
# TABLA DE ARMAS (CUCHILLOS)
# ----------------------------------------------------------------------------
# Cada arma vive en su propio .tres: res://data/knives/<id>.tres (recurso
# KnifeData, editable en el inspector). Campos: damage (daño por golpe),
# El coste de resistencia es global (ver BalanceData.base_energy_cost)
# y price (costo para desbloquear durante la partida, ver RunUpgradeModal.gd).
var knives_db: Dictionary = {}

# ----------------------------------------------------------------------------
# MEJORAS DEL MERCADO ("Mejoras" tab del RunUpgradeModal)
# ----------------------------------------------------------------------------
# Se compran con el dinero de la partida (run_money) y se PIERDEN al quebrar
# el negocio (ver StatsManager.reset_run_stats() y GameManager.start_new_run()).
# run_upgrade_levels guarda cuántas veces se compró cada mejora en esta partida.
var run_upgrade_levels: Dictionary = {
	"damage": 0,       # +5% damage
	"energy_max": 0,   # +5% max resistance
	"luck": 0,         # +0.5% grand sale chance
	"money": 0,        # +5% money
	"launch_rate": 0   # +10% launch frequency
}

# Definición de cada mejora: nombre, descripción, costo inicial (base_cost) y
# cuánto sube el precio cada vez que se compra (cost_mult, ej. 1.1x = +10%).
# Viven en res://data/run_upgrades/*.tres (recurso RunUpgradeData, editable en
# el inspector; el id coincide con la clave de run_upgrade_levels).
# Son ACUMULATIVAS e infinitas: cada compra sube el nivel y el precio crece con
# la fórmula (base_cost × cost_mult^nivel), sin tabla de valores fija.
# Los base_cost están a la escala de lo que se gana por pedido: permiten
# algunas compras los primeros días pero no llenar la tienda de golpe.
# Balance: daño/resistencia/ganancias del mercado y de prestigio doblados
# (mercado: 5% -> 10%; prestigio: 10% -> 20%), jackpot con su categoría propia
# (+0.5% mercado / +1% prestigio, sin cambios), y frecuencia de frutas sin
# cambios (mercado +10% / prestigio +25%).
var run_upgrade_definitions: Dictionary = {}

# Factor real acumulado al comprar daño. El mínimo se decide con el daño
# actual de esa compra, no con la base del arma ni con un valor redondeado.
var run_damage_multiplier: float = 1.0

# ----------------------------------------------------------------------------
# BONOS DE COMODINES (CARTAS) - también se resetean cada partida
# ----------------------------------------------------------------------------
# Cada vez que el jugador elige un comodín (CardSelectionModal), se llama a
# apply_card_upgrade() que suma su efecto a una de estas variables. Los
# multiplicadores empiezan en 1.0 (sin efecto) y los bonos aditivos en 0.0.
var card_damage_multiplier: float = 1.0
var card_energy_multiplier: float = 1.0
var card_money_multiplier: float = 1.0
var card_jackpot_bonus: float = 0.0
var card_jackpot_multiplier_bonus: float = 0.0
var card_crit_chance: float = 0.0
var card_launch_rate_multiplier: float = 1.0
var card_reward_min_multiplier: float = 1.0
var card_reward_max_multiplier: float = 1.0
var card_fruit_hp_multiplier: float = 1.0
var card_energy_cost_multiplier: float = 1.0
var card_weapon_price_multiplier: float = 1.0
var card_fruit_price_multiplier: float = 1.0
var card_upgrade_price_multiplier: float = 1.0
var card_order_target_multiplier: float = 1.0
var card_golden_fruit_chance: float = 0.0
# Bonus ADITIVO al multiplicador de racha (se suma al que dé la racha actual).
# Cada comodín de racha suma su valor (Común +0.1, Rara +0.2, Épica +0.5, Legendaria +1.0).
var card_streak_bonus: float = 0.0
# Probabilidad adicional (sumada, 0.0 a 1.0) de ROMPER una piedra al golpearla
# (desaparece, no penaliza). Épica +0.01 / Legendaria +0.03.
var card_stone_break_chance: float = 0.0
# Contador de comodines "primera piedra del día no quita resistencia" (Rara).
var card_first_stone_free: int = 0
# Contador de comodines míticos "mantener la racha entre días".
var card_streak_keep: int = 0
# Bonus ADITIVO de puntos de prestigio por día completado (se suma al punto
# base de 1 ⭐). Es la ÚNICA forma de aumentar la reputación diaria: solo los
# comodines ACTIVOS pueden aportar aquí (0.0 si ninguno tiene este efecto).
var card_prestige_bonus: float = 0.0
var active_cards: Array = []

# --- Caché de stats FINALES (hot paths) --------------------------------------
# Se recalculan SOLO cuando cambian sus entradas, para que los getters que se
# llaman todos los frames (lanzamiento de frutas) o ante cada corte (daño,
# energía, dinero, jackpot) sean O(1). Un valor guardado como -1 marca "sucio":
# se recalcula a petición la próxima vez que se lea. Cualquier operación que
# cambie mejoras del mercado, comodines, prestigio O el arma equipada debe
# llamar a invalidar_stat_cache() antes de emitir stats_updated (ver
# buy_run_upgrade, apply_card_upgrade, buy_prestige_upgrade, reset_run_stats,
# SaveManager.reset_save y GameManager.set_equipped_knife_this_run).
var _final_damage: float = -1.0
var _final_max_energy: float = -1.0
var _final_energy_cost: float = -1.0
var _final_money_multiplier: float = -1.0
var _final_jackpot_bonus: float = -1.0
var _final_launch_rate: float = -1.0

# Marca TODOS los valores finales como "sucios": se recalcularán en el próximo
# acceso a cada getter. Llamar SIEMPRE tras cualquier cambio de sus entradas.
func invalidate_stat_cache() -> void:
	_final_damage = -1.0
	_final_max_energy = -1.0
	_final_energy_cost = -1.0
	_final_money_multiplier = -1.0
	_final_jackpot_bonus = -1.0
	_final_launch_rate = -1.0

func _ready() -> void:
	_load_balance()
	_build_catalogs()
	reset_run_stats()

# Carga las constantes globales de balance desde data/balance.tres. Si el .tres
# no existe o falla, se usan los valores por defecto de BalanceData.new().
func _load_balance() -> void:
	var loaded := load(BALANCE_PATH) as BalanceData
	if loaded:
		balance = loaded
	else:
		push_warning("StatsManager: no se encontró %s, usando valores por defecto" % BALANCE_PATH)

# Carga el índice único de datos: res://data/catalog.tres (recurso GameCatalog).
# Ese Resource referencia explícitamente cada .tres de data/ y por eso el
# exportador los mete sí o sí en el APK.
# OJO: no se listan carpetas con DirAccess porque al exportar los .tres se
# empaquetan convertidos a binario bajo una ruta interna distinta y
# "res://data/<carpeta>/" deja de existir: el listado salía vacío y el juego se
# quedaba con los datos de respaldo (solo Puño y ninguna mejora).
func _load_game_catalog() -> GameCatalog:
	var catalog := load(GameCatalog.CATALOG_PATH) as GameCatalog
	if catalog == null:
		push_error("StatsManager: no se pudo cargar %s (armas, mejoras y prestigio quedarían vacíos)" % GameCatalog.CATALOG_PATH)
	return catalog

# Indexa una lista de recursos de data/ por su campo "id".
# Devuelve un Dictionary id -> Resource (KnifeData/RunUpgradeData/...).
func _index_by_id(items: Array) -> Dictionary:
	var index: Dictionary = {}
	for item in items:
		if item == null:
			continue
		var item_id: Variant = item.get("id")
		if item_id == null or str(item_id) == "":
			push_warning("StatsManager: ignorado un ítem de catalog.tres sin id válido")
			continue
		index[str(item_id)] = item
	return index

func _build_catalogs() -> void:
	var catalog := _load_game_catalog()
	knives_db = {}
	run_upgrade_definitions = {}
	prestige_definitions = {}
	if catalog:
		knives_db = _index_by_id(catalog.knives)
		run_upgrade_definitions = _index_by_id(catalog.run_upgrades)
		prestige_definitions = _index_by_id(catalog.prestige_upgrades)
	# Blindaje: si el catálogo no llegó se usa el Puño por defecto para que el
	# daño nunca sea 0.0 ni get_equipped_knife_data() dé null.
	if knives_db.is_empty():
		push_warning("StatsManager: knives_db vacía (revisar res://data/catalog.tres), usando el Puño por defecto")
		var fist := KnifeData.new()
		fist.id = "weapon_fist"
		fist.name = "Puño"
		fist.description = "La herramienta más básica para empezar."
		fist.damage = 5.0
		fist.unlock_order = 1
		fist.price = 0
		fist.icon = "👊"
		knives_db["weapon_fist"] = fist

# Se llama al empezar cada negocio nuevo (ver GameManager.start_new_run()).
# Vuelve las mejoras y los bonos de comodines a su estado inicial, tal como
# se espera en un roguelite: solo lo permanente (prestigio) sobrevive.
func reset_run_stats() -> void:
	invalidate_stat_cache()
	for key in run_upgrade_levels.keys():
		run_upgrade_levels[key] = 0
	run_damage_multiplier = 1.0
	card_damage_multiplier = 1.0
	card_energy_multiplier = 1.0
	card_money_multiplier = 1.0
	card_jackpot_bonus = 0.0
	card_jackpot_multiplier_bonus = 0.0
	card_crit_chance = 0.0
	card_launch_rate_multiplier = 1.0
	card_reward_min_multiplier = 1.0
	card_reward_max_multiplier = 1.0
	card_fruit_hp_multiplier = 1.0
	card_energy_cost_multiplier = 1.0
	card_weapon_price_multiplier = 1.0
	card_fruit_price_multiplier = 1.0
	card_upgrade_price_multiplier = 1.0
	card_order_target_multiplier = 1.0
	card_golden_fruit_chance = 0.0
	card_streak_bonus = 0.0
	card_stone_break_chance = 0.0
	card_first_stone_free = 0
	card_streak_keep = 0
	card_prestige_bonus = 0.0
	active_cards.clear()
	emit_signal("stats_updated")

func get_equipped_knife_data() -> KnifeData:
	var equipped_id: String = GameManager.run_equipped_knife
	if knives_db.has(equipped_id):
		return knives_db[equipped_id] as KnifeData
	return knives_db["weapon_fist"] as KnifeData

# Ids de TODAS las armas en orden de progresión (campo unlock_order de
# KnifeData, ascendente; editable en res://data/knives/*.tres). Orden
# DETERMINISTA, igual que FruitDatabase.get_sorted_fruit_ids(): NO usar
# knives_db.keys(), cuyo orden de iteración no está garantizado.
func get_sorted_knife_ids() -> Array[String]:
	var ids: Array[String] = []
	for knife_id in knives_db.keys():
		ids.append(str(knife_id))
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ka: KnifeData = knives_db[a] as KnifeData
		var kb: KnifeData = knives_db[b] as KnifeData
		return ka.unlock_order < kb.unlock_order
	)
	return ids

# Daño final sin redondear: arma x mercado x comodines x prestigio.
# El mínimo del mercado se aplica exclusivamente al comprar (ver abajo).
func get_final_damage() -> float:
	if _final_damage < 0.0:
		_final_damage = _compute_final_damage()
	return _final_damage

# Ver get_final_damage: el cálculo real del daño final (solo se ejecuta cuando
# el valor está marcado como sucio).
func _compute_final_damage() -> float:
	var knife: KnifeData = get_equipped_knife_data()
	return knife.damage * run_damage_multiplier * card_damage_multiplier * get_prestige_multiplier("experience", balance.prestige_damage_bonus_per_level)

# Prestigio consulta solo la base de una nueva partida y sus niveles guardados.
# No depende del arma de la run, comodines, mejoras temporales ni cachés finales.
func get_prestige_multiplier(upgrade_id: String, bonus: float) -> float:
	return pow(1.0 + bonus, SaveManager.get_prestige_level(upgrade_id))

func get_permanent_stat(upgrade_id: String) -> float:
	match upgrade_id:
		"experience":
			var knife: KnifeData = knives_db["weapon_fist"] as KnifeData
			return knife.damage * get_prestige_multiplier(upgrade_id, balance.prestige_damage_bonus_per_level)
		"expert_hand":
			return balance.base_max_energy * get_prestige_multiplier(upgrade_id, balance.prestige_energy_bonus_per_level)
		"good_provider":
			return get_prestige_multiplier(upgrade_id, balance.prestige_money_bonus_per_level)
		"good_fortune":
			return SaveManager.get_prestige_level(upgrade_id) * balance.prestige_jackpot_bonus_per_level
		"launch_speed":
			return balance.base_launch_rate * get_prestige_multiplier(upgrade_id, balance.prestige_launch_bonus_per_level)
	return 0.0

func get_run_damage_upgrade_next_value() -> float:
	var current: float = get_final_damage()
	var next_value: float = current * (1.0 + balance.run_damage_bonus_per_level)
	if current < balance.damage_pity_floor:
		next_value = maxf(next_value, current + balance.damage_pity_flat_per_level)
	return next_value

# Resistencia máxima final = 100 base x mejoras del mercado x comodines x prestigio
func get_final_max_energy() -> float:
	if _final_max_energy < 0.0:
		_final_max_energy = _compute_final_max_energy()
	return _final_max_energy

func _compute_final_max_energy() -> float:
	var base_energy: float = balance.base_max_energy
	var run_bonus: float = pow(1.0 + balance.run_energy_bonus_per_level, run_upgrade_levels["energy_max"])
	var prestige_bonus: float = get_prestige_multiplier("expert_hand", balance.prestige_energy_bonus_per_level)
	return base_energy * run_bonus * card_energy_multiplier * prestige_bonus

# Resistencia por corte: estadística global, independiente del arma equipada.
func get_final_energy_cost() -> float:
	if _final_energy_cost < 0.0:
		_final_energy_cost = _compute_final_energy_cost()
	return _final_energy_cost

func _compute_final_energy_cost() -> float:
	return balance.base_energy_cost * balance.resistance_cost_multiplier * card_energy_cost_multiplier

# Multiplicador final aplicado al dinero ganado por cada fruta cortada.
func get_final_money_multiplier() -> float:
	if _final_money_multiplier < 0.0:
		_final_money_multiplier = _compute_final_money_multiplier()
	return _final_money_multiplier

func _compute_final_money_multiplier() -> float:
	var run_bonus: float = pow(1.0 + balance.run_money_bonus_per_level, run_upgrade_levels["money"])
	var prestige_bonus: float = get_prestige_multiplier("good_provider", balance.prestige_money_bonus_per_level)
	return 1.0 * run_bonus * card_money_multiplier * prestige_bonus

# Probabilidad extra (sumada, no multiplicada) de que una fruta sea "Gran Venta"/Jackpot.
func get_final_jackpot_bonus() -> float:
	if _final_jackpot_bonus < 0.0:
		_final_jackpot_bonus = _compute_final_jackpot_bonus()
	return _final_jackpot_bonus

func _compute_final_jackpot_bonus() -> float:
	var run_bonus: float = run_upgrade_levels["luck"] * balance.run_jackpot_bonus_per_level
	var prestige_bonus: float = SaveManager.get_prestige_level("good_fortune") * balance.prestige_jackpot_bonus_per_level
	return run_bonus + card_jackpot_bonus + prestige_bonus

func get_final_jackpot_multiplier() -> float:
	return balance.base_jackpot_multiplier + card_jackpot_multiplier_bonus

func get_golden_fruit_chance() -> float:
	return balance.golden_fruit_chance + card_golden_fruit_chance

# Bonus ADITIVO acumulado por comodines de racha (p.ej. +0.5 con un Épico).
func get_streak_bonus() -> float:
	return card_streak_bonus

# Probabilidad total (0.0 a 1.0) de romper una piedra al golpearla.
func get_stone_break_chance() -> float:
	return card_stone_break_chance

# Bonus de puntos de prestigio (reputación) por día completado: se suma al
# punto base de 1 ⭐. Solo los comodines ACTIVOS pueden aumentarlo (ver
# card_prestige_bonus / effect_type "prestige" en _apply_card_effect).
func get_prestige_per_day_bonus() -> float:
	return card_prestige_bonus

# True si el jugador tiene al menos un comodín "primera piedra del día gratis".
func has_first_stone_free() -> bool:
	return card_first_stone_free > 0

# True si el jugador tiene al menos un comodín mítico que mantiene la racha
# entre días.
func has_streak_keep() -> bool:
	return card_streak_keep > 0

func get_fruit_max_hp_multiplier() -> float:
	return card_fruit_hp_multiplier

func get_fruit_min_reward_multiplier() -> float:
	return card_reward_min_multiplier * balance.reward_rebalance_multiplier

func get_fruit_max_reward_multiplier() -> float:
	return card_reward_max_multiplier * balance.reward_rebalance_multiplier

func get_weapon_price(price: int) -> int:
	return int(round(price * card_weapon_price_multiplier))

func get_fruit_price(price: int) -> int:
	return int(round(price * card_fruit_price_multiplier))

func get_final_critical_chance() -> float:
	return card_crit_chance

# El multiplicador crítico es FIJO (x1.5, editable en data/balance.tres). Los
# comodines solo pueden aumentar la probabilidad de crítico (card_crit_chance).
func get_final_critical_multiplier() -> float:
	return balance.critical_damage_multiplier

# Frutas (o obstáculos) lanzadas por segundo.
func get_final_launch_rate() -> float:
	if _final_launch_rate < 0.0:
		_final_launch_rate = _compute_final_launch_rate()
	return _final_launch_rate

func _compute_final_launch_rate() -> float:
	var run_bonus: float = pow(1.0 + balance.run_launch_bonus_per_level, run_upgrade_levels["launch_rate"])
	var prestige_bonus: float = get_prestige_multiplier("launch_speed", balance.prestige_launch_bonus_per_level)
	return balance.base_launch_rate * run_bonus * card_launch_rate_multiplier * prestige_bonus

# Intervalo ALEATORIO (en segundos) entre obstáculos: 1 a 2 s. Independiente
# de la frecuencia de frutas y de todas las mejoras/comodines/prestigio.
func get_obstacle_interval() -> float:
	return randf_range(balance.obstacle_interval_min, balance.obstacle_interval_max)

# Penalización de resistencia por golpear un obstáculo (fracción de la máxima).
func get_obstacle_resistance_penalty() -> float:
	return maxf(1.0, get_final_max_energy() * balance.obstacle_resistance_penalty_fraction)

# Precio final de las mejoras del mercado: la primera compra (nivel 0) cuesta
# el base_cost ($5) y cada compra siguiente crece ×1.5: 5, 7.5, 11.25 → ..., y
# así sucesivamente (fórmula base_cost × cost_mult^nivel, sin tabla fija).
func get_run_upgrade_cost(upgrade_id: String) -> float:
	if not run_upgrade_definitions.has(upgrade_id):
		return 999999.0
	var def: RunUpgradeData = run_upgrade_definitions[upgrade_id]
	var level: int = run_upgrade_levels[upgrade_id]
	return snappedf(float(def.base_cost) * pow(float(def.cost_mult), float(level)) * card_upgrade_price_multiplier, 0.01)

func get_order_target_multiplier() -> float:
	return card_order_target_multiplier

func buy_run_upgrade(upgrade_id: String) -> void:
	if run_upgrade_levels.has(upgrade_id):
		if upgrade_id == "damage":
			var current_damage: float = get_final_damage()
			run_damage_multiplier *= get_run_damage_upgrade_next_value() / current_damage
		run_upgrade_levels[upgrade_id] += 1
		GameManager._upgrades_bought_this_run += 1
		AchievementManager.record_metric("upgrades_bought_run", 1)
		if upgrade_id == "launch_rate" and run_upgrade_levels["launch_rate"] >= 3:
			AchievementManager.set_metric("launch_upgrades_run", 3)
		if run_upgrade_levels["damage"] >= 1 and run_upgrade_levels["energy_max"] >= 1 and run_upgrade_levels["luck"] >= 1 and run_upgrade_levels["money"] >= 1:
			AchievementManager.set_flag("bought_all_upgrade_types")
		invalidate_stat_cache()
		emit_signal("stats_updated")

func apply_card_upgrade(card_id: String, effect_type: String, effect_value: Variant, card_title: String = "") -> void:
	active_cards.append({"id": card_id, "title": card_title})
	SaveManager.discover_card(card_id)
	# Logros de comodines descubiertos.
	var rarity: String = "Común"
	for card in CardDatabase.ALL_CARDS:
		if str(card["id"]) == str(card_id):
			rarity = str(card["rarity"])
			break
	var discovered_count: int = SaveManager.get_discovered_cards().size()
	AchievementManager.set_metric("cards_discovered", discovered_count)
	match rarity:
		"Rara":
			AchievementManager.record_metric("cards_rare", 1)
		"Épica":
			AchievementManager.record_metric("cards_epic", 1)
		"Legendaria":
			AchievementManager.record_metric("cards_legendary", 1)
		"Mítico":
			AchievementManager.set_flag("discover_mythic")
	if effect_type == "multi":
		for effect in effect_value:
			_apply_card_effect(str(effect["type"]), float(effect["value"]))
	else:
		_apply_card_effect(effect_type, float(effect_value))
	invalidate_stat_cache()
	emit_signal("stats_updated")

func _apply_card_effect(effect_type: String, effect_value: float) -> void:
	match effect_type:
		"damage":
			card_damage_multiplier += effect_value
		"energy_max":
			card_energy_multiplier += effect_value
		"money":
			card_money_multiplier += effect_value
		"jackpot":
			card_jackpot_bonus += effect_value
		"jackpot_multiplier":
			card_jackpot_multiplier_bonus += effect_value
		"crit_chance":
			card_crit_chance += effect_value
		"launch_rate":
			card_launch_rate_multiplier += effect_value
		"reward_min":
			card_reward_min_multiplier += effect_value
		"reward_max":
			card_reward_max_multiplier += effect_value
		"fruit_hp":
			card_fruit_hp_multiplier += effect_value
		"energy_cost":
			card_energy_cost_multiplier += effect_value
		"weapon_price":
			card_weapon_price_multiplier += effect_value
		"fruit_price":
			card_fruit_price_multiplier += effect_value
		"upgrade_price":
			card_upgrade_price_multiplier += effect_value
		"order_target":
			card_order_target_multiplier += effect_value
		"golden_fruit_chance":
			card_golden_fruit_chance += effect_value
		"all_prices":
			card_weapon_price_multiplier += effect_value
			card_fruit_price_multiplier += effect_value
			card_upgrade_price_multiplier += effect_value
		"streak_bonus":
			card_streak_bonus += effect_value
		"stone_break_chance":
			card_stone_break_chance += effect_value
		"prestige":
			card_prestige_bonus += effect_value
		"first_stone_free":
			card_first_stone_free += int(effect_value)
		"streak_keep":
			card_streak_keep += int(effect_value)

# ----------------------------------------------------------------------------
# MEJORAS DE PRESTIGIO (permanentes, compradas con reputación/estrellas)
# ----------------------------------------------------------------------------
# Se guardan en SaveManager (prestige_levels) y NO se resetean nunca. Son
# ACUMULATIVAS e infinitas (no tienen max_level): cada compra sube el nivel y
# el efecto crece con él. Se generan puntos de reputación por cada día
# completado (ver GameManager): 1 ⭐ base por día + bonus de comodines ACTIVOS.
# Cada mejora vive en res://data/prestige/<id>.tres (recurso PrestigeUpgradeData,
# editable en el inspector). Los precios por nivel usan el coste base del .tres
# y crecen ×1.5 por nivel (ver data/balance.tres).
var prestige_definitions: Dictionary = {}

# Factor de crecimiento del precio de prestigio por nivel (ver data/balance.tres).
func get_prestige_upgrade_cost(upgrade_id: String) -> float:
	if not prestige_definitions.has(upgrade_id):
		return 999999.0
	var def: PrestigeUpgradeData = prestige_definitions[upgrade_id]
	var current_lvl: int = SaveManager.get_prestige_level(upgrade_id)
	# Los valores no se hardcodean por nivel: el precio crece con la fórmula.
	return snappedf(float(def.cost) * pow(balance.prestige_price_growth, current_lvl), 0.01)

func is_prestige_upgrade_maxed(upgrade_id: String) -> bool:
	return not prestige_definitions.has(upgrade_id)

func buy_prestige_upgrade(upgrade_id: String) -> bool:
	if is_prestige_upgrade_maxed(upgrade_id):
		return false
	var cost: float = get_prestige_upgrade_cost(upgrade_id)
	if SaveManager.spend_prestige_points(cost):
		var new_lvl: int = SaveManager.get_prestige_level(upgrade_id) + 1
		SaveManager.set_prestige_level(upgrade_id, new_lvl)
		AchievementManager.record_metric("prestige_spent", cost)
		AchievementManager.record_metric("prestige_bought", 1)
		invalidate_stat_cache()
		emit_signal("stats_updated")
		return true
	return false
