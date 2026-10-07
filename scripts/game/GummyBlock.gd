extends Area2D
class_name GummyBlock
# ============================================================================
# GummyBlock: cubo de gelatina golpeable. Controla su dureza
# (current_hp/max_hp), los golpes y la recompensa al producir una gomita.
# Jackpot es la recompensa especial. Ballistic gestiona la trayectoria.
# Los valores de balance (vida, recompensa, probabilidad de jackpot) NO se
# definen aquí: vienen de RecipeData/RecipeDatabase.gd.
# ============================================================================

signal block_destroyed(block_instance: GummyBlock)
signal block_hit

const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/game/FloatingText.tscn")
const GELATIN_SPLASH_SCENE: PackedScene = preload("res://scenes/game/GelatinSplash.tscn")

@export var recipe_data: RecipeData

# Parámetros de BALANCE del golpe, editables en el inspector (GummyBlock.tscn).
# Cooldown entre daños de un mismo golpe (evita golpes dobles por frame).
@export_range(0.01, 1.0, 0.005) var hit_cooldown_duration: float = 0.08
# Velocidad máxima del giro visual al lanzar (rango simétrico -max..max).
@export_range(0.0, 10.0, 0.5) var max_spin_speed: float = 3.5
# El Jackpot de una gomita dorada multiplica su recompensa por este factor.
@export_range(1.0, 5.0, 0.1) var golden_reward_multiplier: float = 2.0
# Desplazamiento aleatorio de los textos flotantes al procesar (px).
@export_range(0.0, 60.0, 1.0) var text_offset_x: float = 15.0
@export_range(0.0, 120.0, 1.0) var text_offset_y: float = 20.0
# Gotas de gelatina por golpe: base + radio * splash_per_radius (clamped en GelatinSplash).
@export_range(0.0, 40.0, 1.0) var splash_base_amount: float = 14.0
@export_range(0.0, 1.0, 0.05) var splash_per_radius: float = 0.25

var current_hp: float = 10.0
var max_hp: float = 10.0
var is_dying: bool = false
var hit_cooldown: float = 0.0
var is_golden: bool = false
var spin_speed: float = 1.0
var last_stroke_dir: Vector2 = Vector2.RIGHT
# La presentación 3D puede sustituir únicamente la salpicadura visual.
var custom_hit_particles: bool = false

@onready var visual_node: BlockSpriteFallback = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel
@onready var ballistic: Ballistic = $Ballistic

func _ready() -> void:
	spin_speed = randf_range(-max_spin_speed, max_spin_speed)

func setup(p_recipe_data: RecipeData) -> void:
	recipe_data = p_recipe_data
	is_golden = randf() < StatsManager.get_golden_gummy_chance()
	max_hp = recipe_data.max_hp
	current_hp = max_hp

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = recipe_data.radius
	if collision_shape:
		collision_shape.shape = circle_shape

	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		health_bar.size = Vector2(recipe_data.radius * 2.2, 10.0)
		health_bar.position = Vector2(-recipe_data.radius * 1.1, -recipe_data.radius - 20.0)

	if name_label:
		name_label.text = ("✨ " if is_golden else "🧊 ") + RecipeVisualLibrary.cube_name(recipe_data.id)
		name_label.position = Vector2(-80, -recipe_data.radius - 46.0)

	queue_redraw()
	if visual_node and is_instance_valid(visual_node):
		visual_node.refresh_visual()

# Lanza la cubo desde from_position con una velocidad inicial (parábola).
# Las paredes laterales determinan dónde rebota antes de caer.
func launch(from_position: Vector2, launch_velocity: Vector2, p_wall_left: float = 0.0, p_wall_right: float = 0.0, p_escape_y: float = 0.0) -> void:
	if ballistic:
		# Gravedad/paredes/escape por defecto: los aporta el componente Ballistic
		# (editables en el inspector). Ver Ballistic.gd (sentinel -1 = por defecto).
		ballistic.launch(from_position, launch_velocity, -1.0, p_wall_left, p_wall_right, p_escape_y)

func _process(delta: float) -> void:
	if is_dying:
		return

	if hit_cooldown > 0.0:
		hit_cooldown -= delta

	# Giro visual (solo estético; la colisión es un círculo en el centro).
	if visual_node and is_instance_valid(visual_node):
		visual_node.rotation += spin_speed * delta

func can_be_hit() -> bool:
	return not is_dying and hit_cooldown <= 0.0

