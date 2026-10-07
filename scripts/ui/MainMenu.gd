extends Control
# ============================================================================
# MainMenu: pantalla inicial del juego (Jugar, Tienda de Prestigio, Progreso,
# Comodines, Ajustes, Reiniciar Progreso). Solo emite señales; Main.gd decide
# qué hacer con cada botón presionado. Los sliders de ajustes viven en una
# SettingsSection reutilizable y el diálogo de reiniciar es un ConfirmDialog
# estilizado (no el ConfirmationDialog feo de Godot).
# ============================================================================

signal start_game_requested
signal open_prestige_shop_requested
signal open_progress_requested
signal open_cards_requested
signal open_achievements_requested
# El jugador quiere retomar la partida guardada (GameManager.restore_run_state).
signal continue_run_requested

@onready var continue_button: Button = $CenterVBox/ButtonsVBox/ContinueButton
@onready var play_button: Button = $CenterVBox/ButtonsVBox/PlayButton
@onready var prestige_shop_button: Button = $CenterVBox/ButtonsVBox/NavigationGrid/PrestigeShopButton
@onready var progress_button: Button = $CenterVBox/ButtonsVBox/NavigationGrid/ProgressButton
@onready var achievements_button: Button = $CenterVBox/ButtonsVBox/NavigationGrid/AchievementsButton
@onready var cards_button: Button = $CenterVBox/ButtonsVBox/NavigationGrid/CardsButton
@onready var settings_button: Button = $CenterVBox/ButtonsVBox/SettingsButton
@onready var reset_button: Button = $SettingsPanel/SettingsCard/VBox/ResetButton
@onready var reset_confirm_dialog: ConfirmDialog = $SettingsPanel/ResetConfirmDialog
@onready var new_run_confirm_dialog: ConfirmDialog = $NewRunConfirmDialog
@onready var version_label: Label = $VersionLabel

@onready var settings_panel: Control = $SettingsPanel
@onready var settings_card: PanelContainer = $SettingsPanel/SettingsCard
@onready var settings_section: SettingsSection = $SettingsPanel/SettingsCard/VBox/SettingsSection
@onready var back_button: Button = $SettingsPanel/SettingsCard/VBox/BackButton
@onready var goal_label: Label = $CenterVBox/TitleVBox/GoalLabel
@onready var title_label: Label = $CenterVBox/TitleVBox/TitleLabel
@onready var center_vbox: VBoxContainer = $CenterVBox

var _anim_started: bool = false

# Pool de frases retadoras que rotan en el menú principal mientras el jugador
# intenta llegar a los 100 días.
const CHALLENGE_PHRASES: Array[String] = [
	"Rompe cubos y revela gomitas.",
	"Nuevas recetas, gomitas más valiosas.",
	"¡Evita el caramelo endurecido!",
	"100 días y ni una excusa.",
	"100 días de locura gelatinosa.",
	"100 días, un dulce desafío.",
	"100 días para romper el molde.",
	"100 días sin perder el ritmo.",
	"100 días y gomitas a lo grande.",
]
var _phrase_index: int = 0

func _ready() -> void:
	var icons := preload("res://scripts/ui/GummyIcons.gd")
	prestige_shop_button.icon = icons.texture("prestige")
	progress_button.icon = icons.texture("progress")
	achievements_button.icon = icons.texture("achievement")
	cards_button.icon = icons.texture("card")
	settings_button.icon = icons.texture("settings")
	reset_button.icon = icons.texture("stats")
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	play_button.pressed.connect(_on_play_pressed)
	prestige_shop_button.pressed.connect(_on_prestige_shop_pressed)
	progress_button.pressed.connect(_on_progress_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	cards_button.pressed.connect(_on_cards_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	back_button.pressed.connect(_on_settings_closed)
	continue_button.pressed.connect(_on_continue_pressed)
	new_run_confirm_dialog.confirmed.connect(_on_new_run_confirmed)
	_setup_hover_animations()
	call_deferred("_maybe_animate")
	_refresh_continue_button()

func _setup_hover_animations() -> void:
	UiTheme.add_hover_scale(play_button)
	UiTheme.add_hover_scale(continue_button)
	UiTheme.add_hover_scale(prestige_shop_button)
	UiTheme.add_hover_scale(progress_button)
	UiTheme.add_hover_scale(achievements_button)
	UiTheme.add_hover_scale(cards_button)
	UiTheme.add_hover_scale(settings_button)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_rotate_phrase()
		_refresh_continue_button()
		if not _anim_started:
			_anim_started = true
			call_deferred("_maybe_animate")

# Muestra/oculta "Continuar" según haya una partida guardada en curso y le pone
# el día en el que se quedó. Se refresca al entrar al menú (NOTIFICATION_VISIBIL
# ITY_CHANGED) y al arrancar, porque es la única pantalla sin modal encima.
func _refresh_continue_button() -> void:
	if continue_button == null:
		return
	var has_run: bool = SaveManager.has_active_run()
	continue_button.visible = has_run
	if has_run:
		var day: int = int(SaveManager.get_active_run_snapshot().get("current_order", 1))
		continue_button.text = "▶ CONTINUAR · DÍA " + str(day)

func _rotate_phrase() -> void:
	if goal_label == null or CHALLENGE_PHRASES.is_empty():
		return
	var phrase: String = CHALLENGE_PHRASES[_phrase_index % CHALLENGE_PHRASES.size()]
	_phrase_index += 1
	goal_label.text = phrase

func _maybe_animate() -> void:
	if not is_visible_in_tree():
		return
	animate_in()

func animate_in() -> void:
	center_vbox.pivot_offset = center_vbox.size * 0.5
	center_vbox.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(center_vbox, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_play_pressed() -> void:
	SoundManager.play_click()
	if SaveManager.has_active_run():
		# No se puede sobrescribir la run guardada sin confirmar: si la pierde
		# por error sería un estado irrecuperable (se reinicia el negocio).
		new_run_confirm_dialog.open(
			"NUEVA PARTIDA",
			"Hay una partida en progreso.\n¿Quieres comenzar una nueva partida?\nSe perderá la partida guardada actual.",
			"EMPEZAR",
			"CANCELAR"
		)
		return
	emit_signal("start_game_requested")

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	emit_signal("continue_run_requested")

func _on_new_run_confirmed() -> void:
	SoundManager.play_click()
	SaveManager.clear_active_run()
	emit_signal("start_game_requested")

func _on_prestige_shop_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_prestige_shop_requested")

func _on_progress_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_progress_requested")

func _on_achievements_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_achievements_requested")

func _on_cards_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_cards_requested")

func _on_settings_pressed() -> void:
	SoundManager.play_click()
	settings_section.sync()
	settings_panel.visible = true
	UiTheme.pop_in(settings_card)

func _on_settings_closed() -> void:
	SoundManager.play_click()
	reset_confirm_dialog.visible = false
	settings_panel.visible = false

func _on_reset_pressed() -> void:
	SoundManager.play_click()
	var message: String = "¿Seguro que quieres reiniciar todo el progreso permanente?\nEsta acción no se puede deshacer."
	if SaveManager.has_active_run():
		message += "\nTambién se borrará la partida guardada en curso."
	reset_confirm_dialog.open(
		"REINICIAR PROGRESO",
		message,
		"REINICIAR",
		"CANCELAR"
	)

func _on_reset_confirmed() -> void:
	SaveManager.reset_save()
