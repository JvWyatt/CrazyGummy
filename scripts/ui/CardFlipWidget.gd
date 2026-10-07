class_name CardFlipWidget
extends Control
# ============================================================================
# CardFlipWidget: la carta de comodín con FRENTE y REVERSO. Es el componente
# visual único del juego y se reutiliza tal cual en tres sitios:
#
#   - PICK (por defecto): la pantalla de elección de comodines
#     (CardSelectionModal), con el botón ELEGIR debajo.
#   - THUMBNAIL: la miniatura de la galería de comodines del menú
#     (CardsModal). Sin botón: al tocarla avisa con `previewed`.
#   - DETAIL: presentación de solo lectura, también sin reverso.
#
# IMPORTANTE: este widget NO contiene lógica de selección ni efectos. Solo
# PRESENTA la Dictionary de CardDatabase que ya generaba el sistema y emite
# "chosen(card_data)" (modo PICK) o "previewed(card_data)" (modo THUMBNAIL)
# para que quien lo usa decida. No se tocan get_random_cards(), las
# probabilidades ni effect_type/effect_value.
#
# MAQUETA (las dos caras son idénticas para que el giro sea simétrico):
#
#     ┌───────────────┐  <- marco del color de la RAREZ
#     │               │
#     │  la carta     │  <- ilustración, ceñida al marco (sin estirar)
#     │               │
#     └───────────────┘
#      [  ELEGIR  ]     <- DEBAJO del marco, FUERA de la carta (solo modo PICK)
#
# El marco se dimensiona a partir del aspect ratio real de la ilustración, de
# modo que la caja nunca queda más alta que la imagen. El botón va fuera para
# que no se confunda con parte de la carta.
#
# TAMAÑO: todo se mide a partir del ancho pedido con set_mode(), así que la
# misma carta sirve como miniatura (galería) y como carta grande (detalle).
#
# IMPORTANTE (tamaño del reverso): las dos caras miden SIEMPRE lo mismo, la
# del widget entero. El reverso no se encoge ni se estira para que quepa el
# texto: la imagen del dorso va a sangre de fondo y la rareza, el título y la
# descripción se dibujan ENCIMA. Ver _build_back_art().
# ============================================================================

signal chosen(card_data: Dictionary)
signal previewed(card_data: Dictionary)

# Cómo se presenta la carta. El ancho se pasa aparte en set_mode().
enum Presentation {
	PICK,       # carta elegible con botón ELEGIR (CardSelectionModal)
	THUMBNAIL,  # miniatura de la galería: al tocarla avisa con previewed
	DETAIL,     # solo lectura; nunca se gira
}

const CARD_SIZE: Vector2 = Vector2(180, 300)
# Grosor del marco de rareza y aire que queda entre el marco y la imagen.
const CARD_FRAME: float = 2.0
const CARD_PADDING: float = 6.0
# Separación entre el borde inferior de la carta y el botón ELEGIR.
const CARD_GAP: float = 10.0
const BUTTON_HEIGHT: float = 56.0
# Margen que deja el contenido del reverso respecto al borde de la imagen.
const BACK_TEXT_INSET: float = 6.0
# Velo que se echa sobre la imagen del dorso para que el texto se lea encima.
const COLOR_BACK_SCRIM: Color = Color(0.055, 0.04, 0.1, 0.78)
const BACK_TEXTURE: Texture2D = preload("res://assets/crazy_gummy/ui/cards/back.svg")
const FRONT_ART_TEXTURE: Texture2D = preload("res://assets/crazy_gummy/ui/cards/front.svg")

# Pista que se añade al final de la descripción del reverso, según el modo.
const HINT_PICK: String = "\n\n⟳ Toca para volver"
const HINT_DETAIL: String = "\n\n⟳ Toca para ver el anverso"

var _data: Dictionary = {}
var _flipping: bool = false
var _showing_back: bool = false
var _pointer_down: bool = false
var _press_position: Vector2
@export var tap_slop: float = 18.0

var _presentation: Presentation = Presentation.PICK
var _card_width: float = CARD_SIZE.x