# Aplica daño a la cubo (llamado desde SwipeController al detectar un golpe).
# stroke_dir es la direccion del trazo en pantalla (para separar las mitades 3D
# perpendicularmente al golpe). Si la vida llega a 0 o menos, la cubo muere.
func take_damage(amount: float, is_critical: bool, stroke_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dying:
		return

	if stroke_dir.length_squared() > 1.0:
		last_stroke_dir = stroke_dir.normalized()

	hit_cooldown = hit_cooldown_duration # Evita golpes dobles en el mismo arrastre
	current_hp -= amount
	if health_bar:
		health_bar.value = max(0.0, current_hp)
	block_hit.emit()

	# Sound (cached to avoid redundant calls)
	if is_critical:
		SoundManager.play_crit()
	else:
		SoundManager.play_hit()

	# Visual Squash & Stretch (optimized)
	if visual_node and is_instance_valid(visual_node):
		var tween: Tween = create_tween().set_parallel(false)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_node, "scale", Vector2(1.25, 0.75), 0.06)
		tween.tween_property(visual_node, "scale", Vector2(0.85, 1.15), 0.08)
		tween.tween_property(visual_node, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BOUNCE)

	# Spawn Damage Text (daño con 2 decimales, ej. "-5.70").
	_spawn_floating_text(
		("-" + UiTheme.format_stat(amount)) if not is_critical else ("¡CRÍTICO! -" + UiTheme.format_stat(amount)),
		Color(1.0, 0.3, 0.3) if not is_critical else Color(1.0, 0.85, 0.1),
		1.0 if not is_critical else 1.35
	)

	if current_hp <= 0.0:
		die()

	# Salpicadura de gelatina del color de la cubo en cada golpe.
	_emit_gelatin_splash()

func _emit_gelatin_splash() -> void:
	if custom_hit_particles:
		return
	if not is_instance_valid(get_parent()) or recipe_data == null:
		return
	var splash: GelatinSplash = GELATIN_SPLASH_SCENE.instantiate()
	get_parent().add_child(splash)
	splash.position = global_position
	splash.setup(recipe_data.base_color, int(splash_base_amount + recipe_data.radius * splash_per_radius), recipe_data.id)

func die() -> void:
	if is_dying:
		return
	is_dying = true
	# Congela el movimiento al morir (la animación de salida lo enmascara).
	if ballistic:
		ballistic.stop()

	# Gran venta calculation: la probabilidad de Jackpot la gestiona SOLO la
	# stat pura global (StatsManager.get_final_jackpot_bonus), procedente de la
	# suerte: mejoras del mercado + comodines + prestigio. Las cubos en sí ya
	# no aportan probabilidad base: todas usan la estadística global.
	var total_jackpot_chance: float = StatsManager.get_final_jackpot_bonus()
	var is_jackpot: bool = is_golden or randf() < total_jackpot_chance
	var base_reward: float = 0.0

	if is_jackpot:
		base_reward = recipe_data.max_reward * StatsManager.get_final_jackpot_multiplier()
		if is_golden:
			base_reward *= golden_reward_multiplier
		SoundManager.play_jackpot()
		var text: String = ("✨ GOMITA DORADA ✨\n" if is_golden else "") + "⭐ ¡JACKPOT! ⭐\n+$" + UiTheme.format_money(base_reward * StatsManager.get_final_money_multiplier() * GameManager.get_streak_multiplier())
		_spawn_floating_text(text, Color(1.0, 0.88, 0.2), 1.6, 1.2)
	else:
		base_reward = randf_range(recipe_data.min_reward, recipe_data.max_reward)
		SoundManager.play_coin()
		var text: String = "+$" + UiTheme.format_money(base_reward * StatsManager.get_final_money_multiplier() * GameManager.get_streak_multiplier())
		_spawn_floating_text(text, Color(0.3, 1.0, 0.4), 1.15, 0.8)

	GameManager.register_gummy_produced(recipe_data, base_reward, is_jackpot, is_golden)

	# Burst Out Animation (highly optimized)
	if visual_node and is_instance_valid(visual_node):
		var death_tween: Tween = create_tween()
		death_tween.set_parallel(true)
		death_tween.set_trans(Tween.TRANS_BACK)
		death_tween.set_ease(Tween.EASE_OUT)
		death_tween.tween_property(visual_node, "scale", Vector2(1.8, 1.8), 0.12)
		death_tween.tween_property(visual_node, "modulate:a", 0.0, 0.12)

		death_tween.tween_callback(func():
			if is_instance_valid(self):
				emit_signal("block_destroyed", self)
				queue_free()
		)

func _spawn_floating_text(text: String, color: Color, scale_mult: float = 1.0, duration: float = 0.75) -> void:
	if not is_instance_valid(self) or not is_instance_valid(get_parent()):
		return
	
	var ft = FLOATING_TEXT_SCENE.instantiate()
	if ft and is_instance_valid(ft):
		ft.position = global_position + Vector2(randf_range(-text_offset_x, text_offset_x), -text_offset_y)
		get_parent().add_child(ft)
		if ft.has_method("setup"):
			ft.setup(text, color, scale_mult, duration)

# Llamado por Ballistic cuando la cubo sale de la pantalla sin ser procesada.
func _on_projectile_escaped() -> void:
	queue_free()
