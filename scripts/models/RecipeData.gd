class_name RecipeData
extends Resource
# ============================================================================
# RecipeData: datos base de una receta/gomita y la dureza de su cubo.
# El balance se edita en data/recipes/; IDs canónicos, sin aliases de compatibilidad.
# En runtime, RecipeDatabase.create_block_recipe() crea una copia con los
# multiplicadores de comodines/mejoras ya aplicados. No edites los valores por
# defecto aquí para balancear: eso se hace en los archivos de data/recipes/.
# ============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var icon_emoji: String = "🍬"
@export var max_hp: float = 10.0
@export var min_reward: float = 1.0
@export var max_reward: float = 3.0
@export var unlock_order: int = 1
# Precio de la receta en el mercado (0 = gratis, la primera).
# Antes vivía hardcodeado en RunUpgradeModal.gd (recipe_prices).
@export var price: int = 0
@export var base_color: Color = Color(0.9, 0.2, 0.2)
@export var inner_color: Color = Color(1.0, 0.4, 0.4)
@export var accent_color: Color = Color(0.2, 0.8, 0.3)
@export var radius: float = 40.0
@export var visual_family: String = "round"
