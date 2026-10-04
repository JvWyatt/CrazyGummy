extends Node
# ============================================================================
# SettingsManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Ajustes del JUGADOR que persisten entre partidas pero NO son progreso de
# juego (los progreso viven en SaveManager). Aqui viven los volúmenes de
# audio por bus: general (Master), música y efectos (SFX). Se guardan en un
# ConfigFile ("user://settings.cfg") independiente del save para que
# "Reiniciar progreso" no los borre.
# ============================================================================

const SETTINGS_FILE: String = "user://settings.cfg"

const SAVE_DEBOUNCE: float = 0.5

var _cfg := ConfigFile.new()
var _save_pending: bool = false
var _save_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cfg.load(SETTINGS_FILE)
	_apply_audio()

# Guarda en disco refrescando 0.5s después del último cambio (así mover el
# slider no escribe el archivo 60 veces por segundo mientras se arrastra).
func _process(delta: float) -> void:
	if not _save_pending:
		return
	_save_timer -= delta
	if _save_timer <= 0.0:
		_save_pending = false
		_cfg.save(SETTINGS_FILE)

# Fuerza el guardado inmediato al cerrar/poner en segundo plano el juego.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _save_pending:
			_save_pending = false
			_cfg.save(SETTINGS_FILE)

# ---------------------------------------------------------------------------
# Audio (0.0 - 1.0 lineales sobre los buses del mezclador)
# ---------------------------------------------------------------------------

func get_master_volume() -> float:
	return float(_cfg.get_value("audio", "master", 1.0))

func get_music_volume() -> float:
	return float(_cfg.get_value("audio", "music", 1.0))

func get_sfx_volume() -> float:
	return float(_cfg.get_value("audio", "sfx", 1.0))

func set_master_volume(linear: float) -> void:
	if is_equal_approx(get_master_volume(), linear):
		return
	_apply_volume("Master", linear)
	_cfg.set_value("audio", "master", clampf(linear, 0.0, 1.0))
	_request_save()

func set_music_volume(linear: float) -> void:
	if is_equal_approx(get_music_volume(), linear):
		return
	_apply_volume("Music", linear)
	_cfg.set_value("audio", "music", clampf(linear, 0.0, 1.0))
	_request_save()

func set_sfx_volume(linear: float) -> void:
	if is_equal_approx(get_sfx_volume(), linear):
		return
	_apply_volume("SFX", linear)
	_cfg.set_value("audio", "sfx", clampf(linear, 0.0, 1.0))
	_request_save()

# ---------------------------------------------------------------------------
# Internos
# ---------------------------------------------------------------------------

func _apply_audio() -> void:
	set_master_volume(get_master_volume())
	set_music_volume(get_music_volume())
	set_sfx_volume(get_sfx_volume())

# Convierte el valor lineal (0..1) a dB y lo aplica al bus. 0 = silencio total
# (-80 dB) para que el interruptor "mute" sea de verdad silencio.
func _apply_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var db: float = -80.0 if linear <= 0.0001 else linear_to_db(clampf(linear, 0.0001, 1.0))
	AudioServer.set_bus_volume_db(idx, db)

func _request_save() -> void:
	_save_pending = true
	_save_timer = SAVE_DEBOUNCE