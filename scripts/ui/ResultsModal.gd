extends Control
# ============================================================================
# ResultsModal: resumen del negocio exitoso, cerrado o en quiebra.
# ============================================================================

signal return_to_menu_requested

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var orders_label: Label = $Panel/VBox/StatsVBox/OrdersLabel
@onready var money_label: Label = $Panel/VBox/StatsVBox/MoneyLabel
@onready var gummies_label: Label = $Panel/VBox/StatsVBox/GummiesLabel
@onready var jackpots_label: Label = $Panel/VBox/StatsVBox/JackpotsLabel
@onready var golden_label: Label = $Panel/VBox/StatsVBox/GoldenLabel
@onready var prestige_earned_label: Label = $Panel/VBox/PrestigeContainer/VBox/PrestigeEarnedLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueButton

func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)

func open_modal(summary: Dictionary) -> void:
	visible = true
	if summary.get("successful", false):
		title_label.text = "🏆 NEGOCIO EXITOSO"
	elif summary.get("end_reason", "failed") == "quit":
		title_label.text = "NEGOCIO FINALIZADO"
	else:
		title_label.text = "NEGOCIO EN QUIEBRA"
	UiTheme.pop_in($Panel)
	orders_label.text = "📋 Días completados en el negocio: " + str(summary.get("completed_orders", 0))
	money_label.text = "💰 Ganancias generadas: $" + UiTheme.format_money(float(summary.get("money_generated", 0.0)))
	gummies_label.text = "🍬 Gomitas producidas: " + str(summary.get("gummies_produced", 0))
	jackpots_label.text = "⭐ Jackpots conseguidos: " + str(summary.get("jackpots", 0))
	golden_label.text = "✨ Gomitas doradas: " + str(summary.get("golden_gummies", 0))
	prestige_earned_label.text = "+ " + UiTheme.format_money(float(summary.get("earned_prestige", 0))) + " ⭐"

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("return_to_menu_requested")
