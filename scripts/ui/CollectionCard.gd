class_name CollectionCard
extends PanelContainer
## Caras, tipografía y tamaños editables en components/CollectionCard.tscn.

@export_range(0.05, 0.4) var flip_time: float = 0.16
@export var tap_slop: float = 18.0

var action_button: Button
var is_locked: bool = true
var _face: Control
var _front: Control
var _back: Control
var _scrim: ColorRect
var _badge: Label
var _art_texture: TextureRect
var _art_emoji: Label
var _back_name_label: Label
var _stats_label: Label
var _desc_label: Label
var _revealable: bool = false
var _flip_tween: Tween
var _flipped: bool = false
var _pointer_down: bool = false
var _press_position: Vector2

static func create() -> CollectionCard:
	var card := (load("res://scenes/ui/components/CollectionCard.tscn") as PackedScene).instantiate() as CollectionCard
	card.action_button = card.get_node("Column/Face/Back/ActionButton")
	card._face = card.get_node("Column/Face")
	card._front = card.get_node("Column/Face/Front")
	card._back = card.get_node("Column/Face/Back")
	card._scrim = card.get_node("Column/Face/LockScrim")
	card._badge = card.get_node("Column/Face/LockBadge")
	card._art_texture = card.get_node("Column/Face/Front/ArtBox/ArtTexture")
	card._art_emoji = card.get_node("Column/Face/Front/ArtBox/ArtEmoji")
	card._back_name_label = card.get_node("Column/Face/Back/BackName")
	card._stats_label = card.get_node("Column/Face/Back/Stats")
	card._desc_label = card.get_node("Column/Face/Back/Desc")
	card._face.gui_input.connect(card._on_face_gui_input)
	card._face.resized.connect(card._layout_faces)
	return card

func _ready() -> void:
	# También permite usar la escena directamente desde el editor.
	if _face == null:
		action_button = $Column/Face/Back/ActionButton
		_face = $Column/Face
		_front = $Column/Face/Front
		_back = $Column/Face/Back
		_scrim = $Column/Face/LockScrim
		_badge = $Column/Face/LockBadge
		_art_texture = $Column/Face/Front/ArtBox/ArtTexture
		_art_emoji = $Column/Face/Front/ArtBox/ArtEmoji
		_back_name_label = $Column/Face/Back/BackName
		_stats_label = $Column/Face/Back/Stats
		_desc_label = $Column/Face/Back/Desc
		_face.gui_input.connect(_on_face_gui_input)
		_face.resized.connect(_layout_faces)
	resized.connect(_fit_artwork_face)
	theme_changed.connect(_fit_artwork_face)
	_fit_artwork_face()
	_layout_faces()
	UiTheme.add_hover_scale(action_button)
	UiTheme.decorate_panel(self)

func _fit_artwork_face() -> void:
	# El frente es un área cuadrada de arte puro; el reverso (mismo cuadrado)
	# acomoda el nombre, los datos y la acción con su jerarquía propia.
	var padding: float = get_theme_stylebox("panel").get_minimum_size().x
	var side: float = maxf(size.x, custom_minimum_size.x) - padding
	if not is_equal_approx(_face.custom_minimum_size.y, side):
		_face.custom_minimum_size.y = side

func set_visual_state(state: String) -> void:
	# Solo acabado: disponibilidad y acciones continúan decididas por la tienda.
	var base_type: StringName = &"IllustratedCard" if _art_texture.texture != null else &"CompactCard"
	var sb := get_theme_stylebox("panel", base_type).duplicate() as StyleBoxFlat
	if state == "equipped":
		sb.border_color = UiTheme.COLOR_ACTION
	elif state == "owned":
		sb.border_color = UiTheme.COLOR_SUCCESS.darkened(0.25)
	elif state == "buyable":
		sb.border_color = UiTheme.COLOR_ACTION.darkened(0.25)
	else:
		sb.border_color = UiTheme.COLOR_BORDER.darkened(0.25)
	add_theme_stylebox_override("panel", sb)

func _layout_faces() -> void:
	for child in _face.get_children():
		child.pivot_offset = _face.size * 0.5

func setup(item_id: String, emoji: String, display_name: String, stats: String, desc: String, texture: Texture2D, name_role: StringName = &"CardTitle") -> void:
	var artwork: Texture2D = texture if texture != null else preload("res://scripts/ui/CollectionArt.gd").texture_for(item_id)
	_art_texture.texture = artwork
	_art_texture.visible = artwork != null
	_art_emoji.text = emoji
	_art_emoji.visible = artwork == null
	if artwork == null:
		preload("res://scripts/ui/GummyIcons.gd").replace_label(_art_emoji, item_id if item_id.begins_with("tool_") else "recipe")
	theme_type_variation = &"IllustratedCard" if artwork != null else &"CompactCard"
	_back_name_label.text = display_name
	# El reverso conserva el rol tipográfico de su origen.
	_back_name_label.theme_type_variation = name_role
	_stats_label.text = stats
	_desc_label.text = desc
	_desc_label.visible = not desc.is_empty()
	set_meta("item_id", item_id)

func set_locked(locked: bool, _lock_hint: String = "", revealable: bool = false) -> void:
	is_locked = locked
	_revealable = revealable
	_scrim.visible = locked
	_badge.visible = locked
	_art_texture.visible = not locked and _art_texture.texture != null
	_art_emoji.visible = not locked and _art_texture.texture == null
	# El bloqueo nunca revela nombres de objetos que aún no se han descubierto.
	_badge.text = "🔒\nPOR DESCUBRIR"
	# Las comprables (cadena desbloqueada) pueden voltearse para ver su precio;
	# las bloqueadas sin descubrir permanecen veladas sin revelar contenido.
	if locked and not revealable:
		_face.tooltip_text = ""
	elif locked:
		_face.tooltip_text = "Toca para ver datos y precio"
	else:
		_face.tooltip_text = "Toca para ver datos"
	theme_type_variation = &"IllustratedCard" if _art_texture.texture != null else &"CompactCard"
	if locked and not revealable and _flipped:
		if _flip_tween:
			_flip_tween.kill()
		_flipped = false
		_back.visible = false
		_front.visible = true
		_face.scale = Vector2.ONE

func reset_face() -> void:
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	_flipped = false
	_pointer_down = false
	_front.visible = true
	_back.visible = false
	_face.scale = Vector2.ONE

func _on_face_gui_input(event: InputEvent) -> void:
	# Las bloqueadas sin descubrir no voltean: el velo no debe revelar nada.
	if (is_locked and not _revealable) or event.device == InputEvent.DEVICE_ID_EMULATION:
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
		pointer_event = event.button_index == MOUSE_BUTTON_LEFT
		pressed = event.pressed
		position = event.position
	if not pointer_event:
		return
	if pressed:
		_pointer_down = true
		_press_position = position
		return
	var was_down: bool = _pointer_down
	_pointer_down = false
	if was_down and position.distance_to(_press_position) <= tap_slop:
		accept_event()
		_play_flip(not _flipped)

func _play_flip(to_back: bool) -> void:
	if _flip_tween:
		_flip_tween.kill()
	_flipped = to_back
	_face.pivot_offset = _face.size * 0.5
	_flip_tween = create_tween()
	_flip_tween.tween_property(_face, "scale:x", 0.0, flip_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flip_tween.tween_callback(func():
		_front.visible = not to_back
		_back.visible = to_back
	)
	_flip_tween.tween_property(_face, "scale:x", 1.0, flip_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
