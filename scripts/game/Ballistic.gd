extends Node
class_name Ballistic
# ============================================================================
# Ballistic: componente de movimiento parab\u00f3lico (estilo Fruit Ninja).
# ----------------------------------------------------------------------------
# Se usa como hijo de frutas y obst\u00e1culos. Es puramente mec\u00e1nico: no
# sabe nada de frutas, obst\u00e1culos, vida, resistencia ni da\u00f1o.
# Los proyectiles REBOTAN en las paredes laterales (wall_left/wall_right) y
# solo salen del juego al caer por debajo de escape_y (entonces llama a
# _on_projectile_escaped() en su padre).
# ============================================================================

var velocity: Vector2 = Vector2.ZERO
# Constantes del lanzamiento, compartidas por frutas y obstáculos.
# Gravedad x1.21 (960 - 1161.6): junto con la velocidad x1.1 de FruitSpawner,
# los proyectiles van 10% más rápido pero conservan el mismo alcance/altura.
const DEFAULT_GRAVITY: float = 1161.6
const DEFAULT_WALL_LEFT: float = 10.0
const DEFAULT_WALL_RIGHT: float = 710.0
const DEFAULT_ESCAPE_Y: float = 1500.0

# Valores POR DEFECTO editables en el inspector de cada escena (Fruit.tscn y
# Obstacle.tscn). Al lanzar con centinelas (gravedad -1, paredes/escape 0) se
# usan estos valores exportados; si el llamador pasa valores reales, mandan los
# suyos (ver FruitSpawner, que pasa las paredes y la altura de escape REALES).
@export_range(0.0, 5000.0, 0.1) var gravity_default: float = DEFAULT_GRAVITY
@export_range(0.0, 2000.0, 1.0) var wall_left_default: float = DEFAULT_WALL_LEFT
@export_range(0.0, 2000.0, 1.0) var wall_right_default: float = DEFAULT_WALL_RIGHT
@export_range(0.0, 4000.0, 1.0) var escape_y_default: float = DEFAULT_ESCAPE_Y

var gravity: float = DEFAULT_GRAVITY
var escape_y: float = DEFAULT_ESCAPE_Y
var wall_left: float = DEFAULT_WALL_LEFT
var wall_right: float = DEFAULT_WALL_RIGHT
var is_active: bool = false

# Lanza desde from_position con una velocidad inicial y gravedad determinadas.
# Solo funciona si el padre es un Node2D (se desplaza al padre).
# p_escape_y: altura (px) por debajo de la cual el proyectil "escapa". Debe ir
# acorde al alto REAL del viewport: un valor fijo (p.ej. 1500) elimina las
# frutas al instante en pantallas más altas que 720x1280 (la fruta nace a
# play_bounds.end.y + 150, que en pantalla alta supera 1500).
func launch(from_position: Vector2, launch_velocity: Vector2, p_gravity: float = -1.0, p_wall_left: float = 0.0, p_wall_right: float = 0.0, p_escape_y: float = 0.0) -> void:
	var parent := get_parent()
	if parent is Node2D:
		parent.position = from_position
	velocity = launch_velocity
	# Los centinelas (-1 / 0) resuelven a los valores exportados del inspector.
	gravity = gravity_default if p_gravity < 0.0 else p_gravity
	wall_left = wall_left_default if p_wall_left <= 0.0 else p_wall_left
	wall_right = wall_right_default if p_wall_right <= 0.0 else p_wall_right
	escape_y = escape_y_default if p_escape_y <= 0.0 else p_escape_y
	is_active = true

func stop() -> void:
	is_active = false

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	var parent := get_parent()
	if not (parent is Node2D):
		is_active = false
		return

	velocity.y += gravity * delta
	parent.position += velocity * delta
	var p: Vector2 = parent.position

	# Rebote en las paredes laterales (solo si viene hacia la pared, para no
	# quedarse atrapado dentro del borde). La vertical no cambia.
	if p.x < wall_left:
		if velocity.x < 0.0:
			parent.position.x = wall_left + (wall_left - p.x)
			velocity.x = -velocity.x
	elif p.x > wall_right:
		if velocity.x > 0.0:
			parent.position.x = wall_right - (p.x - wall_right)
			velocity.x = -velocity.x

	# Solo abandona el juego al caer por debajo (nunca por los laterales).
	if parent.position.y > escape_y:
		is_active = false
		if parent.has_method("_on_projectile_escaped"):
			parent._on_projectile_escaped()
