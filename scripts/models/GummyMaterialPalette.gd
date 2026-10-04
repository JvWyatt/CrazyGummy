class_name GummyMaterialPalette
extends Resource
# Catálogo exclusivamente visual; el índice lee el unlock_order existente.

@export var tiers: Array[Material] = []
@export var golden_material: Material

func material_for(tier: int, golden: bool) -> Material:
	if golden and golden_material != null:
		return golden_material
	if tiers.is_empty():
		return null
	return tiers[clampi(tier - 1, 0, tiers.size() - 1)]
