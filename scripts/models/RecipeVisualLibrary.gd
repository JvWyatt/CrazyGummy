extends RefCounted
class_name RecipeVisualLibrary
## Solo geometría: referencias explícitas para importación/exportación del catálogo.

const RECIPE_IDS = ["bear_classic", "ring", "ring_premium", "worm", "worm_premium", "bottle", "bottle_premium", "heart", "heart_premium", "fish", "fish_premium", "crocodile", "crocodile_premium", "shark", "shark_premium", "dragon", "dragon_premium", "unicorn", "unicorn_premium", "bear_crown"]
const GUMMIES = [
	preload("res://assets/crazy_gummy/gummies/gummy_01_bear.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_02_ring.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_03_ring_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_04_worm.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_05_worm_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_06_bottle.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_07_bottle_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_08_heart.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_09_heart_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_10_fish.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_11_fish_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_12_crocodile.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_13_crocodile_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_14_shark.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_15_shark_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_16_dragon.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_17_dragon_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_18_unicorn.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_19_unicorn_premium.glb"),
	preload("res://assets/crazy_gummy/gummies/gummy_20_bear_crown.glb"),
]
const CUBES = [
	preload("res://assets/crazy_gummy/cubes/cube_01_classic.glb"),
	preload("res://assets/crazy_gummy/cubes/cube_02_wavy.glb"),
	preload("res://assets/crazy_gummy/cubes/cube_03_faceted.glb"),
	preload("res://assets/crazy_gummy/cubes/cube_04_relief.glb"),
	preload("res://assets/crazy_gummy/cubes/cube_05_crown.glb"),
	preload("res://assets/crazy_gummy/cubes/cube_06_crown_exclusive.glb"),
]
const CUBE_NAMES = ["Clásico", "Ondulado", "Facetado", "Relieve", "Corona", "Corona +"]
const HARD_CANDY = preload("res://assets/crazy_gummy/Obstaculos/obstacle_hard_candy.glb")
const HARD_CANDY_BROKEN = preload("res://assets/crazy_gummy/Obstaculos/obstacle_hard_candy_broken.glb")

static func recipe_index(recipe_id: String) -> int:
	var index := RECIPE_IDS.find(recipe_id)
	assert(index >= 0, "Receta sin geometría definitiva: " + recipe_id)
	return maxi(index, 0)

static func cube_index(recipe_id: String) -> int:
	var index := recipe_index(recipe_id)
	return 5 if index == 19 else mini(index / 4, 4)

static func gummy_scene(recipe_id: String) -> PackedScene:
	return GUMMIES[recipe_index(recipe_id)]

static func cube_scene(recipe_id: String) -> PackedScene:
	return CUBES[cube_index(recipe_id)]

static func cube_name(recipe_id: String) -> String:
	return CUBE_NAMES[cube_index(recipe_id)] + (" +" if recipe_id.ends_with("_premium") else "")

static func product_orientation(recipe_id: String) -> Vector3:
	# El cocodrilo se exportó longitudinal al eje Z: presentar su perfil.
	return Vector3(0, 90, 0) if recipe_id in ["crocodile", "crocodile_premium"] else Vector3.ZERO
