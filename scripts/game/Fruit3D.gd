extends Node3D
class_name Fruit3D
# ============================================================================
# Fruit3D: representacion 3D de un proyectil (fruta o piedra) que espeja la
# posicion de su gemelo 2D (Fruit.gd / Obstacle.gd). 100% estetico.
#
# Existen DOS "modelos" por fruta:
#   - WHOLE : la fruta ENTERA (se ve cuando se LANZA).
#   - BROKEN: la fruta partida (se ve cuando la fruta SE ROMPE / se corta).
# Durante la prueba Crazy Gummy, todas usan GummyVisual y el catálogo de
# materiales; el cargador de frutas original queda disponible como respaldo.
#
# DONDE PONER TUS MODELOS (los dos por fruta, con el mismo id que en
# FruitDatabase):
#   res://assets/models/whole/<id>.glb     (modelo entero)
#   res://assets/models/broken/<id>.glb    (modelo roto)
#   res://assets/models/rock.glb           (piedra, un solo modelo - no se rompe)
#   Ejemplo: res://assets/models/whole/apple.glb
#
# Reglas de exportacion (Blender -> .glb):
#   - Origen en el centro de la fruta, orientado como en Godot (+Y arriba,
#     +Z hacia la camara). Tamano real en unidades: diametro = 2 * radio
#     efectivo (el radio de FruitData por la escala). Frutas pequeñas ~64
#     unidades de diametro, la sandia ~192.
#   - Modelo ROTO: exportalo con DOS nodos/grupos (las dos mitades, aun si cada
#     mitad tiene varias mallas) y se usan tal cual, SIN espejo: necesario para
#     frutas asimetricas (banana, etc., donde cada lado es distinto). Si
#     exportas SOLO UNA malla, se duplica espejada en runtime para formar la
#     otra (frutas simetricas). Las mitades caen por gravedad hasta salir de
#     pantalla (sin hitbox).
#   Si el .glb no existe, se usa la fruta esferica de color base (fallback).
# ============================================================================

const WHOLE_MODELS_DIR: String = "res://assets/models/whole/"
const BROKEN_MODELS_DIR: String = "res://assets/models/broken/"
const ROCK_MODELS_DIR: String = "res://assets/models/"
# Factor SOLO visual (0.75 = -25%): reduce el tamaño del modelo 3D un 25% sin
# tocar el hitbox de corte (que fija fd.radius en Fruit.gd, 2D). Este espejo
# 3D es puramente estético. Coherente con FruitVisual.visual_scale.
# Editables en el inspector de la escena Fruit3D.tscn.
@export_range(0.1, 2.0, 0.05) var visual_scale: float = 0.75
# Gravedad con la que caen las mitades del modelo roto tras el corte.
@export_range(0.0, 4000.0, 10.0) var broken_gravity: float = 1500.0
# Presentación provisional de todas las frutas; se conserva la referencia existente.
@export var strawberry_visual_scene: PackedScene = preload("res://scenes/game/GummyVisual.tscn")
@export var gummy_material_palette: GummyMaterialPalette = preload("res://assets/crazy_gummy/materials/palette.tres")

var _gummy_visual: GummyVisual

var is_rock: bool = false
var _broken: bool = false
var _broken_has_halves: bool = false
var _radius: float = 40.0
var _spin: Vector3 = Vector3.ZERO
var _broken_vel_a: Vector3 = Vector3.ZERO
var _broken_vel_b: Vector3 = Vector3.ZERO

var half_a: MeshInstance3D
var half_b: MeshInstance3D

@onready var whole: Node3D = $Whole
@onready var broken: Node3D = $Broken

func is_broken() -> bool:
	return _broken

# Convierte la posicion 2D (px, eje Y hacia abajo) a coordenadas del mundo 3D
# espejo (camera ortografica 1:1 centrada en 0,0). Usa el tamano REAL del
# viewport para que el mapeo siga exacto en pantallas mas altas que 720x1280.
func set_pos2d(pos: Vector2) -> void:
	var vs := get_viewport().get_visible_rect().size
	position = Vector3(pos.x - vs.x / 2.0, vs.y / 2.0 - pos.y, 0.0)

