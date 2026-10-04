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
# En el centro vive SIEMPRE el número de frutas de la racha actual. El
# multiplicador NO es texto permanente: aparece en el MISMO sitio durante un
# instante (con una pequeña animación) solo cuando se activa o sube, y luego
# desaparece dejando el contador otra vez a la vista.
#
# El ritmo de frutas por segundo NO va aquí: es un contador informativo y vive
# en su propio panel del HUD (RatePanel), al lado opuesto.
#
# Solo pinta y anima; los datos llegan desde HUD.gd (GameManager/StatsManager).
# ============================================================================

@export var track_color: Color = Color(0.16, 0.2, 0.32, 1)
@export var fill_color: Color = Color(1.0, 0.55, 0.2, 1)
@export var inner_color: Color = Color(1.0, 0.55, 0.2, 0.35)
@export var inner_bg: Color = Color(0.055, 0.071, 0.125, 0.95)
@export var ring_width: float = 12.0
@export var inner_width: float = 5.0

var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _progress_tween: Tween
var _flash_tween: Tween
var _multiplier_tween: Tween

# Cuánto permanece visible el multiplicador cuando se activa o aumenta.
@export var multiplier_hold: float = 1.3

@onready var value_label: Label = $Center/ValueLabel
@onready var multiplier_label: Label = $Center/MultiplierLabel

func _ready() -> void:
	# El multiplicador arranca oculto: solo aparece cuando toca.
	_show_value()

# --- Datos -----------------------------------------------------------------

# ratio: avance hacia el siguiente nivel (0..1). streak: frutas de la racha.
# El multiplicador NO se escribe aquí a propósito: lo controla show_multiplier()
# para que nunca quede fijo en pantalla.
func set_streak(ratio: float, streak: int) -> void:
	value_label.text = str(streak)
	_animate_progress(clampf(ratio, 0.0, 1.0))

# Aviso momentáneo del multiplicador: sustituye al contador en el centro, hace
# un pequeño rebote, espera y devuelve el control al número de la racha.
# Se llama solo cuando el multiplicador se activa o sube (ver HUD.gd).
func show_multiplier(multiplier: float) -> void:
	multiplier_label.text = "x" + UiTheme.format_stat(multiplier)
	if _multiplier_tween and _multiplier_tween.is_valid():
		_multiplier_tween.kill()

	multiplier_label.visible = true
	multiplier_label.modulate = Color(1, 1, 1, 1)
	# Pivote al centro para que el rebote crezca sobre sí mismo y no se deslice.
	multiplier_label.pivot_offset = multiplier_label.size * 0.5
	multiplier_label.scale = Vector2(0.55, 0.55)
	value_label.visible = false

	_multiplier_tween = create_tween()
	_multiplier_tween.set_parallel(true)
	# Rebote de entrada (ligeramente por encima de 1 para que "explote").
	_multiplier_tween.tween_property(multiplier_label, "scale", Vector2(1.18, 1.18), 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_multiplier_tween.tween_property(multiplier_label, "scale", Vector2(1.0, 1.0), 0.16)\
		.set_delay(0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_multiplier_tween.tween_property(multiplier_label, "modulate:a", 0.0, 0.28)\
		.set_delay(multiplier_hold).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_multiplier_tween.chain().tween_callback(_show_value)

# Vuelve a mostrar el contador de racha (fin del aviso o racha rota).
func _show_value() -> void:
	multiplier_label.visible = false
	value_label.visible = true

# Destello rojo al romperse la racha (al tocar una piedra u obstáculo).
func flash_break() -> void:
	if _multiplier_tween and _multiplier_tween.is_valid():
		_multiplier_tween.kill()
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
