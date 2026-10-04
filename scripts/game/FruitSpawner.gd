extends Node2D
class_name FruitSpawner
# ============================================================================
# FruitSpawner: lanza frutas (y obstáculos) desde la PARTE DE ABAJO siguiendo
# una trayectoria parabólica (estilo Fruit Ninja). La cantidad no es un número
# fijo en pantalla: se lanzan X proyectiles por segundo según
# StatsManager.get_final_launch_rate() (mejora "Cosecha Veloz" + prestigio
# "Ritmo Veloz" + comodines). Cada lanzamiento puede ser una fruta (de las
# desbloqueadas en este negocio) o un obstáculo (piedra) que penaliza la
# resistencia al golpearlo.
#
# La lógica de vida/resistencia/daño vive en Fruit.gd / Obstacle.gd; aquí solo
# se decide QUÉ se lanza y con qué velocidad.
# ============================================================================

const FRUIT_SCENE: PackedScene = preload("res://scenes/game/Fruit.tscn")
const OBSTACLE_SCENE: PackedScene = preload("res://scenes/game/Obstacle.tscn")

# Área de juego donde aparece la fruta (la altura de aparición queda justo
# debajo para que la parábola la suba hasta la pantalla).
@export var play_bounds: Rect2 = Rect2(10, 240, 700, 900)

# Parámetros del lanzamiento. La velocidad inicial (y el ángulo respecto a la
# vertical) se eligen al azar dentro de estos rangos para que cada lanzamiento
# sea un poco distinto: los más lentos quedan a media altura y los más rápidos
# se pierden por el borde superior y vuelven a caer. La gravedad y el punto de
# desaparición viven en Ballistic.gd.
# La velocidad inicial subió 10% (x1.1) y la gravedad se ajustó también
# (x1.21, ver Fruit.gd/Obstacle.gd/Ballistic.gd) para que las frutas crucen la
# pantalla un 10% más rápido pero alcancen la MISMA altura y alcance que antes
# (la parábola mantiene su forma; el tiempo de vuelo es ~0.91x).
# Todos estos valores se editan en el inspector de la escena (FruitSpawner.tscn).
@export_range(100.0, 4000.0, 10.0) var launch_speed_min: float = 880.0
@export_range(100.0, 4000.0, 10.0) var launch_speed_max: float = 1760.0
@export_range(0.0, 89.0, 1.0) var launch_angle_max_deg: float = 20.0
# Margen horizontal mínimo desde los bordes y altura de aparición bajo el campo.
@export_range(0.0, 400.0, 1.0) var spawn_margin_x: float = 70.0
@export_range(0.0, 400.0, 1.0) var spawn_offset_below: float = 150.0
# Altura extra por debajo del borde real del viewport donde "escapan" los
# proyectiles (ver _escape_y).
@export_range(0.0, 300.0, 1.0) var escape_offset: float = 60.0
# Fracciones del viewport que definen el campo de juego en pantallas altas.
@export_range(0.0, 1.0, 0.01) var play_bounds_top_fraction: float = 0.1875
@export_range(0.0, 1.0, 0.01) var play_bounds_height_fraction: float = 0.703125

var active_fruits: Array[Fruit] = []
var active_obstacles: Array[Obstacle] = []
var is_spawning_enabled: bool = false
var launch_timer: float = 0.0
var obstacle_timer: float = 0.0

func _ready() -> void:
	call_deferred("_adapt_play_bounds")
	get_viewport().size_changed.connect(func(): call_deferred("_adapt_play_bounds"))
	GameManager.run_started.connect(func():
		clear_all()
		is_spawning_enabled = true
		launch_timer = 0.0
	)
	GameManager.run_ended.connect(func(_summary): clear_all(); is_spawning_enabled = false)
	GameManager.order_completed.connect(func(_order): clear_all())

# El area de juego mantiene las MISMA proporciones que el diseno 720x1280
# (borde 10px, tope al 18.75% del alto, fondo al 89%) pero escala con el alto
# REAL del viewport, para que el campo llene pantallas mas altas como la del
# movil. En el escritorio (720x1280) queda identico a antes.
func _adapt_play_bounds() -> void:
	var vp := get_viewport_rect()
	if vp.size.y <= 0.0:
		return
	play_bounds = Rect2(
		10.0,
		vp.size.y * play_bounds_top_fraction,
		maxf(10.0, vp.size.x - 20.0),
		vp.size.y * play_bounds_height_fraction
	)