func setup_fruit(fd: FruitData, golden: bool, p_scale: float = 1.0) -> void:
	is_rock = false
	var radius: float = fd.radius * visual_scale * maxf(p_scale, 0.05)
	_radius = radius
	if strawberry_visual_scene != null:
		_gummy_visual = strawberry_visual_scene.instantiate()
		add_child(_gummy_visual)
		var appearance: Material = gummy_material_palette.material_for(fd.unlock_order, golden) if gummy_material_palette != null else null
		_gummy_visual.setup(radius, appearance, golden)
		_gummy_visual.finished.connect(queue_free)
		_spin = Vector3(
			randf_range(-2.5, 2.5),
			randf_range(-2.0, 2.0),
			randf_range(-1.5, 1.5)
		)
		return

	_clear_children(whole)
	var w_model := _load_model(WHOLE_MODELS_DIR + fd.id + ".glb")
	if is_instance_valid(w_model):
		_fit_content(w_model, radius)
		whole.add_child(w_model)
	else:
		_add_proc_sphere(radius, fd.base_color, golden, 32, 24)

	_clear_children(broken)
	_broken_has_halves = false
	var b_model := _load_model(BROKEN_MODELS_DIR + fd.id + ".glb")
	if is_instance_valid(b_model) and _model_mesh_count(b_model) > 0:
		_dispose_broken_model(b_model, radius)
	else:
		if is_instance_valid(b_model):
			push_warning("Fruit3D: el modelo roto de '%s' no tiene mallas, usando fallback." % fd.id)
			b_model.free()
		_setup_proc_broken(radius, fd)

	_spin = Vector3(
		randf_range(-2.5, 2.5),
		randf_range(-2.0, 2.0),
		randf_range(-1.5, 1.5)
	)

func setup_rock(p_radius: float) -> void:
	is_rock = true
	_radius = p_radius
	_clear_children(whole)
	var model := _load_model(ROCK_MODELS_DIR + "rock.glb")
	if is_instance_valid(model):
		_fit_content(model, p_radius)
		whole.add_child(model)
	else:
		_add_proc_sphere(p_radius, Color(0.5, 0.52, 0.56), false, 24, 18)
	_clear_children(broken)
	_broken_has_halves = false
	broken.visible = false
	_spin = Vector3(
		randf_range(-2.0, 2.0),
		randf_range(-2.0, 2.0),
		randf_range(-1.5, 1.5)
	)

func _process(delta: float) -> void:
	if not visible:
		return
	if _broken:
		if _broken_has_halves:
			_update_broken_halves(delta)
		return
	rotation.z += _spin.z * delta
	rotation.x += _spin.x * delta
	rotation.y += _spin.y * delta

