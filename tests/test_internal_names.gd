extends SceneTree
## Auditoría de nomenclatura activa y referencias estáticas. Los aliases antiguos
## solo se admiten en SaveMigration y en su fixture de compatibilidad.

var failures: int = 0
var checks: int = 0
var obsolete: RegEx
var references: RegEx

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _scan(directory: String) -> void:
	var folder := DirAccess.open(directory)
	if folder == null:
		_check(false, "No se puede auditar " + directory)
		return
	for name: String in folder.get_directories():
		_scan(directory.path_join(name))
	for name: String in folder.get_files():
		var path: String = directory.path_join(name)
		if path in ["res://scripts/models/SaveMigration.gd", "res://tests/test_save_compatibility.gd", "res://tests/test_internal_names.gd"]:
			continue
		_check(obsolete.search(name) == null, "Archivo con nombre obsoleto: " + path)
		if name.get_extension() not in ["gd", "tscn", "tres", "gdshader", "import"]:
			continue
		var text: String = FileAccess.get_file_as_string(path)
		for line: String in text.split("\n"):
			# El patrón negativo de identidad visible es deliberado, no una API vieja.
			if path == "res://tests/test_theme_migration.gd" and line.contains("_legacy_words.compile"):
				continue
			_check(obsolete.search(line) == null, "Nombre obsoleto en " + path + ": " + line)
		for match_result: RegExMatch in references.search_all(text):
			var resource_path: String = match_result.get_string(1)
			_check(ResourceLoader.exists(resource_path), "Referencia inexistente: " + resource_path + " en " + path)

func _run() -> void:
	obsolete = RegEx.new()
	# Estos términos son entradas de la auditoría, nunca nombres de arquitectura.
	obsolete.compile("(?i)fruit|frut[a-záéíóú_]*|(?<![a-z])(?:cut|slice|strawberry|banana|peach|cherry|apple|pear|kiwi|mango|lemon|watermelon|melon|pineapple|papaya|coconut|avocado|guava|quince|pumpkin)(?![a-z])")
	references = RegEx.new()
	references.compile("\"(res://[^\"\\n]+\\.(?:gd|tscn|tres|png|svg|jpg))\"")
	for directory: String in ["res://scripts", "res://scenes", "res://data", "res://tests", "res://assets/crazy_gummy", "res://assets/ui", "res://assets/fonts"]:
		_scan(directory)
	print("Nomenclatura interna: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures else 0)
