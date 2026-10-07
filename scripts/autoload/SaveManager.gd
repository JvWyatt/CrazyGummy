extends Node
# ============================================================================
# SaveManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Guarda el progreso PERMANENTE del jugador en disco (archivo JSON en
# "user://"), es decir, todo lo que sobrevive aunque el negocio quiebre o se
# cierre el juego: reputación/prestigio, mejoras de prestigio, y estadísticas
# históricas (gomitas producidas, mejor día, reputación acumulada, etc).
#
# IMPORTANTE: "unlocked_recipes"/"unlocked_tools"/"equipped_tool" aquí
# guardados son solo un registro histórico (para la pantalla de Progreso).
# Lo que realmente se usa DURANTE una partida vive en GameManager
# (run_unlocked_recipes, run_unlocked_tools, run_equipped_tool), que se
# reinicia cada vez que empieza un negocio nuevo.
#
# "active_run" es una instantánea JSON de la partida EN CURSO (Guardar y
# salir), separada del progreso permanente: se guarda/reemplaza entera con
# save_active_run() y se invalida con clear_active_run(). Un dict vacío
# significa "no hay partida guardada para continuar".
# ============================================================================

const SAVE_FILE_PATH: String = "user://crazy_gummy_save.json"
const SAVE_MIGRATION: Script = preload("res://scripts/models/SaveMigration.gd")

signal data_loaded
signal data_saved
signal prestige_changed(new_amount: float)

# Estructura por defecto del guardado. Si agregas una clave nueva aquí,
# load_data() la fusiona automáticamente con partidas guardadas antiguas.
var save_data: Dictionary = {
	"version": 3,
	"prestige_points": 0,
	"prestige_levels": {
		"experience": 0,       # Potencia inicial; bono definido en BalanceData.
		"expert_hand": 0,      # Resistencia máxima; bono definido en BalanceData.
		"good_provider": 0,    # Ganancias; bono definido en BalanceData.
		"good_fortune": 0,     # Probabilidad de Jackpot; puntos porcentuales.
		"launch_speed": 0,     # Ritmo de cubos; bono definido en BalanceData.
	},
	"unlocked_tools": ["tool_fists"],
	"unlocked_recipes": ["bear_classic"],
	"discovered_cards": [],
	"equipped_tool": "tool_fists",
	"high_score_order": 0,
	"total_gummies_produced": 0,
	"total_reputation_earned": 0,
	"days_started": 0,
	"best_clients_in_day": 0,
	# Logros desbloqueados + métricas/flags de progreso. TODO lo gestiona
	# AchievementManager; aquí solo se guarda para persistirlo entre sesiones.
	"achievements": {
		"unlocked": [],
		"metrics": {},
		"flags": {}
	},
	# Instantánea de la partida en curso (Guardar y salir). Dict vacío = no hay
	# partida para continuar. Vive en el mismo archivo para correr bajo el mismo
	# sistema atómico de escritura, pero NO toca el progreso permanente.
	"active_run": {}
}

func _ready() -> void:
	load_data()

