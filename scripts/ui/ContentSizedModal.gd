@tool
extends PanelContainer
## Altura natural del contenido, limitada por la pantalla y siempre centrada.
## Anchors horizontales, padding y parámetros editables desde el Inspector.

@export_range(0.3, 0.95, 0.01) var max_height_ratio: float = 0.88
@export_range(0, 100) var extra_padding: float = 0.0
@export_range(0, 300) var minimum_height: float = 96.0
## Pestaña de referencia para conservar la altura al cambiar de sección.
@export var tab_height_reference: NodePath

var _fit_queued: bool = false
var _fitting: bool = false
var _safe_insets: Vector4 = Vector4.ZERO
var _horizontal_offsets: Vector2

func _ready() -> void:
	_horizontal_offsets = Vector2(offset_left, offset_right)
	anchor_top = 0.5
	anchor_bottom = 0.5
	get_viewport().size_changed.connect(_queue_fit)
	visibility_changed.connect(_queue_fit)
	resized.connect(_queue_fit)
	theme_changed.connect(_queue_fit)
	get_tree().node_added.connect(_on_node_added)
	_watch_controls(self)
	_queue_fit()

func update_safe_area(insets: Vector4) -> void:
	_safe_insets = insets
	offset_left = _horizontal_offsets.x + lerpf(insets.x, -insets.z, anchor_left)
	offset_right = _horizontal_offsets.y + lerpf(insets.x, -insets.z, anchor_right)
	_queue_fit()

func _on_node_added(node: Node) -> void:
	if is_ancestor_of(node):
		_watch_controls(node)
		_queue_fit()

func _watch_controls(node: Node) -> void:
	if node is Control:
		if not node.minimum_size_changed.is_connected(_queue_fit):
			node.minimum_size_changed.connect(_queue_fit)
		if not node.visibility_changed.is_connected(_queue_fit):
			node.visibility_changed.connect(_queue_fit)
	if not node.child_exiting_tree.is_connected(_on_child_exiting):
		node.child_exiting_tree.connect(_on_child_exiting)
	for child in node.get_children():
		_watch_controls(child)

func _on_child_exiting(_child: Node) -> void:
	_queue_fit()

func _queue_fit() -> void:
	if not is_inside_tree() or _fit_queued or _fitting:
		return
	_fit_queued = true
	_fit.call_deferred()

func _fit() -> void:
	_fit_queued = false
	if not is_visible_in_tree():
		return
	_fitting = true
	var parent_rect := get_parent_area_size()
	var safe_height: float = parent_rect.y - _safe_insets.y - _safe_insets.w
	var desired: float = _natural_height(self) + extra_padding
	var height: float = maxf(get_combined_minimum_size().y, minf(maxf(desired, minimum_height), safe_height * max_height_ratio))
	var center_shift: float = (_safe_insets.y - _safe_insets.w) * 0.5
	offset_top = center_shift - height * 0.5
	offset_bottom = center_shift + height * 0.5
	pivot_offset = size * 0.5
	_fitting = false

func _natural_height(control: Control) -> float:
	var children: Array[Control] = []
	for child in control.get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion():
			children.append(child)
	var native_height: float = control.get_combined_minimum_size().y
	if children.is_empty():
		return native_height
	if control is ScrollContainer:
		return maxf(native_height, _natural_height(children[0]))
	if control is TabContainer:
		var current: Control = control.get_current_tab_control()
		if not tab_height_reference.is_empty():
			var reference := get_node_or_null(tab_height_reference) as Control
			if reference and reference.get_parent() == control:
				current = reference
		var body_height: float = _natural_height(current) if current else 0.0
		return maxf(native_height, body_height + control.get_tab_bar().get_combined_minimum_size().y + control.get_theme_stylebox("panel").get_minimum_size().y)
	if control is VBoxContainer:
		var height: float = control.get_theme_constant("separation") * maxi(children.size() - 1, 0)
		for child in children:
			height += _natural_height(child)
		return maxf(native_height, height)
	if control is HBoxContainer:
		for child in children:
			native_height = maxf(native_height, _natural_height(child))
		return native_height
	if control is PanelContainer:
		return maxf(native_height, _natural_height(children[0]) + control.get_theme_stylebox("panel").get_minimum_size().y)
	return native_height
