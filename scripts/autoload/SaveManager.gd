extends Node
# ============================================================================
# SaveManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Guarda el progreso PERMANENTE del jugador en disco (archivo JSON en
# "user://"), es decir, todo lo que sobrevive aunque el negocio quiebre o se
# cierre el juego: reputación/prestigio, mejoras de prestigio, y estadísticas
# históricas (frutas cortadas, mejor día, reputación acumulada, etc).
#
# IMPORTANTE: "unlocked_fruits"/"unlocked_knives"/"equipped_knife" aquí
# guardados son solo un registro histórico (para la pantalla de Progreso).
# Lo que realmente se usa DURANTE una partida vive en GameManager
# (run_unlocked_fruits, run_unlocked_knives, run_equipped_knife), que se
# reinicia cada vez que empieza un negocio nuevo.
# ============================================================================

const SAVE_FILE_PATH: String = "user://fruit_cutter_save.json"

signal data_loaded
signal data_saved
signal prestige_changed(new_amount: float)

# Estructura por defecto del guardado. Si agregas una clave nueva aquí,
# load_data() la fusiona automáticamente con partidas guardadas antiguas.
var save_data: Dictionary = {
	"prestige_points": 0,
	"prestige_levels": {
		"experience": 0,       # +20% starting damage / lvl
		"expert_hand": 0,      # +20% max energy / lvl
		"good_provider": 0,    # +20% money / lvl
		"good_fortune": 0,     # +7.77% jackpot chance / lvl
		"launch_speed": 0,     # +25% launch frequency / lvl
	},
	"unlocked_knives": ["weapon_fist"],
	"unlocked_fruits": ["strawberry"],
	"discovered_cards": [],
	"equipped_knife": "weapon_fist",
	"high_score_order": 0,
	"total_fruits_cut": 0,
	"total_reputation_earned": 0,
	"days_started": 0,
	"best_clients_in_day": 0,
	# Logros desbloqueados + métricas/flags de progreso. TODO lo gestiona
	# AchievementManager; aquí solo se guarda para persistirlo entre sesiones.
	"achievements": {
		"unlocked": [],
		"metrics": {},
		"flags": {}
	}
}

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		save_to_disk()
		emit_signal("data_loaded")
		return

	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
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

	var loaded_dict = json.data
	if typeof(loaded_dict) == TYPE_DICTIONARY:
		# Merge with defaults to ensure all keys exist
		for key in save_data.keys():
			if loaded_dict.has(key):
				if typeof(save_data[key]) == TYPE_DICTIONARY and typeof(loaded_dict[key]) == TYPE_DICTIONARY:
					for sub_key in save_data[key].keys():
						if loaded_dict[key].has(sub_key):
							save_data[key][sub_key] = loaded_dict[key][sub_key]
				else:
					save_data[key] = loaded_dict[key]

	emit_signal("data_loaded")

func save_to_disk() -> void:
	var json_string: String = JSON.stringify(save_data, "\t")
	# Escritura atómica: primero se escribe a un archivo temporal y luego se
	# renombra. Si la app muere durante la escritura, el save original no se
	# corrompe (el rename es atómico en la mayoría de sistemas de archivos).
	var tmp_path: String = SAVE_FILE_PATH + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("Error opening save file for write: " + str(FileAccess.get_open_error()))
		# Fallback: intento directo (sin protección atómica).
		file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		if file == null:
			push_error("Fallback save also failed: " + str(FileAccess.get_open_error()))
			return
		file.store_string(json_string)
		file.close()
		emit_signal("data_saved")
		return
	file.store_string(json_string)
	file.close()
	# Renombrar tmp -> save (atómico en POSIX; en Windows puede fallar si el
	# destino ya existe, por eso se intenta primero).
	if DirAccess.rename_absolute(tmp_path, SAVE_FILE_PATH) != OK:
		# Fallback Windows: eliminar destino y reintentar.
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		DirAccess.rename_absolute(tmp_path, SAVE_FILE_PATH)
	emit_signal("data_saved")

func get_prestige_points() -> float:
	return snappedf(float(save_data.get("prestige_points", 0)), 0.01)

# Reputación ganada al quebrar un negocio (ver GameManager.end_run_failed).
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

func get_unlocked_knives() -> Array:
	var unlocked: Array = save_data.get("unlocked_knives", ["weapon_fist"])
	if not ("weapon_fist" in unlocked):
		unlocked.append("weapon_fist")
		save_data["unlocked_knives"] = unlocked
	return unlocked

func get_unlocked_fruits() -> Array:
	return save_data.get("unlocked_fruits", ["strawberry"])

func unlock_fruit(fruit_id: String) -> void:
	var unlocked: Array = get_unlocked_fruits()
	if not (fruit_id in unlocked):
		unlocked.append(fruit_id)
		save_data["unlocked_fruits"] = unlocked
		save_to_disk()

func get_discovered_cards() -> Array:
	return save_data.get("discovered_cards", [])

func discover_card(card_id: String) -> void:
	var discovered: Array = get_discovered_cards()
	if not (card_id in discovered):
		discovered.append(card_id)
		save_data["discovered_cards"] = discovered
		save_to_disk()

func unlock_knife(knife_id: String) -> void:
	var unlocked: Array = get_unlocked_knives()
	if not (knife_id in unlocked):
		unlocked.append(knife_id)
		save_data["unlocked_knives"] = unlocked
		save_to_disk()

func record_run_stats(completed_order: int, fruits_cut: int) -> void:
	if completed_order > int(save_data.get("high_score_order", 0)):
		save_data["high_score_order"] = completed_order
	# NOTA: el dinero histórico total ya no se acumula (no se muestra en ningún
	# lugar de la UI); solo se cuentan las frutas cortadas y el mejor día.
	save_data["total_fruits_cut"] = int(save_data.get("total_fruits_cut", 0)) + fruits_cut
	var best_clients: int = int(save_data.get("best_clients_in_day", 0))
	if completed_order > best_clients:
		save_data["best_clients_in_day"] = completed_order
	save_to_disk()

func record_day_started() -> void:
	save_data["days_started"] = int(save_data.get("days_started", 0)) + 1
	save_to_disk()

func reset_save() -> void:
	save_data = {
		"prestige_points": 0,
		"prestige_levels": {
			"experience": 0,
			"expert_hand": 0,
			"good_provider": 0,
			"good_fortune": 0,
			"launch_speed": 0,
		},
		"unlocked_knives": ["weapon_fist"],
		"unlocked_fruits": ["strawberry"],
		"discovered_cards": [],
		"equipped_knife": "weapon_fist",
		"high_score_order": 0,
		"total_fruits_cut": 0,
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
