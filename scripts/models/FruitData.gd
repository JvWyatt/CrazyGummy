class_name FruitData
extends Resource
# ============================================================================
# FruitData: los datos base de UNA fruta (balance y apariencia). El balance se
# edita VISUALMENTE en los .tres de res://data/fruits/ (un archivo por fruta).
# En runtime, FruitDatabase.create_fruit_resource() crea una copia con los
# multiplicadores de comodines/mejoras ya aplicados. No edites los valores por
# defecto aquí para balancear: eso se hace en los archivos de data/fruits/.
# ============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var icon_emoji: String = "🍎"
@export var max_hp: float = 10.0
@export var min_reward: float = 1.0
@export var max_reward: float = 3.0
@export var unlock_order: int = 1
# Precio de desbloqueo en la Frutería del mercado (0 = gratis, la primera).
# Antes vivía hardcodeado en RunUpgradeModal.gd (fruit_prices).
@export var price: int = 0
@export var base_color: Color = Color(0.9, 0.2, 0.2)
@export var inner_color: Color = Color(1.0, 0.4, 0.4)
@export var accent_color: Color = Color(0.2, 0.8, 0.3)
@export var radius: float = 40.0
@export var shape_type: String = "round"
