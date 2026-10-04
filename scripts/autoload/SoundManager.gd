extends Node
# ============================================================================
# SoundManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Genera efectos de sonido por c\u00f3digo (sin archivos de audio) usando ondas
# simples (seno, ruido, sierra, cuadrada). No contiene valores de balance del
# juego; si quieres cambiar el sonido de una acci\u00f3n, busca la funci\u00f3n
# play_xxx() correspondiente m\u00e1s abajo en este archivo.
# ============================================================================

# Procedural Sound Effect Generator for instant audio feedback in Godot 4
var is_sound_enabled: bool = true

var player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

# Ruta opcional para pistas de música propias. Si el archivo NO existe, se
# genera un loop procedural (sin assets) para que los sliders de música del
# menú siempre tengan algo que controlar.
#   - MUSIC_PATH: música del MENÚ (relajada).
#   - GAME_MUSIC_PATH: música del JUEGO (más rítmica/activa).
const MUSIC_PATH: String = "res://assets/music/main_loop.ogg"
const GAME_MUSIC_PATH: String = "res://assets/music/game_loop.ogg"

var music_player: AudioStreamPlayer

# Caché de streams de FX de FRECUENCIA FIJA (click, moneda, victoria, jackpot,
# game over), generados una sola vez y reutilizados. Reduce el churn de memoria
# en móvil: evita asignar un buffer de audio nuevo en cada pulsación/arrastre,
# que es una causa habitual de cierres en Android (no en escritorio).
var _stream_cache: Dictionary = {}

func _cached_stream(key: String, builder: Callable) -> AudioStreamWAV:
	if not _stream_cache.has(key):
		_stream_cache[key] = builder.call()
	return _stream_cache[key]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	for i in range(POOL_SIZE):
		var asp := AudioStreamPlayer.new()
		asp.bus = "SFX"
		add_child(asp)
		player_pool.append(asp)
	play_menu_music()

func _get_available_player() -> AudioStreamPlayer:
	for player in player_pool:
		if not player.playing:
			return player
	return player_pool[0]

# Si por alguna razón el layout de buses no cargara (p.ej. una build sin el
# default_bus_layout.tres), crea el bus en runtime. Así los sliders del menú
# siempre tienen un bus real que controlar.
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)

# ---------------------------------------------------------------------------
# Música (soundtrack)
# ---------------------------------------------------------------------------

# Contextos de música: "menu" (relajada) y "game" (más rítmica). Cada contexto
# tiene su propia pista: primero el archivo propio (assets/music/*.ogg) y, si
# no existe, un loop procedural generado en runtime.

var _menu_stream: AudioStream
var _game_stream: AudioStream
var _current_context: String = ""

func play_menu_music() -> void:
	_play_context("menu")

func play_game_music() -> void:
	_play_context("game")

func _play_context(context: String) -> void:
	if music_player == null:
		return
	if _current_context == context and music_player.playing:
		return
	var stream: AudioStream = _get_context_stream(context)
	if stream == null:
		# No hay pista de música disponible (solo .ogg reales; el fallback
		# procedural desactivado). Silencio estable: el crash de Android
		# era el streaming de AudioStreamWAV (AudioTrack::onMoreData).
		music_player.stop()
		_current_context = context
		return
	music_player.stream = stream
	_current_context = context
	music_player.play()

func _get_context_stream(context: String) -> AudioStream:
	match context:
		"menu":
			if _menu_stream == null:
				_menu_stream = _load_existing(MUSIC_PATH)
			return _menu_stream
		"game":
			if _game_stream == null:
				_game_stream = _load_existing(GAME_MUSIC_PATH)
			return _game_stream
	return _load_existing(MUSIC_PATH)

# Carga SOLO una pista de música existente (assets/music/*.ogg). Si no existe,
# devuelve null (silencio) en lugar de generar un loop procedural en runtime:
# esos AudioStreamWAV en streaming crashean en Android (AudioTrack::onMoreData).
# Cuando quieras soundtrack, coloca los .ogg/MP3 en assets/music/.
func _load_existing(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var custom_stream = load(path)
		if custom_stream is AudioStream:
			return custom_stream as AudioStream
	return null

func _generate_tone_stream(freq_start: float, freq_end: float, duration: float, type: String = "sine", decay: float = 4.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_samples * 2) # 16-bit mono

	var phase: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var current_freq: float = lerp(freq_start, freq_end, t)
		phase += 2.0 * PI * current_freq / float(sample_rate)
		if phase > 2.0 * PI:
			phase -= 2.0 * PI

		var env: float = exp(-t * decay)
		var sample_val: float = 0.0

		match type:
			"sine":
				sample_val = sin(phase)
			"noise":
				sample_val = randf_range(-1.0, 1.0)
			"saw":
				sample_val = (fmod(phase, 2.0 * PI) / PI) - 1.0
			"square":
				sample_val = 1.0 if sin(phase) > 0.0 else -1.0

		var int_val: int = int(clamp(sample_val * env * 0.5 * 32767.0, -32768.0, 32767.0))
		# Store 16-bit LE
		var unsigned_val: int = int_val if int_val >= 0 else int_val + 65536
		byte_array[i * 2] = unsigned_val & 0xFF
		byte_array[i * 2 + 1] = (unsigned_val >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_array
	return stream

func play_slice() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(randf_range(800.0, 1200.0), 300.0, 0.08, "noise", 8.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -4.0
	p.play()

func play_hit() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(randf_range(400.0, 600.0), 180.0, 0.06, "saw", 10.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -6.0
	p.play()

func play_thud() -> void:
	if not is_sound_enabled: return
	var stream := _generate_tone_stream(randf_range(120.0, 90.0), 60.0, 0.18, "noise", 9.0)
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -4.0
	p.play()

func play_coin() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("coin", func(): return _generate_tone_stream(980.0, 1320.0, 0.12, "sine", 5.0))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -5.0
	p.play()

func play_jackpot() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("jackpot", func(): return _generate_tone_stream(500.0, 1600.0, 0.45, "square", 2.5))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -2.0
	p.play()

func play_crit() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("crit", func(): return _generate_tone_stream(1200.0, 600.0, 0.18, "saw", 6.0))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -3.0
	p.play()

func play_click() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("click", func(): return _generate_tone_stream(700.0, 500.0, 0.04, "sine", 12.0))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -8.0
	p.play()

func play_victory() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("victory", func(): return _generate_tone_stream(600.0, 1200.0, 0.35, "sine", 3.0))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -3.0
	p.play()

func play_game_over() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("game_over", func(): return _generate_tone_stream(500.0, 120.0, 0.6, "saw", 2.0))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -2.0
	p.play()

func play_achievement() -> void:
	if not is_sound_enabled: return
	var stream := _cached_stream("achievement", func(): return _generate_tone_stream(880.0, 1560.0, 0.35, "sine", 3.0))
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = -3.0
	p.play()
