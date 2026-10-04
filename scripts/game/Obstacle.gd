extends Area2D
class_name Obstacle
# ============================================================================
# Obstacle: objeto que NO es una fruta (piedra...).
# ----------------------------------------------------------------------------
# No se destruye al cortarlo y no da recompensa: golpearlo penaliza la
# resistencia (ver GameManager.penalize_resistance). Tiene su propio cooldown
# de impacto para evitar penalizaciones dobles dentro de un mismo corte.
# Movimiento: usa el componente Ballistic (estilo Fruit Ninja).
# ============================================================================

@export var radius: float = 35.0
# Radio mínimo admisible: el setup enmarca el radio del lanzador por abajo.
@export_range(1.0, 100.0, 1.0) var min_radius: float = 24.0
# Cooldown entre golpes de un mismo corte (evita doble penalización).
@export_range(0.01, 2.0, 0.01) var hit_cooldown_duration: float = 0.25
# Velocidad máxima del giro visual (rango simétrico -max..max).
@export_range(0.0, 6.0, 0.5) var max_spin_speed: float = 2.0
# Colores de la piedra dibujada en _draw (editables en el inspector).
@export var stone_body_color: Color = Color(0.45, 0.47, 0.52)
@export var stone_outline_color: Color = Color(0.25, 0.27, 0.31)
@export var stone_highlight_color: Color = Color(0.62, 0.65, 0.7)

var hit_cooldown: float = 0.0
var spin_speed: float = 1.0
var _flash_tween: Tween

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ballistic: Ballistic = $Ballistic

func _ready() -> void:
	spin_speed = randf_range(-max_spin_speed, max_spin_speed)

func setup(p_radius: float) -> void:
	radius = maxf(min_radius, p_radius)
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = radius
	if collision_shape:
		collision_shape.shape = circle_shape
	queue_redraw()

func launch(from_position: Vector2, launch_velocity: Vector2, p_wall_left: float = 0.0, p_wall_right: float = 0.0, p_escape_y: float = 0.0) -> void:
	if ballistic:
		# Gravedad/paredes/escape por defecto: los aporta el componente Ballistic
		# (editables en el inspector). Ver Ballistic.gd (sentinel -1 = por defecto).
		ballistic.launch(from_position, launch_velocity, -1.0, p_wall_left, p_wall_right, p_escape_y)

func _process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta
	rotation += spin_speed * delta

func can_be_hit() -> bool:
	return hit_cooldown <= 0.0

func on_hit() -> void:
	hit_cooldown = hit_cooldown_duration
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(self, "scale", Vector2(1.3, 0.85), 0.06)
	_flash_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# Rompe la piedra (tiró el comodín de probabilidad): la deja invisible y la
# libera. No penaliza ni rompe la racha; el llamador gestiona el feedback.
func break_stone() -> void:
	set_process(false)
	hide()
	collision_shape.set_deferred("disabled", true)
	queue_free()

func _draw() -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-radius * 0.9, radius * 0.3),
		Vector2(-radius * 0.6, -radius * 0.7),
		Vector2(-radius * 0.1, -radius * 0.95),
		Vector2(radius * 0.5, -radius * 0.6),
		Vector2(radius * 0.95, 0.0),
		Vector2(radius * 0.6, radius * 0.8),
		Vector2(-radius * 0.2, radius * 0.9)
	])
	draw_colored_polygon(pts, stone_body_color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), stone_outline_color, 3.0)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.3), radius * 0.18, stone_highlight_color)

func _on_projectile_escaped() -> void:
	queue_free()