# Cambia del modelo ENTERO al modelo ROTO. Las mitades sueltan el hitbox (la
# fruta 2D ya no existe) y caen por gravedad hasta salir de la pantalla.
# p_cut_dir es la direccion del trazo en pantalla: las mitades se separan
# PERPENDICULAR al corte y se abren girando sobre el eje del corte.
func break_apart(p_cut_dir: Vector2 = Vector2.RIGHT, motion: Ballistic = null) -> void:
	if _broken:
		return
	_broken = true
	whole.visible = false
	broken.visible = true
	var previous_spin := _spin
	_spin = Vector3.ZERO
	rotation = Vector3.ZERO
	if is_instance_valid(_gummy_visual):
		broken.visible = false
		_gummy_visual.break_apart(motion, previous_spin)
		return

	if _broken_has_halves:
		var c := p_cut_dir
		if c.length_squared() < 0.0001:
			c = Vector2.RIGHT
		c = c.normalized()
		# Normal en pantalla (eje Y hacia abajo): perpendicular al trazo.
		var n2 := Vector2(-c.y, c.x)
		if randf() < 0.5:
			n2 = -n2
		# Al mundo 3D espejo (eje Y hacia arriba).
		var n3 := Vector3(n2.x, -n2.y, 0.0)
		var c3 := Vector3(c.x, -c.y, 0.0)
		var sep := _radius * 2.6
		# Separacion perpendicular + un empuje del filo y caida base.
		_broken_vel_a = n3 * sep + c3 * sep * 0.35 + Vector3(0.0, -sep * 0.35, 0.0)
		_broken_vel_b = -n3 * sep + c3 * sep * 0.35 + Vector3(0.0, -sep * 0.35, 0.0)
		half_a.position = n3 * (_radius * 0.3)
		half_b.position = -n3 * (_radius * 0.3)
		# Abren el corte: rotacion sobre el eje del propio trazo.
		half_a.rotate(c3, 0.35)
		half_b.rotate(c3, -0.35)
	else:
		var t := create_tween()
		t.tween_property(broken, "scale", Vector3(1.5, 1.5, 1.5), 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_callback(func(): queue_free())

# El impacto solo deforma el hijo visual; el nodo espejo conserva su escala.
func has_custom_hit_particles() -> bool:
	return is_instance_valid(_gummy_visual)

func play_hit() -> void:
	if not _broken and is_instance_valid(_gummy_visual):
		_gummy_visual.play_hit()

# Gravedad simple en el espacio espejo: las mitades caen, giran y se liberan al
# salir por abajo. Ya no dependen de la posicion 2D ni del sistema de colisiones.
func _update_broken_halves(delta: float) -> void:
	if half_a == null or half_b == null:
		queue_free()
		return
	_broken_vel_a.y -= broken_gravity * delta
	_broken_vel_b.y -= broken_gravity * delta
	half_a.position += _broken_vel_a * delta
	half_b.position += _broken_vel_b * delta
	half_a.rotation.z += -2.5 * delta
	half_b.rotation.z += 2.5 * delta
	if half_a.position.y < _kill_y() or half_b.position.y < _kill_y():
		queue_free()

# Altura a la que las mitades "salen" de pantalla: justo debajo del borde real
# del viewport (adaptado a pantallas mas altas que 720x1280).
func _kill_y() -> float:
	var vs := get_viewport().get_visible_rect().size
	return -vs.y / 2.0 - 20.0

# ============================================================================
# Carga de modelos del usuario (con fallback procedural).
# ============================================================================

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()

# Carga y devuelve el primer Node3D raiz de un .glb, o null si no existe.
func _load_model(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var inst: Node = scene.instantiate()
	if inst is Node3D:
		return inst as Node3D
	inst.free()
	return null

# ============================================================================
# Modelo ROTO:
#   - Si el .glb trae DOS grupos de mallas (las dos mitades, caso normal al
#     exportar desde Blender con las dos partes), se usan TAL CUAL como las dos
#     mitades. NO se espeja nada: ideal para frutas asimetricas (banana, coco,
#     sandia...) donde cada lado es distinto.
#   - Si trae SOLO UNA malla (lo mas comun en frutas simetricas), se duplica
#     espejada en runtime para formar la otra mitad.
#   - Las mallas de cada mitad se agrupan por su nodo padre, asi una mitad con
#     varias piezas (cascara + pulpa) cae entera y nunca se mezclan mitades.
# ============================================================================
func _dispose_broken_model(model: Node3D, target_radius: float) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model, meshes)
	if meshes.is_empty():
		broken.add_child(model)
		return

	# Manda cada mitad como "grupo" si el autor exporto las dos partes en nodos
	# separados (>= 2 grupos): cada grupo = una mitad, con todos sus meshes.
	var groups := _collect_mesh_groups(model)
	if groups.size() >= 2:
		if groups.size() > 2:
			push_warning("Fruit3D: '%s' creo %d grupos de mallas; se usan los 2 primeros como mitades." % [model.name, groups.size()])
		_broken_has_halves = true
		_build_half_from_group(groups[0] as Node3D, "HalfA", target_radius)
		_build_half_from_group(groups[1] as Node3D, "HalfB", target_radius)
		model.free()
		return

	# Sin grupos claros pero con >= 2 mallas sueltas: cada malla es una mitad.
	if meshes.size() >= 2:
		_broken_has_halves = true
		half_a = _steal_mesh_as_half(meshes[0], "HalfA")
		half_b = _steal_mesh_as_half(meshes[1], "HalfB")
		model.free()
		_fit_content(half_a, target_radius)
		_fit_content(half_b, target_radius)
		return

	# Una sola malla: duplicarla espejada (fruta simetrica).
	_broken_has_halves = true
	var src := meshes[0]
	src.get_parent().remove_child(src)
	broken.add_child(src)
	half_a = src
	half_b = MeshInstance3D.new()
	half_b.name = "HalfBMirror"
	half_b.mesh = _mirror_mesh(src.mesh)
	half_b.transform = src.transform
	broken.add_child(half_b)
	model.free()
	_fit_content(half_a, target_radius)
	_fit_content(half_b, target_radius)

func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, out)

