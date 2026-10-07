extends Sprite2D
class_name BlockSpriteFallback
# ============================================================================
# BlockSpriteFallback: representación SPRITE (Sprite2D) de una cubo.
# ----------------------------------------------------------------------------
# Únicamente visual: NO contiene lógica de balance ni reglas. Lee la cubo que
# ya existe (recipe_data / is_golden en GummyBlock.gd) y muestra su imagen.
#
# SUSTITUCIÓN POR ARTE REAL:
#   Este respaldo 2D es opcional y está oculto en GummyBlock.tscn: el gameplay
#   activo usa los cubos/gomitas 3D. Si algún día se repone arte de respaldo,
#   basta con dejar los .png en OPTIONAL_SPRITE_DIR con nombre <id>.png. La
#   lógica del juego, los IDs y el balance no cambian.
#
# Tamaños:
#   Cada png se generó con diámetro = 2 * radius (el radio/aparición de cada
#   cubo), para que se vea exactamente igual a como dibujaba el sistema
#   anterior (la escena GummyBlock.tscn escala x1.5 todo el nodo). El anillo dorado
#   se escala por radio en _refresh().
# ============================================================================

# Carpeta opcional de respaldo (puede no existir: la carga es tolerante).
const OPTIONAL_SPRITE_DIR: String = "res://assets/provisional/recipe_sprites"
const GOLDEN_RING_FILE: String = "golden_ring.png"
# Radio de referencia con el que se dibujó el anillo dorado en píxeles.
const RING_REF_RADIUS: float = 50.0
# Factor SOLO visual (0.75 = -25%). Reduce el sprite un 25% SIN tocar el hitbox
# de golpe (el hitbox lo fija fd.radius en GummyBlock.gd). Coherente con Projectile3D.
# Editable en el inspector de la escena GummyBlock.tscn (nodo "Visual").
@export_range(0.1, 2.0, 0.05) var visual_scale: float = 0.75

# IDs canónicos con respaldo opcional: un id desconocido cae en el clásico.
const OPTIONAL_SPRITE_IDS: Array[String] = [
	"bear_classic", "ring", "ring_premium", "worm", "worm_premium",
	"bottle", "bottle_premium", "heart", "heart_premium", "fish",
	"fish_premium", "crocodile", "crocodile_premium", "shark",
	"shark_premium", "dragon", "dragon_premium", "unicorn",
	"unicorn_premium", "bear_crown",
]

static var _texture_cache: Dictionary = {}
static var _ring_texture_cache: Texture2D

@onready var block_parent: GummyBlock = get_parent() as GummyBlock
@onready var golden_ring: Sprite2D = $GoldenRing

func _ready() -> void:
	if not _ring_texture_cache:
		_ring_texture_cache = _load_optional_texture(OPTIONAL_SPRITE_DIR.path_join(GOLDEN_RING_FILE))
	if golden_ring and _ring_texture_cache:
		golden_ring.texture = _ring_texture_cache
	refresh_visual()

# Se llama desde GummyBlock.gd (setup) cuando cambia recipe_data/is_golden.
func refresh_visual() -> void:
	if not block_parent:
		return
	var fd: RecipeData = block_parent.recipe_data
	if not fd:
		return
	var tex: Texture2D = _texture_for(fd.id)
	# Estos sprites son opcionales: limpiar también la imagen de una receta previa.
	texture = tex
	var texture_width: float = float(tex.get_width()) if tex != null else 0.0
	# Ajusta el sprite al radio actual: los .png se generaron con diametro
	# 2 * radio ORIGINAL, y el nodo GummyBlock.tscn escala x1.5, asi que diametro
	# visible = tex_width * 1.5 * k. Para que quede en 2 * radio * 1.5,
	# k = 2 * radio / tex_width.
	if texture_width > 0.0:
		var k: float = 2.0 * fd.radius * visual_scale / texture_width
		scale = Vector2(k, k)
	else:
		scale = Vector2.ONE
	if golden_ring:
		golden_ring.visible = block_parent.is_golden and texture_width > 0.0 and golden_ring.texture != null
		# El anillo (png = 2*RING_REF px) se escala con el mismo k del sprite
		# para que rodee a la cubo en cualquier radio.
		var rk: float = texture_width / (2.0 * RING_REF_RADIUS) if texture_width > 0.0 else 1.0
		golden_ring.scale = Vector2(rk, rk)

func _texture_for(recipe_id: String) -> Texture2D:
	if _texture_cache.has(recipe_id):
		return _texture_cache[recipe_id]
	# Respeta el orden de la cadena: un id sin arte hereda el clásico.
	var sprite_id: String = recipe_id if recipe_id in OPTIONAL_SPRITE_IDS else "bear_classic"
	var tex: Texture2D = _load_optional_texture(OPTIONAL_SPRITE_DIR.path_join(sprite_id + ".png"))
	if tex:
		_texture_cache[recipe_id] = tex
	return tex

func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	return load(path) as Texture2D
