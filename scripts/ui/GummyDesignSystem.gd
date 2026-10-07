@tool
extends RefCounted
## Acabados globales, regenerados por TypographyTheme también en el editor.
## Las medidas de contenido conservan el contrato de los Containers existentes.

const BG := Color("#141323")
const PANEL := Color("#211f36")
const ROW := Color("#2d2945")
const BORDER := Color("#655c83")
const AQUA := Color("#7ce8d5")
const CORAL := Color("#ff8fa3")
const GOLD := Color(1.0, 0.835, 0.29)
const TEXT := Color("#f8f2ff")
const DIM := Color("#c1b6d2")
const SUCCESS := Color("#91e8b8")
const DANGER := Color("#ff788d")
const SURFACE_PATH := "res://assets/crazy_gummy/ui/buttons/gel_surface.svg"
const SLIDER_THUMB_PATH := "res://assets/crazy_gummy/ui/icons/slider_thumb.svg"

static func panel(bg: Color, border: Color, radius: int, padding: Vector2, shadow: int = 5) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding.x
	box.content_margin_right = padding.x
	box.content_margin_top = padding.y
	box.content_margin_bottom = padding.y
	box.shadow_color = Color(0.035, 0.02, 0.08, 0.55)
	box.shadow_size = shadow
	box.shadow_offset = Vector2(0, 4)
	return box

static func gel(color: Color, pressed: bool = false) -> StyleBox:
	# El Theme @tool puede cargarse antes de importar los SVG en un clon limpio.
	if not ResourceLoader.exists(SURFACE_PATH):
		return panel(color.darkened(0.18) if pressed else color, color.lightened(0.2), 22, Vector2(24, 10))
	var box := StyleBoxTexture.new()
	box.texture = load(SURFACE_PATH) as Texture2D
	box.modulate_color = color
	box.texture_margin_left = 26
	box.texture_margin_right = 26
	box.texture_margin_top = 20
	box.texture_margin_bottom = 20
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	# La superficie hundida pierde profundidad sin mover su área táctil.
	if pressed:
		box.modulate_color = color.darkened(0.18)
	return box

static func _buttons(theme: Theme, type_name: String, normal: Color, text: Color) -> void:
	if type_name != "Button":
		theme.set_type_variation(type_name, "Button")
	theme.set_stylebox("normal", type_name, gel(normal))
	theme.set_stylebox("hover", type_name, gel(normal.lightened(0.10)))
	theme.set_stylebox("pressed", type_name, gel(normal, true))
	theme.set_stylebox("hover_pressed", type_name, gel(normal, true))
	theme.set_stylebox("disabled", type_name, gel(Color("#454057")))
	var focus := panel(Color.TRANSPARENT, AQUA, 24, Vector2(24, 10), 0)
	focus.draw_center = false
	theme.set_stylebox("focus", type_name, focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, type_name, text)
	theme.set_color("font_disabled_color", type_name, DIM)

static func _variation(theme: Theme, type_name: String, box: StyleBoxFlat) -> void:
	theme.set_type_variation(type_name, "PanelContainer")
	theme.set_stylebox("panel", type_name, box)