func _model_mesh_count(model: Node3D) -> int:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model, meshes)
	return meshes.size()

# Devuelve los hijos directos del modelo que contienen mallas (cada mitad
# exportada como objeto separado en Blender es uno de estos "grupos").
func _collect_mesh_groups(model: Node3D) -> Array[Node]:
	var groups: Array[Node] = []
	for child in model.get_children():
		if _node_has_mesh(child):
			groups.append(child)
	return groups

func _node_has_mesh(node: Node) -> bool:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh != null
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false

# Desmonta un grupo (nodo 3D) del modelo importado y lo cuelga de "broken" como
# una mitad completa, ajustando su tamano al radio del hitbox.
func _build_half_from_group(group: Node3D, half_name: String, target_radius: float) -> void:
	if group == null:
		push_warning("Fruit3D: grupo de mitad nulo ignorado en modelo roto.")
		return
	group.name = half_name
	if group.get_parent():
		group.get_parent().remove_child(group)
	broken.add_child(group)
	if half_name == "HalfA":
		half_a = group
	else:
		half_b = group
	_fit_content(group, target_radius)

# Mueve una malla suelta a un contenedor 3D nuevo y lo devuelve como mitad.
func _steal_mesh_as_half(mi: MeshInstance3D, half_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = half_name
	if mi.get_parent():
		mi.get_parent().remove_child(mi)
	root.add_child(mi)
	broken.add_child(root)
	return root

# Devuelve una copia de la malla reflejada sobre el plano X=0, con las normales
# negadas y el culling de caras corregido (se invierten los triangulos). Asi la
# mitad duplicada forma la otra mitad sin invertir la escala ni perder caras.
func _mirror_mesh(src_mesh: Mesh) -> Mesh:
	if src_mesh == null:
		return null
	var out := ArrayMesh.new()
	for s in range(src_mesh.get_surface_count()):
		var arrays := _to_classic_arrays(src_mesh.surface_get_arrays(s))
		var verts: PackedVector3Array = _as_vec3s(arrays[Mesh.ARRAY_VERTEX])
		for v in range(verts.size()):
			var p := verts[v]
			p.x = -p.x
			verts[v] = p
		var norms: PackedVector3Array = _as_vec3s(arrays[Mesh.ARRAY_NORMAL])
		for n in range(norms.size()):
			var nn := norms[n]
			nn.x = -nn.x
			norms[n] = nn
		var idx: PackedInt32Array = _as_indexes(arrays[Mesh.ARRAY_INDEX])
		if idx.size() >= 3 and idx.size() % 3 == 0:
			var i3 := 0
			while i3 < idx.size():
				var tmp := idx[i3 + 1]
				idx[i3 + 1] = idx[i3 + 2]
				idx[i3 + 2] = tmp
				i3 += 3
			arrays[Mesh.ARRAY_INDEX] = idx
		elif verts.size() >= 3 and verts.size() % 3 == 0:
			# Sin indices: invertir cada triangulo intercambiando vertices y normales.
			var i3 := 0
			while i3 < verts.size():
				var p := verts[i3 + 1]
				verts[i3 + 1] = verts[i3 + 2]
				verts[i3 + 2] = p
				if norms.size() == verts.size():
					var n := norms[i3 + 1]
					norms[i3 + 1] = norms[i3 + 2]
					norms[i3 + 2] = n
				i3 += 3
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		out.add_surface_from_arrays(src_mesh.surface_get_primitive_type(s), arrays)
		var mat: Material = src_mesh.surface_get_material(s)
		if mat:
			out.surface_set_material(out.get_surface_count() - 1, mat)
	return out

# Convierte el resultado de surface_get_arrays() (Array clasico o Dictionary,
# segun la version de Godot) al Array clasico de 13 posiciones.
func _to_classic_arrays(raw: Variant) -> Array:
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	if raw is Dictionary:
		for key in raw:
			out[key] = raw[key]
	elif raw is Array:
		var src: Array = raw
		var n := mini(src.size(), Mesh.ARRAY_MAX)
		for i in range(n):
			out[i] = src[i]
	else:
		push_warning("Fruit3D: surface_get_arrays devolvio un formato no soportado")
	return out

func _as_vec3s(v: Variant) -> PackedVector3Array:
	return v if v is PackedVector3Array else PackedVector3Array()

func _as_indexes(v: Variant) -> PackedInt32Array:
	return v if v is PackedInt32Array else PackedInt32Array()

# Escala y centra el contenido de un modelo importado para que su dimension
# mayor mida exactamente target_radius * 2 (el diametro del hitbox). Asi los
# .glb quedan alineados con el hitbox sin importar la escala/offset con los
# que se exportaron (p. ej. Blender a tamanos de metros o centimetros).
func _fit_content(node: Node3D, target_radius: float) -> void:
	var aabb := _content_aabb(node)
	if aabb.size == Vector3.ZERO:
		return
	var max_dim := maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if max_dim <= 0.0:
		return
	var s: float = (target_radius * 2.0) / max_dim
	node.scale = node.scale * s
	node.position = -aabb.get_center() * s

# AABB en el espacio local de "node" abarcando toda su malla (raiz + hijos).
func _content_aabb(node: Node3D) -> AABB:
	var aabb := AABB()
	var has_content := false
	var candidates: Array[Node] = [node]
	candidates.append_array(node.find_children("*", "MeshInstance3D", true, false))
	for child in candidates:
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or mi.mesh.get_aabb().size == Vector3.ZERO:
			continue
		var rel := node.global_transform.affine_inverse() * mi.global_transform
		var box: AABB = rel * mi.mesh.get_aabb()
		aabb = box if not has_content else aabb.merge(box)
		has_content = true
	return aabb

# ============================================================================
# Fallback procedural: esfera entera + dos mitades cortadas (sin assets).
# ============================================================================

func _add_proc_sphere(r: float, color: Color, golden: bool, radial: int, rings: int) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = radial
	sm.rings = rings
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	if golden:
		mat.albedo_color = Color(1.0, 0.85, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.15)
		mat.emission_energy_multiplier = 0.6
	var mi := MeshInstance3D.new()
	mi.name = "ProcMesh"
	mi.mesh = sm
	mi.material_override = mat
	whole.add_child(mi)

func _setup_proc_broken(r: float, fd: FruitData) -> void:
	_broken_has_halves = true
	var flesh_n := Vector3(0.45, 0.2, 0.87).normalized()
	half_a = MeshInstance3D.new()
	half_a.name = "HalfA"
	half_a.mesh = _build_half_mesh(r, flesh_n, fd.base_color, fd.inner_color)
	half_b = MeshInstance3D.new()
	half_b.name = "HalfB"
	half_b.mesh = _build_half_mesh(r, -flesh_n, fd.base_color, fd.inner_color)
	broken.add_child(half_a)
	broken.add_child(half_b)

func _build_half_mesh(r: float, ndir: Vector3, base_col: Color, inner_col: Color) -> Mesh:
	var mesh := ArrayMesh.new()

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var inds := PackedInt32Array()

	# Cascara: rejilla esferica recortada al semiespacio p.dot(ndir) >= 0.
	var lat := 16
	var lon := 28
	for i in range(lat):
		var t0 := PI * float(i) / float(lat)
		var t1 := PI * float(i + 1) / float(lat)
		for j in range(lon):
			var p0 := TAU * float(j) / float(lon)
			var p1 := TAU * float(j + 1) / float(lon)
			var a := _sphere_corner(r, t0, p0)
			var b := _sphere_corner(r, t0, p1)
			var c := _sphere_corner(r, t1, p0)
			var d := _sphere_corner(r, t1, p1)
			_push_clipped_tri(verts, norms, uvs, inds, a, b, c, ndir)
			_push_clipped_tri(verts, norms, uvs, inds, a, c, d, ndir)

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _as_arrays(verts, norms, uvs, inds))
	mesh.surface_set_material(0, _make_mat(base_col, 0.6))

	# Pulpa: disco plano (la cara del corte), ligeramente hundido hacia dentro
	# para no asomarse por el borde de la cascara.
	var cap_verts := PackedVector3Array()
	var cap_norms := PackedVector3Array()
	var cap_uvs := PackedVector2Array()
	var cap_inds := PackedInt32Array()
	_push_cap_disc(r, ndir, cap_verts, cap_norms, cap_uvs, cap_inds)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _as_arrays(cap_verts, cap_norms, cap_uvs, cap_inds))
	var cap_mat := _make_mat(inner_col, 0.9)
	cap_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(1, cap_mat)

	return mesh

