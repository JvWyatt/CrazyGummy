extends Control
# ============================================================================
# RunUpgradeModal: el "mercado" que se abre entre pedidos, con 3 pestañas:
#   - Mejoras: sube potencia/resistencia/suerte/ganancias/ritmo de la partida.
#   - Recetas: desbloquea nuevas gomitas para esta partida (nodo Recetas).
#   - Herramientas: desbloquea y equipa herramientas (nodo Herramientas).
# TODO lo comprado aquí usa GameManager.run_money y se pierde si el negocio
# quiebra (ver GameManager.start_new_run que reinicia run_unlocked_recipes,
# run_unlocked_tools y StatsManager.run_upgrade_levels).
#
# DISEÑO EN REJILLA: las tres pestañas muestran tarjetas en un ResponsiveGrid
# (scripts/ui/ResponsiveGrid.gd): ShopCard para las mejoras y CollectionCard
# para recetas y herramientas. El aspecto de las tarjetas vive en esos scripts;
# aquí solo hay datos, precios y compra. Para volver al listado vertical basta
# con cambiar el nodo ItemsGrid por el VBoxContainer anterior.
# ============================================================================

signal start_next_order_requested
signal open_stats_requested
signal save_and_quit_requested

@onready var title_label: Label = $Panel/VBox/HeaderHBox/TitleLabel
@onready var money_label: Label = $Panel/VBox/HeaderHBox/MoneyLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var items_container: ResponsiveGrid = $Panel/VBox/TabContainer/Mejoras/ItemsGrid
@onready var recipe_items_container: ResponsiveGrid = $Panel/VBox/TabContainer/Recetas/ItemsGrid
@onready var tool_items_container: ResponsiveGrid = $Panel/VBox/TabContainer/Herramientas/ItemsGrid
@onready var stats_button: Button = $Panel/VBox/BottomHBox/StatsButton
@onready var save_and_quit_button: Button = $Panel/VBox/BottomHBox/SaveExitButton
@onready var continue_button: Button = $Panel/VBox/BottomHBox/ContinueButton

# Cached row refs so purchases can update in place instead of rebuilding the whole shop
var _upgrade_rows: Dictionary = {} # key -> {name_lbl, buy_btn}
var _recipe_rows: Dictionary = {} # recipe_id -> {card, buy_btn, price}
var _tool_rows: Dictionary = {} # tool_id -> {card, buy_btn}
var _prepare_queue: Array[Dictionary] = []

func _ready() -> void:
	stats_button.icon = preload("res://scripts/ui/GummyIcons.gd").texture("stats")
	stats_button.expand_icon = true
	stats_button.text = "Datos"
	# Títulos visibles independientes de las rutas históricas de los nodos.
	$Panel/VBox/TabContainer.set_tab_title(1, "Recetas")
	$Panel/VBox/TabContainer.set_tab_title(2, "Herramientas")
	StatsManager.stats_updated.connect(_refresh_upgrade_stats)
	close_button.pressed.connect(_on_close_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	save_and_quit_button.pressed.connect(_on_save_and_quit_pressed)
	UiTheme.add_hover_scale(save_and_quit_button, 0.0)
	# Construye una tarjeta por frame mientras el mercado está cerrado.
	_prepare_ui()

func _prepare_ui() -> void:
	for key in StatsManager.run_upgrade_definitions:
		_prepare_queue.append({"shop": "upgrade", "id": key})
	for recipe_id in RecipeDatabase.get_sorted_recipe_ids():
		_prepare_queue.append({"shop": "recipe", "id": recipe_id})
	for tool_id in StatsManager.get_sorted_tool_ids():
		_prepare_queue.append({"shop": "tool", "id": tool_id})
	set_process(true)

func _process(_delta: float) -> void:
	if _prepare_queue.is_empty():
		set_process(false)
		return
	var item: Dictionary = _prepare_queue.pop_front()
	match item["shop"]:
		"upgrade": _rebuild_upgrade_shop([item["id"]])
		"recipe": _rebuild_recipe_shop([str(item["id"])])
		"tool": _rebuild_tool_shop([str(item["id"])])
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
	_rebuild_recipe_shop()
	_rebuild_tool_shop()

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
			stat_name = "Potencia"
			var current: float = StatsManager.get_final_damage()
			var increment: float = StatsManager.get_run_damage_upgrade_next_value() - current
			if current < StatsManager.balance.damage_pity_floor and increment > current * bonus:
				return "+" + UiTheme.format_stat(increment) + " Potencia"
		"energy_max":
			bonus = StatsManager.balance.run_energy_bonus_per_level
			stat_name = "Resistencia"
		"luck":
			bonus = StatsManager.balance.run_jackpot_bonus_per_level
			return "+" + UiTheme.format_stat(bonus * 100.0) + " p.p. Jackpot"
		"money":
			bonus = StatsManager.balance.run_money_bonus_per_level
			stat_name = "Ganancias"
		"launch_rate":
			bonus = StatsManager.balance.run_launch_bonus_per_level
			stat_name = "Ritmo"
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

# Actualiza los valores finales también al cambiar herramientas, comodines o prestigio.
func _refresh_upgrade_stats() -> void:
	for key in _upgrade_rows:
		_update_upgrade_row(str(key))

# Receta anterior en la cadena de desbloqueo ("" si es la primera).
# No se puede comprar una receta sin haber comprado la anterior.
func _get_prev_recipe_id(recipe_id: String) -> String:
	var ids: Array[String] = RecipeDatabase.get_sorted_recipe_ids()
	var idx: int = ids.find(recipe_id)
	if idx > 0:
		return ids[idx - 1]
	return ""

# Arma anterior en la cadena de desbloqueo ("" si es la primera). Regla de la
# Herramientas: no se puede desbloquear un herramienta sin haber desbloqueado la anterior.
func _get_prev_tool_id(tool_id: String) -> String:
	var ids: Array[String] = StatsManager.get_sorted_tool_ids()
	var idx: int = ids.find(tool_id)
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
	for recipe_id in _recipe_rows.keys():
		_sync_recipe_row(str(recipe_id))
	_rebuild_tool_shop()

# Sincroniza el texto/estado del botón de una receta teniendo en
# cuenta DOS cosas: dinero suficiente Y que esté desbloqueada la receta anterior
# (regla de cadena).
func _sync_recipe_row(recipe_id: String) -> void:
	if not _recipe_rows.has(recipe_id):
		return
	var row: Dictionary = _recipe_rows[recipe_id]
	var card: CollectionCard = row["card"]
	var buy_btn: Button = row["buy_btn"]
	var unlocked: bool = GameManager.is_recipe_unlocked_this_run(recipe_id)
	var prev_id: String = _get_prev_recipe_id(recipe_id)
	var chain_ok: bool = prev_id == "" or GameManager.is_recipe_unlocked_this_run(prev_id)

	if unlocked:
		# Ya desbloqueada: fuera el velo y se ve la ilustración con sus datos.
		card.set_locked(false)
		buy_btn.text = "DISPONIBLE"
		buy_btn.disabled = true
		card.set_visual_state("owned")
		return
	if not chain_ok:
		card.set_locked(true)
		buy_btn.text = "BLOQUEADO"
		buy_btn.disabled = true
		card.set_visual_state("locked")
		return
	card.set_locked(true, "", true)
	buy_btn.text = "$" + UiTheme.format_money(float(row["price"]))
	buy_btn.tooltip_text = "Adquirir receta"
	buy_btn.disabled = GameManager.run_money < int(row["price"])
	card.set_visual_state("buyable" if not buy_btn.disabled else "discovered")

func _rebuild_recipe_shop(selected_ids: Array[String] = []) -> void:
	var recipe_ids: Array[String] = RecipeDatabase.get_sorted_recipe_ids() if selected_ids.is_empty() else selected_ids
	for recipe_id in recipe_ids:
		var recipe_data: RecipeData = RecipeDatabase.get_recipe_data(recipe_id)
		var price: int = StatsManager.get_recipe_price(recipe_data.price)
		if _recipe_rows.has(recipe_id):
			_recipe_rows[recipe_id]["price"] = price
			_recipe_rows[recipe_id]["card"].reset_face()
			_sync_recipe_row(recipe_id)
			continue

		var stats_lbl: String = "Dureza: " + UiTheme.format_stat(recipe_data.max_hp)
		# Rango monetario compacto para que quepa junto al nombre oficial completo.
		stats_lbl += "\n$" + UiTheme.format_money(recipe_data.min_reward)
		stats_lbl += " - $" + UiTheme.format_money(recipe_data.max_reward)

		# Cara = la receta; reverso = sus números. Las bloqueadas conservan su
		# hueco en el grid pero con el velo, sin arte ni nombre.
		var card := CollectionCard.create()
		card.setup(
			recipe_data.id,
			recipe_data.icon_emoji,
			recipe_data.display_name,
			stats_lbl,
			"",
			null,
			&"Body"
		)
		card.set_locked(true)

		var captured_id: String = str(recipe_id)
		card.action_button.pressed.connect(func():
			_on_buy_recipe(captured_id, int(_recipe_rows[captured_id]["price"]))
		)

		recipe_items_container.add_child(card)
		_recipe_rows[recipe_id] = {"card": card, "buy_btn": card.action_button, "price": price}
		_sync_recipe_row(recipe_id)

# Actualiza una receta tras comprarla, sin reconstruir la tarjeta.
func _update_recipe_row(recipe_id: String) -> void:
	_sync_recipe_row(recipe_id)

func _rebuild_tool_shop(selected_ids: Array[String] = []) -> void:
	var equipped_id: String = GameManager.run_equipped_tool
	var tool_ids: Array[String] = StatsManager.get_sorted_tool_ids() if selected_ids.is_empty() else selected_ids
	for tool_id in tool_ids:
		var tool_data: ToolData = StatsManager.tools_db[tool_id]
		var is_unlocked: bool = GameManager.is_tool_unlocked_this_run(tool_id)
		var is_equipped: bool = tool_id == equipped_id
		var price: int = StatsManager.get_tool_price(tool_data.price)
		var prev_id: String = _get_prev_tool_id(str(tool_id))
		var chain_ok: bool = prev_id == "" or GameManager.is_tool_unlocked_this_run(prev_id)

		var stats_lbl: String = "Potencia: " + UiTheme.format_stat(tool_data.damage)

		# CollectionCard resuelve el arte por ID; el reverso conserva sus números.
		var card: CollectionCard
		if _tool_rows.has(tool_id):
			card = _tool_rows[tool_id]["card"]
			card.reset_face()
		else:
			card = CollectionCard.create()
			card.setup(tool_data.id, tool_data.icon, tool_data.name, stats_lbl, "", null)
			card.action_button.pressed.connect(_on_tool_action.bind(tool_id))
			tool_items_container.add_child(card)
			_tool_rows[tool_id] = {"card": card, "buy_btn": card.action_button}
		# Los Arms ya desbloqueados (o en uso) se ven con normalidad; los de la
		# cadena bloqueados conservan su hueco pero van velados. Las comprables
		# (cadena desbloqueada) voltean para mostrar su precio antes de comprar.
		card.set_locked(not is_unlocked, "", chain_ok)

		if is_equipped:
			card.set_visual_state("equipped")
			card.action_button.text = "EN USO"
			card.action_button.disabled = true
		elif is_unlocked:
			card.set_visual_state("owned")
			card.action_button.text = "EQUIPAR"
			card.action_button.disabled = false
		elif not chain_ok:
			card.set_visual_state("locked")
			card.action_button.text = "BLOQUEADO"
			card.action_button.disabled = true
		else:
			card.action_button.text = "$" + UiTheme.format_money(float(price))
			card.action_button.tooltip_text = "Adquirir herramienta"
			card.action_button.disabled = GameManager.run_money < price
			card.set_visual_state("buyable" if not card.action_button.disabled else "discovered")

func _on_tool_action(tool_id: String) -> void:
	if GameManager.is_tool_unlocked_this_run(tool_id):
		GameManager.set_equipped_tool_this_run(tool_id)
		_rebuild_tool_shop()
		UiTheme.pulse_label(_tool_rows[tool_id]["card"].get_node("Column/Face"), 1.04)
		return
	var previous_id := _get_prev_tool_id(tool_id)
	if previous_id != "" and not GameManager.is_tool_unlocked_this_run(previous_id):
		return
	var tool_data: ToolData = StatsManager.tools_db[tool_id]
	if GameManager.spend_run_money(StatsManager.get_tool_price(tool_data.price)):
		GameManager.unlock_tool_this_run(tool_id)
		GameManager.set_equipped_tool_this_run(tool_id)
		SoundManager.play_victory()
		_refresh_ui()
		_rebuild_tool_shop()

func _on_buy_recipe(recipe_id: String, price: int) -> void:
	var prev_id: String = _get_prev_recipe_id(recipe_id)
	if prev_id != "" and not GameManager.is_recipe_unlocked_this_run(prev_id):
		return
	if GameManager.spend_run_money(price):
		GameManager.unlock_recipe_this_run(recipe_id)
		SoundManager.play_victory()
		_refresh_ui()
		_update_recipe_row(recipe_id)
		UiTheme.pulse_label(_recipe_rows[recipe_id]["card"].get_node("Column/Face"), 1.04)
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

# "Guardar y salir" desde el mercado: Main.gd persiste la run y sale al menú.
# El estado ORDER_CLEARED_CARD_SELECT queda en la instantánea para que al
# continuar se vuelva a abrir este mercado.
func _on_save_and_quit_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("save_and_quit_requested")
