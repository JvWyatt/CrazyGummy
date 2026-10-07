extends SceneTree
## El respaldo 2D puede quedarse sin assets; no debe bloquear el gameplay 3D.
## Ejecutar con XDG_DATA_HOME aislado, como el resto de las regresiones.

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var fallback: GDScript = load("res://scripts/game/BlockSpriteFallback.gd")
	var previous_cache: Dictionary = fallback._texture_cache.duplicate()
	# Fuerza la ausencia sin borrar archivos, incluso si se repone arte en el futuro.
	fallback._texture_cache["bear_classic"] = null
	var block: Node2D = load("res://scenes/game/GummyBlock.tscn").instantiate()
	root.add_child(block)
	var visual: Sprite2D = block.get_node("Visual")
	var ring: Sprite2D = visual.get_node("GoldenRing")
	var recipe := RecipeData.new()
	recipe.id = "bear_classic"
	recipe.radius = 40.0
	block.recipe_data = recipe
	block.is_golden = true
	visual.refresh_visual()
	_check(visual.texture == null and visual.scale == Vector2.ONE, "Sprite ausente sin acceso nulo ni escala residual")
	_check(not ring.visible, "La dorada no muestra anillo sin sprite base")
	var missing_path := "res://assets/provisional/recipe_sprites".path_join("fixture_missing.png")
	_check(visual._load_optional_texture(missing_path) == null, "Carga opcional ausente sin error del motor")
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	fallback._texture_cache[recipe.id] = texture
	ring.texture = texture
	visual.refresh_visual()
	_check(visual.texture == texture and is_equal_approx(visual.scale.x, 2.0 * recipe.radius * visual.visual_scale / 128.0), "El sprite existente conserva el escalado por radio")
	_check(ring.visible and is_equal_approx(ring.scale.x, 128.0 / (2.0 * fallback.RING_REF_RADIUS)), "La dorada conserva el escalado del anillo")
	ring.texture = null
	visual.refresh_visual()
	_check(not ring.visible, "El anillo opcional ausente permanece oculto con sprite válido")
	fallback._texture_cache[recipe.id] = null
	visual.refresh_visual()
	_check(visual.texture == null and visual.scale == Vector2.ONE and not ring.visible, "Cambiar a una receta sin arte limpia el sprite previo")
	_check(block.recipe_data == recipe and recipe.radius == 40.0 and block.is_golden, "El fallback no modifica datos ni variante dorada")
	fallback._texture_cache = previous_cache
	block.queue_free()
	await process_frame
	print("Respaldo 2D: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
