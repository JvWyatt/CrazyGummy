extends Node3D
class_name GummyVisual
# Presentación definitiva por receta: no conoce vida, economía ni colisiones.

signal finished

@export_group("Color de gelatina")
@export var palette: Array[Color] = [
	Color("#F2384A"), Color("#FF8A24"), Color("#FFD83D"), Color("#72D94C"),
	Color("#20E6C1"), Color("#32A8F0"), Color("#9B55E7"), Color("#FF65A3")
]
@export var fallback_color: Color = Color("#F2384A")
@export var randomize_material_color: bool = true
@export_range(0.0, 1.0, 0.01) var roughness: float = 0.25
@export_group("Impacto")
@export var squash: Vector3 = Vector3(1.18, 0.72, 1.18)
@export var stretch: Vector3 = Vector3(0.92, 1.18, 0.92)
@export_range(0.01, 0.2, 0.01) var squash_duration: float = 0.05
@export_range(0.01, 0.2, 0.01) var stretch_duration: float = 0.07
@export_range(0.01, 0.5, 0.01) var recovery_duration: float = 0.16
@export_range(0.0, 2.0, 0.05) var hit_particle_extent_ratio: float = 0.8
@export_range(0.0, 2.0, 0.05) var hit_particle_front_ratio: float = 1.25
@export_group("Producto terminado")
@export_range(0.1, 2.0, 0.05) var product_scale: float = 1.0
@export var product_rotation_degrees: Vector3 = Vector3.ZERO
@export var product_offset: Vector3 = Vector3.ZERO
@export_range(0.01, 0.5, 0.01) var product_reveal_duration: float = 0.12
@export_range(0.1, 1.0, 0.05) var product_reveal_scale: float = 0.65
@export var product_fallback_velocity: Vector2 = Vector2(100.0, -250.0)
@export_range(0.0, 45.0, 1.0) var product_sway_angle_degrees: float = 18.0
@export_range(0.1, 6.0, 0.1) var product_sway_speed: float = 2.0

var current_color: Color
var appearance_material: Material
var _visual_rng := RandomNumberGenerator.new()
var _materials: Array[StandardMaterial3D] = []
var _hit_tween: Tween
var _broken: bool = false
var _product_sway_direction: float = 1.0
var _broken_elapsed: float = 0.0
var _radius: float = 0.0

@onready var cube: Node3D = $Cube
@onready var product: Node3D = $Product
@onready var particles: CPUParticles3D = $Burst
@onready var hit_particles: CPUParticles3D = $HitBurst
@onready var product_motion: Node2D = $ProductMotion
@onready var product_ballistic: Ballistic = $ProductMotion/Ballistic

func setup(radius: float, appearance: Material = null, golden: bool = false, recipe_id: String = "bear_classic") -> void:
	_radius = radius
	_install_model($Cube/Model, RecipeVisualLibrary.cube_scene(recipe_id))
	_install_model($Product/Model, RecipeVisualLibrary.gummy_scene(recipe_id))
	$Product/Model.rotation_degrees = RecipeVisualLibrary.product_orientation(recipe_id)
	_visual_rng.randomize()
	particles.seed = _visual_rng.randi()
	hit_particles.seed = _visual_rng.randi()
	hit_particles.emission_box_extents = Vector3(radius, radius, 0.0) * hit_particle_extent_ratio
	for emitter: CPUParticles3D in [particles, hit_particles]:
		# Material propio: el RGB no depende del tinte de vértices del backend.
		emitter.material_override = emitter.mesh.surface_get_material(0).duplicate()
		emitter.color = Color.WHITE
	set_process(false)
	_fit_model($Cube/Model, radius)
	_fit_model($Product/Model, radius * product_scale)
	product.rotation_degrees = product_rotation_degrees
	product.position = product_offset
	if appearance != null:
		appearance_material = appearance
		_assign_appearance(cube)
		_assign_appearance(product)
		if appearance is ShaderMaterial:
			var tint: Variant = appearance.get_shader_parameter("primary_color")
			current_color = tint if tint is Color else fallback_color
		elif appearance is BaseMaterial3D:
			current_color = appearance.albedo_color
		if randomize_material_color and not golden and not palette.is_empty():
			# Un índice uniforme: todos los colores tienen la misma probabilidad.
			var color_index := _visual_rng.randi_range(0, palette.size() - 1)
			set_color(palette[color_index])
			if appearance_material is ShaderMaterial:
				# Los patrones bicolor también usan la paleta fija, sin generar tonos HSV.
				appearance_material.set_shader_parameter("secondary_color", palette[(color_index + palette.size() / 2) % palette.size()])
		else:
			_set_particle_color(current_color)
		return
	_prepare_materials(cube)
	_prepare_materials(product)
	var color := fallback_color
	if not palette.is_empty():
		color = palette[_visual_rng.randi_range(0, palette.size() - 1)]
	set_color(color)

