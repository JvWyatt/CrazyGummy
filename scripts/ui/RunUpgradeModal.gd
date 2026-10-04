extends Control
# ============================================================================
# RunUpgradeModal: el "mercado" que se abre entre pedidos, con 3 pestañas:
#   - Mejoras:   sube daño/energía/suerte/dinero con el dinero de la partida
#   - Frutería:  desbloquea frutas nuevas para esta partida
#   - Armas:     desbloquea y equipa armas nuevas para esta partida
# TODO lo comprado aquí usa GameManager.run_money y se pierde si el negocio
# quiebra (ver GameManager.start_new_run que reinicia run_unlocked_fruits,
# run_unlocked_knives y StatsManager.run_upgrade_levels).
#
# DISEÑO EN REJILLA: las tres pestañas muestran tarjetas en un ResponsiveGrid
# (scripts/ui/ResponsiveGrid.gd): ShopCard para las mejoras y CollectionCard
# para frutas y armas. Todo el aspecto de las tarjetas vive en esos scripts;
# aquí solo hay datos, precios y compra. Para volver al listado vertical basta
# con cambiar el nodo ItemsGrid por el VBoxContainer anterior.
# ============================================================================

signal start_next_order_requested
signal open_stats_requested

@onready var title_label: Label = $Panel/VBox/HeaderHBox/TitleLabel
@onready var money_label: Label = $Panel/VBox/HeaderHBox/MoneyLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var items_container: ResponsiveGrid = $Panel/VBox/TabContainer/Mejoras/ItemsGrid
@onready var fruit_items_container: ResponsiveGrid = $Panel/VBox/TabContainer/Frutería/ItemsGrid
@onready var weapon_items_container: ResponsiveGrid = $Panel/VBox/TabContainer/Armas/ItemsGrid
@onready var stats_button: Button = $Panel/VBox/BottomHBox/StatsButton
@onready var continue_button: Button = $Panel/VBox/BottomHBox/ContinueButton

# Cached row refs so purchases can update in place instead of rebuilding the whole shop
var _upgrade_rows: Dictionary = {} # key -> {name_lbl, buy_btn}
var _fruit_rows: Dictionary = {} # fruit_id -> {card, buy_btn, price}
var _weapon_rows: Dictionary = {} # knife_id -> {card, buy_btn}
var _prepare_queue: Array[Dictionary] = []

func _ready() -> void:
	StatsManager.stats_updated.connect(_refresh_upgrade_stats)
	close_button.pressed.connect(_on_close_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	# Construye una tarjeta por frame mientras el mercado está cerrado.
	_prepare_ui()

func _prepare_ui() -> void:
	for key in StatsManager.run_upgrade_definitions:
		_prepare_queue.append({"shop": "upgrade", "id": key})
	for fruit_id in FruitDatabase.get_sorted_fruit_ids():
		_prepare_queue.append({"shop": "fruit", "id": fruit_id})
	for knife_id in StatsManager.get_sorted_knife_ids():
		_prepare_queue.append({"shop": "weapon", "id": knife_id})
	set_process(true)

func _process(_delta: float) -> void:
	if _prepare_queue.is_empty():
		set_process(false)
		return
	var item: Dictionary = _prepare_queue.pop_front()
	match item["shop"]:
		"upgrade": _rebuild_upgrade_shop([item["id"]])
		"fruit": _rebuild_fruit_shop([str(item["id"])])
		"weapon": _rebuild_weapon_shop([str(item["id"])])
	if _prepare_queue.is_empty():
		set_process(false)

func open_modal(order_completed_num: int = 0) -> void:
	visible = true
	UiTheme.pop_in($Panel)
	if order_completed_num > 0:
		title_label.text = "MERCADO · DÍA " + str(order_completed_num)
		continue_button.text = "▶ SIGUIENTE DÍA"
	else:
		title_label.text = "MERCADO"
		continue_button.text = "▶ CONTINUAR"
	_rebuild_ui()

func _refresh_ui() -> void:
	# Only update money label without rebuilding UI
	money_label.text = "💰 $" + UiTheme.format_money(GameManager.run_money)

# Actualiza las tarjetas existentes; solo instancia las que aún falten.
func _rebuild_ui() -> void:
	_prepare_queue.clear()
	set_process(false)
	money_label.text = "💰 $" + UiTheme.format_money(GameManager.run_money)
	_rebuild_upgrade_shop()
	_rebuild_fruit_shop()
	_rebuild_weapon_shop()

func _rebuild_upgrade_shop(upgrade_keys: Array = []) -> void:
	var keys: Array = StatsManager.run_upgrade_definitions.keys() if upgrade_keys.is_empty() else upgrade_keys
	for key in keys:
		if _upgrade_rows.has(key):
			_update_upgrade_row(str(key))
			_upgrade_rows[key]["buy_btn"].disabled = GameManager.run_money < StatsManager.get_run_upgrade_cost(key)
			continue
		var def: RunUpgradeData = StatsManager.run_upgrade_definitions[key]
		var level: int = StatsManager.run_upgrade_levels[key]
		var cost: float = StatsManager.get_run_upgrade_cost(key)
		var can_buy: bool = GameManager.run_money >= cost

		var effect_text: String = _upgrade_effect_text(str(key))

		var card := ShopCard.create()
		card.setup(
			def.icon,
			def.name,
			"Nivel " + str(level),
			effect_text,
			"MEJORAR $" + UiTheme.format_money(cost),
			can_buy
		)
		card.update_current_stat(str(key))

		var up_key = key
		card.action_button.pressed.connect(func():
			_on_buy_upgrade(up_key)
		)

		items_container.add_child(card)
		_upgrade_rows[key] = {"card": card, "subtitle_lbl": card.subtitle_label, "buy_btn": card.action_button, "desc_lbl": card._desc_label}

# Texto del incremento real de la próxima compra; redondeo solo visual.
func _upgrade_effect_text(key: String) -> String:
	var bonus: float = 0.0
	var stat_name: String = ""
	match key:
		"damage":
			bonus = StatsManager.balance.run_damage_bonus_per_level
			stat_name = "Daño"
			var current: float = StatsManager.get_final_damage()
			var increment: float = StatsManager.get_run_damage_upgrade_next_value() - current
			if current < StatsManager.balance.damage_pity_floor and increment > current * bonus:
				return "+" + UiTheme.format_stat(increment) + " Daño"
		"energy_max":
			bonus = StatsManager.balance.run_energy_bonus_per_level
			stat_name = "Resistencia"
		"luck":
			bonus = StatsManager.balance.run_jackpot_bonus_per_level
			return "+" + UiTheme.format_jackpot(bonus * 100.0, false) + " p.p. Jackpot"
		"money":
			bonus = StatsManager.balance.run_money_bonus_per_level
			stat_name = "Dinero"
		"launch_rate":
			bonus = StatsManager.balance.run_launch_bonus_per_level
			stat_name = "Velocidad"
	return "+" + UiTheme.format_stat(bonus * 100.0) + "% " + stat_name

# Update a single upgrade row (level text + cost) after purchase, no rebuild
func _update_upgrade_row(key: String) -> void:
	if not _upgrade_rows.has(key):
		return
	var row: Dictionary = _upgrade_rows[key]
	var level: int = StatsManager.run_upgrade_levels[key]
	var cost: float = StatsManager.get_run_upgrade_cost(key)
	row["card"].update_current_stat(key)
	row["subtitle_lbl"].text = "Nivel " + str(level)
	row["desc_lbl"].text = _upgrade_effect_text(key)
	row["buy_btn"].text = "MEJORAR $" + UiTheme.format_money(float(cost))

# Actualiza los valores finales también al cambiar armas, comodines o prestigio.
func _refresh_upgrade_stats() -> void:
	for key in _upgrade_rows:
		_update_upgrade_row(str(key))

# Fruta anterior en la cadena de desbloqueo ("" si es la primera). Regla de
# la Frutería: no se puede comprar una fruta sin haber comprado la anterior.
func _get_prev_fruit_id(fruit_id: String) -> String:
	var ids: Array[String] = FruitDatabase.get_sorted_fruit_ids()
	var idx: int = ids.find(fruit_id)
	if idx > 0:
		return ids[idx - 1]
	return ""

# Arma anterior en la cadena de desbloqueo ("" si es la primera). Regla de la
# Armería: no se puede desbloquear un arma sin haber desbloqueado la anterior.
func _get_prev_knife_id(knife_id: String) -> String:
	var ids: Array[String] = StatsManager.get_sorted_knife_ids()
	var idx: int = ids.find(knife_id)
	if idx > 0:
		return ids[idx - 1]
	return ""

# Refresh disabled state of all buy buttons based on current money, no node creation
func _refresh_affordability() -> void:
	var money: float = GameManager.run_money
	for key in _upgrade_rows.keys():
		var row: Dictionary = _upgrade_rows[key]
		var cost: float = StatsManager.get_run_upgrade_cost(key)
		row["buy_btn"].disabled = money < cost
	for fruit_id in _fruit_rows.keys():
		_sync_fruit_row(str(fruit_id))
	_rebuild_weapon_shop()

# Sincroniza el texto/estado del botón de una fruta de la Frutería teniendo en
# cuenta DOS cosas: dinero suficiente Y que esté desbloqueada la fruta anterior
# (regla de cadena).
func _sync_fruit_row(fruit_id: String) -> void:
	if not _fruit_rows.has(fruit_id):
		return
	var row: Dictionary = _fruit_rows[fruit_id]
	var card: CollectionCard = row["card"]
	var buy_btn: Button = row["buy_btn"]
	var unlocked: bool = GameManager.is_fruit_unlocked_this_run(fruit_id)
	var prev_id: String = _get_prev_fruit_id(fruit_id)
	var chain_ok: bool = prev_id == "" or GameManager.is_fruit_unlocked_this_run(prev_id)

	if unlocked:
		# Ya desbloqueada: fuera el velo y se ve el emoji con sus datos.
		card.set_locked(false)
		buy_btn.text = "DISPONIBLE"
		buy_btn.disabled = true
		return
	if not chain_ok:
		card.set_locked(true)
		buy_btn.text = "BLOQUEADO"
		buy_btn.disabled = true
		return
	card.set_locked(true)
	buy_btn.text = "$" + UiTheme.format_money(float(row["price"]))
	buy_btn.tooltip_text = "Desbloquear fruta"
	buy_btn.disabled = GameManager.run_money < int(row["price"])

func _rebuild_fruit_shop(selected_ids: Array[String] = []) -> void:
	var fruit_ids: Array[String] = FruitDatabase.get_sorted_fruit_ids() if selected_ids.is_empty() else selected_ids
	for fruit_id in fruit_ids:
		var fruit_data: FruitData = FruitDatabase.get_fruit_data(fruit_id)
		var price: int = StatsManager.get_fruit_price(fruit_data.price)
		if _fruit_rows.has(fruit_id):
			_fruit_rows[fruit_id]["price"] = price
			_fruit_rows[fruit_id]["card"].reset_face()
			_sync_fruit_row(fruit_id)
			continue

		var stats_lbl: String = "Vida: " + UiTheme.format_stat(fruit_data.max_hp)
		stats_lbl += "\nGanancias:\n$" + UiTheme.format_money(fruit_data.min_reward)
		stats_lbl += " - $" + UiTheme.format_money(fruit_data.max_reward)

		# Cara = la fruta; reverso = sus numeros. Las bloqueadas conservan su
		# hueco en el grid pero con el velo, sin arte ni nombre.
		var card := CollectionCard.create()
		card.setup(
			fruit_data.id,
			fruit_data.icon_emoji,
			fruit_data.display_name,
			stats_lbl,
			"",
			null
		)
		card.set_locked(true)

		var captured_id: String = str(fruit_id)
		card.action_button.pressed.connect(func():
			_on_buy_fruit(captured_id, int(_fruit_rows[captured_id]["price"]))
		)

		fruit_items_container.add_child(card)
		_fruit_rows[fruit_id] = {"card": card, "buy_btn": card.action_button, "price": price}
		_sync_fruit_row(fruit_id)

# Update a single fruit row (unlocked state) after purchase, no rebuild
func _update_fruit_row(fruit_id: String) -> void:
	_sync_fruit_row(fruit_id)

func _rebuild_weapon_shop(selected_ids: Array[String] = []) -> void:
	var equipped_id: String = GameManager.run_equipped_knife
	var knife_ids: Array[String] = StatsManager.get_sorted_knife_ids() if selected_ids.is_empty() else selected_ids
	for knife_id in knife_ids:
		var knife_data: KnifeData = StatsManager.knives_db[knife_id]
		var is_unlocked: bool = GameManager.is_knife_unlocked_this_run(knife_id)
		var is_equipped: bool = knife_id == equipped_id
		var price: int = StatsManager.get_weapon_price(knife_data.price)
		var prev_id: String = _get_prev_knife_id(str(knife_id))
		var chain_ok: bool = prev_id == "" or GameManager.is_knife_unlocked_this_run(prev_id)

		var stats_lbl: String = "Daño: " + UiTheme.format_stat(knife_data.damage)

		# Cara = el arma; reverso = sus numeros y descripcion. Sin imagen propia
		# todavia, el anverso usa el icono del arma.
		var card: CollectionCard
		if _weapon_rows.has(knife_id):
			card = _weapon_rows[knife_id]["card"]
			card.reset_face()
		else:
			card = CollectionCard.create()
			card.setup(knife_data.id, knife_data.icon, knife_data.name, stats_lbl, "", null)
			card.action_button.pressed.connect(_on_weapon_action.bind(knife_id))
			weapon_items_container.add_child(card)
			_weapon_rows[knife_id] = {"card": card, "buy_btn": card.action_button}
		# Los Arms ya desbloqueados (o en uso) se ven con normalidad; los de la
		# cadena bloqueados conservan su hueco pero van velados.
		card.set_locked(not is_unlocked)

		if is_equipped:
			card.action_button.text = "EN USO"
			card.action_button.disabled = true
		elif is_unlocked:
			card.action_button.text = "EQUIPAR"
			card.action_button.disabled = false
		elif not chain_ok:
			card.action_button.text = "BLOQUEADO"
			card.action_button.disabled = true
		else:
			card.action_button.text = "$" + UiTheme.format_money(float(price))
			card.action_button.tooltip_text = "Desbloquear arma"
			card.action_button.disabled = GameManager.run_money < price

func _on_weapon_action(knife_id: String) -> void:
	if GameManager.is_knife_unlocked_this_run(knife_id):
		GameManager.set_equipped_knife_this_run(knife_id)
		_rebuild_weapon_shop()
		return
	var previous_id := _get_prev_knife_id(knife_id)
	if previous_id != "" and not GameManager.is_knife_unlocked_this_run(previous_id):
		return
	var knife_data: KnifeData = StatsManager.knives_db[knife_id]
	if GameManager.spend_run_money(StatsManager.get_weapon_price(knife_data.price)):
		GameManager.unlock_knife_this_run(knife_id)
		GameManager.set_equipped_knife_this_run(knife_id)
		SoundManager.play_victory()
		_refresh_ui()
		_rebuild_weapon_shop()

func _on_buy_fruit(fruit_id: String, price: int) -> void:
	var prev_id: String = _get_prev_fruit_id(fruit_id)
	if prev_id != "" and not GameManager.is_fruit_unlocked_this_run(prev_id):
		return
	if GameManager.spend_run_money(price):
		GameManager.unlock_fruit_this_run(fruit_id)
		SoundManager.play_victory()
		_refresh_ui()
		_update_fruit_row(fruit_id)
		_refresh_affordability()

func _on_buy_upgrade(upgrade_id: String) -> void:
	var cost: float = StatsManager.get_run_upgrade_cost(upgrade_id)
	if GameManager.spend_run_money(cost):
		SoundManager.play_coin()
		StatsManager.buy_run_upgrade(upgrade_id)
		_refresh_ui()
		_update_upgrade_row(upgrade_id)
		UiTheme.pulse_label(_upgrade_rows[upgrade_id]["card"].current_stat_label)
		_refresh_affordability()

func _on_stats_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_stats_requested")

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("start_next_order_requested")

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("start_next_order_requested")
