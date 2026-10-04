extends Control
# ============================================================================
# ProgressModal: muestra el progreso permanente del jugador: días completados,
# negocios en quiebra y comodines descubiertos. Todo viene de
# SaveManager.save_data, solo lectura.
# ============================================================================

@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var progress_container: VBoxContainer = $Panel/VBox/ScrollContainer/ProgressVBox

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in progress_container.get_children():
		child.queue_free()
	var best: int = int(SaveManager.save_data.get("best_clients_in_day", 0))
	$Panel/VBox/MilestonePanel/Content/BestLabel.text = str(best) + " / 100 días"
	$Panel/VBox/MilestonePanel/Content/ProgressBar.value = mini(best, 100)

	_add_row("Negocios iniciados", str(int(SaveManager.save_data.get("days_started", 0))))
	_add_row("Frutas cortadas en total", UiTheme.format_money(float(SaveManager.save_data.get("total_fruits_cut", 0))))
	_add_row("Comodines descubiertos", str(SaveManager.get_discovered_cards().size()) + " / " + str(CardDatabase.ALL_CARDS.size()))

func _add_row(label_text: String, value_text: String) -> void:
	var card := StatCard.create()
	card.setup("", label_text, value_text, UiTheme._palette_color("color_success", UiTheme.COLOR_SUCCESS))
	progress_container.add_child(card)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