var _front: Control
var _back: Control
var _art_container: Control
var _back_art_rect: TextureRect
var _art_label: Label
var _back_title: Label
var _back_desc: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_front = Control.new()
	_back = Control.new()
	add_child(_front)
	add_child(_back)
	_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_metrics()

# Elige cómo se presenta la carta y de qué ancho. Debe llamarse ANTES de
# configure(); si se cambia después, la carta se reconstruye sola.
func set_mode(mode: Presentation, card_width: float = CARD_SIZE.x) -> void:
	_presentation = mode
	_card_width = maxf(card_width, 40.0)
	_rebuild()

# ---------------------------------------------------------------------------
# Medidas: el marco se calcula a partir del aspect ratio real de la imagen para
# que la caja nunca sea más alta que la carta que contiene.
# ---------------------------------------------------------------------------

# Espacio que ocupa el marco por cada lado (grosor + aire interior).
static func _card_inset() -> float:
	return CARD_FRAME + CARD_PADDING

# Altura sobre ancho de la ilustración (352x512 -> 1.4545 en estas cartas).
static func _art_ratio() -> float:
	var tex_size: Vector2 = FRONT_ART_TEXTURE.get_size()
	if tex_size.x <= 0.0:
		return 1.45
	return tex_size.y / tex_size.x

# Tamaño del hueco donde va la ilustración, ya dentro del marco.
func _art_size() -> Vector2:
	var width: float = _card_width - _card_inset() * 2.0
	return Vector2(width, width * _art_ratio())

# Tamaño de la caja con marco.
func _card_box() -> Vector2:
	return Vector2(_card_width, _art_size().y + _card_inset() * 2.0)

# ¿Esta presentación lleva el botón ELEGIR colgando fuera del marco?
func _has_choose_button() -> bool:
	return _presentation == Presentation.PICK

# Pista que se añade al reverso. En miniatura no se pone: el reverso es diminuto.
func _hint_text() -> String:
	match _presentation:
		Presentation.PICK:
			return HINT_PICK
		Presentation.DETAIL:
			return HINT_DETAIL
		_:
			return ""

# Alto total del widget: carta (+ botón, si lo lleva).
func _total_height() -> float:
	var height: float = _card_box().y
	if _has_choose_button():
		height += CARD_GAP + BUTTON_HEIGHT
	return height

func _apply_metrics() -> void:
	# El alto lo marca el contenido (carta + botón), no el modal: así el marco
	# queda ceñido a la ilustración y la carta no se estira en vertical.
	custom_minimum_size = Vector2(_card_width, _total_height())
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_front.visible = not _showing_back
	_back.visible = _showing_back

# Descarta las caras actuales y las vuelve a montar con la presentación actual.
func _rebuild() -> void:
	_flipping = false
	_showing_back = false
	for face in [_front, _back]:
		for child in face.get_children():
			face.remove_child(child)
			child.queue_free()
	_apply_metrics()
	if not _data.is_empty():
		configure(_data)

# Rellena el widget con los datos de una carta de CardDatabase.
func configure(card_data: Dictionary) -> void:
	_data = card_data
	var border: Color = card_data.get("color", Color(0.3, 0.7, 1.0))
	var title_text: String = str(card_data.get("title", ""))
	var desc_text: String = str(card_data.get("desc", ""))
	var icon_text: String = str(card_data.get("icon", "🃏"))

	_build_face(true, border)
	if _presentation == Presentation.PICK:
		_build_face(false, border)

	if _art_label != null:
		_art_label.text = icon_text
	if _back_title:
		_back_title.text = title_text
		_back_desc.text = desc_text + _hint_text()

	var image: Variant = card_data.get("image", FRONT_ART_TEXTURE)
	if image != null:
		_set_art_texture(_art_container, image)
		_build_rarity_marks(_art_container, border)
	if _presentation != Presentation.PICK:
		tooltip_text = title_text + "\n" + desc_text
	if _back_art_rect != null:
		_back_art_rect.texture = BACK_TEXTURE

