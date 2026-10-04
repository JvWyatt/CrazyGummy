extends Control
# ============================================================================
# HUD: la interfaz que se ve MIENTRAS juegas (barra de dinero/meta del día
# superior, barrita de racha a la derecha bajo el dinero, anillo circular de
# racha, panel de frutas/s y multiplicador, arma equipada y botones de
# Stats/Pausa). Solo muestra datos que vienen de GameManager/StatsManager; no
# decide reglas.
#
# El botón de pausa abre el PausePanel: pausa la ronda (pause_turn), permite
# ajustar el volumen (SettingsSection), continuar jugando o salir del negocio
# (con ConfirmDialog estilizado antes de renunciar).
#
# Layout superior: objetivo, recursos y telemetría se ordenan con Containers.
# SafeAreaLayout en Main adapta los márgenes al notch del móvil. AchToast NO
# vive aquí sino en ToastLayer, un CanvasLayer propio con layer = 10: así se
# dibuja por encima del HUD (aunque comparta su altura) y nunca queda tapado
# mientras dura el aviso.
# ============================================================================

signal open_stats_requested
signal quit_run_requested
signal bonus_celebration_requested

@onready var money_label: Label = $TopContainer/VBox/MoneyBar/MoneyLabel
@onready var money_bar: ProgressBar = $TopContainer/VBox/MoneyBar
@onready var day_label: Label = $TopContainer/VBox/TopHBox/DayLabel
@onready var status_info_label: Label = $TopContainer/VBox/TopHBox/StatusInfoLabel
@onready var knife_label: Label = $BottomContainer/KnifeInfoLabel
@onready var stats_btn: Button = $BottomContainer/ButtonsHBox/StatsButton
@onready var pause_btn: Button = $BottomContainer/ButtonsHBox/PauseButton
@onready var pause_panel: Control = $PausePanel
@onready var pause_card: PanelContainer = $PausePanel/Card
@onready var pause_day_label: Label = $PausePanel/Card/PauseVBox/PauseDayLabel
@onready var continue_btn: Button = $PausePanel/Card/PauseVBox/ContinueButton
@onready var settings_btn: Button = $PausePanel/Card/PauseVBox/SettingsButton
@onready var pause_quit_btn: Button = $PausePanel/Card/PauseVBox/PauseQuitButton
@onready var pause_vbox: VBoxContainer = $PausePanel/Card/PauseVBox
@onready var settings_vbox: VBoxContainer = $PausePanel/Card/SettingsVBox
@onready var settings_section: SettingsSection = $PausePanel/Card/SettingsVBox/SettingsSection
@onready var settings_back_btn: Button = $PausePanel/Card/SettingsVBox/SettingsBackButton
@onready var pause_confirm_dialog: ConfirmDialog = $PauseConfirmDialog
@onready var streak_ring: StreakRing = $TopContainer/VBox/Telemetry/StreakRing
@onready var time_bar: ProgressBar = $TopContainer/VBox/Resources/TimeBar
@onready var time_label: Label = $TopContainer/VBox/Resources/TimeBar/TimeLabel
@onready var energy_bar: ProgressBar = $TopContainer/VBox/Resources/EnergyBar
@onready var energy_label: Label = $TopContainer/VBox/Resources/EnergyBar/EnergyLabel
@onready var rate_value: Label = $TopContainer/VBox/Telemetry/RatePanel/VBox/RateValue
@onready var multiplier_value: Label = $TopContainer/VBox/Telemetry/RatePanel/VBox/MultiplierValue
@onready var milestone_label: Label = $MilestoneLabel
@onready var ach_toast: PanelContainer = $ToastLayer/AchToast
@onready var ach_icon: Label = $ToastLayer/AchToast/HBox/AchIcon
@onready var ach_title: Label = $ToastLayer/AchToast/HBox/VBox/AchTitle
@onready var ach_desc: Label = $ToastLayer/AchToast/HBox/VBox/AchDesc

