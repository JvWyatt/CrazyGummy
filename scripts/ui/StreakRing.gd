class_name StreakRing
extends Control
# ============================================================================
# StreakRing: anillo circular de la RACHA. Es la mecánica de combo/progresión
# del juego, así que vive separado del panel de estado (dinero, tiempo y
# estamina son barras horizontales en la parte superior).
#
# El aro exterior es el PROGRESO DE LA RACHA: cuánto falta para llegar al
# siguiente nivel. No se pone ningún texto del tipo "llega a X", porque el
# propio aro ya lo comunica.
#
# En el centro vive SIEMPRE el número de gomitas de la racha actual: no se
# sustituye nunca por otro texto. El aviso del multiplicador (cuando sube) lo
# pinta el HUD en su propio panel (RatePanel/MultiplierFlyLabel).
#
# El ritmo de cubos por segundo NO va aquí: es un contador informativo y vive
# en su propio panel del HUD (RatePanel), al lado opuesto.
#
# Solo pinta y anima; los datos llegan desde HUD.gd (GameManager/StatsManager).
# ============================================================================

@export var track_color: Color = Color("#514560")
@export var fill_color: Color = Color("#ff8fa3")
@export var inner_color: Color = Color(1.0, 0.65, 0.78, 0.25)
@export var inner_bg: Color = Color("#211f36")
@export var ring_width: float = 12.0
@export var inner_width: float = 5.0

var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _progress_tween: Tween
var _flash_tween: Tween

@onready var value_label: Label = $Center/ValueLabel
@onready var multiplier_label: Label = $Center/MultiplierLabel

func _ready() -> void:
	# El aviso del multiplicador arranca oculto: solo lo pinta el HUD.
	_show_value()

# --- Datos -----------------------------------------------------------------

# ratio: avance hacia el siguiente nivel (0..1). streak: gomitas de la racha.
func set_streak(ratio: float, streak: int) -> void:
	value_label.text = str(streak)
	_animate_progress(clampf(ratio, 0.0, 1.0))

# Vuelve a mostrar el contador de racha (racha rota).
func _show_value() -> void:
	multiplier_label.visible = false
	value_label.visible = true

# Destello rojo al romperse la racha (al tocar una caramelo endurecido u obstáculo).
func flash_break() -> void:
	_show_value()
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_method(_set_fill, fill_color, Color(1.0, 0.25, 0.25), 0.12)
	_flash_tween.tween_method(_set_fill, Color(1.0, 0.25, 0.25), fill_color, 0.45)

# --- Animación ---------------------------------------------------------------

func _animate_progress(target: float) -> void:
	# La señal streak_changed llega varias veces por segundo: si el objetivo no
	# ha cambiado se deja que la animación termine, si no el aro se quedaria
	# restarting y siempre iría por detrás.
	if is_equal_approx(target, _target_progress) and _progress_tween != null and _progress_tween.is_valid():
		return
	_target_progress = target
	if _progress_tween and _progress_tween.is_valid():
		_progress_tween.kill()
	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_progress_tween.tween_method(_set_display, _display_progress, target, 0.18)

func _set_display(value: float) -> void:
	_display_progress = clampf(value, 0.0, 1.0)
	queue_redraw()

func _set_fill(color: Color) -> void:
	fill_color = color
	queue_redraw()

# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	if radius <= 0.0:
		return
	# Fondo interior para dar contraste al texto central.
	var inner_radius := radius - ring_width - inner_width
	draw_circle(center, inner_radius + inner_width, inner_bg)
	# Aro INTERIOR decorativo: solo enarca la lectura del combo.
	var inner_arc_radius := radius - ring_width - inner_width * 0.5
	draw_arc(center, inner_arc_radius, 0.0, TAU, 64, inner_color, inner_width, true)
	# Aro EXTERIOR: progreso hacia el siguiente nivel de racha.
	var arc_radius := radius - ring_width * 0.5
	draw_arc(center, arc_radius, 0.0, TAU, 64, track_color, ring_width, true)
	if _display_progress > 0.0:
		draw_arc(center, arc_radius, -PI / 2.0, -PI / 2.0 + TAU * _display_progress, 64, fill_color, ring_width, true)
		# Reflejo fino y extremos redondos: acabado gummy sin partículas continuas.
		draw_arc(center, arc_radius - ring_width * 0.22, -PI / 2.0, -PI / 2.0 + TAU * _display_progress, 64, fill_color.lightened(0.45), 1.5, true)
		var end_angle: float = -PI / 2.0 + TAU * _display_progress
		draw_circle(center + Vector2(cos(end_angle), sin(end_angle)) * arc_radius, ring_width * 0.5, fill_color)