func _make_custom_tooltip(for_text: String) -> Object:
	var tip := preload("res://scenes/ui/components/CardTooltip.tscn").instantiate()
	tip.set_text(for_text)
	return tip

# Gira SOLO la carta. El boton ELEGIR es hermano del marco, no hijo suyo, asi
# que se queda quieto durante la vuelta: antes se escalaba el widget entero y
# el boton se volteaba pegado a la tarjeta.
func flip() -> void:
	if _flipping or _presentation != Presentation.PICK:
		return
	_flipping = true
	_set_cards_filter(Control.MOUSE_FILTER_IGNORE)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_cards_scale, 1.0, 0.0, 0.14).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_front.visible = _showing_back
		_back.visible = not _showing_back
		_showing_back = not _showing_back
	)
	tween.tween_method(_set_cards_scale, 0.0, 1.0, 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_flipping = false
		_set_cards_filter(Control.MOUSE_FILTER_PASS)
	)

# Solo la carta da la vuelta. Este manejador esta conectado UNICAMENTE al
# marco (CardFrame), que envuelve la cara entera: asi la pulsacion y la suelta
# llegan siempre al mismo control y en las MISMAS coordenadas locales, de modo
# que cualquier punto de la carta (tambien el texto del reverso) cuenta como
# toque. El boton ELEGIR vive FUERA del marco, asi que al pulsarlo no le llega
# este evento: se limita a elegir la carta, sin girar nada.
func _on_card_gui_input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var pointer_event: bool = false
	var pressed: bool = false
	var position: Vector2
	if event is InputEventScreenTouch:
		if event.canceled:
			_pointer_down = false
			return
		pointer_event = true
		pressed = event.pressed
		position = event.position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pointer_event = mb.button_index == MOUSE_BUTTON_LEFT
		pressed = mb.pressed
		position = mb.position
	if not pointer_event:
		return
	if pressed:
		_pointer_down = true
		_press_position = position
		return
	var was_down: bool = _pointer_down
	_pointer_down = false
	if not was_down or position.distance_to(_press_position) > tap_slop:
		return
	accept_event()
	SoundManager.play_click()
	# En miniatura no hay nada que girar: el toque solo pide abrirla en grande.
	if _presentation != Presentation.PICK:
		previewed.emit(_data)
		return
	flip()

# ---------------------------------------------------------------------------
# Construcción de caras
# ---------------------------------------------------------------------------

# Escala solo los dos marcos de carta (el widget y el boton no se tocan).
func _set_cards_scale(value: float) -> void:
	for face in [_front, _back]:
		var frame := face.get_node_or_null("Column/CardFrame") as Control
		if frame != null:
			frame.scale.x = value

# El boton ELEGIR debe quedar quieto: solo se atenua el toque de las cartas
# mientras dure la vuelta, nunca el del boton.
func _set_cards_filter(filter: int) -> void:
	for face in [_front, _back]:
		var frame := face.get_node_or_null("Column/CardFrame") as Control
		if frame != null:
			frame.mouse_filter = filter

func _build_face(is_front: bool, border: Color) -> void:
	var face := _front if is_front else _back
	if face.get_child_count() > 0:
		return
	face.mouse_filter = Control.MOUSE_FILTER_PASS

	# Columna: MARCO DE LA CARTA y, debajo y fuera, el botón ELEGIR.
	var column := VBoxContainer.new()
	column.name = "Column"
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation", int(CARD_GAP))
	face.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var frame := _make_card_frame(border)
	column.add_child(frame)

	if is_front:
		_build_front_art(frame)
	else:
		_build_back_art(frame)

	if _has_choose_button():
		column.add_child(_make_choose_button())

