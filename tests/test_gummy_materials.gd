extends SceneTree
# Catálogo visual completo. -- --capture guarda una lámina en /tmp/opencode.

var checks: int = 0
var failures: int = 0
var viewport: SubViewport
var world: Node3D
var capture: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _mesh(model: Node3D) -> MeshInstance3D:
	return model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D

func _snapshot(fd: Resource) -> Array:
	var values: Array = []
	for key in ["id", "display_name", "max_hp", "min_reward", "max_reward", "unlock_order", "price", "radius", "shape_type", "base_color", "inner_color", "accent_color"]:
		values.append(fd.get(key))
	return values

func _show_pair(mirror: Node3D, index: int, title: String, finish_name: String) -> void:
	var visual := mirror.get_node("GummyVisual") as GummyVisual
	var x := 50.0 + float(index % 5) * 200.0
	var y := 85.0 + float(index / 5) * 165.0
	mirror.position = Vector3(x - 500.0, 425.0 - y, 0.0)
	# Tamaño uniforme solo en la lámina de comparación, no durante el juego.
	var comparison_scale: float = 35.0 / mirror._radius
	mirror.scale = Vector3.ONE * comparison_scale
	mirror.set_process(false)
	visual.set_process(false)
	visual.product_ballistic.stop()
	visual.particles.hide()
	visual.hit_particles.hide()
	visual.cube.show()
	visual.cube.rotation = Vector3(0.15, 0.25, 0.0)
	visual.product.show()
	visual.product.scale = Vector3.ONE
	visual.product.position = Vector3(85.0 / comparison_scale, 0.0, 0.0)
	visual.product.rotation = Vector3.ZERO
	var label := Label.new()
	var prefix := "%02d" % (index + 1) if index < 20 else "★"
	label.text = "%s · %s\n%s" % [prefix, title, finish_name]
	label.position = Vector2(x - 42.0, y + 47.0)
	label.size = Vector2(190.0, 62.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_contents = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	viewport.add_child(label)

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	root.get_node("SoundManager").is_sound_enabled = false
	root.get_node("GameManager").set_process(false)
	var database: Script = load("res://scripts/models/FruitDatabase.gd")
	var palette: Resource = load("res://assets/crazy_gummy/materials/palette.tres")
	var ids: Array[String] = database.get_sorted_fruit_ids()
	var expected_ids: Array[String] = ["strawberry", "banana", "peach", "cherry", "orange", "apple", "pear", "kiwi", "mango", "lemon", "watermelon", "melon", "pineapple", "papaya", "coconut", "avocado", "dragon_fruit", "guava", "quince", "pumpkin"]
	_check(ids == expected_ids and palette.tiers.size() == ids.size(), "Se conservan las 20 frutas y hay un material por tier")
	viewport = SubViewport.new()
	viewport.size = Vector2i(1000, 850)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	world = load("res://scenes/game/Fruit3DWorld.tscn").instantiate()
	viewport.add_child(world)
	var fruit_scene: PackedScene = load("res://scenes/game/Fruit3D.tscn")
	var cube_mesh: Mesh
	var bear_mesh: Mesh
	var normals: Array[Material] = []
	var spawn_colors: Array[Color] = []
	var golden_mirror: Node3D
	for index in ids.size():
		var fd: Resource = database.create_fruit_resource(ids[index])
		var snapshot := _snapshot(fd)
		var mirror: Node3D = fruit_scene.instantiate()
		world.add_child(mirror)
		mirror.setup_fruit(fd, false, 1.5)
		mirror.set_process(false)
		var visual := mirror.get_node("GummyVisual") as GummyVisual
		var cube := _mesh(visual.cube)
		var bear := _mesh(visual.product)
		if cube_mesh == null:
			cube_mesh = cube.mesh
			bear_mesh = bear.mesh
		_check(cube.mesh == cube_mesh and bear.mesh == bear_mesh, "Modelos compartidos para " + fd.id)
		var source: ShaderMaterial = palette.material_for(fd.unlock_order, false)
		var same_finish: bool = visual.appearance_material.shader == source.shader
		for parameter in ["opacity", "surface_roughness", "internal_glow", "pattern_mode", "pattern_scale", "pattern_mix", "sugar_amount", "sugar_scale"]:
			same_finish = same_finish and visual.appearance_material.get_shader_parameter(parameter) == source.get_shader_parameter(parameter)
		_check(same_finish, "Color aleatorio conserva el acabado para " + fd.id)
		_check(visual.palette.has(visual.current_color) and visual.appearance_material != source, "Color de spawn aleatorio y material propio para " + fd.id)
		if not spawn_colors.has(visual.current_color):
			spawn_colors.append(visual.current_color)
		_check(cube.material_override == bear.material_override and cube.material_override == visual.appearance_material, "Cubo y osito comparten acabado en " + fd.id)
		_check(not normals.has(visual.appearance_material), "Variante diferenciada para " + fd.id)
		normals.append(visual.appearance_material)
		var material := visual.appearance_material as ShaderMaterial
		_check(material.shader.resource_path.ends_with("gummy.gdshader"), "Shader gummy ligero compartido en " + fd.id)
		var opacity: Variant = material.get_shader_parameter("opacity")
		_check(opacity is float and opacity >= 0.82 and opacity < 1.0, "Translucidez moderada y legible en " + fd.id)
		mirror.play_hit()
		visual._hit_tween.custom_step(0.04)
		_check(not visual.cube.scale.is_equal_approx(Vector3.ONE), "Wobble existente funciona en " + fd.id)
		visual._hit_tween.custom_step(1.0)
		_check(visual.cube.scale.is_equal_approx(Vector3.ONE), "Wobble recupera forma en " + fd.id)
		mirror.break_apart()
		_check(not visual.cube.visible and visual.product.visible and not mirror._broken_has_halves, "Transformación existente a un osito para " + fd.id)
		_check(_snapshot(fd) == snapshot, "Datos originales intactos para " + fd.id)
		if capture:
			_show_pair(mirror, index, fd.display_name, material.resource_name.split("·", false)[-1].strip_edges())
		else:
			mirror.queue_free()

		var gold: Node3D = fruit_scene.instantiate()
		world.add_child(gold)
		gold.setup_fruit(fd, true, 1.5)
		var gold_visual := gold.get_node("GummyVisual") as GummyVisual
		_check(gold_visual.appearance_material == palette.golden_material and _mesh(gold_visual.cube).material_override == _mesh(gold_visual.product).material_override, "Dorada conserva oro fijo en cubo/osito de " + fd.id)
		_check(_snapshot(fd) == snapshot, "Variante dorada no modifica valores de " + fd.id)
		if golden_mirror == null and capture:
			golden_mirror = gold
			_show_pair(gold, 22, "Dorada", "Oro metálico opaco")
		else:
			gold.queue_free()

	_check(spawn_colors.size() > 1, "Los spawns muestran varios colores reales, no un tinte fijo")
	var rock: Node3D = fruit_scene.instantiate()
	world.add_child(rock)
	rock.setup_rock(40.0)
	_check(rock.is_rock and not rock.has_node("GummyVisual") and _mesh(rock.get_node("Whole")).mesh is SphereMesh, "Obstáculo mantiene su esfera por defecto")
	var original: ShaderMaterial = palette.tiers[0]
	var original_color: Color = original.get_shader_parameter("primary_color")
	var custom: Node3D = fruit_scene.instantiate()
	world.add_child(custom)
	custom.setup_fruit(database.create_fruit_resource("strawberry"), false)
	custom.get_node("GummyVisual").set_color(Color.BLUE)
	_check(original.get_shader_parameter("primary_color") == original_color, "Personalizar una instancia no modifica el material compartido")
	rock.queue_free()
	custom.queue_free()
	if capture:
		for frame in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/opencode/gummy_20_materials.png")
	viewport.queue_free()
	await process_frame
	print("Materiales Crazy Gummy: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
