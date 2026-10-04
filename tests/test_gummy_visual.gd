extends SceneTree
# Integración real sin addons. Usar XDG_DATA_HOME aislado para proteger la partida.
# godot --headless --path . --script tests/test_gummy_visual.gd
# Con renderizado: añadir -- --capture para guardar imágenes en /tmp/opencode.

var failures: int = 0
var checks: int = 0
var game: Node
var spawner: Node
var world: Node
var viewport: SubViewport
var last_reward: float = 0.0
var last_jackpot: bool = false
var capture: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _record_reward(_data: Resource, reward: float, jackpot: bool) -> void:
	last_reward = reward
	last_jackpot = jackpot

func _save_frame(stage: String, tracked: Node3D = null) -> void:
	if not capture:
		return
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var center := Vector2(360, 640)
	if tracked != null:
		center = Vector2(tracked.global_position.x + 360.0, 640.0 - tracked.global_position.y)
	image = image.get_region(Rect2i(Vector2i(center) - Vector2i(100, 120), Vector2i(200, 240)))
	image.resize(400, 480)
	image.save_png("/tmp/opencode/gummy_%s.png" % stage)

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	game = root.get_node("GameManager")
	root.get_node("SoundManager").is_sound_enabled = false
	game.set_process(false)
	game.fruit_destroyed_event.connect(_record_reward)
	spawner = load("res://scenes/game/FruitSpawner.tscn").instantiate()
	root.add_child(spawner)
	spawner.set_process(false)
	viewport = SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	world = load("res://scenes/game/Fruit3DWorld.tscn").instantiate()
	viewport.add_child(world)
	world.setup_fruit_spawner(spawner)

	for golden: bool in [false, true]:
		game.start_new_run()
		spawner.disable_spawning()
		spawner._launch_fruit()
		var fruit: Node = spawner.active_fruits[0]
		fruit.is_golden = golden
		var fd: Resource = fruit.fruit_data
		var hp: float = fruit.current_hp
		var logical_scale: Vector2 = fruit.scale
		var hit_radius: float = fruit.collision_shape.shape.radius
		_check(fd.id == "strawberry", "Spawn original de fresa")
		_check(hp == fd.max_hp, "Vida de FruitData intacta")
		_check(hit_radius == fd.radius, "Radio lógico intacto")
		await process_frame
		await process_frame
		var mirror: Node3D = world._fruit_mirrors.get(fruit.get_instance_id())
		_check(is_instance_valid(mirror), "El spawner crea el espejo 3D")
		var gummy := mirror.get_node("GummyVisual") as GummyVisual
		_check(gummy != null, "La fresa usa el cubo")
		_check(gummy.cube.visible and not gummy.product.visible, "Solo cubo al aparecer")
		var expected_material: Material = mirror.gummy_material_palette.material_for(fd.unlock_order, golden)
		_check(gummy.appearance_material == expected_material if golden else gummy.appearance_material.shader == expected_material.shader and gummy.palette.has(gummy.current_color), "Oro fijo o color aleatorio con el acabado del tier")
		_check((gummy.particles.material_override as StandardMaterial3D).albedo_color == gummy.current_color, "Material de ruptura del color actual")
		_check((gummy.hit_particles.material_override as StandardMaterial3D).albedo_color == gummy.current_color, "Material de impacto del color actual")
		_check(fruit.custom_hit_particles, "El cubo sustituye la salpicadura original roja")
		gummy.set_color(Color(0.2, 0.55, 1.0))
		var model := gummy.get_node("Cube/Model") as Node3D
		var dimensions: Vector3 = mirror._content_aabb(model).size * model.scale
		_check(is_equal_approx(maxf(dimensions.x, maxf(dimensions.y, dimensions.z)), fd.radius * logical_scale.x * mirror.visual_scale * 2.0), "Cubo normalizado al tamaño visual original")

		# Comprobación visual centrada; el lanzamiento real ya se ha ejecutado.
		fruit.ballistic.stop()
		fruit.ballistic.velocity = Vector2(140.0, -200.0)
		fruit.position = Vector2(360, 640)
		mirror.set_pos2d(fruit.global_position)
		mirror.set_process(false)
		mirror.rotation = Vector3(0.2, 0.35, 0.0)
		if not golden:
			await _save_frame("spawn")
		fruit.take_damage(1.0, false)
		# Paso determinista para verificar el impacto sin depender del FPS.
		gummy._hit_tween.custom_step(0.04)
		_check(not gummy.cube.scale.is_equal_approx(Vector3.ONE), "Golpe real activa deformación 3D")
		_check(gummy.hit_particles.emitting and gummy.hit_particles.amount < gummy.particles.amount, "Cada golpe emite pocos fragmentos, menos que la ruptura")
		_check(spawner.find_children("*", "CPUParticles2D", false, false).is_empty(), "No aparece la salpicadura de color de fresa")
		if not golden:
			await create_timer(0.08).timeout
			await _save_frame("hit")
		var hit_seed := gummy.hit_particles.seed
		fruit.take_damage(1.0, true)
		_check(gummy.hit_particles.emitting and gummy.hit_particles.seed != hit_seed, "Golpes consecutivos vuelven a emitir fragmentos")
		await create_timer(0.4).timeout
		_check(gummy.cube.scale.is_equal_approx(Vector3.ONE), "Golpes consecutivos recuperan la forma")
		_check(fruit.current_hp == hp - 2.0, "Daño original exacto")
		_check(fruit.scale == logical_scale and fruit.collision_shape.shape.radius == hit_radius, "Wobble conserva escala lógica y colisión")
		_check(mirror.scale == Vector3.ONE, "Wobble no escala el espejo")

		# La misma tirada debe dar la misma recompensa con o sin presentación gummy.
		var inherited_velocity: Vector2 = fruit.ballistic.velocity
		var inherited_gravity: float = fruit.ballistic.gravity
		var inherited_left: float = fruit.ballistic.wall_left
		var inherited_right: float = fruit.ballistic.wall_right
		# Reproduce un cubo tumbado y de espaldas justo antes de la ruptura.
		mirror.rotation = Vector3(PI / 2.0, PI, PI / 2.0)
		seed(91234)
		fruit.take_damage(hp, false)
		var gummy_reward := last_reward
		var gummy_jackpot := last_jackpot
		_check(game.total_fruits_cut_run == 1, "Destrucción paga y registra exactamente una fresa")
		_check(game.run_money == gummy_reward and game.order_progress == gummy_reward, "Dinero y progreso usan el flujo original")
		await process_frame
		await process_frame
		_check(mirror.is_broken(), "La señal original activa la ruptura")
		_check(not gummy.cube.visible and gummy.product.visible, "Cubo desaparece y aparece un único osito")
		_check(not mirror._broken_has_halves, "Osito no se duplica ni se divide en mitades")
		_check(gummy.product.global_basis.z.normalized().dot(Vector3.BACK) > 0.99, "Osito aparece de frente incluso si el cubo estaba tumbado y de espaldas")
		_check(gummy.particles.emitting, "Ruptura dispara el burst de cuadritos")
		_check(gummy.particles.mesh is BoxMesh and gummy.particles.one_shot, "Burst breve con fragmentos cúbicos")
		_check(gummy.product_ballistic.velocity.x == inherited_velocity.x and gummy.product_ballistic.gravity == inherited_gravity, "Osito hereda velocidad horizontal y gravedad del cubo")
		_check(gummy.product_ballistic.wall_left == inherited_left and gummy.product_ballistic.wall_right == inherited_right, "Osito reutiliza los mismos rebotes laterales")
		var product_position := gummy.product.global_position
		var product_rotation := gummy.product.rotation
		await create_timer(0.08).timeout
		_check(gummy.product.global_position.x > product_position.x, "Osito avanza horizontalmente, no solo en vertical")
		_check(not gummy.product.rotation.is_equal_approx(product_rotation), "Osito continúa girando")
		_check(absf(gummy.product.rotation_degrees.z) <= gummy.product_sway_angle_degrees + 0.01 and gummy.product.global_basis.z.normalized().dot(Vector3.BACK) > 0.99, "Balanceo suave conserva la vista frontal sin tumbar el osito")
		if not golden:
			await _save_frame("burst")
			await create_timer(0.4).timeout
			await _save_frame("bear", gummy.product)
		await create_timer(1.8).timeout
		_check(not is_instance_valid(mirror), "Osito y partículas se liberan automáticamente")

		game.start_new_run()
		spawner.disable_spawning()
		var control: Node = load("res://scenes/game/Fruit.tscn").instantiate()
		root.add_child(control)
		control.setup(fd)
		control.is_golden = golden
		seed(91234)
		control.take_damage(hp, false)
		_check(last_reward == gummy_reward and last_jackpot == gummy_jackpot, "Recompensa y Jackpot idénticos al flujo sin gummy (dorada=%s)" % golden)
		await process_frame
		await process_frame

	# La selección de paleta no consume el RNG global; cada material es local.
	var database: Script = load("res://scripts/models/FruitDatabase.gd")
	var other: Node3D = load("res://scenes/game/Fruit3D.tscn").instantiate()
	world.add_child(other)
	other.setup_fruit(database.create_fruit_resource("strawberry"), false)
	var visual := other.get_node("GummyVisual") as GummyVisual
	var independent: GummyVisual = load("res://scenes/game/GummyVisual.tscn").instantiate()
	world.add_child(independent)
	seed(100)
	var expected_random := randf()
	seed(100)
	independent.setup(30.0)
	_check(randf() == expected_random, "Selección de paleta no consume el RNG global")
	var original_color := independent.current_color
	visual.set_color(Color(1.0, 0.8, 0.15))
	_check((visual.particles.material_override as StandardMaterial3D).albedo_color == visual.current_color and (visual.hit_particles.material_override as StandardMaterial3D).albedo_color == visual.current_color, "Variante dorada tiñe ambos bursts")
	_check(independent.current_color == original_color and independent._materials[0].albedo_color == original_color, "Color de una instancia no modifica otra")
	independent.queue_free()
	other.queue_free()
	var banana: Node3D = load("res://scenes/game/Fruit3D.tscn").instantiate()
	world.add_child(banana)
	banana.setup_fruit(database.create_fruit_resource("banana"), false)
	_check(banana.has_node("GummyVisual") and not banana._broken_has_halves and banana.get_node("GummyVisual").appearance_material.resource_name == banana.gummy_material_palette.material_for(2, false).resource_name, "La banana usa el mismo cubo y su acabado visual con color aleatorio, sin cambiar su identificador")
	banana.queue_free()
	var rock: Node3D = load("res://scenes/game/Fruit3D.tscn").instantiate()
	world.add_child(rock)
	rock.setup_rock(40.0)
	rock.play_hit()
	_check(rock.is_rock and not rock.has_node("GummyVisual") and rock.scale == Vector3.ONE, "Roca conserva su representación")
	rock.queue_free()
	spawner.queue_free()
	viewport.queue_free()
	await process_frame
	print("Gummy visual: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