# Marco del color de la rareza. SIZE_SHRINK_BEGIN para que NUNCA crezca: si el
# modal deja más alto, sobra espacio abajo en vez de estirar la carta.
func _make_card_frame(border: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = "CardFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.gui_input.connect(_on_card_gui_input)
	# La carta NO se estira a lo ancho: se queda con el ancho pedido en
	# set_mode() y se CENTRA en el hueco que le deja la celda. Si el marco
	# creciera hasta llenarla (la rejilla reparte entre las columnas el ancho
	# sobrante) la ilustración, que conserva su proporción, quedaría con aire a
	# los lados y el borde de rareza se despegaría de la carta. Ceñido al
	# perímetro, igual que en la pantalla de selección.
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.custom_minimum_size = _card_box()
	frame.clip_contents = true
	# Gira sobre su propio centro, no sobre el del widget.
	frame.pivot_offset = _card_box() * 0.5
	frame.resized.connect(func(): frame.pivot_offset = frame.size * 0.5)
	var inset := _card_inset()
	var sb := UiTheme.card_style(border)
	sb.border_color = border
	var rank: int = maxi(CardDatabase.RARITIES.find(str(_data.get("rarity", "Común"))), 0)
	sb.bg_color = sb.bg_color.lerp(border, 0.04 + rank * 0.02)
	sb.shadow_color = Color(border.r, border.g, border.b, 0.10 + rank * 0.04)
	sb.shadow_size = 4 + rank
	sb.set_border_width_all(int(CARD_FRAME))
	sb.content_margin_left = inset
	sb.content_margin_right = inset
	sb.content_margin_top = inset
	sb.content_margin_bottom = inset
	frame.add_theme_stylebox_override("panel", sb)
	return frame

func _build_rarity_marks(art: Control, color: Color) -> void:
	var rarity: String = str(_data.get("rarity", "Común"))
	var rank: int = maxi(CardDatabase.RARITIES.find(rarity), 0) + 1
	var badge := Label.new()
	badge.name = "RarityBadge"
	badge.theme_type_variation = &"Body"
	badge.text = rarity
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_color_override("font_color", color.lightened(0.35))
	art.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	badge.offset_top = 12
	var seal := Label.new()
	seal.name = "RaritySeal"
	seal.theme_type_variation = &"Body"
	seal.text = "◆".repeat(rank)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.add_theme_color_override("font_color", color)
	art.add_child(seal)
	seal.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	seal.offset_top = -38
	seal.offset_bottom = -8

# El frontal es solo la carta y el botón: sin nombre de mejora ni ningún texto
# encima. El nombre y la descripción se leen al girar la carta. Como el nombre
# ya no se pinta, se deja como tooltip del arte (solo se ve al pasar el ratón
# por encima; no añade texto a la carta).
func _build_front_art(frame: Control) -> void:
	var art := Control.new()
	art.name = "ArtPanel"
	art.mouse_filter = Control.MOUSE_FILTER_PASS
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.custom_minimum_size = _art_size()
	art.clip_contents = true
	frame.add_child(art)
	_art_container = art

	# Marcador de posición: si una carta llega sin imagen se ve su icono.
	var art_vbox := VBoxContainer.new()
	art_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	art_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(art_vbox)
	art_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art_label := Label.new()
	art_label.name = "ArtLabel"
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.theme_type_variation = &"IconLabel"
	art_label.modulate = Color(1, 1, 1, 0.9)
	art_vbox.add_child(art_label)
	_art_label = art_label

# El reverso es la MISMA carta girada: no se redimensiona nunca. La imagen del
# dorso llena el hueco del marco (que ya tiene su proporción) y el texto
# (título y descripción) va ENCIMA, superpuesto y centrado verticalmente.
#
# El trick que lo hace posible: el contenido cuelga de un Control simple
# ("Overlay", NO es un Container) con clip_contents = true. Al no ser Container
# no propaga su tamaño mínimo hacia el PanelContainer, así que la carta no
# crece ni se encoge por muy larga que sea la descripción; y clip_contents
# recorta el texto que no quepa en vez de deformar la carta.
#
# Ojo con los Labels con autowrap: devuelven un tamaño mínimo de (1 px de
# ancho, alto medido a 1 px), así que hay que darles a todos el ancho útil con
# custom_minimum_size. Sin eso el texto se mide a un carácter por línea y el
# marco acabaría midiendo 74x2336 px, saliéndose de la pantalla.
func _build_back_art(frame: Control) -> void:
	var overlay := Control.new()
	overlay.name = "Overlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.clip_contents = true
	frame.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_back_art_rect = _make_art_rect()
	_back_art_rect.name = "BackArt"
	overlay.add_child(_back_art_rect)
	_back_art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Velo oscuro para que el texto se lea sobre la ilustración.
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = COLOR_BACK_SCRIM
	overlay.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Bloque de texto centrado sobre la imagen. Su ancho se fija para que los
	# Labels con autowrap midan bien el salto de línea.
	var text_width: float = _art_size().x - BACK_TEXT_INSET * 2.0
	var text_scroll := ScrollContainer.new()
	text_scroll.name = "TextScroll"
	text_scroll.set_script(preload("res://scripts/ui/TouchScrollContainer.gd"))
	text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# El texto NO escucha toques: el giro lo lleva el marco (que lo envuelve) para
	# que pulsación y suelta lleguen siempre al mismo control. Si el ScrollContainer
	# también los recibiera, cada uno mezclaría sus coordenadas locales con las del
	# otro y el mismo toque parecería un arrastre largo (la carta no giraba).
	# Sigue pudiendo desplazarse con el dedo: TouchScrollContainer lo hace en
	# _input(), que no depende del mouse_filter.
	text_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(text_scroll)
	text_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_scroll.offset_left = BACK_TEXT_INSET
	text_scroll.offset_top = BACK_TEXT_INSET
	text_scroll.offset_right = -BACK_TEXT_INSET
	text_scroll.offset_bottom = -BACK_TEXT_INSET
	var text_box := VBoxContainer.new()
	text_box.name = "TextBox"
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 8)
	text_scroll.add_child(text_box)
	_back_title = _make_title_label(text_width)
	_back_desc = Label.new()
	_back_desc.name = "DescLabel"
	_back_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_back_desc.custom_minimum_size = Vector2(text_width, 0)
	_back_desc.theme_type_variation = &"JokerDescription"
	text_box.add_child(_back_title)
	text_box.add_child(_back_desc)

