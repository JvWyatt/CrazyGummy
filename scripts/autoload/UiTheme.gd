extends Node
# ============================================================================
# UiTheme: paleta central + helpers + micro-interacciones para la interfaz.
# ----------------------------------------------------------------------------
# El TEMA global vive AHORA en un archivo editable visualmente:
#   res://themes/ui01_theme.tres
# Ahí se cambian colores, bordes, fuentes y estilos de botones/paneles/barras
# desde el inspector (también expone tipos personalizados "PrimaryButton",
# "DangerButton", "ModalPanel", "Card" y el grupo de colores "Palette").
# Este script solo CARGA ese theme y aporta helpers para la UI generada por
# código. Si el .tres falta, _build_fallback_theme() replica el estilo por
# código para que el juego nunca se quede sin tema.
# ============================================================================

const THEME_PATH: String = "res://themes/ui01_theme.tres"

# Colores de la paleta central (usados por code-hints como ConfirmDialog).
# Por defecto replican el theme; siempre consulta _palette_color() si quieres
# que el valor editable del .tres sea el que manda.
const COLOR_BG: Color = Color(0.055, 0.071, 0.125)
const COLOR_PANEL: Color = Color(0.078, 0.102, 0.18)
const COLOR_ROW: Color = Color(0.102, 0.129, 0.22)
const COLOR_BORDER: Color = Color(0.196, 0.251, 0.42)
const COLOR_ACCENT: Color = Color(1.0, 0.835, 0.29)
const COLOR_TEXT: Color = Color(0.9, 0.93, 0.98)
const COLOR_TEXT_DIM: Color = Color(0.65, 0.72, 0.82)
const COLOR_SUCCESS: Color = Color(0.31, 0.84, 0.62)
const COLOR_DANGER: Color = Color(1.0, 0.35, 0.37)


func _ready() -> void:
	_install_theme()

# ---------------------------------------------------------------------------
# Tema global
# ---------------------------------------------------------------------------

func _install_theme() -> void:
	var theme := load(THEME_PATH) as Theme
	if theme == null:
		push_warning("UiTheme: no se pudo cargar %s; usando tema de respaldo por código." % THEME_PATH)
		theme = _build_fallback_theme()
	if theme.has_method("refresh_typography"):
		theme.refresh_typography()
	get_tree().root.theme = theme

# Devuelve el Theme activo (o null si aún no está aplicado).
func _current_theme() -> Theme:
	return get_tree().root.theme as Theme if get_tree() and (get_tree().root.theme as Theme) else null

# Lee un color de la paleta editable del theme ("Palette/<clave>") con
# alternativa en código si el .tres no lo define.
func _palette_color(key: String, fallback: Color) -> Color:
	var theme := _current_theme()
	if theme and theme.has_color(key, "Palette"):
		return theme.get_color(key, "Palette")
	return fallback

# ---------------------------------------------------------------------------
# Helpers para la UI generada por código
# ---------------------------------------------------------------------------

# Aplica un estilo de botón destacado según la variante: "primary" (dorado,
# usado p.ej. para JUGAR) o "danger" (rojo, usado p.ej. para REINICIAR).
# Los estilos vienen del theme (tipos personalizados PrimaryButton/DangerButton).
func apply_button_style(button: Button, variant: String = "primary") -> void:
	if button == null:
		return
	match variant:
		"primary":
			_apply_theme_button(
				button,
				"PrimaryButton",
				[Color(0.98, 0.78, 0.22), Color(1, 0.95, 0.62), 6],
				[Color(1, 0.86, 0.38), Color(1, 0.97, 0.72), 7],
				[Color(0.8, 0.6, 0.12), Color(0.95, 0.75, 0.25), 3],
				Color(0.32, 0.2, 0.04))
		"danger":
			_apply_theme_button(
				button,
				"DangerButton",
				[Color(0.42, 0.14, 0.16), Color(0.75, 0.3, 0.32), 4],
				[Color(0.52, 0.2, 0.22), Color(0.9, 0.4, 0.42), 5],
				[Color(0.3, 0.08, 0.1), Color(0.6, 0.2, 0.22), 1],
				Color(1.0, 0.85, 0.85))
		_:
			return

