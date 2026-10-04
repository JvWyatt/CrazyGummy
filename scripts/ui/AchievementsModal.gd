extends Control
# ============================================================================
# AchievementsModal: pestaña "LOGROS" del menú principal. Muestra todos los
# logros del juego agrupados por categoría y pestañas, su estado (desbloqueado
# / pendiente) y, cuando corresponde, una barra de progreso. Solo lectura.
# ============================================================================

@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var close_modal_button: Button = $Panel/VBox/CloseModalButton
@onready var summary_label: Label = $Panel/VBox/SummaryLabel
@onready var tabs: TabContainer = $Panel/VBox/Tabs

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	close_modal_button.pressed.connect(_on_close_pressed)
	get_tree().process_frame.connect(_pump_tab_build)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

# ---------------------------------------------------------------------------
# Acceso / desbloqueo según progreso (6.2)
# ---------------------------------------------------------------------------
# La Lista COMPLETA de logros (con los pendientes a la vista) se revela SOLO
# tras cruzar la meta del juego (día 100). Antes, la sección muestra
# únicamente los logros ya conseguidos, sin spoilear los que faltan.
var _game_completed: bool = false

func _is_game_completed() -> bool:
	return AchievementManager.is_unlocked("centenario")

# Construcción incremental asíncrona --------------------------------------------------
# El listado completo de logros implica ~120 filas anidadas; añadirlas de golpe a un
# TabContainer ya visible dispara un layout muy costoso (~2.7s, congelando la UI). Para
# que la pantalla ABRA prácticamente instantánea, el modal se muestra de inmediato y las
# filas se van añadiendo por lotes, uno por frame, de modo que la UI nunca se congela.
const ROWS_PER_FRAME := 14
var _pending_categories: Array = []
var _current_defs: Array = []
var _current_vbox: VBoxContainer = null
var _build_in_progress := false

func _refresh_ui() -> void:
	# Resumen general.
	var unlocked_count: int = AchievementManager.get_unlocked_ids().size()
	var total_count: int = AchievementManager.DEFINITIONS.size()
	_game_completed = _is_game_completed()
	if _game_completed:
		summary_label.text = "🏆 " + str(unlocked_count) + " / " + str(total_count) + " logros completados"
	else:
		summary_label.text = "🏆 " + str(unlocked_count) + " logros completados"

	# Cancela cualquier construcción previa en curso.
	_build_in_progress = false
	_pending_categories.clear()
	_current_defs.clear()

	# Limpia pestañas previas.
	for child in tabs.get_children():
		child.queue_free()

	# Todos los logros en UNA sola lista, sin dividir por categoría (el campo
	# "cat" es solo interno para crearlos, no se muestra). Antes de completar
	# el juego (6.2) se filtran los logros aún NO conseguidos para no spoilearlos.
	var all_defs: Array = []
	for def in AchievementManager.DEFINITIONS:
		if not _game_completed and not AchievementManager.is_unlocked(str(def.get("id", ""))):
			continue
		all_defs.append(def)

	_build_in_progress = true
	if all_defs.is_empty():
		# Sin logros aún y sin completar el juego: muestra un aviso.
		_pending_categories.append({
			"cat": "",
			"tag": "Aún no hay logros",
			"icon": "🤫",
			"defs": [{"id": "", "name": "Completa tu primer logro durante la partida.", "desc": "", "icon": "", "cat": "", "kind": "flag", "flag": ""}],
			"placeholder": true,
		})
	else:
		_pending_categories.append({
			"cat": "todos",
			"tag": "TODOS LOS LOGROS",
			"icon": "🏆",
			"defs": all_defs,
		})

func _pump_tab_build() -> void:
	if not _build_in_progress:
		return
	for _i in ROWS_PER_FRAME:
		if _current_defs.is_empty() and not _next_tab():
			break
		_current_vbox.add_child(_make_row(_current_defs.pop_front()))

func _next_tab() -> bool:
	if _pending_categories.is_empty():
		_build_in_progress = false
		_current_vbox = null
		return false

	var info: Dictionary = _pending_categories.pop_front()
	_current_defs = info["defs"].duplicate()

	var cat_unlocked: int = 0
	for d in _current_defs:
		if AchievementManager.is_unlocked(str(d.get("id", ""))):
			cat_unlocked += 1

	var scroll := ScrollContainer.new()
	scroll.set_script(preload("res://scripts/ui/TouchScrollContainer.gd"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var header := Label.new()
	if info.get("placeholder", false):
		header.text = str(info["icon"]) + " " + str(info["tag"])
	else:
		header.text = str(info["icon"]) + " " + str(info["tag"]) + "  (" + str(cat_unlocked) + "/" + str(_current_defs.size()) + ")"
	header.theme_type_variation = &"Subtitle"
	header.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(header)

	# Añadir la pestaña vacía (solo header) es barato; las filas llegan por lotes tras ella.
	# El nombre del nodo es lo que TabContainer muestra como titulo de pestaña por
	# defecto; se asigna un titulo legible para que no salga "ScrollContainer".
	scroll.name = "Tab_" + str(randi())
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, str(info["icon"]) + " " + str(info["tag"]))
	_current_vbox = vbox
	return true

func _make_row(def: Dictionary) -> Control:
	var id: String = str(def.get("id", ""))
	var unlocked: bool = AchievementManager.is_unlocked(id)
	var prog: Dictionary = AchievementManager.get_progress(id)

	var panel := PanelContainer.new()
	var border_color: Color = Color(0.4, 0.78, 0.55) if unlocked else Color(0.28, 0.36, 0.58)
	UiTheme.apply_card(panel, border_color)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Fila superior (fila única): icono + nombre + estado. Se usa UNA sola
	# Label para evitar el HBoxContainer anidado, que dispara un calc de layout
	# extremadamente caro dentro de estas estructuras de scroll (ver 6.0).
	var name_lbl := Label.new()
	name_lbl.text = str(def.get("icon", "🏆")) + "  " + str(def.get("name", "")) + "   " + ("✅" if unlocked else "🔒")
	name_lbl.theme_type_variation = &"CardTitle"
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.modulate = Color(0.95, 0.95, 1.0) if unlocked else Color(0.72, 0.78, 0.88)
	vbox.add_child(name_lbl)

	# Descripción.
	var desc_lbl := Label.new()
	desc_lbl.text = str(def.get("desc", ""))
	desc_lbl.theme_type_variation = &"CaptionLabel"
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Barra de progreso SOLO para logros de tipo counter (progreso gradual).
	if prog["target"] > 1.0:
		var bar := ProgressBar.new()
		bar.max_value = prog["target"]
		bar.value = minf(prog["progress"], prog["target"])
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		vbox.add_child(bar)
		var prog_lbl := Label.new()
		prog_lbl.text = "Progreso: " + AchievementManager.get_progress_text(id)
		prog_lbl.theme_type_variation = &"CaptionLabel"
		prog_lbl.modulate = Color(0.55, 0.85, 0.7) if not unlocked else Color(0.4, 0.7, 0.55)
		vbox.add_child(prog_lbl)

	panel.add_child(vbox)
	return panel

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
