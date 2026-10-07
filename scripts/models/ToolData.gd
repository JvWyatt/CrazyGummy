class_name ToolData
extends Resource
# ============================================================================
# ToolData: datos de UNA herramienta/cuchillo del juego. El balance se edita
# VISUALMENTE en los .tres de res://data/tools/ (un archivo por herramienta).
# Cargados por StatsManager al iniciar (tools_db: String -> ToolData).
# ============================================================================

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var damage: float = 5.0
# Posición en la cadena de desbloqueo (1 = la primera). Ordena la Herramientas y
# define la herramienta PREVIA requerida (la del unlock_order inmediatamente menor),
# exactamente igual que RecipeData.unlock_order en la Recetas. Sin este campo
# la tienda quedaba en el orden arbitrario de iteración del Dictionary.
@export var unlock_order: int = 1
# Costo para desbloquear durante la partida (ver RunUpgradeModal.gd).
@export var price: int = 0
@export var icon: String = "👊"
