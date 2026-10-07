class_name BalanceData
extends Resource
# ============================================================================
# BalanceData: constantes de balance global del juego (editables visualmente).
# Se editan en res://data/balance.tres desde el inspector. Cargado por
# StatsManager al iniciar (si el .tres falta, usa los valores por defecto).
# ============================================================================

# Gasto global por golpe: todas las herramientas comparten la misma resistencia.
@export var base_energy_cost: float = 1.0
# Factor global para ajustar el gasto sin modificar herramientas individuales.
@export var resistance_cost_multiplier: float = 1.0
# Probabilidad base (0.0 a 1.0) de que aparezca una receta dorada al generarse.
# 0%: la gomita dorada solo se activa mediante comodines (card_golden_gummy_chance).
@export var golden_gummy_chance: float = 0.0
# Multiplicador aplicado a las recompensas mínima/máxima de las recetas para
# ajustar el balance general de ganancias sin tocar cada receta una por una.
@export var reward_rebalance_multiplier: float = 1.0
# Daño crítico: SIEMPRE multiplica el daño por este valor. No se puede mejorar
# ni por mejoras del mercado ni por comodines (balance fijo).
@export var critical_damage_multiplier: float = 1.5

# ---- Frecuencia de lanzamiento (recetas/obstáculos por segundo) -------------
# La frecuencia final = base x (1 + bonus run)^nivel x (1 + bonus prestigio)^nivel x comodines.
@export var base_launch_rate: float = 1.0
# +5% de ritmo de cubos por cada compra de Ritmo en el mercado.
@export var run_launch_bonus_per_level: float = 0.05
# +10% de frecuencia por cada nivel de prestigio "Ritmo Veloz".
@export var prestige_launch_bonus_per_level: float = 0.10

# ---- Obstáculos (caramelos endurecidos...) ------------------------------------------------
# Frecuencia de obstáculos COMPLETAMENTE SEPARADA de la de recetas: es una TASA
# FIJA de caramelos endurecidos por segundo, sin mejoras/comodines, con intervalo ALEATORIO.
@export var obstacle_interval_min: float = 1.0
@export var obstacle_interval_max: float = 2.0
# Fracción de la resistencia MÁXIMA total que se pierde al golpear un
# obstáculo (10% por golpe: un peligro moderado y sostenido).
@export var obstacle_resistance_penalty_fraction: float = 0.10

# Factor de crecimiento del precio de prestigio por nivel adquirido (×1.5).
@export var prestige_price_growth: float = 1.5

# ---- Progresión del negocio (días/pedidos) ----------------------------------
# Cuota del día 1 = $0 (regalo); desde el día 2 la cuota es base × growth^(N-2).
@export var base_order_target: float = 10.0
@export var order_target_growth: float = 1.21
# Duración de cada ronda en segundos (límite FIJO, no mejorable).
@export var round_time_seconds: float = 60.0
# Día de victoria (al completarlo se muestran los créditos; luego se puede
# seguir jugando para hacer récords a partir de ese día).
@export var win_day: int = 100

# ---- Resistencia máxima base --------------------------------------------------
@export var base_max_energy: float = 100.0

# ---- Bonos por nivel de las mejoras del mercado --------------------------------
@export var run_damage_bonus_per_level: float = 0.05
# Umbral exclusivo del mercado: por debajo, el incremento porcentual tiene
# un mínimo de damage_pity_flat_per_level; desde el umbral solo se multiplica.
@export var damage_pity_floor: float = 10.0
@export var damage_pity_flat_per_level: float = 1.0
@export var run_energy_bonus_per_level: float = 0.05
@export var run_money_bonus_per_level: float = 0.05
# +0.1 puntos porcentuales por nivel (probabilidad expresada de 0.0 a 1.0).
@export var run_jackpot_bonus_per_level: float = 0.001

# ---- Bonos por nivel de prestigio ---------------------------------------------
@export var prestige_damage_bonus_per_level: float = 0.10
@export var prestige_energy_bonus_per_level: float = 0.10
@export var prestige_money_bonus_per_level: float = 0.10
# +1 punto porcentual por nivel; no es un incremento relativo.
@export var prestige_jackpot_bonus_per_level: float = 0.01

# ---- Gran Venta (Jackpot) ------------------------------------------------------
# Probabilidad base del 1%, antes de sumar mejoras y comodines.
@export var base_jackpot_chance: float = 0.01
# Cuántas veces multiplica la recompensa una receta en "Gran Venta".
@export var base_jackpot_multiplier: float = 2.0