# Pool de frases que se muestran en el centro al alcanzar un hito de racha.
const STREAK_PHRASES: Array[String] = [
	"¡YA PICASTE!",
	"¡BUEN CORTE!",
	"¡ESTO YA ES ENSALADA!",
	"¿TÚ DUERMES?",
	"¡DEJA ALGO PARA MAÑANA!",
	"¡FRUTALMENTE INSANO!",
]
var _milestone_tween: Tween
# Último multiplicador de racha mostrado, para saber si acaba de activarse o de
# subir (streak_changed llega en cada corte de fruta con el valor actual).
var _last_streak_multiplier: float = 1.0

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.order_progress_changed.connect(_on_order_progress_changed)
	GameManager.order_goal_reached.connect(_on_order_goal_reached)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.round_time_changed.connect(_on_round_time_changed)
	StatsManager.stats_updated.connect(_on_stats_updated)
	GameManager.run_knife_equipped.connect(func(_id): _update_knife_display())
	GameManager.streak_changed.connect(_on_streak_changed)
	GameManager.streak_milestone.connect(_on_streak_milestone)
	GameManager.streak_broken.connect(_flash_streak_break)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Las acciones secundarias conservan el tema; Continuar es la acción principal.
	UiTheme.apply_button_style(continue_btn, "primary")
	UiTheme.apply_button_style(pause_quit_btn, "danger")

	stats_btn.pressed.connect(_on_stats_button_pressed)
	pause_btn.pressed.connect(_on_pause_button_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_button_pressed)
	settings_back_btn.pressed.connect(_on_settings_back_pressed)
	pause_quit_btn.pressed.connect(_on_pause_quit_pressed)
	pause_confirm_dialog.confirmed.connect(_on_quit_confirmed)
	_update_knife_display()
	_update_launch_rate_display()
	_last_streak_multiplier = GameManager.get_streak_multiplier()
	_set_multiplier_display(_last_streak_multiplier)
	_on_streak_changed(GameManager.current_streak, _last_streak_multiplier)
	# Estado inicial de las barras de tiempo y estamina (por si el HUD ya
	# existia cuando arranco la ronda y no llegaron las senales).
	_on_energy_changed(GameManager.current_energy, StatsManager.get_final_max_energy())
	_on_round_time_changed(GameManager.round_time_left)

func format_damage(value: float) -> String:
	return UiTheme.format_stat(value)

func _update_knife_display() -> void:
	var knife_data: KnifeData = StatsManager.get_equipped_knife_data()
	var knife_name: String = knife_data.name
	var knife_icon: String = knife_data.icon
	knife_label.text = knife_icon + " " + knife_name + " (⚔️" + format_damage(StatsManager.get_final_damage()) + ")"

func _on_stats_updated() -> void:
	_update_knife_display()
	_update_launch_rate_display()
	_on_streak_changed(GameManager.current_streak, GameManager.get_streak_multiplier())

func _update_launch_rate_display() -> void:
	# Contador informativo: NO es un recurso consumible, asi que va fuera del
	# anillo de racha, en una pieza compacta con su propia jerarquia visual.
	var rate: float = StatsManager.get_final_launch_rate()
	rate_value.text = "🍓 " + UiTheme.format_stat(rate) + " frutas/s"

var _last_money: float = -1.0
var _order_target: float = 0.0

func _on_money_changed(amount: float) -> void:
	_update_money_display(amount)
	if amount > _last_money and _last_money >= 0.0:
		UiTheme.pulse_label(money_label)
	_last_money = amount

# En fase de BONUS (cuota ya cumplida) el rótulo deja de mostrar el progreso hacia
# el objetivo y pasa a mostrar la ganancia extra del día, que es lo único que
# sigue aumentando al seguir cortando fruta.
func _update_money_display(amount: float) -> void:
	if _is_bonus_phase():
		money_label.text = "💰 BONUS  +$" + UiTheme.format_money(GameManager.get_order_bonus())
		money_label.modulate = UiTheme.COLOR_ACCENT
	else:
		money_label.text = "💰 $" + UiTheme.format_money(amount) + " / $" + UiTheme.format_money(_order_target)
		money_label.modulate = Color.WHITE

