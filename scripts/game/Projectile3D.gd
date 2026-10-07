extends Node3D
class_name Projectile3D
## Espejo estético del proyectil 2D; no calcula daño ni recompensas.

@export_range(0.1, 2.0, 0.05) var visual_scale: float = 0.75
@export_range(0.0, 4000.0, 10.0) var broken_gravity: float = 1500.0
@export var gummy_visual_scene: PackedScene = preload("res://scenes/game/GummyVisual.tscn")
@export var gummy_material_palette: GummyMaterialPalette = preload("res://assets/crazy_gummy/materials/palette.tres")

var _gummy_visual: GummyVisual
var is_obstacle: bool = false
var _broken: bool = false
var _broken_has_halves: bool = false
var _radius: float = 40.0
var _spin: Vector3 = Vector3.ZERO
var _candy_velocity: Vector3 = Vector3.ZERO

@onready var whole: Node3D = $Whole
@onready var broken: Node3D = $Broken

func is_broken() -> bool:
	return _broken

func set_pos2d(pos: Vector2) -> void:
	var vs := get_viewport().get_visible_rect().size
	position = Vector3(pos.x - vs.x / 2.0, vs.y / 2.0 - pos.y, 0.0)

func setup_block(fd: RecipeData, golden: bool, p_scale: float = 1.0) -> void:
	is_obstacle = false
	_radius = fd.radius * visual_scale * maxf(p_scale, 0.05)
	_gummy_visual = gummy_visual_scene.instantiate()
	add_child(_gummy_visual)
	var appearance: Material = gummy_material_palette.material_for(fd.unlock_order, golden)
	_gummy_visual.setup(_radius, appearance, golden, fd.id)
	_gummy_visual.finished.connect(queue_free)
	_spin = Vector3(randf_range(-2.5, 2.5), randf_range(-2.0, 2.0), randf_range(-1.5, 1.5))

func setup_obstacle(p_radius: float) -> void:
	is_obstacle = true
	_radius = p_radius * visual_scale
	_install_candy(whole, RecipeVisualLibrary.HARD_CANDY)
	_install_candy(broken, RecipeVisualLibrary.HARD_CANDY_BROKEN)
	broken.hide()
	_spin = Vector3(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0), randf_range(-1.5, 1.5))

func _install_candy(container: Node3D, scene: PackedScene) -> void:
	var model: Node3D = scene.instantiate()
	container.add_child(model)
	_fit_content(model, _radius)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		# Conservar exactamente el acabado opaco que usaba el obstáculo activo.
		mesh.material_override = preload("res://assets/crazy_gummy/ui/effects/hardened_candy.tres")

func _process(delta: float) -> void:
	if not visible:
		return
	if _broken:
		if is_obstacle:
			_candy_velocity.y -= broken_gravity * delta
			position += _candy_velocity * delta
			broken.rotation.z += 2.5 * delta
			if position.y < -get_viewport().get_visible_rect().size.y / 2.0 - _radius:
				queue_free()
		return
	rotation += _spin * delta

func break_apart(_stroke_dir: Vector2 = Vector2.RIGHT, motion: Ballistic = null) -> void:
	if _broken:
		return
	_broken = true
	whole.hide()
	var previous_spin := _spin
	_spin = Vector3.ZERO
	if is_instance_valid(_gummy_visual):
		rotation = Vector3.ZERO
		_gummy_visual.break_apart(motion, previous_spin)
	else:
		# Mostrar el GLB roto intacto: sin cortar, duplicar ni generar mallas.
		broken.show()
		_candy_velocity = Vector3(motion.velocity.x, -motion.velocity.y, 0) if motion != null else Vector3(0, -200, 0)

func has_custom_hit_particles() -> bool:
	return is_instance_valid(_gummy_visual)

func play_hit() -> void:
	if not _broken and is_instance_valid(_gummy_visual):
		_gummy_visual.play_hit()

func _fit_content(node: Node3D, target_radius: float) -> void:
	var bounds := _content_aabb(node)
	var longest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if longest > 0.0:
		var factor := target_radius * 2.0 / longest
		node.scale *= factor
		node.position = -bounds.get_center() * factor

func _content_aabb(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var candidates: Array[Node] = [node]
	candidates.append_array(node.find_children("*", "MeshInstance3D", true, false))
	for child in candidates:
		var mesh := child as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var relative := node.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = relative * mesh.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds
