extends CPUParticles2D
class_name JuiceSplash
# ============================================================================
# JuiceSplash: pequena explosion de "zumo" del color de la fruta que acompaña
# cada corte. Un solo burst radial (one_shot) que cae un instante con gravedad
# y se auto-libera al terminar.
#
# ----------------------------------------------------------------------------
# TEXTURAS POR FRUTA (estructura):
# Crea aqui:  assets/fruits/juice/{fruit_id}.png
# con fruit_id = la clave de FruitDatabase.gd (strawberry, banana, peach, ...).
#   - Si existe el PNG, se usa tal cual (debe llevar ya su propio color, con
#     fondo transparente). Si no, se usa la gota generada en codigo teñida con
#     base_color de la fruta.
#   - La escala visual es la misma sea cual sea la resolucion del PNG: las
#     particulas salen de ~4.8 a 19.2 px (variacion aleatoria por gota).
# ----------------------------------------------------------------------------
#
# Uso: instancia a la posicion del corte y llama
#      setup(color, cantidad, fruit_id).
# ============================================================================

const JUICE_DIR: String = "res://assets/fruits/juice/"
const SUPPORTED_EXTS: Array[String] = ["png", "svg"]

# Tamaños visibles de las gotas (px) y límites de cantidad por corte.
# Editables en el inspector de la escena (JuiceSplash.tscn).
@export_range(0.0, 80.0, 0.1) var drop_size_min_px: float = 4.8
@export_range(0.0, 80.0, 0.1) var drop_size_max_px: float = 19.2
@export_range(0, 128, 1) var amount_min: int = 8
@export_range(0, 256, 1) var amount_max: int = 48

# Gotas compartidas: se cargan/generan una sola vez y reutilizan entre cortes.
static var _drop_texture: ImageTexture
static var _fruit_textures: Dictionary = {}

func _ready() -> void:
	finished.connect(queue_free)
	set_emitting(true)

# Aplica color/cantidad y la textura por fruta si existe.
# Cada particula recibe un tamano aleatorio entre min y max (escala relativa al
# ancho de la textura) para que parezcan gotas liquidas desiguales.
func setup(color: Color, p_amount: int = 16, fruit_id: String = "") -> void:
	amount = clampi(p_amount, amount_min, amount_max)
	var tex: Texture2D = JuiceSplash._get_fruit_texture(fruit_id)
	if tex:
		texture = tex
		modulate = Color(1, 1, 1, 1)
	else:
		texture = JuiceSplash._get_drop_texture()
		modulate = color
	# Normaliza al ancho real del PNG: ~4.8-19.2 px visibles en pantalla.
	var px := maxf(float(texture.get_width()), 1.0)
	scale_amount_min = drop_size_min_px / px
	scale_amount_max = drop_size_max_px / px

# Carga y cachea la textura de zumo de una fruta (null si no existe).
static func _get_fruit_texture(fruit_id: String) -> Texture2D:
	if fruit_id.is_empty():
		return null
	if _fruit_textures.has(fruit_id):
		return _fruit_textures[fruit_id]
	for ext in SUPPORTED_EXTS:
		var path := "%s%s.%s" % [JUICE_DIR, fruit_id, ext]
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			_fruit_textures[fruit_id] = tex
			return tex
	_fruit_textures[fruit_id] = null
	return null

static func _get_drop_texture() -> ImageTexture:
	if _drop_texture == null:
		_drop_texture = _generate_drop_texture(64)
	return _drop_texture

# Dibuja una gota en escala de grises (blanco * modulate = color de la fruta)
# con sombreado 3D tipo "liquido metalizado":
#   - Mascara circular con borde suavizado (transparencia).
#   - Iluminacion Phong falsa: normal de esfera + luz desde arriba-izquierda,
#     centro brillante, borde oscuro y transiciones contrastadas.
#   - Specular apretado (validado al cuadrado de la luz) = brillo "metal".
#   - Fresnel: anillo luminoso en el contorno, como el borde de una gota/sup.
static func _generate_drop_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := size * 0.5
	var radius := size * 0.46
	# Fuente de luz arriba-izquierda, mirando al espectador.
	var light_dir := Vector3(-0.45, -0.65, 0.615).normalized()
	var view_dir := Vector3(0.0, 0.0, 1.0)
	var half_vec := (light_dir + view_dir).normalized()
	for y in size:
		for x in size:
			var pos := Vector2(x + 0.5, y + 0.5)
			var v := pos - Vector2(center, center)
			var d := v.length() / radius
			# Mascara de la gota (borde suavizado).
			var alpha := clampf(1.0 - (d - 0.82) / 0.30, 0.0, 1.0)
			if alpha <= 0.0:
				continue
			# Normal esferica proyectada (ilusion 3D).
			var nx := v.x / radius
			var ny := v.y / radius
			var nz := sqrt(maxf(1.0 - nx * nx - ny * ny, 0.0))
			var normal := Vector3(nx, ny, nz)
			# Luz difusa + especular (brillo metalizado apretado).
			var diffuse := maxf(normal.dot(light_dir), 0.0)
			var spec := pow(maxf(normal.dot(half_vec), 0.0), 70.0)
			# Fresnel: anillo luminoso en el contorno (efecto gota de vidrio).
			var rim := pow(maxf(1.0 - normal.dot(view_dir), 0.0), 3.0)
			var shade := 0.08 + 0.55 * diffuse + spec * 1.6 + rim * 0.5
			# Halo de absorcion interior: oscurece al alejarse del centro.
			var halo := clampf((d - 0.55) / 0.30, 0.0, 1.0)
			shade *= 1.0 - halo * 0.22
			shade = clampf(shade, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, alpha))
	return ImageTexture.create_from_image(img)