# Aplica los styleboxes/colores de un tipo personalizado del theme. Si el
# .tres no define ese tipo, construye inline con los mismos valores.
func _apply_theme_button(button: Button, theme_type: String, normal: Array, hover: Array, pressed: Array, font_color: Color) -> void:
	var theme := _current_theme()
	var states: Array[String] = ["normal", "hover", "pressed", "hover_pressed"]
	var fallback_by_state := {"normal": normal, "hover": hover, "pressed": pressed, "hover_pressed": pressed}
	if theme and theme.has_stylebox("normal", theme_type):
		for state in states:
			var sb := theme.get_stylebox(state, theme_type)
			if sb:
				button.add_theme_stylebox_override(state, sb)
		if theme.has_stylebox("focus", theme_type):
			button.add_theme_stylebox_override("focus", theme.get_stylebox("focus", theme_type))
	else:
		for state in states:
			var vals: Array = fallback_by_state[state]
			button.add_theme_stylebox_override(state, _pill_style(vals[0], vals[1], int(vals[2])))
	if theme and theme.has_color("font_color", theme_type):
		button.add_theme_color_override("font_color", theme.get_color("font_color", theme_type))
		button.add_theme_color_override("font_hover_color", theme.get_color("font_hover_color", theme_type))
		button.add_theme_color_override("font_pressed_color", theme.get_color("font_pressed_color", theme_type))
	else:
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", font_color)
		button.add_theme_color_override("font_pressed_color", font_color)

# Estilo de tarjeta modal: fondo oscuro con borde brillante y sombra grande
# (p.ej. el panel de ajustes del menú principal). Proviene del tipo
# personalizado "ModalPanel" del theme (con respaldo en código).
func apply_modal_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	var theme := _current_theme()
	var style: StyleBox = null
	if theme and theme.has_stylebox("panel", "ModalPanel"):
		style = theme.get_stylebox("panel", "ModalPanel")
	if style == null:
		style = _box_style(Color(0.09, 0.11, 0.19, 0.98), Color(0.45, 0.55, 0.85), 18, 10)
		style.content_margin_left = 28
		style.content_margin_right = 28
		style.content_margin_top = 24
		style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)

