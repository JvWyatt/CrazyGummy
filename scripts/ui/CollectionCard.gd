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
var _name_label: Label
var _back_name_label: Label
var _stats_label: Label
var _desc_label: Label
var _flip_tween: Tween
var _flipped: bool = false
var _pointer_down: bool = false
var _press_position: Vector2

static func create() -> CollectionCard:
	var card := (load("res://scenes/ui/components/CollectionCard.tscn") as PackedScene).instantiate() as CollectionCard
	card.action_button = card.get_node("Column/ActionButton")
	card._face = card.get_node("Column/Face")
	card._front = card.get_node("Column/Face/Front")
	card._back = card.get_node("Column/Face/Back")
	card._scrim = card.get_node("Column/Face/LockScrim")
	card._badge = card.get_node("Column/Face/LockBadge")
	card._art_texture = card.get_node("Column/Face/Front/ArtBox/ArtTexture")
	card._art_emoji = card.get_node("Column/Face/Front/ArtBox/ArtEmoji")
	card._name_label = card.get_node("Column/Face/Front/FrontName")
	card._back_name_label = card.get_node("Column/Face/Back/BackName")
	card._stats_label = card.get_node("Column/Face/Back/Stats")
	card._desc_label = card.get_node("Column/Face/Back/Desc")
	card._face.gui_input.connect(card._on_face_gui_input)
	card._face.resized.connect(card._layout_faces)
	return card

func _ready() -> void:
	# También permite usar la escena directamente desde el editor.
	if _face == null:
		action_button = $Column/ActionButton
		_face = $Column/Face
		_front = $Column/Face/Front
		_back = $Column/Face/Back
		_scrim = $Column/Face/LockScrim
		_badge = $Column/Face/LockBadge
		_art_texture = $Column/Face/Front/ArtBox/ArtTexture
		_art_emoji = $Column/Face/Front/ArtBox/ArtEmoji
		_name_label = $Column/Face/Front/FrontName
		_back_name_label = $Column/Face/Back/BackName
		_stats_label = $Column/Face/Back/Stats
		_desc_label = $Column/Face/Back/Desc
		_face.gui_input.connect(_on_face_gui_input)
		_face.resized.connect(_layout_faces)
	_layout_faces()

func _layout_faces() -> void:
	for child in _face.get_children():
		child.pivot_offset = _face.size * 0.5

func setup(item_id: String, emoji: String, display_name: String, stats: String, desc: String, texture: Texture2D) -> void:
	_art_texture.texture = texture
	_art_texture.visible = texture != null
	_art_emoji.text = emoji
	_art_emoji.visible = texture == null
	_name_label.text = display_name
	_back_name_label.text = display_name
	_stats_label.text = stats
	_desc_label.text = desc
	_desc_label.visible = not desc.is_empty()
	set_meta("item_id", item_id)

func set_locked(locked: bool, _lock_hint: String = "") -> void:
	is_locked = locked
	_scrim.visible = locked
	_badge.visible = locked
	_art_texture.visible = not locked and _art_texture.texture != null
	_art_emoji.visible = not locked and _art_texture.texture == null
	_name_label.visible = not locked
	# El bloqueo nunca revela nombres de objetos que aún no se han descubierto.
	_badge.text = "🔒\nPOR DESCUBRIR"
	_face.tooltip_text = "" if locked else "Toca para ver datos"
	if locked and _flipped:
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
	if is_locked or event.device == InputEvent.DEVICE_ID_EMULATION:
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

static func fruit_texture(fruit_id: String) -> Texture2D:
	var path: String = str(FruitVisual.TEXTURE_PATHS.get(fruit_id, ""))
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
