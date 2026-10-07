extends Area2D
class_name Obstacle
signal candy_broken(obstacle: Obstacle)
# ============================================================================
# Obstacle: Caramelo Endurecido. candy/candy son identificadores históricos.
# ----------------------------------------------------------------------------
# No da recompensa: golpearlo penaliza la
# resistencia (ver GameManager.penalize_resistance). Tiene su propio cooldown
# de impacto para evitar penalizaciones dobles dentro de un mismo golpe.
# Los comodines pueden romperlo; el resultado se llama Caramelo Endurecido Roto.
# Movimiento: usa el componente Ballistic.
# ============================================================================

@export var radius: float = 35.0
# Radio mínimo admisible: el setup enmarca el radio del lanzador por abajo.
@export_range(1.0, 100.0, 1.0) var min_radius: float = 24.0
# Cooldown entre golpes de un mismo golpe (evita doble penalización).
@export_range(0.01, 2.0, 0.01) var hit_cooldown_duration: float = 0.25
# Velocidad máxima del giro visual (rango simétrico -max..max).
@export_range(0.0, 6.0, 0.5) var max_spin_speed: float = 2.0
# Colores de la caramelo endurecido dibujada en _draw (editables en el inspector).
@export var candy_body_color: Color = Color("#8b3047")
@export var candy_outline_color: Color = Color("#3b192e")
@export var candy_highlight_color: Color = Color("#efb4a5")

var hit_cooldown: float = 0.0
var spin_speed: float = 1.0
var _flash_tween: Tween
var custom_visual: bool = false

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

# Rompe la caramelo endurecido (tiró el comodín de probabilidad): la deja invisible y la
# libera. No penaliza ni rompe la racha; el llamador gestiona el feedback.
func break_candy() -> void:
	candy_broken.emit(self)
	set_process(false)
	hide()
	collision_shape.set_deferred("disabled", true)
	queue_free()

func _draw() -> void:
	if custom_visual:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * 0.75)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-radius * 0.9, radius * 0.3),
		Vector2(-radius * 0.6, -radius * 0.7),
		Vector2(-radius * 0.1, -radius * 0.95),
		Vector2(radius * 0.5, -radius * 0.6),
		Vector2(radius * 0.95, 0.0),
		Vector2(radius * 0.6, radius * 0.8),
		Vector2(-radius * 0.2, radius * 0.9)
	])
	draw_colored_polygon(pts, candy_body_color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), candy_outline_color, 3.0)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.3), radius * 0.18, candy_highlight_color)
	draw_arc(Vector2.ZERO, radius * 0.68, -0.7, 1.1, 16, candy_highlight_color, radius * 0.16, true)
	draw_polyline(PackedVector2Array([Vector2(-radius * 0.5, 0), Vector2(0, -radius * 0.12), Vector2(radius * 0.18, radius * 0.15), Vector2(radius * 0.6, 0)]), candy_outline_color, 2.0, true)

func _on_projectile_escaped() -> void:
	queue_free()
