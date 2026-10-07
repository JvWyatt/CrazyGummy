extends Node3D
class_name Projectile3DWorld
# ============================================================================
# Projectile3DWorld: pequeno "presentador" 3D que vive dentro del SubViewport
# transparente del juego. Cada frame espeja la posicion de las cubos/caramelos endurecidos
# 2D (BlockSpawner.active_blocks / active_obstacles) en nodos Projectile3D y,
# cuando una cubo muere (se corta), dispara su animacion de "modelo roto".
#
# La camara es ortografica y mapea 1:1 con los 720x1280 px: la cubo 2D en
# posicion (x, y) aparece en 3D en (x - 360, 640 - y).
# ============================================================================

const PROJECTILE3D_SCENE: PackedScene = preload("res://scenes/game/Projectile3D.tscn")

var block_spawner: BlockSpawner

var _block_mirrors: Dictionary = {}
var _obstacle_mirrors: Dictionary = {}

func setup_block_spawner(p_block_spawner: BlockSpawner) -> void:
	block_spawner = p_block_spawner

func _ready() -> void:
	var sub_viewport := get_viewport() as SubViewport
	if sub_viewport != null:
		sub_viewport.size_changed.connect(_adapt_camera)
	call_deferred("_adapt_camera")

# La camara ortografica mapea 1:1 con el SubViewport: su "size" (extension
# vertical en unidades del mundo) debe seguir el alto real del viewport para
# que las cubos 3D ocupen toda la pantalla en pantallas mas altas que 720x1280.
func _adapt_camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	if vs.y > 1.0:
		$Camera3D.size = vs.y

func _process(_delta: float) -> void:
	if not is_instance_valid(block_spawner):
		return
	_sync_blocks()
	_sync_obstacles()

func _sync_blocks() -> void:
	var seen: Dictionary = {}
	for block in block_spawner.active_blocks:
		if not is_instance_valid(block):
			continue
		var id: int = block.get_instance_id()
		seen[id] = true
		var mirror: Projectile3D = _block_mirrors.get(id)
		if not is_instance_valid(mirror):
			mirror = PROJECTILE3D_SCENE.instantiate()
			add_child(mirror)
			# La escala del nodo 2D (GummyBlock.tscn usa scale 1.5) es parte del
			# "radio efectivo": con ella el modelo 3D coincide con el hitbox.
			mirror.setup_block(block.recipe_data, block.is_golden, block.scale.x)
			block.custom_hit_particles = mirror.has_custom_hit_particles()
			block.block_hit.connect(mirror.play_hit)
			block.block_destroyed.connect(_on_block_destroyed.bind(id))
			_block_mirrors[id] = mirror
		if not mirror.is_broken():
			mirror.set_pos2d(block.global_position)

	for id in _block_mirrors.keys():
		if seen.has(id):
			continue
		var mirror: Projectile3D = _block_mirrors[id]
		if is_instance_valid(mirror) and not mirror.is_broken():
			mirror.queue_free()
		_block_mirrors.erase(id)

func _sync_obstacles() -> void:
	var seen: Dictionary = {}
	for obstacle in block_spawner.active_obstacles:
		if not is_instance_valid(obstacle):
			continue
		var id: int = obstacle.get_instance_id()
		seen[id] = true
		var mirror: Projectile3D = _obstacle_mirrors.get(id)
		if not is_instance_valid(mirror):
			mirror = PROJECTILE3D_SCENE.instantiate()
			add_child(mirror)
			mirror.setup_obstacle(obstacle.radius)
			obstacle.custom_visual = true
			obstacle.queue_redraw()
			obstacle.candy_broken.connect(_on_candy_broken.bind(id))
			_obstacle_mirrors[id] = mirror
		if not mirror.is_broken():
			mirror.set_pos2d(obstacle.global_position)

	for id in _obstacle_mirrors.keys():
		if seen.has(id):
			continue
		var mirror: Projectile3D = _obstacle_mirrors[id]
		if is_instance_valid(mirror) and not mirror.is_broken():
			mirror.queue_free()
		_obstacle_mirrors.erase(id)

func _on_block_destroyed(block: GummyBlock, id: int) -> void:
	var mirror: Projectile3D = _block_mirrors.get(id)
	if is_instance_valid(mirror):
		mirror.break_apart(block.last_stroke_dir, block.ballistic)

func _on_candy_broken(obstacle: Obstacle, id: int) -> void:
	var mirror: Projectile3D = _obstacle_mirrors.get(id)
	if is_instance_valid(mirror):
		mirror.set_pos2d(obstacle.global_position)
		mirror.break_apart(Vector2.RIGHT, obstacle.ballistic)
