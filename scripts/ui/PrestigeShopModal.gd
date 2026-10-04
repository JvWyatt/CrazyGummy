extends Control
# ============================================================================
# PrestigeShopModal: tienda de mejoras PERMANENTES compradas con reputación
# (prestige_points en SaveManager). Los precios/efectos de cada mejora están
# en StatsManager.prestige_definitions.
# ============================================================================

@onready var prestige_label: Label = $Panel/VBox/HeaderHBox/PrestigeLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var items_container: ResponsiveGrid = $Panel/VBox/ScrollContainer/ItemsGrid

var _upgrade_cards: Dictionary = {}

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	SaveManager.prestige_changed.connect(func(_p): _refresh_ui())
	StatsManager.stats_updated.connect(_refresh_ui)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	prestige_label.text = "⭐ " + UiTheme.format_money(SaveManager.get_prestige_points()) + " Rep."

	for key in StatsManager.prestige_definitions.keys():
		var def: PrestigeUpgradeData = StatsManager.prestige_definitions[key]
		var level: int = SaveManager.get_prestige_level(key)
		var cost: float = StatsManager.get_prestige_upgrade_cost(key)
		var can_buy: bool = SaveManager.get_prestige_points() >= cost

		var effect_text: String = ""
		match key:
			"experience": effect_text = "+" + UiTheme.format_stat(StatsManager.balance.prestige_damage_bonus_per_level * 100.0) + "% Daño"
			"expert_hand": effect_text = "+" + UiTheme.format_stat(StatsManager.balance.prestige_energy_bonus_per_level * 100.0) + "% Resistencia"
			"good_provider": effect_text = "+" + UiTheme.format_stat(StatsManager.balance.prestige_money_bonus_per_level * 100.0) + "% Dinero"
			"good_fortune": effect_text = "+" + UiTheme.format_jackpot(StatsManager.balance.prestige_jackpot_bonus_per_level * 100.0, true) + " p.p. Jackpot"
			"launch_speed": effect_text = "+" + UiTheme.format_stat(StatsManager.balance.prestige_launch_bonus_per_level * 100.0) + "% Velocidad"

		# Tarjeta compacta del grid (scripts/ui/ShopCard.gd). Todo el diseno de
		# la tarjeta vive ahi; aqui solo se conectan los datos y la compra.
		var card: ShopCard
		if _upgrade_cards.has(key):
			card = _upgrade_cards[key]
		else:
			card = ShopCard.create()
			_upgrade_cards[key] = card
			var captured_key: String = str(key)
			card.action_button.pressed.connect(func():
				if StatsManager.buy_prestige_upgrade(captured_key):
					SoundManager.play_victory()
					UiTheme.pulse_label(card.current_stat_label)
			)
			items_container.add_child(card)
		card.setup(
			def.icon,
			def.name,
			"Nivel " + str(level),
			effect_text,
			"MEJORAR " + UiTheme.format_money(cost) + " ⭐",
			can_buy
		)
		card.update_current_stat(str(key))

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
