extends Node
## Ajusta los rectángulos anclados al área segura sin sustituir su layout.
## Los márgenes de diseño siguen siendo los offsets editables de cada escena.

@export var targets: Array[NodePath] = []
## Izquierda, arriba, derecha, abajo; unidades del viewport para previsualizar.
@export var preview_insets: Vector4 = Vector4.ZERO

var _base_offsets: Dictionary = {}

func _ready() -> void:
	for path in targets:
		var control := get_node_or_null(path) as Control
		if control:
			_base_offsets[control] = Vector4(control.offset_left, control.offset_top, control.offset_right, control.offset_bottom)
	get_viewport().size_changed.connect(_update_layout)
	_update_layout.call_deferred()

func _update_layout() -> void:
	var insets := preview_insets
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := Rect2(DisplayServer.get_display_safe_area())
		if safe.has_area():
			var inverse := get_viewport().get_screen_transform().affine_inverse()
			var viewport_rect := get_viewport().get_visible_rect()
			var start: Vector2 = inverse * safe.position
			var end: Vector2 = inverse * safe.end
			insets = Vector4(maxf(start.x, 0), maxf(start.y, 0), maxf(viewport_rect.end.x - end.x, 0), maxf(viewport_rect.end.y - end.y, 0))
	for control: Control in _base_offsets:
		if control.has_method("update_safe_area"):
			control.update_safe_area(insets)
			continue
		var base: Vector4 = _base_offsets[control]
		# Interpolar por ancla conserva también controles pegados solo a un borde.
		control.offset_left = base.x + lerpf(insets.x, -insets.z, control.anchor_left)
		control.offset_top = base.y + lerpf(insets.y, -insets.w, control.anchor_top)
		control.offset_right = base.z + lerpf(insets.x, -insets.z, control.anchor_right)
		control.offset_bottom = base.w + lerpf(insets.y, -insets.w, control.anchor_bottom)
