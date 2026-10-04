extends Control
# ============================================================================
# CreditsModal: pantalla de CRÉDITOS que se muestra al completar el DÍA 100
# (el objetivo del juego). Ofrece dos salidas:
#   - "Continuar": seguir jugando para batir nuevos récords (día 101+).
#   - "Salir": volver al menú principal.
# Al continuar se retoma el flujo normal de fin de día (comodín + tienda).
# ============================================================================

signal continue_requested   # -> Main: abrir el flujo normal de fin de día (día 100)
signal exit_requested       # -> Main: volver al menú principal

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var quota_label: Label = $Panel/VBox/QuotaLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueButton
@onready var exit_btn: Button = $Panel/VBox/ExitButton

func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func open_modal(completed_order: int) -> void:
	visible = true
	UiTheme.pop_in($Panel)
	title_label.text = "🎬 ¡CRÉDITOS!"
	subtitle_label.text = "¡Completaste los " + str(completed_order) + " días del juego!"
	# Muestra la cuota del día alcanzado (objetivo cumplido). Los días siguen
	# creciendo tras el 100 para quien quiera batir nuevos récords.
	quota_label.text = "Cuota del día " + str(completed_order) + ": $" + UiTheme.format_money(GameManager.get_order_target_for(completed_order))

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("continue_requested")

func _on_exit_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("exit_requested")