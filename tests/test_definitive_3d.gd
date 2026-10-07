extends SceneTree
## Main y spawner reales; fixtures aislados. -- --capture guarda evidencia gráfica.

var failures := 0
var checks := 0
var capture := false
var host: SubViewport

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _frame(name: String) -> void:
	if not capture:
		return
	for node in host.find_children("*", "Node2D", true, false):
		if node.scene_file_path == "res://scenes/game/FloatingText.tscn":
			node.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	host.get_texture().get_image().save_png("/tmp/opencode/definitive_%s.png" % name)

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	host = SubViewport.new()
	host.size = Vector2i(720, 1280)
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	host.add_child(main)
	await process_frame
	var game := root.get_node("GameManager")
	root.get_node("SoundManager").is_sound_enabled = false
	main.main_menu.start_game_requested.emit()
	game.set_process(false)
	var spawner: Node = main.block_spawner
	spawner.disable_spawning()
	var world: Node3D = main._projectile3d_viewport.get_child(0)
	var expected_cubes := [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5]
	for tier in 20:
		for golden in [false, true]:
			var recipe_id: String = RecipeVisualLibrary.RECIPE_IDS[tier]
			game.run_unlocked_recipes.assign([recipe_id])
			spawner._launch_block()
			var block: Node = spawner.active_blocks[-1]
			block.is_golden = golden
			block.ballistic.stop()
			block.position = Vector2(360, 600)
			await process_frame
			var mirror: Node3D = world._block_mirrors[block.get_instance_id()]
			mirror.set_process(false)
			mirror.rotation = Vector3(0.15, 0.3, 0)
			var visual: GummyVisual = mirror.get_node("GummyVisual")
			var cube: Node = visual.get_node("Cube/Model").get_child(0)
			var gummy: Node = visual.get_node("Product/Model").get_child(0)
			_check(cube.scene_file_path == RecipeVisualLibrary.CUBES[expected_cubes[tier]].resource_path, "Cubo de tier %d" % (tier + 1))
			_check(gummy.scene_file_path == RecipeVisualLibrary.GUMMIES[tier].resource_path, "Gomita de tier %d" % (tier + 1))
			_check(block.current_hp == block.recipe_data.max_hp, "Dureza conservada")
			if not golden:
				await _frame("tier_%02d_cube" % (tier + 1))
			var produced_before: int = game.total_gummies_produced_run
			block.take_damage(block.max_hp, false)
			await block.block_destroyed
			await process_frame
			_check(game.total_gummies_produced_run == produced_before + 1, "Una recompensa por ruptura")
			_check(visual.product.visible and not visual.cube.visible, "Revelado del producto real")
			_check(visual.appearance_material == mirror.gummy_material_palette.golden_material if golden else visual.palette.has(visual.current_color), "Oro/paleta conservados")
			visual.product_ballistic.stop()
			visual.set_process(false)
			visual.product.scale = Vector3.ONE
			if not golden or tier == 19:
				await _frame("tier_%02d_%s" % [tier + 1, "gold" if golden else "gummy"])
			mirror.queue_free()
			await process_frame
	spawner._launch_obstacle()
	var candy: Node = spawner.active_obstacles[-1]
	_check(candy.radius >= 30.0 and candy.radius <= 90.0, "Caramelo comparte el rango de tamaño del cubo clásico")
	candy.ballistic.stop()
	candy.ballistic.velocity = Vector2(0, 100)
	candy.position = Vector2(360, 600)
	await process_frame
	var candy_mirror: Node3D = world._obstacle_mirrors[candy.get_instance_id()]
	candy_mirror.set_process(false)
	_check(is_equal_approx(candy_mirror._radius, candy.radius * candy_mirror.visual_scale), "Caramelo usa la misma proporción visual que los cubos")
	_check(candy.custom_visual and candy_mirror.whole.get_child(0).scene_file_path == RecipeVisualLibrary.HARD_CANDY.resource_path, "Caramelo Duro del spawner usa GLB y oculta fallback 2D")
	await _frame("hard_candy")
	var money_before: float = game.run_money
	var streak_before: int = game.current_streak
	candy.break_candy()
	await process_frame
	await process_frame
	_check(is_instance_valid(candy_mirror) and candy_mirror.is_broken() and candy_mirror.broken.visible and not candy_mirror.whole.visible, "La eliminación 2D conserva el modelo roto visible")
	_check(candy_mirror.broken.get_child(0).scene_file_path == RecipeVisualLibrary.HARD_CANDY_BROKEN.resource_path, "GLB roto intacto")
	_check(game.run_money == money_before and game.current_streak == streak_before, "Rotura de caramelo conserva dinero y racha")
	await _frame("hard_candy_broken")
	candy_mirror.set_process(true)
	await create_timer(1.6).timeout
	_check(not is_instance_valid(candy_mirror), "Caramelo roto se libera al escapar")
	host.queue_free()
	await process_frame
	print("Assets 3D definitivos: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
