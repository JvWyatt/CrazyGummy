class_name FruitDatabase
extends RefCounted
# ============================================================================
# FruitDatabase
# ----------------------------------------------------------------------------
# Carga el balance de TODAS las frutas del juego desde los archivos .tres de
# res://data/fruits/ (un archivo por fruta, editables en el inspector), usando
# como índice res://data/catalog.tres (recurso GameCatalog). Para cambiar la
# dificultad/recompensa de una fruta, edita su .tres; para añadir una fruta
# nueva, crea su .tres con un id distinto y arrástralo a la lista "fruits" de
# res://data/catalog.tres. Significado de cada campo (ver FruitData.gd):
#   - max_hp:         vida máxima (cuántos golpes aguanta según el daño del arma).
#                     Curva ×1.9: fruta 1 = 20 HP, fruta 20 ≈ 3.96M HP.
#   - min_reward/max_reward: rango de dinero que paga al cortarla (antes de
#                     multiplicadores de mejoras/comodines/prestigio).
#                     max_reward = 2^(orden-1): fresa = $1, cada rango duplica el
#                     máximo anterior (fruta 20 ≈ $524K). El MINIMO de cada fruta
#                     = el MÁXIMO de la fruta anterior (sin factor): el factor
#                     (×2) SOLO se aplica al nuevo máximo. Fruta 1 (fresa) es la
#                     base: min $0.10 – max $1.00.
#   - price:          precio de desbloqueo en la Frutería (0 = gratis)
#   - unlock_order:   orden de aparición histórico (no cambia el precio)
#   - base_color/inner_color/accent_color/radius/shape_type: solo apariencia
#
# Estas frutas se desbloquean con dinero de la partida en la pestaña
# "Frutería" del mercado (ver RunUpgradeModal.gd) y se olvidan al quebrar el
# negocio (ver GameManager.run_unlocked_fruits).
# ============================================================================

# Cache: id -> FruitData (recurso completo, SIN multiplicadores de runtime).
static var _fruits: Dictionary = {}
static var _loaded: bool = false

# Fruta ENTERA de respaldo hardcodeada (evita nunca devolver null a Fruit.gd).
static func _build_fallback() -> FruitData:
	var fd := FruitData.new()
	fd.id = "strawberry"
	fd.display_name = "Fresa"
	fd.icon_emoji = "🍓"
	fd.max_hp = 20.0
	fd.min_reward = 0.1
	fd.max_reward = 1.0
	fd.unlock_order = 1
	fd.price = 0
	fd.base_color = Color(0.95, 0.22, 0.32)
	fd.inner_color = Color(1.0, 0.45, 0.55)
	fd.accent_color = Color(0.2, 0.8, 0.3)
	fd.radius = 20.0
	fd.shape_type = "strawberry"
	return fd

# Las frutas se leen del índice res://data/catalog.tres y NO listando
# res://data/fruits/ con DirAccess: en el juego exportado los .tres se empaquetan
# convertidos a binario, esa carpeta deja de existir y el listado salía vacío
# (el juego se quedaba solo con la Fresa de respaldo). Ver GameCatalog.gd.
static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var catalog := load(GameCatalog.CATALOG_PATH) as GameCatalog
	if catalog == null:
		push_error("FruitDatabase: no se pudo cargar %s (fallback a la fresa)" % GameCatalog.CATALOG_PATH)
		_fruits["strawberry"] = _build_fallback()
		return
	for fd in catalog.fruits:
		if fd and not fd.id.is_empty():
			_fruits[fd.id] = fd
		else:
			push_warning("FruitDatabase: ignorada una fruta de catalog.tres (sin FruitData o sin id)")
	if _fruits.is_empty():
		push_warning("FruitDatabase: catalog.tres sin frutas válidas (fallback a la fresa)")
		_fruits["strawberry"] = _build_fallback()

# Datos BASE de una fruta (sin multiplicadores). Fallback a la fresa.
static func get_fruit_data(fruit_id: String) -> FruitData:
	_ensure_loaded()
	if _fruits.has(fruit_id):
		return _fruits[fruit_id]
	return _fruits.get("strawberry")

# Devuelve los ids de fruta ORDENADOS por unlock_order (la secuencia de
# desbloqueo de la Frutería). Se usa para bloquear en cadena: no se puede
# comprar una fruta sin haber comprado la anterior.
static func get_sorted_fruit_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	var fruits: Dictionary = _fruits
	for fruit_id in fruits.keys():
		ids.append(str(fruit_id))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int((fruits[a] as FruitData).unlock_order) < int((fruits[b] as FruitData).unlock_order)
	)
	return ids

# Crea una fruta "real" (FruitData) a partir de la tabla de arriba, aplicando
# los multiplicadores de comodines activos (vida, recompensas).
# El max_hp final se redondea siempre hacia abajo (floor) para que la vida
# mostrada/usada en el juego sea siempre un número entero.
static func create_fruit_resource(fruit_id: String) -> FruitData:
	var base := get_fruit_data(fruit_id)
	var fd: FruitData = base.duplicate()
	fd.max_hp = floor(base.max_hp * StatsManager.get_fruit_max_hp_multiplier())
	fd.min_reward = base.min_reward * StatsManager.get_fruit_min_reward_multiplier()
	fd.max_reward = base.max_reward * StatsManager.get_fruit_max_reward_multiplier()
	# Frutas x2 de tamaño: el radio de la DB se duplica en runtime para que los
	# sprites, el hitbox y el modelo 3D se vean el doble de grandes (antes eran
	# demasiado pequeñas). Scales sprite, hitbox y modelo 3D a la vez.
	fd.radius = base.radius * 2.0
	return fd
