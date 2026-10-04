extends Control
# ============================================================================
# CardsModal: galería de comodines (descubiertos históricamente, o los activos
# en la partida actual). Solo lectura, no modifica balance.
#
# PRESENTACION: rejilla de miniaturas reales —el mismo CardFlipWidget que se usa
# en la pantalla de elección, en modo THUMBNAIL— en lugar del listado de texto.
# PC: descripción al pasar el ratón. Móvil: panel de texto al tocar la carta.
# No hay reversos ni cartas ampliadas en esta sección.
# ============================================================================

@export_range(104.0, 240.0) var thumbnail_width: float = 144.0

@onready var title_label: Label = $Panel/VBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var rarity_legend: RichTextLabel = $Panel/VBox/RarityLegend
@onready var empty_label: Label = $Panel/VBox/EmptyLabel
@onready var cards_grid: ResponsiveGrid = $Panel/VBox/ScrollContainer/CardsGrid
@onready var card_tooltip: PanelContainer = $CardTooltip

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	get_viewport().size_changed.connect(_close_detail)
	visibility_changed.connect(_close_detail)

func _input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_close_detail()

func open_discovered_cards() -> void:
	title_label.text = "🃏 Comodines descubiertos"
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_cards(SaveManager.get_discovered_cards())

func open_active_cards() -> void:
	title_label.text = "ⓘ Comodines activos"
	visible = true
	UiTheme.pop_in($Panel)
	var active_ids: Array = []
	for card in StatsManager.active_cards:
		active_ids.append(card.get("id", ""))
	_refresh_cards(active_ids)

func _refresh_cards(card_ids: Array) -> void:
	for child in cards_grid.get_children():
		child.queue_free()

	var found_cards: Array[Dictionary] = []
	for card_id in card_ids:
		for card in CardDatabase.ALL_CARDS:
			if str(card["id"]) == str(card_id):
				found_cards.append(card)
				break

	empty_label.visible = found_cards.is_empty()
	rarity_legend.visible = not found_cards.is_empty()
	if found_cards.is_empty():
		rarity_legend.text = ""
		return

	# Ordenadas por rareza (de la mas comun a la mas rara) para que la rejilla
	# se lea por franjas de color sin necesidad de encabezados intermedios.
	found_cards.sort_custom(_sort_by_rarity)

	for card in found_cards:
		cards_grid.add_child(_make_thumbnail(card))

	_update_rarity_legend(found_cards)

# Miniatura de la rejilla: el MISMO componente de carta de la pantalla de
# elección, en modo THUMBNAIL (sin botón: al tocarla pide abrirla en grande).
func _make_thumbnail(card_data: Dictionary) -> CardFlipWidget:
	var thumb := CardFlipWidget.new()
	thumb.set_mode(CardFlipWidget.Presentation.THUMBNAIL, thumbnail_width)
	thumb.configure(card_data)
	thumb.set_meta("card_id", str(card_data.get("id", "")))
	thumb.previewed.connect(_on_thumbnail_pressed)
	return thumb

# --- Vista de detalle -------------------------------------------------------

func _on_thumbnail_pressed(card_data: Dictionary) -> void:
	_open_detail(card_data)

# Descripción pequeña sobre la galería; el grid conserva su distribución.
func _open_detail(card_data: Dictionary) -> void:
	var anchor_rect := Rect2(get_global_mouse_position(), Vector2.ZERO)
	for thumb in cards_grid.get_children():
		if thumb is CardFlipWidget and not thumb.is_queued_for_deletion() and thumb.get_meta("card_id", "") == str(card_data.get("id", "")):
			anchor_rect = thumb.get_global_rect()
			break
	card_tooltip.show_at(str(card_data.get("title", "Comodín")) + "\n" + str(card_data.get("desc", "")), anchor_rect, get_viewport().get_visible_rect())

func _close_detail() -> void:
	if is_instance_valid(card_tooltip):
		card_tooltip.hide()

# --- Leyenda de rarezas -----------------------------------------------------

# Resumen "Común 12 · Rara 3 · Épica 1": sustituye a los encabezados de rareza
# que tenía el listado de texto, ahora que la rejilla no separa secciones.
func _update_rarity_legend(found_cards: Array[Dictionary]) -> void:
	var parts: PackedStringArray = []
	for rarity in CardDatabase.RARITIES:
		var count: int = 0
		for card in found_cards:
			if str(card["rarity"]) == rarity:
				count += 1
		if count <= 0:
			continue
		var hex: String = CardDatabase.rarity_color(rarity).to_html(false)
		parts.append("[color=#" + hex + "]" + rarity + " " + str(count) + "[/color]")
	rarity_legend.text = " · ".join(parts)

func _sort_by_rarity(a: Dictionary, b: Dictionary) -> bool:
	var ia: int = CardDatabase.RARITIES.find(str(a.get("rarity", "")))
	var ib: int = CardDatabase.RARITIES.find(str(b.get("rarity", "")))
	return ia < ib

# --- Cierre -----------------------------------------------------------------

func _on_close_pressed() -> void:
	SoundManager.play_click()
	_close_detail()
	visible = false