# ¿Se ha cumplido ya la cuota del día? A partir de ese momento todo el dinero que
# se genere es ganancia extra y la interfaz lo dice (barra dorada + rótulo BONUS).
func _is_bonus_phase() -> bool:
	return GameManager.daily_goal_reached

func _on_order_progress_changed(progress: float, target: float) -> void:
	_order_target = target
	var bonus_phase: bool = _is_bonus_phase()
	day_label.text = ("🎯 Día " + str(GameManager.current_order) + " · BONUS") if bonus_phase else ("🎯 Día " + str(GameManager.current_order))
	day_label.modulate = UiTheme.COLOR_ACCENT if bonus_phase else Color.WHITE
	status_info_label.text = "💼 Negocio " + str(SaveManager.save_data.get("days_started", 1))
	money_bar.max_value = target
	# La barra no crece con el bonus: se queda llena y en dorado, para que se lea
	# "objetivo cumplido" y no "todavía no llego".
	money_bar.value = target if bonus_phase else minf(progress, target)
	money_bar.modulate = UiTheme.COLOR_ACCENT if bonus_phase else Color.WHITE
	_update_money_display(GameManager.run_money)

# El día se cumple con una fruta: activa una sola lluvia dorada hasta terminar
# la ronda + aviso en el centro. La interfaz se queda en modo BONUS.
func _on_order_goal_reached(_bonus: float) -> void:
	bonus_celebration_requested.emit()
	_show_bonus_banner()
	_on_order_progress_changed(GameManager.order_progress, GameManager.order_target)