# Escala el botón al pasar el ratón encima para dar feedback táctil de
# interacción. Recalcula el pivot si el tamaño cambia.
func add_hover_scale(button: Control, amount: float = 0.0) -> void:
	if button == null:
		return
	var hover_scale: float = amount if amount > 0.0 else _motion_value("hover_scale_percent", 103) / 100.0
	var duration: float = _motion_value("hover_duration_ms", 120) / 1000.0
	button.pivot_offset = button.size * 0.5
	button.resized.connect(func():
		button.pivot_offset = button.size * 0.5
	)
	button.mouse_entered.connect(func():
		var tween := _replace_motion(button, &"hover_tween")
		tween.tween_property(button, "scale", Vector2.ONE * hover_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	button.mouse_exited.connect(func():
		var tween := _replace_motion(button, &"hover_tween")
		tween.tween_property(button, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

# Tarjeta/panel genérico para la UI generada por código. Si cambias el borde o
# el fondo por defecto, aquí se lee la paleta editable del theme.
func card_style(border_color: Color = COLOR_BORDER, bg_color: Color = COLOR_ROW) -> StyleBoxFlat:
	var theme := _current_theme()
	if theme and theme.has_stylebox("panel", "Card"):
		var editable_style := theme.get_stylebox("panel", "Card").duplicate() as StyleBoxFlat
		if border_color != COLOR_BORDER:
			editable_style.border_color = border_color
		if bg_color != COLOR_ROW:
			editable_style.bg_color = bg_color
		return editable_style
	var style := _box_style(bg_color, border_color, 14, 6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

# Da un estilo de tarjeta consistente a un PanelContainer. Con los colores por
# defecto usa el tipo personalizado "Card" del theme (editable); con un borde o
# fondo propio (p.ej. rareza de comodín) construye uno inline.
func apply_card(panel: PanelContainer, border_color: Color = COLOR_BORDER, bg_color: Color = COLOR_ROW) -> void:
	if panel == null:
		return
	if border_color == COLOR_BORDER and bg_color == COLOR_ROW:
		var theme := _current_theme()
		if theme and theme.has_stylebox("panel", "Card"):
			panel.add_theme_stylebox_override("panel", theme.get_stylebox("panel", "Card"))
			return
	panel.add_theme_stylebox_override("panel", card_style(border_color, bg_color))

# Redondeo exclusivo de presentación: siempre un decimal, incluida la parte .0.
# El texto devuelto nunca se usa como entrada de los cálculos de estadísticas.
func format_stat(value: float) -> String:
	return "%.1f" % snappedf(value, 0.1)

## Precisión visual del jackpot: no participa en los cálculos del juego.
func format_jackpot(value: float, permanent: bool) -> String:
	return ("%.2f" if permanent else "%.3f") % value

# Dinero con un decimal y sufijos para cantidades grandes (1250 -> "1.3K").
func format_money(value: float) -> String:
	var v: float = float(value)
	var suffixes: Array = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp"]
	var idx: int = 0
	while v >= 1000.0 and idx < suffixes.size() - 1:
		v /= 1000.0
		idx += 1
	return format_stat(v) + (suffixes[idx] if idx > 0 else "")

# Entrada suave de modales/paneles: fade + escala con rebote suave.
func pop_in(control: Control) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.modulate.a = 0.0
	control.scale = Vector2.ONE * _motion_value("pop_start_percent", 96) / 100.0
	var tween := _replace_motion(control, &"pop_tween")
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, _motion_value("pop_fade_ms", 180) / 1000.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, _motion_value("pop_scale_ms", 240) / 1000.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Pulso de escala en una etiqueta (p.ej. al subir el dinero).
func pulse_label(label: Control, amount: float = 0.0) -> void:
	if label == null:
		return
	label.pivot_offset = label.size * 0.5
	var peak: float = amount if amount > 0.0 else _motion_value("pulse_peak_percent", 108) / 100.0
	var tween := _replace_motion(label, &"pulse_tween")
	tween.tween_property(label, "scale", Vector2.ONE * peak, _motion_value("pulse_in_ms", 90) / 1000.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, _motion_value("pulse_out_ms", 180) / 1000.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _motion_value(key: StringName, fallback: int) -> float:
	var theme := _current_theme()
	return float(theme.get_constant(key, "Motion")) if theme and theme.has_constant(key, "Motion") else float(fallback)

func _replace_motion(control: Control, key: StringName) -> Tween:
	var previous: Tween = control.get_meta(key) as Tween if control.has_meta(key) else null
	if previous and previous.is_valid():
		previous.kill()
	var tween := control.create_tween()
	control.set_meta(key, tween)
	return tween

# Ráfaga de confeti para momentos de victoria (recibe el panel contenedor y
# una posición en coordenadas locales del panel).
func confetti_burst(parent: Node, local_position: Vector2, amount: int = 90) -> void:
	if parent == null:
		return
	var particles := CPUParticles2D.new()
	particles.position = local_position
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = 1.4
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.spread = 160.0
	particles.gravity = Vector2(0, 360)
	particles.initial_velocity_min = 260.0
	particles.initial_velocity_max = 460.0
	particles.angular_velocity_min = -320.0
	particles.angular_velocity_max = 320.0
	particles.damping_min = 40.0
	particles.damping_max = 160.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.835, 0.29),
		Color(0.31, 0.84, 0.62),
		Color(0.3, 0.7, 1.0),
		Color(1.0, 0.45, 0.55),
		Color(0.85, 0.5, 1.0)
	])
	particles.color_ramp = ramp
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0, 1), 0, 0, 0, 0)
	scale_curve.add_point(Vector2(1, 0.4), 0, 0, 0, 0)
	particles.scale_amount_curve = scale_curve
	parent.add_child(particles)
	_cleanup_confetti_later(particles)

func _cleanup_confetti_later(particles: Node) -> void:
	await get_tree().create_timer(2.4).timeout
	if is_instance_valid(particles):
		particles.queue_free()

# Lluvia de confeti DORADO durante la fase BONUS (al cumplir la cuota del
# día). A diferencia de confetti_burst(), que explota desde un punto, aquí las
# partículas caen desde una franja ancha de la pantalla: es un aviso de que el
# objetivo del día se ha cumplido y que a partir de ahora el dinero es ganancia
# extra. La franja inicial ocupa el fondo superior para verse desde el primer
# instante, sin invadir la UI. Main la elimina al terminar la ronda o salir.
func golden_confetti(parent: Node, viewport_size: Vector2) -> void:
	if parent == null:
		return
	var particles := CPUParticles2D.new()
	particles.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.3)
	particles.emitting = true
	particles.amount = 72
	particles.lifetime = 3.2
	particles.local_coords = false
	particles.fixed_fps = 30
	particles.preprocess = 1.0
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.3)
	particles.direction = Vector2(0, 1)
	particles.spread = 18.0
	particles.gravity = Vector2(0, 70)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 180.0
	particles.angular_velocity_min = -110.0
	particles.angular_velocity_max = 110.0
	particles.damping_min = 6.0
	particles.damping_max = 18.0
	particles.scale_amount_min = 0.7
	particles.scale_amount_max = 1.3
	# Confeti rectangular: más legible que los puntos de un píxel por defecto.
	var image := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(image)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.95, 0.72, 0.95),
		Color(1.0, 0.835, 0.29, 1.0),
		Color(0.98, 0.7, 0.22, 0.9),
		Color(0.95, 0.65, 0.2, 0.0),
	])
	particles.color_ramp = ramp
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0, 0.6), 0, 0, 0, 0)
	scale_curve.add_point(Vector2(1, 1.0), 0, 0, 0, 0)
	particles.scale_amount_curve = scale_curve
	parent.add_child(particles)

