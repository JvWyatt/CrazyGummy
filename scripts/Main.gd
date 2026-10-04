extends Node
# ============================================================================
# Main: el "director de orquesta" de la escena principal (scenes/Main.tscn).
# No contiene l\u00f3gica de balance ni reglas del juego: solo conecta las
# se\u00f1ales de GameManager y de cada pantalla/modal de la interfaz (ui/*.gd)
# para mostrar/ocultar lo correcto en cada momento (men\u00fa, juego, tiendas,
# resultados). Si buscas c\u00f3mo se pasa de una pantalla a otra, es aqu\u00ed.
# ============================================================================

const FRUIT3D_WORLD_SCENE: PackedScene = preload("res://scenes/game/Fruit3DWorld.tscn")

# Diagnóstico de cierres SOLO en móvil (no reproducibles en escritorio): cada
# cambio de pantalla y un latido periódico se vuelcan a user://crashlog.txt.
# Si la app muere, la última línea indica en qué pantalla/acción se quedó.
const CRASH_LOG_PATH: String = "user://crashlog.txt"
var _heartbeat_acc: float = 0.0

func _log(_tag: String, _detail: String = "") -> void:
	var f := FileAccess.open(CRASH_LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_line("[%.2f] %s %s" % [Time.get_ticks_msec() / 1000.0, _tag, _detail])

func _process(delta: float) -> void:
	_heartbeat_acc += delta
	if _heartbeat_acc >= 1.0:
		_heartbeat_acc = 0.0
		_log("heartbeat", _current_screen_tag())

@onready var main_menu: Control = $MainMenu
@onready var game_world: Node2D = $GameWorld
@onready var goal_celebration: Node2D = $GoalCelebration
@onready var fruit_spawner: Node2D = $GameWorld/FruitSpawner
@onready var swipe_controller: Node2D = $GameWorld/SwipeController
@onready var hud: Control = $GameWorld/HUDLayer/HUD
@onready var fruit3d_layer: SubViewportContainer = $Fruit3DLayer
var _fruit3d_viewport: SubViewport

@onready var run_upgrade_modal: Control = $Modals/RunUpgradeModal
@onready var stats_modal: Control = $Modals/StatsModal
@onready var card_selection_modal: Control = $Modals/CardSelectionModal
@onready var results_modal: Control = $Modals/ResultsModal
@onready var prestige_shop_modal: Control = $Modals/PrestigeShopModal
@onready var progress_modal: Control = $Modals/ProgressModal
@onready var cards_modal: Control = $Modals/CardsModal
@onready var credits_modal: Control = $Modals/CreditsModal
@onready var achievements_modal: Control = $Modals/AchievementsModal

func _ready() -> void:
	# Wire Main Menu events
	main_menu.start_game_requested.connect(_on_start_game_requested)
	main_menu.open_prestige_shop_requested.connect(_on_open_prestige_shop_requested)
	main_menu.open_progress_requested.connect(_on_open_progress_requested)
	main_menu.open_achievements_requested.connect(_on_open_achievements_requested)
	main_menu.open_cards_requested.connect(_on_open_cards_requested)

	# Wire HUD events
	hud.open_stats_requested.connect(_on_open_stats_requested)
	hud.quit_run_requested.connect(_on_quit_run_requested)
	hud.bonus_celebration_requested.connect(_on_bonus_celebration_requested)
	stats_modal.open_cards_requested.connect(_on_open_active_cards_requested)

	# Wire Modals events
	run_upgrade_modal.open_stats_requested.connect(_on_open_stats_requested)
	card_selection_modal.card_chosen.connect(_on_card_chosen)
	run_upgrade_modal.start_next_order_requested.connect(_on_start_next_order_from_shop)
	stats_modal.modal_closed.connect(_on_stats_modal_closed)
	results_modal.return_to_menu_requested.connect(_on_return_to_menu_requested)

	# Wire Credits (día 100) events
	credits_modal.continue_requested.connect(_on_credits_continue_requested)
	credits_modal.exit_requested.connect(_on_credits_exit_requested)

	# Wire Modal events for completion flow
	card_selection_modal.unpayable.connect(func(): GameManager.end_run_failed())

	# Wire Game Manager events
	GameManager.order_completed.connect(_on_order_completed)
	GameManager.run_ended.connect(_on_run_ended)

	_init_fruit3d_overlay()

	# Initial state: Show Main Menu
	_show_main_menu()

# Instancia el mundo 3D de frutas dentro del SubViewport transparente, que
# espeja las frutas/piedras 2D (ver Fruit3DWorld.gd). Puro visual.
# Fruit3DLayer es hijo directo de Main (como Background/MainMenu), por lo que
# sus anchors abarcan el canvas completo (720x1280 de base, mas alto en moviles).
# El SubViewportContainer tiene `stretch` activado: el contenedor redimensiona
# el SubViewport a su propio rect cada frame, asi la camara/set_pos2d mapean 1:1
# con cualquier alto real (no hay que fijar `size` a mano: se ignora + warning).
func _init_fruit3d_overlay() -> void:
	var world: Node3D = FRUIT3D_WORLD_SCENE.instantiate()
	_fruit3d_viewport = fruit3d_layer.get_node("Viewport")
	_fruit3d_viewport.add_child(world)
	if world.has_method("setup_fruit_spawner"):
		world.setup_fruit_spawner(fruit_spawner)

func _current_screen_tag() -> String:
	if main_menu.visible and (settings_panel_visible()):
		if main_menu.reset_confirm_dialog.visible: return "menu+settings+reset"
		return "menu+settings"
	if main_menu.visible:
		if prestige_shop_modal.visible: return "menu+prestige"
		if progress_modal.visible: return "menu+progress"
		if achievements_modal.visible: return "menu+achievements"
		if cards_modal.visible: return "menu+cards"
		return "menu"
	if game_world.visible:
		return "game"
	return "?"

func settings_panel_visible() -> bool:
	return main_menu.has_node("SettingsPanel") and main_menu.get_node("SettingsPanel").visible

func _on_bonus_celebration_requested() -> void:
	UiTheme.golden_confetti(goal_celebration, get_viewport().get_visible_rect().size)

func _clear_goal_celebration() -> void:
	for child in goal_celebration.get_children():
		child.queue_free()

func _show_main_menu() -> void:
	_clear_goal_celebration()
	_log("show_menu")
	main_menu.visible = true
	SoundManager.play_menu_music()
	game_world.visible = false
	hud.visible = false
	fruit_spawner.disable_spawning()
	fruit_spawner.clear_all()
	run_upgrade_modal.visible = false
	stats_modal.visible = false
	card_selection_modal.visible = false
	results_modal.visible = false
	prestige_shop_modal.visible = false
	progress_modal.visible = false
	cards_modal.visible = false
	credits_modal.visible = false
	achievements_modal.visible = false

func _on_start_game_requested() -> void:
	main_menu.visible = false
	game_world.visible = true
	hud.visible = true
	fruit_spawner.enable_spawning()
	SoundManager.play_game_music()
	GameManager.start_new_run()

func _on_open_prestige_shop_requested() -> void:
	_log("open", "prestige")
	prestige_shop_modal.open_modal()

func _on_open_progress_requested() -> void:
	_log("open", "progress")
	progress_modal.open_modal()

func _on_open_achievements_requested() -> void:
	_log("open", "achievements")
	achievements_modal.open_modal()

func _on_open_cards_requested() -> void:
	_log("open", "cards")
	cards_modal.open_discovered_cards()

func _on_open_active_cards_requested() -> void:
	cards_modal.open_active_cards()

func _on_open_stats_requested() -> void:
	if game_world.visible and GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.pause_turn()
	stats_modal.open_modal()

func _on_stats_modal_closed() -> void:
	if game_world.visible and GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.resume_turn()

func _on_quit_run_requested() -> void:
	GameManager.end_run_failed()

func _on_order_completed(order_num: int) -> void:
	_clear_goal_celebration()
	fruit_spawner.clear_all()
	# Objetivo del juego: al completar el día de victoria (get_win_day()) se muestran los CRÉDITOS
	# en lugar del flujo normal de fin de día. Desde ahí se puede continuar
	# (nuevos récords) o salir al menú.
	if order_num >= GameManager.get_win_day():
		credits_modal.open_modal(order_num)
		return
	# Resumen del día (conseguido/impuesto/ganancia) y comodines se muestran
	# juntos en el CardSelectionModal (el impuesto se paga automáticamente ahí).
	card_selection_modal.open_modal(order_num)

func _on_credits_continue_requested() -> void:
	# Tras los créditos, retomar el flujo normal de fin de día (comodín + tienda)
	# para seguir haciendo récords a partir del día 100.
	card_selection_modal.open_modal(GameManager.get_win_day())

func _on_credits_exit_requested() -> void:
	_show_main_menu()

func _on_card_chosen(order_num: int) -> void:
	# After choosing blessing card, open in-run upgrades shop between rounds
	run_upgrade_modal.open_modal(order_num)

func _on_start_next_order_from_shop() -> void:
	_clear_goal_celebration()
	fruit_spawner.enable_spawning()
	GameManager.advance_to_next_order()

func _on_run_ended(summary: Dictionary) -> void:
	_clear_goal_celebration()
	fruit_spawner.clear_all()
	results_modal.open_modal(summary)

func _on_return_to_menu_requested() -> void:
	_show_main_menu()
