@tool
class_name TypographyStyle
extends Resource
## Una única fuente de verdad para cada rol tipográfico del juego.

@export var font: Font:
	set(value):
		if font and font.changed.is_connected(emit_changed):
			font.changed.disconnect(emit_changed)
		font = value
		if font and not font.changed.is_connected(emit_changed):
			font.changed.connect(emit_changed)
		emit_changed()
@export_range(10, 72) var font_size: int = 18:
	set(value):
		font_size = value
		emit_changed()
@export var color: Color = Color(0.9, 0.93, 0.98):
	set(value):
		color = value
		emit_changed()
@export_range(100, 900, 100) var weight: int = 400:
	set(value):
		weight = value
		emit_changed()
@export_range(-2, 12) var letter_spacing: int = 0:
	set(value):
		letter_spacing = value
		emit_changed()
@export_range(-2, 12) var word_spacing: int = 0:
	set(value):
		word_spacing = value
		emit_changed()
@export_range(0, 16) var line_spacing: int = 2:
	set(value):
		line_spacing = value
		emit_changed()
@export_range(0, 8) var outline_size: int = 0:
	set(value):
		outline_size = value
		emit_changed()
@export var outline_color: Color = Color(0.015, 0.025, 0.04, 0.95):
	set(value):
		outline_color = value
		emit_changed()

func make_font(emoji_fallback: Font, bold: bool = false) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = font
	variation.fallbacks = [emoji_fallback] if emoji_fallback else []
	var target_weight: int = maxi(weight, 700) if bold else weight
	variation.variation_opentype = {"wght": target_weight}
	if font:
		# Fuentes estáticas: peso sintético; fuentes variables: eje wght real.
		var weight_axis: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		if not font.get_supported_variation_list().has(weight_axis):
			variation.variation_embolden = maxf(0.0, float(target_weight - font.get_font_weight()) / 300.0)
	variation.spacing_glyph = letter_spacing
	variation.spacing_space = word_spacing
	return variation