func load_data() -> void:
	var source_path: String = SAVE_FILE_PATH
	if not FileAccess.file_exists(source_path):
		for candidate: String in SAVE_MIGRATION.legacy_save_paths():
			if FileAccess.file_exists(candidate):
				source_path = candidate
				break
	if not FileAccess.file_exists(source_path):
		save_to_disk()
		emit_signal("data_loaded")
		return

	var file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		push_error("Error opening save file for read: " + str(FileAccess.get_open_error()))
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("JSON Parse Error in save file: " + json.get_error_message())
		return

	var loaded_dict: Variant = json.data
	if typeof(loaded_dict) == TYPE_DICTIONARY:
		var needs_migration: bool = source_path != SAVE_FILE_PATH or int(loaded_dict.get("version", 0)) < SAVE_MIGRATION.CURRENT_VERSION
		loaded_dict = SAVE_MIGRATION.migrate(loaded_dict)
		# Merge with defaults to ensure all keys exist
		for key in save_data.keys():
			if loaded_dict.has(key):
				if key == "active_run" and typeof(loaded_dict[key]) == TYPE_DICTIONARY:
					# La instantánea de partida es un dict libre (no tiene sub-claves
					# por defecto que fusionar); se reemplaza entera o se pierde.
					save_data[key] = loaded_dict[key]
				elif typeof(save_data[key]) == TYPE_DICTIONARY and typeof(loaded_dict[key]) == TYPE_DICTIONARY:
					for sub_key in save_data[key].keys():
						if loaded_dict[key].has(sub_key):
							save_data[key][sub_key] = loaded_dict[key][sub_key]
				else:
					save_data[key] = loaded_dict[key]
		if needs_migration:
			# El archivo anterior permanece intacto; las siguientes cargas usan el nuevo.
			save_to_disk()

	emit_signal("data_loaded")

func save_to_disk() -> bool:
	save_data["version"] = SAVE_MIGRATION.CURRENT_VERSION
	var json_string: String = JSON.stringify(save_data, "\t")
	# Escritura atómica: primero se escribe a un archivo temporal y luego se
	# renombra. Si la app muere durante la escritura, el save original no se
	# corrompe (el rename es atómico en la mayoría de sistemas de archivos).
	var tmp_path: String = SAVE_FILE_PATH + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("Error opening save file for write: " + str(FileAccess.get_open_error()))
		return false
	file.store_string(json_string)
	file.close()
	# Renombrar tmp -> save (atómico en POSIX; en Windows puede fallar si el
	# destino ya existe, por eso se intenta primero).
	if DirAccess.rename_absolute(tmp_path, SAVE_FILE_PATH) != OK:
		push_error("No se pudo reemplazar el guardado; se conserva el archivo anterior")
		return false
	emit_signal("data_saved")
	return true

func get_prestige_points() -> float:
	return snappedf(float(save_data.get("prestige_points", 0)), 0.01)

# Reputación concedida al completar cada día (GameManager._on_day_completed).
# Es la "moneda" permanente que se gasta en la Tienda de Prestigio. Se guarda
# con 2 decimales exactos para no arrastrar errores de redondeo de float.
func add_prestige_points(amount: float) -> void:
	var new_value: float = snappedf(get_prestige_points() + float(amount), 0.01)
	save_data["prestige_points"] = new_value
	save_data["total_reputation_earned"] = snappedf(float(save_data.get("total_reputation_earned", 0)) + float(amount), 0.01)
	save_to_disk()
	emit_signal("prestige_changed", new_value)

func spend_prestige_points(amount: float) -> bool:
	if get_prestige_points() >= float(amount):
		var new_value: float = snappedf(get_prestige_points() - float(amount), 0.01)
		save_data["prestige_points"] = new_value
		save_to_disk()
		emit_signal("prestige_changed", new_value)
		return true
	return false

func get_prestige_level(upgrade_id: String) -> int:
	var levels: Dictionary = save_data.get("prestige_levels", {})
	return int(levels.get(upgrade_id, 0))

func set_prestige_level(upgrade_id: String, level: int) -> void:
	if not save_data.has("prestige_levels"):
		save_data["prestige_levels"] = {}
	save_data["prestige_levels"][upgrade_id] = level
	save_to_disk()

func get_unlocked_tools() -> Array:
	var unlocked: Array = save_data.get("unlocked_tools", ["tool_fists"])
	if not ("tool_fists" in unlocked):
		unlocked.append("tool_fists")
		save_data["unlocked_tools"] = unlocked
	return unlocked

func get_unlocked_recipes() -> Array:
	return save_data.get("unlocked_recipes", ["bear_classic"])