func _show_bonus_banner() -> void:
	milestone_label.text = "🎯 ¡META CUMPLIDA!  BONUS"
	milestone_label.modulate = UiTheme.COLOR_ACCENT
	milestone_label.scale = Vector2(0.85, 0.85)
	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	_milestone_tween = create_tween()
	_milestone_tween.set_parallel(true)
	_milestone_tween.tween_property(milestone_label, "scale", Vector2(1.1, 1.1), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_milestone_tween.tween_property(milestone_label, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_milestone_tween.tween_property(milestone_label, "modulate:a", 0.0, 0.45).set_delay(1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _on_energy_changed(current_e: float, max_e: float) -> void:
	# La estamina es estado de partida: barra propia en el panel superior.
	energy_bar.max_value = max_e
	energy_bar.value = clampf(current_e, 0.0, max_e)
	energy_label.text = "⚡ " + str(ceili(current_e)) + " / " + str(ceili(max_e))

# La señal round_time_changed llega cada frame; los rótulos solo cambian una vez
# por décima de segundo, así que se guardan para evitar escrituras redundantes.
var _last_time_text: String = ""
var _last_time_urgent: bool = false

func _on_round_time_changed(time_left: float) -> void:
	# El tiempo restante se vacia: la barra muestra lo que queda de la ronda.
	var secs: int = ceili(maxf(0.0, time_left))
	var total: float = GameManager.get_round_time()
	time_bar.max_value = total
	time_bar.value = clampf(time_left, 0.0, total)
	var text: String = "⏱ " + str(secs) + " s"
	if text != _last_time_text:
		_last_time_text = text
		time_label.text = text
	var urgent: bool = secs <= 10
	if urgent != _last_time_urgent:
		_last_time_urgent = urgent
		time_label.modulate = Color(1, 0.55, 0.55) if urgent else Color.WHITE

func _on_stats_button_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_stats_requested")

# --- Racha de frutas --------------------------------------------------------

# Hitos ordenados ascendentemente para calcular progreso entre hitos. A partir
# de 1000 la progresión es por bandas de 1000 frutas (2000, 3000...), sin más.
const STREAK_ORDER: Array[int] = [10, 50, 100, 250, 500, 1000]
@onready var multiplier_fly_label: Label = $MultiplierFlyLabel
var _multiplier_fly_tween: Tween

func _on_streak_changed(streak: int, multiplier: float) -> void:
	# La señal de reinicio envía x1; el valor real también incluye comodines.
	if streak == 0:
		multiplier = GameManager.get_streak_multiplier()
	# El aro del anillo ES el progreso hacia el siguiente nivel, asi que no hace
	# falta ningun texto del tipo "llega a X": el hueco del aro ya lo dice.
	var info: Dictionary = _streak_progress(streak)
	var span: int = maxi(int(info["range"]), 1)
	streak_ring.set_streak(float(info["progress"]) / float(span), streak)
	# El multiplicador solo se avisa cuando SUBE (se activa o aumenta); entre hito
	# y hito el anillo se queda mostrando el contador de racha, sin texto extra.
	if multiplier > _last_streak_multiplier:
		_animate_multiplier_fly(multiplier)
	elif multiplier < _last_streak_multiplier or streak == 0:
		_cancel_multiplier_fly()
		_set_multiplier_display(GameManager.get_streak_multiplier())
	_last_streak_multiplier = multiplier

func _set_multiplier_display(multiplier: float) -> void:
	multiplier_value.text = "🔥 x" + UiTheme.format_stat(multiplier)

func _cancel_multiplier_fly() -> void:
	if _multiplier_fly_tween and _multiplier_fly_tween.is_valid():
		_multiplier_fly_tween.kill()
	multiplier_fly_label.visible = false
	streak_ring.value_label.visible = true

func _animate_multiplier_fly(multiplier: float) -> void:
	_cancel_multiplier_fly()
	multiplier_fly_label.text = "x" + UiTheme.format_stat(multiplier)
	multiplier_fly_label.visible = true
	multiplier_fly_label.modulate = Color.WHITE
	# El recorrido queda en la franja superior, lejos de las frases del centro.
	var start_pos: Vector2 = streak_ring.global_position + streak_ring.size * 0.5 - multiplier_fly_label.size * 0.5
	var end_pos: Vector2 = multiplier_value.global_position + multiplier_value.size * 0.5 - multiplier_fly_label.size * 0.5
	multiplier_fly_label.global_position = start_pos
	multiplier_fly_label.scale = Vector2(0.5, 0.5)
	multiplier_fly_label.pivot_offset = multiplier_fly_label.size * 0.5
	streak_ring.value_label.visible = false

	_multiplier_fly_tween = create_tween()
	_multiplier_fly_tween.tween_property(multiplier_fly_label, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_multiplier_fly_tween.tween_property(multiplier_fly_label, "scale", Vector2.ONE, 0.15)
	_multiplier_fly_tween.tween_interval(0.2)
	_multiplier_fly_tween.tween_callback(func(): streak_ring.value_label.visible = true)
	_multiplier_fly_tween.set_parallel(true)
	_multiplier_fly_tween.tween_property(multiplier_fly_label, "global_position", end_pos, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_multiplier_fly_tween.tween_property(multiplier_fly_label, "scale", Vector2(0.35, 0.35), 0.4)
	_multiplier_fly_tween.tween_property(multiplier_fly_label, "modulate:a", 0.0, 0.1).set_delay(0.3)
	_multiplier_fly_tween.chain().tween_callback(func():
		multiplier_fly_label.visible = false
		_set_multiplier_display(multiplier)
	)

# Destello rojo al romperse la racha (al tocar una piedra u obstáculo).
func _flash_streak_break() -> void:
	streak_ring.flash_break()

# Calcula el progreso de la barra de racha entre el hito anterior y el siguiente.
# Devuelve {range: intervalo, progress: avance dentro del intervalo, next: hito}.
func _streak_progress(streak: int) -> Dictionary:
	var last: int = STREAK_ORDER[STREAK_ORDER.size() - 1]
	if streak >= last:
		# Por encima de 1000 se muestran bandas de 1000 frutas, siempre abiertas:
		# next = siguiente millar, dentro de una ventana de 1000 frutas.
		var band: int = int((streak - last) / 1000)
		var window_start: int = last + band * 1000
		var next: int = window_start + 1000
		return {"range": 1000, "progress": streak - window_start, "next": next}
	var prev: int = 0
	var next: int = STREAK_ORDER[0]
	for m in STREAK_ORDER:
		if streak < m:
			next = m
			break
		prev = m
	var range: int = next - prev
	var progress: int = streak - prev
	return {"range": range, "progress": progress, "next": next}

func _on_streak_milestone(_milestone: int) -> void:
	if STREAK_PHRASES.is_empty():
		return
	var phrase: String = STREAK_PHRASES[randi() % STREAK_PHRASES.size()]
	milestone_label.text = "🔥 " + phrase
	milestone_label.modulate = Color(1, 1, 1, 1)
	milestone_label.scale = Vector2(0.8, 0.8)
	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	_milestone_tween = create_tween()
	_milestone_tween.set_parallel(true)
	_milestone_tween.tween_property(milestone_label, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_milestone_tween.tween_property(milestone_label, "scale", Vector2(1.0, 1.0), 0.35).set_delay(0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_milestone_tween.tween_property(milestone_label, "modulate:a", 0.0, 0.5).set_delay(1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# --- Notificación de logros -------------------------------------------------

var _ach_toast_tween: Tween
# Cola de logros pendientes de mostrar: si saltan varios a la vez (típico al
# completar un día), se muestran uno tras otro sin pisarse ni perderse.
var _ach_queue: Array[Dictionary] = []
var _ach_showing: bool = false

func _on_achievement_unlocked(_id: String, def: Dictionary) -> void:
	_ach_queue.append(def)
	if not _ach_showing:
		_show_next_achievement()

func _show_next_achievement() -> void:
	if _ach_queue.is_empty():
		_ach_showing = false
		return
	_ach_showing = true
	var def: Dictionary = _ach_queue.pop_front()
	ach_icon.text = str(def.get("icon", "🏆"))
	ach_title.text = "🎉 Logro completado"
	ach_desc.text = str(def.get("name", "¡Logro conseguido!"))
	# Entrada y salida discretas sin cortar la partida (fade + escala suave,
	# sin mover la posición para no chocar con los anchors del panel).
	if _ach_toast_tween and _ach_toast_tween.is_valid():
		_ach_toast_tween.kill()
	ach_toast.visible = true
	ach_toast.modulate = Color(1, 1, 1, 0)
	ach_toast.scale = Vector2(0.9, 0.9)
	ach_toast.pivot_offset = ach_toast.size * 0.5
	_ach_toast_tween = create_tween()
	_ach_toast_tween.set_parallel(true)
	_ach_toast_tween.tween_property(ach_toast, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ach_toast_tween.tween_property(ach_toast, "scale", Vector2.ONE * 1.04, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ach_toast_tween.chain().tween_interval(2.4)
	_ach_toast_tween.chain().tween_property(ach_toast, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_ach_toast_tween.chain().tween_callback(func():
		ach_toast.visible = false
		_show_next_achievement()
	)
	SoundManager.play_achievement()

# --- Pausa --------------------------------------------------------------

func _on_pause_button_pressed() -> void:
	SoundManager.play_click()
	GameManager.pause_turn()
	pause_day_label.text = "📋 Día " + str(GameManager.current_order)
	pause_vbox.visible = true
	settings_vbox.visible = false
	pause_panel.visible = true
	UiTheme.pop_in(pause_card)

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	pause_panel.visible = false
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.resume_turn()

func _on_settings_button_pressed() -> void:
	SoundManager.play_click()
	settings_section.sync()
	pause_vbox.visible = false
	settings_vbox.visible = true

func _on_settings_back_pressed() -> void:
	SoundManager.play_click()
	settings_vbox.visible = false
	pause_vbox.visible = true

func _on_pause_quit_pressed() -> void:
	SoundManager.play_click()
	pause_confirm_dialog.open(
		"RENUNCIAR AL NEGOCIO",
		"¿Seguro que quieres renunciar a este negocio?\nPerderás el progreso del día actual.",
		"RENUNCIAR",
		"CONTINUAR JUGANDO"
	)

func _on_quit_confirmed() -> void:
	pause_panel.visible = false
	emit_signal("quit_run_requested")