# Ráfaga de partículas de un solo color (p. ej. polvo gris al romper una
# piedra). Se autolimpia solo.
func dust_burst(parent: Node, global_position: Vector2, color: Color, amount: int = 24) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var particles := CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.spread = 180.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 320.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = color
	parent.add_child(particles)
	_cleanup_confetti_later(particles)

# ---------------------------------------------------------------------------
# Respaldo en código (solo si falla la carga de themes/ui01_theme.tres)
# ---------------------------------------------------------------------------

func _pill_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var sb := _box_style(bg, border, 18, shadow_size)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _box_style(bg: Color, border: Color, radius: int, shadow_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = shadow_size
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _build_fallback_theme() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("normal", "Button", _pill_style(Color(0.16, 0.2, 0.34), Color(0.45, 0.55, 0.85, 0.9), 3))
	theme.set_stylebox("hover", "Button", _pill_style(Color(0.23, 0.3, 0.5), Color(0.72, 0.8, 0.97, 1.0), 4))
	theme.set_stylebox("pressed", "Button", _pill_style(Color(0.085, 0.11, 0.2), Color(0.95, 0.78, 0.32, 1.0), 1))
	theme.set_stylebox("disabled", "Button", _pill_style(Color(0.1, 0.12, 0.17), Color(0.18, 0.21, 0.3, 1.0), 0))
	var btn_focus := _pill_style(Color(0, 0, 0, 0), Color(0.3, 0.6, 1.0, 0.9), 0)
	btn_focus.border_width_left = 2
	btn_focus.border_width_top = 2
	btn_focus.border_width_right = 2
	btn_focus.border_width_bottom = 2
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_stylebox("hover_pressed", "Button", theme.get_stylebox("pressed", "Button"))
	theme.set_color("font_color", "Button", Color(0.94, 0.96, 1.0))
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.96, 0.78))
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.86, 0.4))
	theme.set_color("font_disabled_color", "Button", Color(0.45, 0.5, 0.6, 0.7))
	theme.set_constant("separation", "Button", 0)
	theme.set_stylebox("panel", "PanelContainer", _box_style(COLOR_PANEL, Color(0.28, 0.36, 0.58), 14, 8))
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font_size("font_size", "Label", 18)
	return theme
