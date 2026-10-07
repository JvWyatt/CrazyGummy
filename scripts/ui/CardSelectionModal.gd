extends Control
# ============================================================================
# CardSelectionModal: pantalla para elegir un comodín (carta) al completar
# un pedido. Muestra primero el resumen del día (conseguido, impuesto,
# ganancia) y debajo las cartas disponibles como 3 cartas verticales con
# frente y reverso (CardFlipWidget). Al completar el pedido el impuesto
# (objetivo del día) se paga automáticamente aquí; si no se puede pagar, el
# negocio termina (ver Main.gd).
# Las cartas disponibles vienen de CardDatabase.gd (get_random_cards); al
# elegir una se aplica con StatsManager.apply_card_upgrade(). La lógica de
# selección/efectos NO cambia; solo la presentación.
# ============================================================================

signal card_chosen(order_num: int)
signal unpayable

@export_range(148.0, 280.0) var card_max_width: float = 220.0

@onready var cards_container: HBoxContainer = $Panel/VBox/CardsHBox
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var earned_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/EarnedRow/EarnedValue
@onready var tax_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/TaxRow/TaxValue
@onready var profit_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/ProfitRow/ProfitValue
@onready var next_target_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/NextTargetRow/NextTargetValue

var current_completed_order: int = 1
var _selection_committed: bool = false

func _ready() -> void:
	visible = false
	cards_container.resized.connect(_resize_cards)

func open_modal(order_completed_num: int) -> void:
	current_completed_order = order_completed_num
	_selection_committed = false
	visible = true
	UiTheme.pop_in($Panel)
	UiTheme.confetti_burst($Panel, Vector2(maxf($Panel.size.x * 0.5, 360.0), 70.0), 120)
	title_label.text = "🎉 ¡DÍA #" + str(order_completed_num) + " COMPLETADO!"
	subtitle_label.text = "Selecciona 1 comodín para mejorar tu negocio:"

	# Impuesto (objetivo del día): se paga automáticamente al completar el día.
	var tax: float = GameManager.order_target
	var earned: float = GameManager.order_progress

	if not GameManager.spend_run_money(tax):
		# No se puede pagar el impuesto: negocio en quiebra.
		visible = false
		emit_signal("unpayable")
		return

	# Resumen del día: conseguido, impuesto y ganancia neta.
	earned_value.text = "$" + UiTheme.format_money(earned)
	tax_value.text = "$" + UiTheme.format_money(tax)
	var profit: float = earned - tax
	profit_value.text = "$" + UiTheme.format_money(profit)
	profit_value.modulate = UiTheme.COLOR_SUCCESS if profit >= 0.0 else UiTheme.COLOR_DANGER

	# Vista previa del objetivo del próximo día (debajo del impuesto del resumen).
	next_target_value.text = "$" + UiTheme.format_money(GameManager.get_order_target_for(GameManager.current_order + 1))

	for child in cards_container.get_children():
		child.queue_free()

	var cards: Array[Dictionary] = CardDatabase.get_random_cards(3)

	for card_data in cards:
		var widget := CardFlipWidget.new()
		widget.configure(card_data)
		widget.chosen.connect(_on_card_selected)
		cards_container.add_child(widget)
	_resize_cards.call_deferred()

func _resize_cards() -> void:
	var widgets := cards_container.get_children()
	if widgets.is_empty():
		return
	var gap: int = cards_container.get_theme_constant("separation")
	var width: float = minf(card_max_width, (cards_container.size.x - gap * (widgets.size() - 1)) / widgets.size())
	for widget in widgets:
		if widget is CardFlipWidget and not widget.is_queued_for_deletion() and not is_equal_approx(widget.custom_minimum_size.x, width):
			widget.set_mode(CardFlipWidget.Presentation.PICK, width)

func _on_card_selected(card_data: Dictionary) -> void:
	if _selection_committed or not visible:
		return
	_selection_committed = true
	visible = false
	SoundManager.play_victory()
	var effect_value: Variant = card_data["effect_value"] if card_data.has("effect_value") else card_data["effects"]
	StatsManager.apply_card_upgrade(
		card_data["id"],
		card_data["effect_type"],
		effect_value,
		card_data["title"]
	)
	emit_signal("card_chosen", current_completed_order)
