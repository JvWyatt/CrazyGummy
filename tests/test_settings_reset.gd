extends SceneTree
## Confirmación de reinicio: entrada real para detectar si Ajustes tapa el modal.
## Ejecutar con XDG_DATA_HOME aislado para no modificar el progreso del jugador.

var failures: int = 0
var checks: int = 0
var host: SubViewport

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _click(button: Button) -> void:
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	host.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		host.push_input(event, true)
	await create_timer(0.4).timeout

func _run() -> void:
	host = SubViewport.new()
	host.size = Vector2i(720, 1280)
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	host.add_child(menu)
	await create_timer(0.6).timeout
	var settings: Control = menu.get_node("SettingsPanel")
	var dialog = settings.get_node("ResetConfirmDialog")
	await _click(menu.settings_button)
	_check(settings.is_visible_in_tree(), "El botón abre Ajustes")
	await _click(menu.reset_button)
	_check(dialog.is_visible_in_tree(), "La confirmación aparece dentro de Ajustes inmediatamente")
	_check(settings.visible, "Ajustes permanece abierto bajo la confirmación")
	await _click(dialog.cancel_button)
	_check(not dialog.visible, "Cancelar funciona con entrada real: Ajustes no tapa el botón")
	_check(settings.is_visible_in_tree(), "Cancelar devuelve a Ajustes")
	await _click(menu.reset_button)
	var save := root.get_node("SaveManager")
	save.save_data["days_started"] = 42
	await _click(dialog.ok_button)
	_check(not dialog.visible, "Confirmar cierra el diálogo")
	_check(settings.is_visible_in_tree(), "Confirmar conserva Ajustes abierto")
	_check(int(save.save_data.get("days_started", 0)) != 42, "Confirmar ejecuta el reinicio de progreso")
	await _click(menu.back_button)
	_check(not settings.visible and not dialog.visible, "Cerrar Ajustes no deja confirmaciones pendientes")
	await _click(menu.settings_button)
	_check(settings.visible and not dialog.visible, "Reabrir Ajustes no recupera un modal pendiente")
	host.queue_free()
	await process_frame
	print("Reinicio desde Ajustes: %d comprobaciones, %d fallos" % [checks, failures])
	quit(1 if failures > 0 else 0)
