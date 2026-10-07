class_name GameCatalog
extends Resource
# ============================================================================
# GameCatalog: ÍNDICE de TODOS los datos de balance de res://data/.
# ----------------------------------------------------------------------------
# Cada receta, herramienta, mejora de mercado y mejora de prestigio sigue siendo un
# .tres propio y editable (res://data/recipes/*.tres, res://data/tools/*.tres,
# res://data/run_upgrades/*.tres, res://data/prestige/*.tres). Este recurso es
# el ÍNDICE que los referencia a todos, y lo cargan StatsManager (herramientas,
# mejoras y prestigio) y RecipeDatabase (recetas).
#
# POR QUÉ HACE FALTA (no usar DirAccess sobre res://data/):
# Al exportar, Godot convierte los .tres/.tscn a binario y los guarda DENTRO
# del PCK bajo una ruta interna distinta (.godot/exported/...) con una entrada
# de remap. El archivo original "res://data/recipes/bottle.tres" NO existe dentro
# del juego exportado, así que la carpeta "res://data/recipes/" tampoco: un
# DirAccess.open() de ahí devuelve null y el juego se queda con los datos de
# respaldo (una sola receta, un solo herramienta, ninguna mejora). En cambio load() de
# una ruta concreta SÍ funciona siempre porque el remap la resuelve, y al
# referenciar los .tres desde aquí el exportador los incluye sí o sí.
#
# Para añadir un ítem nuevo: crea su .tres en res://data/<carpeta>/ y
# arrástralo a la lista correspondiente de este recurso (res://data/catalog.tres).
# ============================================================================

const CATALOG_PATH: String = "res://data/catalog.tres"

@export_group("Recetas")
@export var recipes: Array[RecipeData] = []

@export_group("Herramientas")
@export var tools: Array[ToolData] = []

@export_group("Mejoras del mercado")
@export var run_upgrades: Array[RunUpgradeData] = []

@export_group("Mejoras de prestigio")
@export var prestige_upgrades: Array[PrestigeUpgradeData] = []
