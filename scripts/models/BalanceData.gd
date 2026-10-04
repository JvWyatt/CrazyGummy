class_name BalanceData
extends Resource
# ============================================================================
# BalanceData: constantes de balance global del juego (editables visualmente).
# Se editan en res://data/balance.tres desde el inspector. Cargado por
# StatsManager al iniciar (si el .tres falta, usa los valores por defecto).
# ============================================================================

# Gasto global por corte: todas las armas comparten la misma resistencia.
@export var base_energy_cost: float = 1.0
# Factor global para ajustar el gasto sin modificar armas individuales.
@export var resistance_cost_multiplier: float = 1.0
# Probabilidad base (0.0 a 1.0) de que aparezca una fruta dorada al generarse.
# 0%: la Fruta Dorada SOLO se activa mediante comodines (card_golden_fruit_chance).
@export var golden_fruit_chance: float = 0.0
# Multiplicador aplicado a las recompensas mínima/máxima de las frutas para
# ajustar el balance general de ganancias sin tocar cada fruta una por una.
@export var reward_rebalance_multiplier: float = 1.0
# Daño crítico: SIEMPRE multiplica el daño por este valor. No se puede mejorar
# ni por mejoras del mercado ni por comodines (balance fijo).
@export var critical_damage_multiplier: float = 1.5

# ---- Frecuencia de lanzamiento (frutas/obstáculos por segundo) -------------
# La frecuencia final = base x (1 + bonus run)^nivel x (1 + bonus prestigio)^nivel x comodines.
@export var base_launch_rate: float = 1.0
# +10% de frecuencia por cada compra de la mejora "Cosecha Veloz" del mercado.
@export var run_launch_bonus_per_level: float = 0.10
# +25% de frecuencia por cada nivel de prestigio "Ritmo Veloz".
@export var prestige_launch_bonus_per_level: float = 0.25

# ---- Obstáculos (piedras...) ------------------------------------------------
# Frecuencia de obstáculos COMPLETAMENTE SEPARADA de la de frutas: es una TASA
# FIJA de piedras por segundo, sin mejoras/comodines, con intervalo ALEATORIO.
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
@export var run_damage_bonus_per_level: float = 0.10
# Umbral exclusivo del mercado: por debajo, el incremento porcentual tiene
# un mínimo de damage_pity_flat_per_level; desde el umbral solo se multiplica.
@export var damage_pity_floor: float = 10.0
@export var damage_pity_flat_per_level: float = 1.0
@export var run_energy_bonus_per_level: float = 0.10
@export var run_money_bonus_per_level: float = 0.10
@export var run_jackpot_bonus_per_level: float = 0.00777

# ---- Bonos por nivel de prestigio ---------------------------------------------
@export var prestige_damage_bonus_per_level: float = 0.20
@export var prestige_energy_bonus_per_level: float = 0.20
@export var prestige_money_bonus_per_level: float = 0.20
@export var prestige_jackpot_bonus_per_level: float = 0.0777

# ---- Gran Venta (Jackpot) ------------------------------------------------------
# Cuántas veces multiplica la recompensa una fruta en "Gran Venta".
@export var base_jackpot_multiplier: float = 2.0
