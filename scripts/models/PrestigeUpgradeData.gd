class_name PrestigeUpgradeData
extends Resource
# ============================================================================
# PrestigeUpgradeData: datos de UNA mejora permanente de prestigio (comprada
# con reputación). El balance se edita VISUALMENTE en los .tres de
# res://data/prestige/ (un archivo por mejora). Cargados por StatsManager
# (prestige_definitions: String -> PrestigeUpgradeData).
# ============================================================================

@export var id: String = ""
@export var name: String = ""
@export var desc: String = ""
# Costo base del nivel 1 (cada nivel crece ×balance.prestige_price_growth).
@export var cost: float = 3.0
@export var icon: String = "⚔️"