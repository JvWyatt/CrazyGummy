extends VBoxContainer
class_name SettingsSection
# ============================================================================
# SettingsSection: bloque reutilizable de sliders de volumen (General, Música,
# SFX) que gestiona directamente SettingsManager y se auto-sincroniza al
# llamar sync(). Se instancia en el menú principal (MainMenu) y en la pausa
# del HUD para no duplicar wiring.
# ============================================================================

@onready var master_slider: HSlider = $MasterRow/MasterSlider
@onready var music_slider: HSlider = $MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $SfxRow/SfxSlider
@onready var master_value: Label = $MasterRow/MasterValue
@onready var music_value: Label = $MusicRow/MusicValue
@onready var sfx_value: Label = $SfxRow/SfxValue

func _ready() -> void:
	master_slider.value_changed.connect(func(v: float): _apply("master", master_slider, master_value, v))
	music_slider.value_changed.connect(func(v: float): _apply("music", music_slider, music_value, v))
	sfx_slider.value_changed.connect(func(v: float): _apply("sfx", sfx_slider, sfx_value, v))
	# Al soltar el slider de SFX se reproduce un click para que el jugador oiga
	# el volumen elegido (solo al soltar, no en cada tick del arrastre).
	sfx_slider.drag_ended.connect(func(_value_changed: bool): SoundManager.play_click())

# Sincroniza los widgets con los valores guardados (llamar al abrir el panel,
# porque los sliders podrían quedar con valores de una sesión anterior).
func sync() -> void:
	master_slider.set_value_no_signal(SettingsManager.get_master_volume() * 100.0)
	music_slider.set_value_no_signal(SettingsManager.get_music_volume() * 100.0)
	sfx_slider.set_value_no_signal(SettingsManager.get_sfx_volume() * 100.0)
	_update(master_value, master_slider.value)
	_update(music_value, music_slider.value)
	_update(sfx_value, sfx_slider.value)

func _apply(bus: String, slider: HSlider, value_label: Label, value: float) -> void:
	match bus:
		"master":
			SettingsManager.set_master_volume(value / 100.0)
		"music":
			SettingsManager.set_music_volume(value / 100.0)
		"sfx":
			SettingsManager.set_sfx_volume(value / 100.0)
	_update(value_label, slider.value)

func _update(value_label: Label, value: float) -> void:
	if value_label:
		value_label.text = "%d%%" % int(round(value))