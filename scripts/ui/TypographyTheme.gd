@tool
class_name TypographyTheme
extends Theme
## Genera las variantes de Control desde Title, Subtitle y Body.
## Se ejecuta también en el editor: cambiar un rol actualiza todas las escenas.

var _updating: bool = false

@export_group("Tipografía global")
@export var title: TypographyStyle:
	set(value):
		_watch_style(title, value)
		title = value
		refresh_typography()
@export var subtitle: TypographyStyle:
	set(value):
		_watch_style(subtitle, value)
		subtitle = value
		refresh_typography()
@export var body: TypographyStyle:
	set(value):
		_watch_style(body, value)
		body = value
		refresh_typography()
@export var emoji_fallback: Font:
	set(value):
		emoji_fallback = value
		refresh_typography()

func _watch_style(previous: TypographyStyle, next: TypographyStyle) -> void:
	if previous and previous.changed.is_connected(refresh_typography):
		previous.changed.disconnect(refresh_typography)
	if next and not next.changed.is_connected(refresh_typography):
		next.changed.connect(refresh_typography)

func refresh_typography() -> void:
	if _updating or not title or not subtitle or not body:
		return
	_updating = true
	var was_blocked: bool = is_blocking_signals()
	set_block_signals(true)
	var title_font := title.make_font(emoji_fallback)
	var subtitle_font := subtitle.make_font(emoji_fallback)
	var body_font := body.make_font(emoji_fallback)
	default_font = body_font
	default_font_size = body.font_size
	_apply_style("Label", body, body_font)
	_apply_style("Button", body, body_font)
	_apply_style("TabBar", body, body_font)
	set_font("title_font", "Window", title_font)
	set_font_size("title_font_size", "Window", title.font_size)
	_apply_style("TooltipLabel", body, body_font)
	for variant in ["Title", "TitleLabel"]:
		set_type_variation(variant, "Label")
		_apply_style(variant, title, title_font)
	for variant in ["Subtitle", "SubtitleLabel", "CardTitle", "ValueLabel", "JokerTitle"]:
		set_type_variation(variant, "Label")
		_apply_style(variant, subtitle, subtitle_font)
	for variant in ["Body", "CaptionLabel", "JokerDescription"]:
		set_type_variation(variant, "Label")
		_apply_style(variant, body, body_font)
	# Los emojis son arte, pero usan la misma fuente/fallback global de Body.
	set_type_variation("IconLabel", "Label")
	_apply_style("IconLabel", body, body_font)
	set_font_size("font_size", "IconLabel", get_constant("icon_size", "TypographyMetrics") if has_constant("icon_size", "TypographyMetrics") else 32)
	for variant in ["PrimaryButton", "DangerButton"]:
		set_type_variation(variant, "Button")
		_apply_style(variant, body, body_font, false)
	# Contraste y estados de botones siguen centralizados en el Theme.
	set_font("font", "TabContainer", body_font)
	set_font_size("font_size", "TabContainer", body.font_size)
	for rich_type in ["RichTextLabel", "BodyRichText"]:
		if rich_type != "RichTextLabel":
			set_type_variation(rich_type, "RichTextLabel")
		for key in ["normal_font", "italics_font", "mono_font"]:
			set_font(key, rich_type, body_font)
		for key in ["bold_font", "bold_italics_font"]:
			set_font(key, rich_type, body.make_font(emoji_fallback, true))
		for key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
			set_font_size(key, rich_type, body.font_size)
		set_color("default_color", rich_type, body.color)
		set_constant("line_separation", rich_type, body.line_spacing)
	_updating = false
	set_block_signals(was_blocked)
	emit_changed()

func _apply_style(type_name: String, style: TypographyStyle, style_font: Font, apply_color: bool = true) -> void:
	set_font("font", type_name, style_font)
	set_font_size("font_size", type_name, style.font_size)
	if apply_color:
		set_color("font_color", type_name, style.color)
	set_color("font_outline_color", type_name, style.outline_color)
	set_constant("outline_size", type_name, style.outline_size)
	set_constant("line_spacing", type_name, style.line_spacing)