func unlock_recipe(recipe_id: String) -> void:
	var unlocked: Array = get_unlocked_recipes()
	if not (recipe_id in unlocked):
		unlocked.append(recipe_id)
		save_data["unlocked_recipes"] = unlocked
		save_to_disk()

func get_discovered_cards() -> Array:
	return save_data.get("discovered_cards", [])

func discover_card(card_id: String) -> void:
	var discovered: Array = get_discovered_cards()
	if not (card_id in discovered):
		discovered.append(card_id)
		save_data["discovered_cards"] = discovered
		save_to_disk()

func unlock_tool(tool_id: String) -> void:
	var unlocked: Array = get_unlocked_tools()
	if not (tool_id in unlocked):
		unlocked.append(tool_id)
		save_data["unlocked_tools"] = unlocked
		save_to_disk()

func record_run_stats(completed_order: int, gummies_produced: int) -> void:
	if completed_order > int(save_data.get("high_score_order", 0)):
		save_data["high_score_order"] = completed_order
	# NOTA: el dinero histórico total ya no se acumula (no se muestra en ningún
	# lugar de la UI); solo se cuentan las gomitas producidas y el mejor día.
	save_data["total_gummies_produced"] = int(save_data.get("total_gummies_produced", 0)) + gummies_produced
	var best_clients: int = int(save_data.get("best_clients_in_day", 0))
	if completed_order > best_clients:
		save_data["best_clients_in_day"] = completed_order
	save_to_disk()

func record_day_started() -> void:
	save_data["days_started"] = int(save_data.get("days_started", 0)) + 1
	save_to_disk()

# --- Partida en curso (Guardar y salir) --------------------------------------
# La instantánea es un dict opaco que genera GameManager.capture_run_state().
# Guardar y salir NO termina la run: solo persiste su estado para continuar
# luego; la derrota real llama clear_active_run() para invalidarla.

func has_active_run() -> bool:
	return save_data.get("active_run", {}) is Dictionary and not save_data.get("active_run", {}).is_empty()

func get_active_run_snapshot() -> Dictionary:
	if not has_active_run():
		return {}
	return save_data.get("active_run", {}).duplicate(true)

func save_active_run(snapshot: Dictionary) -> bool:
	var previous: Variant = save_data.get("active_run", {})
	save_data["active_run"] = snapshot.duplicate(true)
	if save_to_disk():
		return true
	save_data["active_run"] = previous
	return false

func clear_active_run() -> void:
	# Si ya está vacía no se toca el disco (evita escrituras inútiles).
	if save_data.get("active_run", {}) is Dictionary and save_data.get("active_run", {}).is_empty():
		return
	save_data["active_run"] = {}
	save_to_disk()

func reset_save() -> void:
	# Comienza un save en blanco SIN "active_run": un reset de progreso también
	# descarta la partida guardada en curso (sus mejoras dependerían de niveles
	# de prestigio ya borrados y quedarían corruptas).
	save_data = {
		"version": 3,
		"prestige_points": 0,
		"prestige_levels": {
			"experience": 0,
			"expert_hand": 0,
			"good_provider": 0,
			"good_fortune": 0,
			"launch_speed": 0,
		},
		"unlocked_tools": ["tool_fists"],
		"unlocked_recipes": ["bear_classic"],
		"discovered_cards": [],
		"equipped_tool": "tool_fists",
		"high_score_order": 0,
		"total_gummies_produced": 0,
		"total_reputation_earned": 0,
		"days_started": 0,
		"best_clients_in_day": 0,
		"achievements": {
			"unlocked": [],
			"metrics": {},
			"flags": {}
		}
	}
	save_to_disk()
	emit_signal("prestige_changed", 0)
	# El reset de prestigio cambia las stats finales cacheadas en StatsManager.
	StatsManager.invalidate_stat_cache()
	# Los autoloads NO son singletons de engine (Engine.has_singleton daria
	# false): AchievementManager existe siempre como autoload, llamada directa.
	AchievementManager.reset_all()
