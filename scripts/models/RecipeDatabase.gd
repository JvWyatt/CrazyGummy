class_name RecipeDatabase
extends RefCounted
# ============================================================================
# RecipeDatabase
# ----------------------------------------------------------------------------
# Carga las 20 recetas de Crazy Gummy y sus datos de cubo/recompensa.
# Conserva el balance desde los archivos .tres de
# res://data/recipes/ (un archivo por receta, editables en el inspector), usando
# como índice res://data/catalog.tres (recurso GameCatalog). Para cambiar la
# dificultad/recompensa de una receta, edita su .tres; para añadir una receta
# nueva, crea su .tres con un id distinto y arrástralo a la lista "recipes" de
# res://data/catalog.tres. Significado de cada campo (ver RecipeData.gd):
#   - max_hp:         vida máxima (cuántos golpes aguanta según el daño del herramienta).
#                     Curva ×1.9: receta 1 = 20 HP, receta 20 ≈ 3.96M HP.
#   - min_reward/max_reward: rango de dinero que paga al romperlo (antes de
#                     multiplicadores de mejoras/comodines/prestigio).
#                     max_reward = 2^(orden-1): receta inicial = $1, cada rango duplica el
#                     máximo anterior (receta 20 ≈ $524K). El MINIMO de cada receta
#                     = el MÁXIMO de la receta anterior (sin factor): el factor
#                     (×2) SOLO se aplica al nuevo máximo. Receta 1 (receta inicial) es la
#                     base: min $0.10 – max $1.00.
#   - price:          precio de la receta en el mercado (0 = gratis)
#   - unlock_order:   orden de aparición histórico (no cambia el precio)
#   - base_color/inner_color/accent_color/radius/visual_family: solo apariencia
#
# Estas recetas se desbloquean con dinero de la partida en la pestaña
# "Recetas" del mercado y se olvidan al quebrar el
# negocio (ver GameManager.run_unlocked_recipes).
# ============================================================================

# Cache: id -> RecipeData (recurso completo, SIN multiplicadores de runtime).
static var _recipes: Dictionary = {}
static var _loaded: bool = false

# Receta ENTERA de respaldo hardcodeada (evita nunca devolver null a GummyBlock.gd).
static func _build_fallback() -> RecipeData:
	var fd := RecipeData.new()
	fd.id = "bear_classic"
	fd.display_name = "Osito Gummy Clásico"
	fd.icon_emoji = "🍬"
	fd.max_hp = 20.0
	fd.min_reward = 0.1
	fd.max_reward = 1.0
	fd.unlock_order = 1
	fd.price = 0
	fd.base_color = Color(0.95, 0.22, 0.32)
	fd.inner_color = Color(1.0, 0.45, 0.55)
	fd.accent_color = Color(0.2, 0.8, 0.3)
	fd.radius = 20.0
	fd.visual_family = "bear_classic"
	return fd

# Las recetas se leen del índice res://data/catalog.tres y NO listando
# res://data/recipes/ con DirAccess: en el juego exportado los .tres se empaquetan
# convertidos a binario, esa carpeta deja de existir y el listado salía vacío
# (el juego se quedaba solo con la receta inicial de respaldo). Ver GameCatalog.gd.
static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var catalog := load(GameCatalog.CATALOG_PATH) as GameCatalog
	if catalog == null:
		push_error("RecipeDatabase: no se pudo cargar %s (respaldo a Osito Gummy Clásico)" % GameCatalog.CATALOG_PATH)
		_recipes["bear_classic"] = _build_fallback()
		return
	for fd in catalog.recipes:
		if fd and not fd.id.is_empty():
			_recipes[fd.id] = fd
		else:
			push_warning("RecipeDatabase: ignorada una receta de catalog.tres (sin RecipeData o sin id)")
	if _recipes.is_empty():
		push_warning("RecipeDatabase: catalog.tres sin recetas válidas (respaldo a Osito Gummy Clásico)")
		_recipes["bear_classic"] = _build_fallback()

# Datos BASE de una receta (sin multiplicadores). Fallback a la receta inicial.
static func get_recipe_data(recipe_id: String) -> RecipeData:
	_ensure_loaded()
	if _recipes.has(recipe_id):
		return _recipes[recipe_id]
	return _recipes.get("bear_classic")

# Devuelve los ids de receta ORDENADOS por unlock_order (la secuencia de
# desbloqueo de la Recetas). Se usa para bloquear en cadena: no se puede
# comprar una receta sin haber comprado la anterior.
static func get_sorted_recipe_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	var recipes: Dictionary = _recipes
	for recipe_id in recipes.keys():
		ids.append(str(recipe_id))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int((recipes[a] as RecipeData).unlock_order) < int((recipes[b] as RecipeData).unlock_order)
	)
	return ids

# Crea una receta "real" (RecipeData) a partir de la tabla de arriba, aplicando
# los multiplicadores de comodines activos (vida, recompensas).
# El max_hp final se redondea siempre hacia abajo (floor) para que la vida
# mostrada/usada en el juego sea siempre un número entero.
static func create_block_recipe(recipe_id: String) -> RecipeData:
	var base := get_recipe_data(recipe_id)
	var fd: RecipeData = base.duplicate()
	fd.max_hp = floor(base.max_hp * StatsManager.get_block_hardness_multiplier())
	fd.min_reward = base.min_reward * StatsManager.get_recipe_min_reward_multiplier()
	fd.max_reward = base.max_reward * StatsManager.get_recipe_max_reward_multiplier()
	# Recetas x2 de tamaño: el radio de la DB se duplica en runtime para que los
	# sprites, el hitbox y el modelo 3D se vean el doble de grandes (antes eran
	# demasiado pequeñas). Scales sprite, hitbox y modelo 3D a la vez.
	fd.radius = base.radius * 2.0
	return fd
