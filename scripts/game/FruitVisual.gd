extends Sprite2D
class_name FruitVisual
# ============================================================================
# FruitVisual: representación SPRITE (Sprite2D) de una fruta.
# ----------------------------------------------------------------------------
# Únicamente visual: NO contiene lógica de balance ni reglas. Lee la fruta que
# ya existe (fruit_data / is_golden en Fruit.gd) y muestra su imagen.
#
# SUSTITUCIÓN POR ARTE REAL:
#   Cada fruta apunta a su imagen en TEXTURE_PATHS (id -> ruta). Para poner los
#   sprites definitivos basta con reemplazar los .png de res://assets/fruits/
#   (manteniendo los mismos nombres) o cambiar las rutas aquí. La lógica del
#   juego, los IDs y el balance no cambian.
#
# Tamaños:
#   Cada png se generó con diámetro = 2 * radius (el radio/aparición de cada
#   fruta), para que se vea exactamente igual a como dibujaba el sistema
#   anterior (la escena Fruit.tscn escala x1.5 todo el nodo). El anillo dorado
#   se escala por radio en _refresh().
# ============================================================================

# Radio de referencia con el que se dibujó golden_ring.png en píxeles.
const RING_REF_RADIUS: float = 50.0
const GOLDEN_RING_PATH: String = "res://assets/fruits/golden_ring.png"
# Factor SOLO visual (0.75 = -25%). Reduce el sprite un 25% SIN tocar el hitbox
# de corte (el hitbox lo fija fd.radius en Fruit.gd). Coherente con Fruit3D.
# Editable en el inspector de la escena Fruit.tscn (nodo "Visual").
@export_range(0.1, 2.0, 0.05) var visual_scale: float = 0.75

const TEXTURE_PATHS: Dictionary = {
	"strawberry": "res://assets/fruits/strawberry.png",
	"banana": "res://assets/fruits/banana.png",
	"peach": "res://assets/fruits/peach.png",
	"cherry": "res://assets/fruits/cherry.png",
	"orange": "res://assets/fruits/orange.png",
	"apple": "res://assets/fruits/apple.png",
	"pear": "res://assets/fruits/pear.png",
	"kiwi": "res://assets/fruits/kiwi.png",
	"mango": "res://assets/fruits/mango.png",
	"lemon": "res://assets/fruits/lemon.png",
	"watermelon": "res://assets/fruits/watermelon.png",
	"melon": "res://assets/fruits/melon.png",
	"pineapple": "res://assets/fruits/pineapple.png",
	"papaya": "res://assets/fruits/papaya.png",
	"coconut": "res://assets/fruits/coconut.png",
	"avocado": "res://assets/fruits/avocado.png",
	"dragon_fruit": "res://assets/fruits/dragon_fruit.png",
	"guava": "res://assets/fruits/guava.png",
	"quince": "res://assets/fruits/quince.png",
	"pumpkin": "res://assets/fruits/pumpkin.png",
}

static var _texture_cache: Dictionary = {}
static var _ring_texture_cache: Texture2D

@onready var fruit_parent: Fruit = get_parent() as Fruit
@onready var golden_ring: Sprite2D = $GoldenRing

func _ready() -> void:
	if not _ring_texture_cache:
		_ring_texture_cache = load(GOLDEN_RING_PATH)
	if golden_ring and _ring_texture_cache:
		golden_ring.texture = _ring_texture_cache
	refresh_visual()

# Se llama desde Fruit.gd (setup) cuando cambia fruit_data/is_golden.
func refresh_visual() -> void:
	if not fruit_parent:
		return
	var fd: FruitData = fruit_parent.fruit_data
	if not fd:
		return
	var tex: Texture2D = _texture_for(fd.id)
	if tex and texture != tex:
		texture = tex
	# Ajusta el sprite al radio actual: los .png se generaron con diametro
	# 2 * radio ORIGINAL, y el nodo Fruit.tscn escala x1.5, asi que diametro
	# visible = tex_width * 1.5 * k. Para que quede en 2 * radio * 1.5,
	# k = 2 * radio / tex_width.
	if tex:
		var k: float = 2.0 * fd.radius * visual_scale / float(tex.get_width())
		scale = Vector2(k, k)
	if golden_ring:
		golden_ring.visible = fruit_parent.is_golden
		# El anillo (png = 2*RING_REF px) se escala con el mismo k del sprite
		# para que rodee a la fruta en cualquier radio.
		var rk: float = float(tex.get_width()) / (2.0 * RING_REF_RADIUS)
		golden_ring.scale = Vector2(rk, rk)

func _texture_for(fruit_id: String) -> Texture2D:
	if _texture_cache.has(fruit_id):
		return _texture_cache[fruit_id]
	var path: String = str(TEXTURE_PATHS.get(fruit_id, TEXTURE_PATHS["strawberry"]))
	var tex: Texture2D = load(path)
	if tex:
		_texture_cache[fruit_id] = tex
	return tex