func _make_mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _as_arrays(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array, inds: PackedInt32Array) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = inds
	return arrays

func _sphere_corner(r: float, t: float, p: float) -> Dictionary:
	var pos := Vector3(r * sin(t) * cos(p), r * cos(t), r * sin(t) * sin(p))
	return {"p": pos, "n": pos.normalized(), "uv": Vector2(t / PI, p / TAU)}

func _inside_q(c: Dictionary, ndir: Vector3) -> bool:
	return (c["p"] as Vector3).dot(ndir) >= 0.0

func _inter_q(a: Dictionary, b: Dictionary, ndir: Vector3) -> Dictionary:
	var pa: Vector3 = a["p"]
	var pb: Vector3 = b["p"]
	var da := pa.dot(ndir)
	var db := pb.dot(ndir)
	var t := da / (da - db)
	var p := pa.lerp(pb, t)
	return {"p": p, "n": p.normalized(), "uv": (a["uv"] as Vector2).lerp(b["uv"], t)}

# Recorte de un poligono contra el semiespacio p.dot(ndir) >= 0
# (Sutherland-Hodgman para un solo plano).
func _clip_poly(poly: Array, ndir: Vector3) -> Array:
	if poly.is_empty():
		return poly
	var out: Array = []
	for i in range(poly.size()):
		var cur: Dictionary = poly[i]
		var prev: Dictionary = poly[(i - 1 + poly.size()) % poly.size()]
		var cur_in := _inside_q(cur, ndir)
		var prev_in := _inside_q(prev, ndir)
		if cur_in != prev_in:
			out.append(_inter_q(prev, cur, ndir))
		if cur_in:
			out.append(cur)
	return out

