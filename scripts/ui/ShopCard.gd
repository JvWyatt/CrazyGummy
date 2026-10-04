class_name ShopCard
extends PanelContainer
## Tarjeta de mejora: escena editable en components/ShopCard.tscn.
## La tienda aporta datos y conecta la acción; la escena decide la presentación.

var action_button: Button
var name_label: Label
var subtitle_label: Label
var current_stat_label: Label
var _icon_label: Label
var _desc_label: Label

# Crea la tarjeta con su jerarquia interna ya montada.
static func create(border_color: Variant = null) -> ShopCard:
	var card := (load("res://scenes/ui/components/ShopCard.tscn") as PackedScene).instantiate() as ShopCard
	card._bind_nodes()
	if border_color != null:
		UiTheme.apply_card(card, border_color as Color)
	return card

func _ready() -> void:
	_bind_nodes()

func _bind_nodes() -> void:
	action_button = get_node("Content/ActionButton")
	name_label = get_node("Content/NameLabel")
	subtitle_label = get_node("Content/SubtitleLabel")
	current_stat_label = get_node("Content/CurrentStatLabel")
	_icon_label = get_node("Content/IconHolder/IconLabel")
	_desc_label = get_node("Content/DescLabel")

# Rellena el contenido. subtitle puede ir vacio si la mejora no tiene niveles.
func setup(icon: String, title: String, subtitle: String, desc: String, action_text: String, action_enabled: bool) -> void:
	_icon_label.text = icon
	name_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.visible = not subtitle.is_empty()
	_desc_label.text = desc
	action_button.text = action_text
	action_button.disabled = not action_enabled

# Las claves de prestigio leen exclusivamente estadísticas permanentes.
# Solo las claves del mercado consultan los valores finales de la run.
func update_current_stat(stat_key: String) -> void:
	var text: String = ""
	match stat_key:
		"experience":
			text = "Daño: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key))
		"expert_hand":
			text = "Resistencia: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key))
		"good_fortune":
			text = "Jackpot: " + UiTheme.format_jackpot(StatsManager.get_permanent_stat(stat_key) * 100.0, true) + "%"
		"good_provider":
			text = "Dinero: x" + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key))
		"launch_speed":
			text = "Velocidad: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key)) + " frutas/s"
		"damage":
			text = "Daño: " + UiTheme.format_stat(StatsManager.get_final_damage())
		"energy_max":
			text = "Resistencia: " + UiTheme.format_stat(StatsManager.get_final_max_energy())
		"luck":
			text = "Jackpot: " + UiTheme.format_jackpot(StatsManager.get_final_jackpot_bonus() * 100.0, false) + "%"
		"money":
			text = "Dinero: x" + UiTheme.format_stat(StatsManager.get_final_money_multiplier())
		"launch_rate":
			text = "Velocidad: " + UiTheme.format_stat(StatsManager.get_final_launch_rate()) + " frutas/s"
	current_stat_label.text = text
	current_stat_label.visible = not text.is_empty()
