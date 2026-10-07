extends SceneTree
## Fixture histórico deliberadamente aislado: única excepción terminológica en tests.
## Siempre ejecutar con XDG_DATA_HOME separado de las partidas reales.

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var converter: Script = load("res://scripts/models/SaveMigration.gd")
	var old: Dictionary = {
		"prestige_points": 81.25, "prestige_levels": {"experience": 7, "good_fortune": 3},
		"unlocked_fruits": converter.RECIPE_IDS.keys(), "unlocked_knives": converter.TOOL_IDS.keys(),
		"equipped_knife": "weapon_chainsaw", "discovered_cards": converter.CARD_IDS.keys(),
		"total_fruits_cut": 98765, "high_score_order": 135, "total_reputation_earned": 145.5,
		"achievements": {"unlocked": converter.ACHIEVEMENT_IDS.keys(), "metrics": {}, "flags": {}},
	}
	for key: String in converter.METRIC_KEYS:
		old.achievements.metrics[key] = 12345.5
	for id: String in converter.RECIPE_IDS:
		old.achievements.metrics["cut_" + id] = 31
	for key: String in converter.FLAG_KEYS:
		old.achievements.flags[key] = true
	var pristine: Dictionary = old.duplicate(true)
	var migrated: Dictionary = converter.migrate(old)
	_check(old == pristine, "El conversor no modifica la fuente histórica")
	_check(converter.migrate(migrated) == migrated, "Migración idempotente")
	_check(migrated.version == converter.CURRENT_VERSION, "Esquema versionado")
	_check(migrated.prestige_points == 81.25 and migrated.prestige_levels == old.prestige_levels, "Saldo y niveles permanentes exactos")
	_check(migrated.total_gummies_produced == 98765 and migrated.high_score_order == 135, "Contadores y récord intactos")
	_check(migrated.equipped_tool == "tool_crazy_hammer", "Herramienta equipada traducida")
	for id: String in converter.RECIPE_IDS:
		_check(migrated.unlocked_recipes.has(converter.RECIPE_IDS[id]), "Receta migrada: " + id)
		_check(migrated.achievements.metrics["produced_" + converter.RECIPE_IDS[id]] == 31, "Progreso de receta conservado")
	for id: String in converter.TOOL_IDS:
		_check(migrated.unlocked_tools.has(converter.TOOL_IDS[id]), "Herramienta migrada: " + id)
	for id: String in converter.CARD_IDS:
		_check(migrated.discovered_cards.has(converter.CARD_IDS[id]), "Comodín migrado: " + id)
	for id: String in converter.ACHIEVEMENT_IDS:
		_check(migrated.achievements.unlocked.has(converter.ACHIEVEMENT_IDS[id]), "Logro migrado: " + id)
	for key: String in converter.METRIC_KEYS:
		_check(migrated.achievements.metrics[converter.METRIC_KEYS[key]] == 12345.5, "Métrica conservada")
	for key: String in converter.FLAG_KEYS:
		_check(migrated.achievements.flags[converter.FLAG_KEYS[key]], "Flag conservado")
	var mixed: Dictionary = converter.migrate({"unlocked_fruits": ["strawberry"], "unlocked_recipes": ["bear_classic", "ring"], "total_fruits_cut": 40, "total_gummies_produced": 50, "achievements": {"metrics": {"fruits_cut": 40, "gummies_produced": 50}, "flags": {"day_with_fist": true, "day_with_fists": false}}})
	_check(mixed.unlocked_recipes == ["bear_classic", "ring"], "Aliases no duplican descubrimientos")
	_check(mixed.total_gummies_produced == 50 and mixed.achievements.metrics.gummies_produced == 50, "Aliases no duplican métricas")
	_check(mixed.achievements.flags.day_with_fists, "Aliases preservan flags verdaderos")
	_check(converter.migrate({"discovered_cards": ["unknown_card"]}).discovered_cards == ["unknown_card"], "ID desconocido se conserva")
	# Integración real: lectura del archivo antiguo, escritura del nuevo y reset.
	if not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/"):
		_check(false, "Esta prueba necesita XDG_DATA_HOME aislado bajo /tmp")
		quit(1)
		return
	var save: Node = root.get_node("SaveManager")
	DirAccess.remove_absolute(save.SAVE_FILE_PATH)
	var legacy_json: String = JSON.stringify(old)
	var legacy_file := FileAccess.open(converter.LEGACY_SAVE_FILE_PATH, FileAccess.WRITE)
	legacy_file.store_string(legacy_json)
	legacy_file.close()
	save.load_data()
	_check(FileAccess.file_exists(save.SAVE_FILE_PATH), "Se escribe el nuevo archivo canónico")
	_check(FileAccess.get_file_as_string(converter.LEGACY_SAVE_FILE_PATH) == legacy_json, "Archivo histórico intacto")
	_check(save.save_data.prestige_points == 81.25 and save.save_data.total_gummies_produced == 98765, "SaveManager conserva saldo y producción")
	_check(save.save_data.unlocked_recipes.size() == 20 and save.save_data.unlocked_tools.size() == 10, "SaveManager conserva todos los desbloqueos")
	var catalog: Resource = load("res://data/catalog.tres")
	for recipe: Resource in catalog.recipes:
		_check(save.save_data.unlocked_recipes.has(recipe.id), "ID migrado resuelve en catálogo: " + recipe.id)
	for card in CardDatabase.ALL_CARDS:
		if converter.CARD_IDS.values().has(card.id):
			_check(save.get_discovered_cards().has(card.id), "Descubrimiento resuelve en catálogo actual")
	for definition in root.get_node("AchievementManager").DEFINITIONS:
		if converter.ACHIEVEMENT_IDS.values().has(definition.id):
			_check(save.save_data.achievements.unlocked.has(definition.id), "Logro resuelve en catálogo actual")
	var roundtrip: Dictionary = save.save_data.duplicate(true)
	save.save_data.prestige_points = -1
	save.load_data()
	# JSON convierte los enteros a floats; comparar el contenido serializable.
	_check(JSON.parse_string(JSON.stringify(save.save_data)) == JSON.parse_string(JSON.stringify(roundtrip)), "Segunda carga del formato nuevo es idéntica")
	save.reset_save()
	save.load_data()
	_check(save.save_data.total_gummies_produced == 0 and save.get_prestige_points() == 0, "Reset no resucita el archivo antiguo")
	# Versiones anteriores con otro nombre de app en escritorio.
	var candidates: Array[String] = converter.legacy_save_paths()
	if candidates.size() > 1:
		var prior_app_path: String = candidates[1]
		DirAccess.make_dir_recursive_absolute(prior_app_path.get_base_dir())
		var prior_app_file := FileAccess.open(prior_app_path, FileAccess.WRITE)
		prior_app_file.store_string(legacy_json)
		prior_app_file.close()
		DirAccess.remove_absolute(save.SAVE_FILE_PATH)
		DirAccess.remove_absolute(converter.LEGACY_SAVE_FILE_PATH)
		save.load_data()
		_check(save.get_prestige_points() == 81.25 and save.save_data.unlocked_recipes.size() == 20, "Recupera progreso de la carpeta anterior de escritorio")
		_check(FileAccess.get_file_as_string(prior_app_path) == legacy_json, "Carpeta anterior conserva su original")
		save.reset_save()
		save.load_data()
		_check(save.get_prestige_points() == 0, "Formato nuevo tiene prioridad sobre carpetas anteriores")
	print("Compatibilidad de guardados: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