# Permite variantes visuales futuras (por ejemplo doradas) con los mismos modelos.
func set_color(color: Color) -> void:
	current_color = color
	if appearance_material != null:
		# El cubo y la gomita comparten su copia, sin modificar el acabado base del tier.
		appearance_material = appearance_material.duplicate()
		if appearance_material is ShaderMaterial:
			appearance_material.set_shader_parameter("primary_color", color)
		elif appearance_material is BaseMaterial3D:
			appearance_material.albedo_color = color
		_assign_appearance(cube)
		_assign_appearance(product)
	for material in _materials:
		material.albedo_color = color
	_set_particle_color(color)

func _set_particle_color(color: Color) -> void:
	for emitter: CPUParticles3D in [particles, hit_particles]:
		(emitter.material_override as StandardMaterial3D).albedo_color = color

func _assign_appearance(model: Node3D) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = appearance_material

func play_hit() -> void:
	if _broken:
		return
	# Emite delante de la cara visible para que el cubo no oculte los fragmentos.
	hit_particles.global_position = global_position + Vector3(0.0, 0.0, _radius * hit_particle_front_ratio)
	hit_particles.seed = _visual_rng.randi()
	hit_particles.restart()
	_reset_hit()
	_hit_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(cube, "scale", squash, squash_duration)
	_hit_tween.tween_property(cube, "scale", stretch, stretch_duration)
	_hit_tween.tween_property(cube, "scale", Vector3.ONE, recovery_duration) \
		.set_trans(Tween.TRANS_ELASTIC)

func _reset_hit() -> void:
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	cube.scale = Vector3.ONE

func break_apart(motion: Ballistic = null, inherited_spin: Vector3 = Vector3.ZERO) -> void:
	if _broken:
		return
	_broken = true
	_reset_hit()
	cube.hide()
	particles.restart()
	particles.emitting = true
	product.show()
	# El producto nace de frente aunque el cubo estuviera de lado o de espaldas.
	product.rotation_degrees = product_rotation_degrees
	_product_sway_direction = -1.0 if inherited_spin.z < 0.0 else 1.0
	var viewport_size := get_viewport().get_visible_rect().size
	var origin := global_position
	var screen_position := Vector2(origin.x + viewport_size.x / 2.0, viewport_size.y / 2.0 - origin.y)
	if motion != null:
		# Reutiliza la misma parábola, gravedad, paredes y velocidad del cubo.
		product_ballistic.launch(screen_position, motion.velocity, motion.gravity, motion.wall_left, motion.wall_right, motion.escape_y)
	else:
		product_ballistic.launch(screen_position, product_fallback_velocity)
	set_process(true)
	product.scale = Vector3.ONE * product_reveal_scale
	var tween := create_tween()
	tween.tween_property(product, "scale", Vector3.ONE, product_reveal_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_broken_elapsed += delta
	var viewport_size := get_viewport().get_visible_rect().size
	var pos := product_motion.position
	product.global_position = Vector3(pos.x - viewport_size.x / 2.0, viewport_size.y / 2.0 - pos.y, 0.0) + product_offset
	# Balanceo acotado en pantalla: nunca da vueltas ni muestra su espalda.
	product.rotation_degrees = product_rotation_degrees
	product.rotation.z += deg_to_rad(product_sway_angle_degrees) * sin(_broken_elapsed * product_sway_speed) * _product_sway_direction
	# Se libera al escapar por abajo, como los cubos; las partículas terminan antes.
	if not product_ballistic.is_active and _broken_elapsed >= maxf(particles.lifetime, hit_particles.lifetime):
		set_process(false)
		finished.emit()

func _prepare_materials(model: Node3D) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.get_active_material(surface) as StandardMaterial3D
			var material: StandardMaterial3D = source.duplicate() if source else StandardMaterial3D.new()
			material.roughness = roughness
			mesh_instance.set_surface_override_material(surface, material)
			_materials.append(material)

# Normaliza cada modelo una sola vez; el wobble actúa en su padre visual.
func _install_model(container: Node3D, scene: PackedScene) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()
	container.add_child(scene.instantiate())

func _fit_model(model: Node3D, radius: float) -> void:
	var bounds := AABB()
	var has_bounds := false
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var relative: Transform3D = (model.get_parent() as Node3D).global_transform.affine_inverse() * mesh_instance.global_transform
		var box: AABB = relative * mesh_instance.mesh.get_aabb()
		bounds = bounds.merge(box) if has_bounds else box
		has_bounds = true
	var longest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if longest > 0.0:
		var factor := radius * 2.0 / longest
		model.scale *= factor
		model.position = -bounds.get_center() * factor
