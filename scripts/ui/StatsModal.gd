extends Control
# ============================================================================
# StatsModal: pantalla de "Stats" que muestra en detalle los valores finales
# calculados por StatsManager que no se consultan naturalmente en el HUD ni
# en los precios de las tiendas. Solo lectura, sin desgloses de bonificaciones.
#
# PRESENTACIÓN BENTO: una sola rejilla (ResponsiveGrid), sin secciones,
# de tarjetas StatCard con icono, nombre y valor, en orden lógico.
# Dos columnas y seis filas: once estadísticas y acceso a los comodines.
#
# ============================================================================

signal modal_closed
signal open_cards_requested

# Dos columnas con el mismo ancho y alto en todas las casillas.
@export var card_min_width: float = 240.0
@export_range(1, 4) var max_columns: int = 2
@export var grid_separation: int = 10

@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var continue_button: Button = $Panel/VBox/ContinueButton
@onready var stats_container: VBoxContainer = $Panel/VBox/ScrollContainer/StatsVBox

# Rejilla única: todas las estadísticas comparten el mismo flujo visual.
var _stats_grid: ResponsiveGrid = null

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	continue_button.pressed.connect(_on_close_pressed)
	StatsManager.stats_updated.connect(_refresh_if_visible)

func _refresh_if_visible() -> void:
	# Al elegir un comodín no reconstruye tarjetas de una pantalla cerrada.
	# open_modal() siempre consulta los valores actuales al mostrarla.
	if is_visible_in_tree():
		_refresh_ui()

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in stats_container.get_children():
		child.queue_free()
	_create_stats_grid()

	var cost_en: float = StatsManager.get_final_energy_cost()
	var jackpot_bonus: float = StatsManager.get_final_jackpot_bonus() * 100.0
	var jackpot_multiplier: float = StatsManager.get_final_jackpot_multiplier()
	var golden_gummy_chance: float = StatsManager.get_golden_gummy_chance() * 100.0
	var crit_chance: float = StatsManager.get_final_critical_chance() * 100.0
	var crit_mult: float = StatsManager.get_final_critical_multiplier()

	# Procesamiento: consumo de resistencia y golpes críticos.
	_add_stat("⚡", "Coste por golpe", _number(cost_en), Color(0.9, 0.9, 0.9))
	_add_stat("🎯", "Prob. de crítico", _number(crit_chance) + "%", Color(0.8, 0.5, 1.0))
	_add_stat("💥", "Potencia crítica", "x" + _number(crit_mult), Color(0.8, 0.5, 1.0))

	# Cubos de gelatina.
	_add_stat("🧊", "Dureza de cubos", "x" + _number(StatsManager.get_block_hardness_multiplier()), Color(1.0, 0.5, 0.5))

	# Economía
	_add_stat("📉", "Recompensa mínima", "x" + _number(StatsManager.get_recipe_min_reward_multiplier()), Color(1.0, 0.88, 0.3))
	_add_stat("📈", "Recompensa máxima", "x" + _number(StatsManager.get_recipe_max_reward_multiplier()), Color(1.0, 0.88, 0.3))
	_add_stat("💵", "Ganancias", "x" + _number(StatsManager.get_final_money_multiplier()), Color(1.0, 0.88, 0.3))

	# Suerte
	_add_stat("🎰", "Prob. de Jackpot", _number(jackpot_bonus) + "%", Color(1.0, 0.75, 0.2))
	_add_stat("🃏", "Premio Jackpot", "x" + _number(jackpot_multiplier), Color(1.0, 0.75, 0.2))
	_add_stat("🥇", "Prob. gomita dorada", _number(golden_gummy_chance) + "%", Color(1.0, 0.85, 0.2))

	# Caramelo endurecido (candy es el identificador histórico).
	var candy_break: float = StatsManager.get_candy_break_chance()
	_add_stat("🪨", "Prob. romper caramelo", _number(candy_break * 100.0) + "%", Color(0.7, 0.75, 0.85))
	_add_cards_tile()

# La duodécima casilla comparte el marco bento y abre la galería existente.
func _add_cards_tile() -> void:
	var tile := StatCard.create()
	tile.setup("🃏", "Ver comodines", "→", Color(1.0, 0.88, 0.3))
	var button := Button.new()
	button.name = "CardsButton"
	button.tooltip_text = "Ver comodines"
	for style in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	button.pressed.connect(_on_cards_pressed)
	tile.add_child(button)
	_stats_grid.add_child(tile)

# Construye una única rejilla sin títulos ni huecos entre grupos.
func _create_stats_grid() -> void:
	var grid := ResponsiveGrid.new()
	grid.name = "Grid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.h_separation = grid_separation
	grid.v_separation = grid_separation
	grid.min_card_width = card_min_width
	grid.max_columns = max_columns
	grid.uniform_card_size = true
	grid.stretch_rows = false
	stats_container.add_child(grid)
	_stats_grid = grid

func _add_stat(icon: String, title: String, value: String, value_color: Color) -> void:
	var card := StatCard.create()
	card.setup(icon, title, value, value_color)
	_stats_grid.add_child(card)

# Presentación uniforme a un decimal; no modifica el valor interno.
func _number(value: float) -> String:
	return UiTheme.format_stat(value)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("modal_closed")

func _on_cards_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_cards_requested")