func _push_clipped_tri(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array, inds: PackedInt32Array, a: Dictionary, b: Dictionary, c: Dictionary, ndir: Vector3) -> void:
	var poly := _clip_poly([a, b, c], ndir)
	if poly.size() < 3:
		return
	for i in range(1, poly.size() - 1):
		var first: Dictionary = poly[0]
		var va: Dictionary = poly[i]
		var vb: Dictionary = poly[i + 1]
		verts.append(first["p"])
		norms.append(first["n"])
		uvs.append(first["uv"])
		var i0 := verts.size() - 1
		verts.append(va["p"])
		norms.append(va["n"])
		uvs.append(va["uv"])
		var i1 := verts.size() - 1
		verts.append(vb["p"])
		norms.append(vb["n"])
		uvs.append(vb["uv"])
		var i2 := verts.size() - 1
		inds.append_array([i0, i1, i2])

func _push_cap_disc(r: float, ndir: Vector3, verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array, inds: PackedInt32Array) -> void:
	var e1 := ndir.cross(Vector3.UP)
	if e1.length() < 0.001:
		e1 = ndir.cross(Vector3.RIGHT)
	e1 = e1.normalized()
	var e2 := ndir.cross(e1).normalized()
	var cap_n := -ndir
	var center := ndir * -r * 0.03
	var seg := 24

	verts.append(center)
	norms.append(cap_n)
	uvs.append(Vector2(0.5, 0.5))
	for i in range(seg):
		var ang := TAU * float(i) / float(seg)
		var rim := center + r * (cos(ang) * e1 + sin(ang) * e2)
		verts.append(rim)
		norms.append(cap_n)
		uvs.append(Vector2.ZERO)
		if i > 0:
			inds.append_array([0, i, i + 1])
	inds.append_array([0, seg, 1])
