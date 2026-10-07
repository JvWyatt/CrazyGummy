extends Node2D
# ============================================================================
# SwipeController: detecta el gesto de deslizar el dedo/mouse por la pantalla
# y comprueba si el trazo cruza un cubo. Con resistencia suficiente, aplica
# potencia (con posibilidad de crítico) y consume resistencia por golpe.
# ============================================================================

const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/game/FloatingText.tscn")

@export var trail_lifetime: float = 0.2
@export var min_swipe_distance: float = 12.0

var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO
var trail_points: Array[Dictionary] = [] # {"pos": Vector2, "time": float}
var low_energy_cooldown: float = 0.0
var block_spawner: Node2D
# Estado de "golpe" por proyectil dentro del trazo actual: un objeto solo se
# golpea CUANDO el dedo vuelve a ENTRAR de nuevo en su área (estilo impacto),
# no mientras lo sigues con el dedo. instance_id -> ya golpeado en esta entrada.
var _stroke_hits: Dictionary = {}
# Cubos DESTRUIDAS dentro del trazo actual (para el logro "Cinco en Uno":
# procesar 5 cubos con un solo trazo). Se reinicia al empezar cada arrastre.
var _destroyed_this_stroke: int = 0

@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	z_index = 15
	# Get reference to BlockSpawner
	var parent = get_parent()
	if parent:
		block_spawner = parent.get_node("BlockSpawner")
	if not block_spawner or not is_instance_valid(block_spawner):
		block_spawner = get_tree().root.find_child("BlockSpawner", true, false)

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING or not GameManager.is_round_active:
		if is_dragging:
			_end_drag()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag:
		if is_dragging:
			_process_drag(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()
	elif event is InputEventMouseMotion:
		if is_dragging:
			_process_drag(event.position)

func _start_drag(pos: Vector2) -> void:
	is_dragging = true
	last_touch_pos = pos
	trail_points.clear()
	_stroke_hits.clear()
	_destroyed_this_stroke = 0
	trail_points.append({"pos": pos, "time": trail_lifetime})

func _process_drag(pos: Vector2) -> void:
	if pos.distance_to(last_touch_pos) < min_swipe_distance:
		return

	var start_pos: Vector2 = last_touch_pos
	var end_pos: Vector2 = pos
	last_touch_pos = pos

	trail_points.append({"pos": pos, "time": trail_lifetime})

	# Check for block impactos along segment
	_check_stroke_segment(start_pos, end_pos)

func _end_drag() -> void:
	is_dragging = false
	_stroke_hits.clear()

func _process(delta: float) -> void:
	if low_energy_cooldown > 0.0:
		low_energy_cooldown -= delta

	# Update trail points decay
	var i: int = trail_points.size() - 1
	while i >= 0:
		trail_points[i]["time"] -= delta
		if trail_points[i]["time"] <= 0.0:
			trail_points.remove_at(i)
		i -= 1

	# Update Line2D points
	var points_array: PackedVector2Array = PackedVector2Array()
	for pt in trail_points:
		points_array.append(pt["pos"])
	line_2d.points = points_array

func _check_stroke_segment(seg_a: Vector2, seg_b: Vector2) -> void:
	var tree := get_tree()
	if tree == null:
		return

	var blocks: Array[Node] = tree.get_nodes_in_group("gummy_blocks")
	var hit_any: bool = false

	for node in blocks:
		if not is_instance_valid(node) or not (node is GummyBlock):
			continue
		var block: GummyBlock = node as GummyBlock
		if not block.can_be_hit():
			continue

		var block_pos: Vector2 = block.global_position
		# Radio efectivo: el de RecipeData por la escala del nodo (GummyBlock.tscn usa
		# scale 1.5). Asi el area de golpe coincide con el modelo 3D.
		var radius: float = (block.recipe_data.radius * block.scale.x) if block.recipe_data else 40.0 * block.scale.x
		var fid: int = block.get_instance_id()

		# Comportamiento "impacto": mientras el dedo siga DENTRO del área de la
		# cubo no se cuenta otro golpe; solo se corta de nuevo cuando el dedo
		# VOLVIÓ a entrar tras haber salido del hitbox. Asi no se rompe la cubo
		# por seguirla con el dedo.
		var inside: bool = seg_b.distance_to(block_pos) <= radius
		var hit_fresh: bool = _segment_intersects_circle(seg_a, seg_b, block_pos, radius) and not bool(_stroke_hits.get(fid, false))

		# El dedo salió del área: se prepara la cubo para un nuevo golpe.
		if not inside and not hit_fresh:
			_stroke_hits[fid] = false
			continue

		if hit_fresh:
			_stroke_hits[fid] = true
			# Cada golpe gasta la resistencia que dicta el herramienta equipada
			# (independiente de la cubo: ver StatsManager.get_final_energy_cost).
			var energy_cost: float = StatsManager.get_final_energy_cost()
			if GameManager.consume_energy(energy_cost):
				hit_any = true
				# Tirada de crítico: solo la probabilidad se puede mejorar; el
				# multiplicador viene de StatsManager.get_final_critical_multiplier
				# y los críticos no recuperan resistencia.
				var is_crit: bool = randf() < StatsManager.get_final_critical_chance()
				var dmg: float = StatsManager.get_final_damage() * (StatsManager.get_final_critical_multiplier() if is_crit else 1.0)
				block.take_damage(dmg, is_crit, seg_b - seg_a)
				if is_crit:
					AchievementManager.record_metric("crits", 1)
					GameManager._crits_this_day += 1
					if GameManager._crits_this_day >= 3:
						AchievementManager.set_metric("crits_in_one_day", 3)
					# Logro secreto "Estado Mental": crítico sin haber tocado
					# ninguna caramelo endurecido en lo que va de día.
					if GameManager._candies_hit_this_day == 0:
						AchievementManager.set_flag("esoteric_calm")
				# Logro "Cinco en Uno": 5 cubos destruidas con un mismo trazo.
				if block.is_dying:
					_destroyed_this_stroke += 1
					if _destroyed_this_stroke >= 5:
						AchievementManager.record_metric("multi_break_5", 1)
			else:
				_trigger_low_energy_feedback(block_pos)

	# Los obstáculos no son cubos: no se destruyen y golpearlos penaliza la
	# resistencia (ver GameManager.penalize_resistance).
	var obstacles: Array[Node] = tree.get_nodes_in_group("obstacles")
	for node in obstacles:
		if not is_instance_valid(node) or not (node is Obstacle):
			continue
		var obstacle: Obstacle = node as Obstacle
		if not obstacle.can_be_hit():
			continue
		var oid: int = obstacle.get_instance_id()
		var o_inside: bool = seg_b.distance_to(obstacle.global_position) <= obstacle.radius
		var o_hit_fresh: bool = _segment_intersects_circle(seg_a, seg_b, obstacle.global_position, obstacle.radius) and not bool(_stroke_hits.get(oid, false))
		if not o_inside and not o_hit_fresh:
			_stroke_hits[oid] = false
			continue
		if o_hit_fresh:
			_stroke_hits[oid] = true
			obstacle.on_hit()
			hit_any = true
			AchievementManager.record_metric("candies_hit", 1)
			GameManager._candies_hit_this_day += 1

			# Comodín de probabilidad: ¿se ROMPE la caramelo endurecido? (desaparece, no
			# penaliza resistencia ni rompe la racha).
			if StatsManager.get_candy_break_chance() > 0.0 and randf() < StatsManager.get_candy_break_chance():
				SoundManager.play_stroke()
				UiTheme.dust_burst(get_parent(), obstacle.global_position, Color(0.5, 0.52, 0.57))
				obstacle.break_candy()
				_spawn_obstacle_broken_feedback(obstacle.global_position + Vector2(0, -30))
				continue

			# Comodín raro "primera caramelo endurecido del día gratis": la primera caramelo endurecido
			# del día NO quita resistencia (pero sigue rompiendo la racha).
			var free_candy: bool = (
				StatsManager.has_first_candy_free()
				and not GameManager._first_candy_consumed_this_day
			)
			if free_candy:
				GameManager._first_candy_consumed_this_day = true

			# La caramelo endurecido SIEMPRE rompe la racha (incluso con comodín mítico).
			GameManager.break_streak()

			if free_candy:
				SoundManager.play_thud()
				_spawn_obstacle_free_feedback(obstacle.global_position + Vector2(0, -30))
			else:
				var penalty: float = GameManager.penalize_resistance()
				SoundManager.play_thud()
				_spawn_obstacle_feedback(obstacle.global_position + Vector2(0, -30), penalty)

	if hit_any:
		SoundManager.play_stroke()

func _segment_intersects_circle(p1: Vector2, p2: Vector2, center: Vector2, radius: float) -> bool:
	var d: Vector2 = p2 - p1
	var len_sq: float = d.length_squared()
	if len_sq == 0.0:
		return p1.distance_to(center) <= radius

	var t: float = clamp((center - p1).dot(d) / len_sq, 0.0, 1.0)
	var closest_point: Vector2 = p1 + t * d
	return closest_point.distance_to(center) <= radius

func _trigger_low_energy_feedback(pos: Vector2) -> void:
	if low_energy_cooldown > 0.0:
		return
	low_energy_cooldown = 0.5
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.position = pos + Vector2(0, -30)
	get_parent().add_child(ft)
	ft.setup("¡⚡ SIN RESISTENCIA!", Color(1.0, 0.4, 0.2), 1.2, 0.6)

func _spawn_obstacle_feedback(pos: Vector2, penalty: float) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.position = pos
	get_parent().add_child(ft)
	var penalty_text: String = "¡CARAMELO ENDURECIDO!\n-%s ⚡" % UiTheme.format_stat(penalty)
	ft.setup(penalty_text, Color(0.75, 0.3, 0.3), 1.2, 0.6)

func _spawn_obstacle_free_feedback(pos: Vector2) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.position = pos
	get_parent().add_child(ft)
	ft.setup("🛡️ CARAMELO BLOQUEADO", Color(0.3, 0.8, 1.0), 1.2, 0.6)

func _spawn_obstacle_broken_feedback(pos: Vector2) -> void:
	var ft = FLOATING_TEXT_SCENE.instantiate()
	ft.position = pos
	get_parent().add_child(ft)
	ft.setup("💥 CARAMELO ENDURECIDO\nROTO", Color(0.6, 0.7, 0.8), 1.2, 0.6)
