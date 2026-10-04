class_name KnifeData
extends Resource
# ============================================================================
# KnifeData: datos de UNA arma/cuchillo del juego. El balance se edita
# VISUALMENTE en los .tres de res://data/knives/ (un archivo por arma).
# Cargados por StatsManager al iniciar (knives_db: String -> KnifeData).
# ============================================================================

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var damage: float = 5.0
# Posición en la cadena de desbloqueo (1 = la primera). Ordena la Armería y
# define la arma PREVIA requerida (la del unlock_order inmediatamente menor),
# exactamente igual que FruitData.unlock_order en la Frutería. Sin este campo
# la tienda quedaba en el orden arbitrario de iteración del Dictionary.
@export var unlock_order: int = 1
# Costo para desbloquear durante la partida (ver RunUpgradeModal.gd).
@export var price: int = 0
@export var icon: String = "👊"
