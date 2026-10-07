extends RefCounted
## Arte de UI proporcionado por el usuario, indexado únicamente por ID canónico.
## Texturas compartidas/preimportadas: sin edición de imagen ni copias al abrir.
const TEXTURES := {
	"tool_fists": preload("res://assets/crazy_gummy/ui/collection/tool_fists.png"),
	"tool_confectioner_knife": preload("res://assets/crazy_gummy/ui/collection/tool_confectioner_knife.png"),
	"tool_confectioner_hatchet": preload("res://assets/crazy_gummy/ui/collection/tool_confectioner_hatchet.png"),
	"tool_gummy_hammer": preload("res://assets/crazy_gummy/ui/collection/tool_gummy_hammer.png"),
	"tool_sugar_mallet": preload("res://assets/crazy_gummy/ui/collection/tool_sugar_mallet.png"),
	"tool_shredder_axe": preload("res://assets/crazy_gummy/ui/collection/tool_shredder_axe.png"),
	"tool_candy_crusher": preload("res://assets/crazy_gummy/ui/collection/tool_candy_crusher.png"),
	"tool_hydraulic_hammer": preload("res://assets/crazy_gummy/ui/collection/tool_hydraulic_hammer.png"),
	"tool_gummy_crusher": preload("res://assets/crazy_gummy/ui/collection/tool_gummy_crusher.png"),
	"tool_crazy_hammer": preload("res://assets/crazy_gummy/ui/collection/tool_crazy_hammer.png"),
	"bear_classic": preload("res://assets/crazy_gummy/ui/collection/bear_classic.png"),
	"ring": preload("res://assets/crazy_gummy/ui/collection/ring.png"),
	"ring_premium": preload("res://assets/crazy_gummy/ui/collection/ring_premium.png"),
	"worm": preload("res://assets/crazy_gummy/ui/collection/worm.png"),
	"worm_premium": preload("res://assets/crazy_gummy/ui/collection/worm_premium.png"),
	"bottle": preload("res://assets/crazy_gummy/ui/collection/bottle.png"),
	"bottle_premium": preload("res://assets/crazy_gummy/ui/collection/bottle_premium.png"),
	"heart": preload("res://assets/crazy_gummy/ui/collection/heart.png"),
	"heart_premium": preload("res://assets/crazy_gummy/ui/collection/heart_premium.png"),
	"fish": preload("res://assets/crazy_gummy/ui/collection/fish.png"),
	"fish_premium": preload("res://assets/crazy_gummy/ui/collection/fish_premium.png"),
	"crocodile": preload("res://assets/crazy_gummy/ui/collection/crocodile.png"),
	"crocodile_premium": preload("res://assets/crazy_gummy/ui/collection/crocodile_premium.png"),
	"shark": preload("res://assets/crazy_gummy/ui/collection/shark.png"),
	"shark_premium": preload("res://assets/crazy_gummy/ui/collection/shark_premium.png"),
	"dragon": preload("res://assets/crazy_gummy/ui/collection/dragon.png"),
	"dragon_premium": preload("res://assets/crazy_gummy/ui/collection/dragon_premium.png"),
	"unicorn": preload("res://assets/crazy_gummy/ui/collection/unicorn.png"),
	"unicorn_premium": preload("res://assets/crazy_gummy/ui/collection/unicorn_premium.png"),
	"bear_crown": preload("res://assets/crazy_gummy/ui/collection/bear_crown.png"),
}

static func texture_for(item_id: String) -> Texture2D:
	return TEXTURES.get(item_id) as Texture2D
