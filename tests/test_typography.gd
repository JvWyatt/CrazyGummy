extends SceneTree
## Sustitución de los tres roles sin depender de una pantalla concreta.

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
	var theme: Theme = load("res://themes/ui01_theme.tres").duplicate(true)
	var replacement: Font = load("res://assets/fonts/roboto/Roboto-Regular.ttf")
	var roles := {
		"title": ["Title", "TitleLabel"],
		"subtitle": ["Subtitle", "SubtitleLabel", "CardTitle", "ValueLabel", "JokerTitle"],
		"body": ["Body", "Label", "Button", "PrimaryButton", "DangerButton", "TooltipLabel", "CaptionLabel", "JokerDescription", "TabBar"]
	}
	for role in roles:
		var profile: Resource = theme.get(role)
		profile.set("font", replacement)
		profile.set("font_size", 23)
		profile.set("color", Color(0.7, 0.9, 1.0))
		profile.set("weight", 700)
		profile.set("letter_spacing", 2)
		profile.set("word_spacing", 3)
		profile.set("line_spacing", 4)
		for variant in roles[role]:
			var resolved: FontVariation = theme.get_font("font", variant)
			_check(resolved.base_font == replacement, role + " sustituye la fuente de " + variant)
			_check(theme.get_font_size("font_size", variant) == 23, role + " sustituye el tamaño de " + variant)
			_check(resolved.spacing_glyph == 2 and resolved.spacing_space == 3, role + " sustituye espaciados")
			_check(resolved.variation_opentype["wght"] == 700, role + " configura el peso")
			_check(theme.get_constant("line_spacing", variant) == 4, role + " configura interlineado")
			if variant not in ["PrimaryButton", "DangerButton"]:
				_check(theme.get_color("font_color", variant) == profile.get("color"), role + " sustituye el color")
	_check(theme.get_font("normal_font", "RichTextLabel").base_font == replacement, "Body se aplica al texto enriquecido")
	_check(theme.get_font_size("normal_font_size", "RichTextLabel") == 23, "Body se aplica al tamaño de texto enriquecido")
	_check(theme.get_font("font", "TabContainer").base_font == replacement, "Body se aplica a pestañas")
	print("Tipografía: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
