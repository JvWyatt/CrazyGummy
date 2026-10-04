class_name RunUpgradeData
extends Resource
# ============================================================================
# RunUpgradeData: datos de UNA mejora del mercado ("Mejoras"). El balance se
# edita VISUALMENTE en los .tres de res://data/run_upgrades/ (un archivo por
# mejora). Cargados por StatsManager (run_upgrade_definitions: String -> RunUpgradeData).
# El id coincide con la clave de StatsManager.run_upgrade_levels.
# ============================================================================

@export var id: String = ""
@export var name: String = ""
@export var desc: String = ""
# Costo de la primera compra (nivel 0). Cada compra crece ×cost_mult.
@export var base_cost: float = 5.0
@export var cost_mult: float = 1.5
@export var icon: String = "💥"