func _process(delta: float) -> void:
	if not is_spawning_enabled or not GameManager.is_round_active:
		return
	_cleanup_stale()

	# Acumulador de frecuencia: por cada segundo completo con la frecuencia
	# actual se lanza un proyectil (frecuencia 1.0 = 1 fruta/seg).
	launch_timer += delta * StatsManager.get_final_launch_rate()
	var guard: int = 0
	while launch_timer >= 1.0 and guard < 8:
		launch_timer -= 1.0
		_launch_fruit()
		guard += 1

	# Obstáculos: intervalo ALEATORIO de 1-2 s, independiente de la frecuencia
	# de frutas (ver StatsManager.get_obstacle_interval). No mejora con
	# tiendas/comodines y es impredecible.
	obstacle_timer -= delta
	if obstacle_timer <= 0.0:
		_launch_obstacle()
		obstacle_timer = StatsManager.get_obstacle_interval()

func _cleanup_stale() -> void:
	var i: int = active_fruits.size() - 1
	while i >= 0:
		if not is_instance_valid(active_fruits[i]):
			active_fruits.remove_at(i)
		i -= 1
	var j: int = active_obstacles.size() - 1
	while j >= 0:
		if not is_instance_valid(active_obstacles[j]):
			active_obstacles.remove_at(j)
		j -= 1

func enable_spawning() -> void:
	is_spawning_enabled = true
	launch_timer = 0.0
	obstacle_timer = StatsManager.get_obstacle_interval()

func disable_spawning() -> void:
	is_spawning_enabled = false

func clear_all() -> void:
	for fruit in active_fruits:
		if is_instance_valid(fruit):
			fruit.queue_free()
	active_fruits.clear()
	for obstacle in active_obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	active_obstacles.clear()

func _compute_launch() -> Dictionary:
	var speed: float = randf_range(launch_speed_min, launch_speed_max)
	var angle: float = deg_to_rad(randf_range(0.0, launch_angle_max_deg))
	var dir_x: float = 1.0 if randf() > 0.5 else -1.0
	var from: Vector2 = Vector2(
		randf_range(play_bounds.position.x + spawn_margin_x, play_bounds.end.x - spawn_margin_x),
		play_bounds.end.y + spawn_offset_below
	)
	var vel: Vector2 = Vector2(sin(angle) * speed * dir_x, -cos(angle) * speed)
	return {"from": from, "vel": vel}

func _launch_fruit() -> void:
	var unlocked_ids: Array[String] = GameManager.get_unlocked_fruits_for_current_order()
	if unlocked_ids.is_empty():
		unlocked_ids = ["strawberry"]

	var chosen_id: String = unlocked_ids[randi() % unlocked_ids.size()]
	var fruit_res: FruitData = FruitDatabase.create_fruit_resource(chosen_id)
	var launch: Dictionary = _compute_launch()

	var fruit: Fruit = FRUIT_SCENE.instantiate()
	add_child(fruit)
	fruit.add_to_group("fruits")
	fruit.setup(fruit_res)
	fruit.launch(launch["from"], launch["vel"], play_bounds.position.x, play_bounds.end.x, _escape_y())
	fruit.fruit_destroyed.connect(_on_fruit_destroyed)
	active_fruits.append(fruit)
	# Logro "Combinador Dorado": tener 2 frutas doradas vivas en pantalla a la vez.
	if fruit.is_golden:
		var golden_alive: int = 0
		for f in active_fruits:
			if is_instance_valid(f) and f.is_golden and not f.is_dying:
				golden_alive += 1
		if golden_alive >= 2:
			AchievementManager.set_metric("golden_on_screen_2", 1)

func _launch_obstacle() -> void:
	var launch: Dictionary = _compute_launch()
	var obstacle: Obstacle = OBSTACLE_SCENE.instantiate()
	add_child(obstacle)
	obstacle.add_to_group("obstacles")
	obstacle.setup(randf_range(34.5, 50.6))
	obstacle.launch(launch["from"], launch["vel"], play_bounds.position.x, play_bounds.end.x, _escape_y())
	active_obstacles.append(obstacle)

# Altura a la que los proyectiles "escapan" del juego: un poco por debajo del
# borde inferior REAL del viewport. En pantallas altas (movil 720x1560) este
# valor supera el 1500 fijo de Ballistic; si se dejara fijo, las frutas que
# nacen a play_bounds.end.y + 150 (> 1500) escaparian apenas lanzadas.
func _escape_y() -> float:
	return get_viewport_rect().size.y + escape_offset

func _on_fruit_destroyed(fruit: Fruit) -> void:
	if fruit in active_fruits:
		active_fruits.erase(fruit)
