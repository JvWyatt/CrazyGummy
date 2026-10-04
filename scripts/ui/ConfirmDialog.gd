extends Control
class_name ConfirmDialog
# ============================================================================
# ConfirmDialog: popup de confirmacion estilizado, en linea con el diseno de
# tarjetas del juego (scrim + tarjeta con borde). Reemplaza a los feos
# ConfirmationDialog nativos de Godot. Emite confirmed.
#
# Uso: confirm_dialog.open(titulo, mensaje, texto_aceptar, texto_cancelar).
# ============================================================================

signal confirmed

@onready var card: PanelContainer = $Card
@onready var title_label: Label = $Card/VBox/TitleLabel
@onready var message_label: Label = $Card/VBox/MessageLabel
@onready var ok_button: Button = $Card/VBox/ButtonsHBox/OkButton
@onready var cancel_button: Button = $Card/VBox/ButtonsHBox/CancelButton

func _ready() -> void:
	visible = false
	ok_button.pressed.connect(func():
		SoundManager.play_click()
		visible = false
		emit_signal("confirmed")
	)
	cancel_button.pressed.connect(func():
		SoundManager.play_click()
		visible = false
	)

func open(title: String, message: String, ok_text: String = "ACEPTAR", cancel_text: String = "CANCELAR") -> void:
	title_label.text = title
	message_label.text = message
	ok_button.text = ok_text
	cancel_button.text = cancel_text
	visible = true
	UiTheme.pop_in(card)