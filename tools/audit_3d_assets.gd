extends SceneTree
## Auditoría de importados: jerarquía, geometría y láminas de tres vistas.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var paths: Array[String] = []
	for folder in ["gummies", "cubes", "Obstaculos", "obstacles"]:
		var directory: String = "res://assets/crazy_gummy/" + folder
		if not DirAccess.dir_exists_absolute(directory):
			continue
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".glb"):
				paths.append(directory + "/" + file)
	paths.sort()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 270)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.5
	camera.position.z = 5
	world.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -25, 0)
	light.light_energy = 1.2
	world.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#182333")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var atlas := Image.create(720, paths.size() * 270, false, Image.FORMAT_RGBA8)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#bde0e5")
	material.roughness = 0.55
	for index in paths.size():
		var packed: PackedScene = load(paths[index])
		var instances: Array[Node3D] = []
		for view in 3:
			var model: Node3D = packed.instantiate()
			world.add_child(model)
			var meshes := model.find_children("*", "MeshInstance3D", true, false)
			var bounds := AABB()
			var first := true
			var triangles := 0
			for mesh: MeshInstance3D in meshes:
				var box: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.mesh.get_aabb()
				bounds = box if first else bounds.merge(box)
				first = false
				for surface in mesh.mesh.get_surface_count():
					var arrays: Array = mesh.mesh.surface_get_arrays(surface)
					triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size()) / 3
				if view == 0:
					print("  ", model.get_path_to(mesh), " surfaces=", mesh.mesh.get_surface_count(), " bounds=", box, " transform=", mesh.transform)
				mesh.material_override = material
			if view == 0:
				print(paths[index], " meshes=", meshes.size(), " triangles=", triangles, " bounds=", bounds)
			var wrapper := Node3D.new()
			world.add_child(wrapper)
			model.reparent(wrapper)
			var factor := 1.8 / maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
			model.scale *= factor
			model.position = -bounds.get_center() * factor
			wrapper.position.x = (view - 1) * 2.2
			wrapper.rotation_degrees = [Vector3.ZERO, Vector3(0, 90, 0), Vector3(90, 0, 0)][view]
			instances.append(wrapper)
		var label := Label.new()
		label.text = paths[index].get_file() + " · frente / perfil / superior"
		label.position = Vector2(6, 240)
		viewport.add_child(label)
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			atlas.blit_rect(viewport.get_texture().get_image(), Rect2i(0, 0, 720, 270), Vector2i(0, index * 270))
		for instance in instances:
			instance.free()
		label.free()
	if "--capture" in OS.get_cmdline_user_args():
		print("Lámina: ", atlas.save_png("/tmp/opencode/asset_3d_audit.png"))
		for page in 4:
			atlas.get_region(Rect2i(0, page * 1620, 720, 1620)).save_png("/tmp/opencode/asset_3d_audit_%d.png" % page)
	viewport.free()
	quit()
