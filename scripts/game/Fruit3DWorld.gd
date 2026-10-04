extends Node3D
class_name Fruit3DWorld
# ============================================================================
# Fruit3DWorld: pequeno "presentador" 3D que vive dentro del SubViewport
# transparente del juego. Cada frame espeja la posicion de las frutas/piedras
# 2D (FruitSpawner.active_fruits / active_obstacles) en nodos Fruit3D y,
# cuando una fruta muere (se corta), dispara su animacion de "modelo roto".
#
# La camara es ortografica y mapea 1:1 con los 720x1280 px: la fruta 2D en
# posicion (x, y) aparece en 3D en (x - 360, 640 - y).
# ============================================================================

const FRUIT3D_SCENE: PackedScene = preload("res://scenes/game/Fruit3D.tscn")

var fruit_spawner: FruitSpawner

var _fruit_mirrors: Dictionary = {}
var _rock_mirrors: Dictionary = {}

func setup_fruit_spawner(p_fruit_spawner: FruitSpawner) -> void:
	fruit_spawner = p_fruit_spawner

func _ready() -> void:
	var sub_viewport := get_viewport() as SubViewport
	if sub_viewport != null:
		sub_viewport.size_changed.connect(_adapt_camera)
	call_deferred("_adapt_camera")

# La camara ortografica mapea 1:1 con el SubViewport: su "size" (extension
# vertical en unidades del mundo) debe seguir el alto real del viewport para
# que las frutas 3D ocupen toda la pantalla en pantallas mas altas que 720x1280.
func _adapt_camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	if vs.y > 1.0:
		$Camera3D.size = vs.y

func _process(_delta: float) -> void:
	if not is_instance_valid(fruit_spawner):
		return
	_sync_fruits()
	_sync_rocks()

func _sync_fruits() -> void:
	var seen: Dictionary = {}
	for fruit in fruit_spawner.active_fruits:
		if not is_instance_valid(fruit):
			continue
		var id: int = fruit.get_instance_id()
		seen[id] = true
		var mirror: Fruit3D = _fruit_mirrors.get(id)
		if not is_instance_valid(mirror):
			mirror = FRUIT3D_SCENE.instantiate()
			add_child(mirror)
			# La escala del nodo 2D (Fruit.tscn usa scale 1.5) es parte del
			# "radio efectivo": con ella el modelo 3D coincide con el hitbox.
			mirror.setup_fruit(fruit.fruit_data, fruit.is_golden, fruit.scale.x)
			fruit.custom_hit_particles = mirror.has_custom_hit_particles()
			fruit.fruit_hit.connect(mirror.play_hit)
			fruit.fruit_destroyed.connect(_on_fruit_destroyed.bind(id))
			_fruit_mirrors[id] = mirror
		if not mirror.is_broken():
			mirror.set_pos2d(fruit.global_position)

	for id in _fruit_mirrors.keys():
		if seen.has(id):
			continue
		var mirror: Fruit3D = _fruit_mirrors[id]
		if is_instance_valid(mirror) and not mirror.is_broken():
			mirror.queue_free()
		_fruit_mirrors.erase(id)

func _sync_rocks() -> void:
	var seen: Dictionary = {}
	for obstacle in fruit_spawner.active_obstacles:
		if not is_instance_valid(obstacle):
			continue
		var id: int = obstacle.get_instance_id()
		seen[id] = true
		var mirror: Fruit3D = _rock_mirrors.get(id)
		if not is_instance_valid(mirror):
			mirror = FRUIT3D_SCENE.instantiate()
			add_child(mirror)
			mirror.setup_rock(obstacle.radius)
			_rock_mirrors[id] = mirror
		mirror.set_pos2d(obstacle.global_position)

	for id in _rock_mirrors.keys():
		if seen.has(id):
			continue
		var mirror: Fruit3D = _rock_mirrors[id]
		if is_instance_valid(mirror):
			mirror.queue_free()
		_rock_mirrors.erase(id)

func _on_fruit_destroyed(fruit: Fruit, id: int) -> void:
	var mirror: Fruit3D = _fruit_mirrors.get(id)
	if is_instance_valid(mirror):
		mirror.break_apart(fruit.last_cut_dir, fruit.ballistic)