static func apply(theme: Theme) -> void:
	var palette := {"bg": BG, "panel": PANEL, "row": ROW, "border": BORDER, "accent": GOLD, "action": AQUA, "premium": GOLD, "text": TEXT, "text_dim": DIM, "success": SUCCESS, "danger": DANGER, "warning": CORAL, "disabled": Color("#454057")}
	for key in palette:
		theme.set_color("color_" + key, "Palette", palette[key])
	theme.set_color("color_scrim", "Palette", Color(0.04, 0.025, 0.075, 0.76))
	_buttons(theme, "Button", Color("#605779"), TEXT)
	_buttons(theme, "PrimaryButton", AQUA, Color("#14312f"))
	_buttons(theme, "DangerButton", Color("#934559"), TEXT)
	_buttons(theme, "PremiumButton", GOLD, Color("#3b2919"))
	theme.set_color("font_color", "BonusValue", Color("#3b2919"))
	theme.set_color("font_color", "PremiumTitle", GOLD)
	theme.set_stylebox("panel", "PanelContainer", panel(PANEL, BORDER, 22, Vector2(18, 14)))
	_variation(theme, "ModalPanel", panel(PANEL, Color("#8e7ca3"), 28, Vector2(24, 24), 12))
	_variation(theme, "Card", panel(ROW, BORDER, 20, Vector2(18, 16)))
	_variation(theme, "CompactCard", panel(ROW, BORDER, 16, Vector2(10, 6), 4))
	_variation(theme, "IllustratedCard", panel(Color("#1b3152"), BORDER, 16, Vector2(10, 6), 4))
	_variation(theme, "StatPanel", panel(PANEL, BORDER, 18, Vector2(18, 16), 3))
	_variation(theme, "PremiumPanel", panel(Color("#32283d"), GOLD.darkened(0.25), 24, Vector2(18, 16)))
	_variation(theme, "ToastPanel", panel(Color("#30263e"), GOLD, 22, Vector2(18, 14), 10))
	_variation(theme, "TooltipPanel", panel(BG, AQUA.darkened(0.3), 14, Vector2(12, 8), 6))
	_variation(theme, "SummaryPanel", panel(Color("#23383b"), AQUA.darkened(0.4), 16, Vector2(16, 12), 2))
	var track := panel(BG, BORDER, 12, Vector2.ZERO, 0)
	for bar_type in ["ProgressBar", "MoneyBar", "BonusBar", "EnergyBar", "TimeBar", "StreakBar", "HardnessBar"]:
		if bar_type != "ProgressBar":
			theme.set_type_variation(bar_type, "ProgressBar")
		theme.set_stylebox("background", bar_type, track)
		var color: Color = {"MoneyBar": Color("#47877e"), "BonusBar": Color.WHITE, "EnergyBar": Color("#38746c"), "TimeBar": Color("#845267"), "StreakBar": CORAL, "HardnessBar": AQUA}.get(bar_type, SUCCESS)
		var fill := panel(color, color.lightened(0.2), 10, Vector2.ZERO, 0)
		fill.set_border_width_all(1)
		theme.set_stylebox("fill", bar_type, fill)
	var tab_panel := panel(BG, BORDER.darkened(0.25), 18, Vector2(8, 12), 0)
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	for tab_type in ["TabContainer", "TabBar"]:
		for state in ["tab_selected", "tab_unselected", "tab_hovered", "tab_focused", "tab_disabled"]:
			var selected: bool = state == "tab_selected"
			var box := panel(Color("#345651") if selected else PANEL, AQUA if selected else BORDER, 14, Vector2(18, 14), 0)
			theme.set_stylebox(state, tab_type, box)
		theme.set_color("font_selected_color", tab_type, TEXT)
		theme.set_color("font_unselected_color", tab_type, DIM)
		theme.set_color("font_hovered_color", tab_type, TEXT)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		theme.set_stylebox(state, "VScrollBar", panel(AQUA.darkened(0.3), Color.TRANSPARENT, 5, Vector2(4, 2), 0))
	theme.set_stylebox("scroll", "VScrollBar", panel(BG, Color.TRANSPARENT, 5, Vector2(4, 2), 0))
	theme.set_stylebox("slider", "HSlider", panel(BG, BORDER, 6, Vector2(0, 3), 0))
	for state in ["grabber_area", "grabber_area_highlight"]:
		theme.set_stylebox(state, "HSlider", panel(AQUA, Color.TRANSPARENT, 6, Vector2(0, 3), 0))
	if ResourceLoader.exists(SLIDER_THUMB_PATH):
		for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
			theme.set_icon(state, "HSlider", load(SLIDER_THUMB_PATH) as Texture2D)
	var separator := StyleBoxLine.new()
	separator.color = BORDER
	separator.thickness = 2
	theme.set_stylebox("separator", "HSeparator", separator)
	theme.set_constant("hover_scale_percent", "Motion", 101)