func _make_title_label(min_width: float) -> Label:
	var title := Label.new()
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# CRUCIAL: un Label con autowrap devuelve tamaño mínimo de (1 px, alto
	# medido a 1 px) porque su ancho depende del que le da el contenedor. Sin
	# fijar el ancho, el texto se mide a 1 carácter por línea y el contenedor
	# crece a miles de píxeles. Le damos el ancho útil de la carta.
	title.custom_minimum_size = Vector2(min_width, 0)
	title.theme_type_variation = &"JokerTitle"
	return title

func _make_choose_button() -> Button:
	var choose_btn := Button.new()
	choose_btn.name = "ChooseButton"
	choose_btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	choose_btn.text = "ELEGIR"
	choose_btn.theme_type_variation = &"PrimaryButton"
	choose_btn.ready.connect(func(): UiTheme.add_hover_scale(choose_btn))
	choose_btn.pressed.connect(func():
		chosen.emit(_data)
	)
	return choose_btn

# Crea un TextureRect de arte ya configurado.
# IMPORTANTE: expand_mode = EXPAND_IGNORE_SIZE es lo que hace que el TextureRect
# NO imponga su tamaño mínimo (352x512 en estas imágenes); sin eso el control
# crecía hasta el tamaño del PNG y empujaba el marco de la carta.
# IMPORTANTE: stretch_mode = STRETCH_KEEP_ASPECT_CENTERED muestra la imagen
# ENTERA y centrada en el hueco del marco, con su proporción intacta. Como el
# marco ya está calculado con ese mismo proportion, la imagen encaja justa.
func _make_art_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return rect

# Muestra la imagen de la carta en su hueco, conservando el aspect ratio.
func _set_art_texture(container: Control, image: Variant) -> void:
	var tex: Texture2D = null
	if image is Texture2D:
		tex = image
	elif image is String and FileAccess.file_exists(image):
		tex = load(image) as Texture2D
	if tex == null or container == null:
		return
	# Oculta el marcador de posición (icono + hint) y muestra la imagen real.
	for child in container.get_children():
		child.visible = false
	var rect := _make_art_rect()
	rect.texture = tex
	container.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
