extends Node
# ============================================================================
# AchievementManager (Autoload / Singleton)
# ----------------------------------------------------------------------------
# Sistema de LOGROS del juego. Gestiona:
#   - La TABLA de todos los logros (DEFINITIONS), >100 desde la primera versión.
#   - El PROGRESO de cada logro (métricas globales que suman durante toda la
#     partida y entre partidas).
#   - El ESTADO de desbloqueo (persistente, guardado en SaveManager.save_data).
#   - El evento seamless quando un logro se desbloquea (signal achievement_unlocked)
#     para que el HUD muestre la notificación durante la partida.
#
# Design:
#   - kind == "counter" : logros de cantidad/progreso gradual. Progreso =
#     metrics[metric]. Se desbloquea cuando progress >= target. Solo estos
#     usan barra de progreso en la UI.
#   - kind == "flag"    : logros binarios/seguidos/graciosos/easter-egg. Se
#     desbloquean cuando el flag correspondiente se marca con set_flag().
# Las métricas y flags se persisten para que el progreso no se pierda nunca.
# ============================================================================

signal achievement_unlocked(id: String, def: Dictionary)

const SAVE_KEY := "achievements"

# Cuando es true, los desbloqueos se registran PERO no emiten la señal. Se
# gestiona de forma pareada en evaluate_all(suppress_notifications) para
# cubrir el desbloqueo retroactivo silencioso al arrancar.
var _suppress_notifications: bool = false

# Guardado deferred: en lugar de escribir a disco en cada metric/flag update
# (que puede ocurrir 60+ veces por segundo durante rachas largas), se acumulan
# los cambios y se persisten con un debounce de 0.5s.
const SAVE_DEBOUNCE: float = 0.5
var _save_pending: bool = false
var _save_timer: float = 0.0

# ---------------------------------------------------------------------------
# TABLA DE LOGROS
# ---------------------------------------------------------------------------
# Campos:
#   id, name, desc, icon.
#   cat: categoría visual (cantidad | objetivo | estilo | gracioso | secreto).
#   kind: "counter" (progreso gradual) o "flag" (binario).
#   metric: para kind=="counter", clave de la métrica que mide el progreso.
#   target: para kind=="counter", valor objetivo.
#   flag: para kind=="flag", nombre del flag que lo desbloquea.
const DEFINITIONS: Array[Dictionary] = [
	# --- CANTIDAD: Gomitas producidas (IDs históricos conservados) -----------
	{"id":"aprendiz_de_gelatina","name":"Aprendiz de Gelatina","desc":"Produce 250 gomitas en total.","icon":"🍬","cat":"cantidad","kind":"counter","metric":"gummies_produced","target":250},
	{"id":"recolector","name":"Coleccionista de Gomitas","desc":"Produce 1.000 gomitas.","icon":"🍬","cat":"cantidad","kind":"counter","metric":"gummies_produced","target":1000},
	{"id":"experto_en_gelatina","name":"Experto en Gelatina","desc":"Produce 5.000 gomitas.","icon":"🧊","cat":"cantidad","kind":"counter","metric":"gummies_produced","target":5000},
	{"id":"maestro_del_impacto","name":"Maestro del Impacto","desc":"Produce 10.000 gomitas.","icon":"💥","cat":"cantidad","kind":"counter","metric":"gummies_produced","target":10000},
	{"id":"leyenda_gummy","name":"Leyenda Gummy","desc":"Produce 100.000 gomitas.","icon":"🏆","cat":"cantidad","kind":"counter","metric":"gummies_produced","target":100000},
	{"id":"universo_de_gomitas","name":"Universo de Gomitas","desc":"Produce 500.000 gomitas.","icon":"🌌","cat":"cantidad","kind":"counter","metric":"gummies_produced","target":500000},

	# --- CANTIDAD: Días / pedidos completados (mejor marca) ----------------
	{"id":"primer_dia","name":"Primer Día","desc":"Completa tu primer día de producción.","icon":"📅","cat":"cantidad","kind":"counter","metric":"best_day","target":1},
	{"id":"quincena","name":"Media Quincena","desc":"Llega al día 15.","icon":"🗓️","cat":"cantidad","kind":"counter","metric":"best_day","target":15},
	{"id":"mes_entero","name":"Mes Entero","desc":"Llega al día 30.","icon":"📆","cat":"cantidad","kind":"counter","metric":"best_day","target":30},
	{"id":"mes_y_medio","name":"Cincuenta Días Dulces","desc":"Completa el día 50.","icon":"📆","cat":"cantidad","kind":"counter","metric":"best_day","target":50},
	{"id":"centenario","name":"Centenario","desc":"Llega al día 100 (la meta).","icon":"🎬","cat":"objetivo","kind":"counter","metric":"best_day","target":100},
	{"id":"mas_alla","name":"Más Allá de la Meta","desc":"Supera el día 100 (101+).","icon":"🚀","cat":"objetivo","kind":"flag","flag":"surpassed_day_100"},
	{"id":"centenario_cincuenta","name":"Siglo y Medio","desc":"Llega al día 150.","icon":"🚀","cat":"cantidad","kind":"counter","metric":"best_day","target":150},
	{"id":"bicentenario","name":"Bicentenario","desc":"Llega al día 200.","icon":"🌠","cat":"cantidad","kind":"counter","metric":"best_day","target":200},
	{"id":"tricentenario","name":"Tricentenario","desc":"Llega al día 300.","icon":"♾️","cat":"cantidad","kind":"counter","metric":"best_day","target":300},

	# --- CANTIDAD: Dinero generado (acumulado total) ------------------------
	{"id":"alcanzando_metas","name":"Primeros Beneficios","desc":"Genera $100.000 en total.","icon":"💰","cat":"cantidad","kind":"counter","metric":"money_total","target":100000},
	{"id":"millonario_gummy","name":"Millonario Gummy","desc":"Genera $1.000.000 en total.","icon":"💵","cat":"cantidad","kind":"counter","metric":"money_total","target":1000000},
	{"id":"gran_inversor","name":"Gran Inversor","desc":"Genera $10.000.000 en total.","icon":"🏦","cat":"cantidad","kind":"counter","metric":"money_total","target":10000000},
	{"id":"empresario","name":"Empresario","desc":"Genera $100.000.000 en total.","icon":"🏛️","cat":"cantidad","kind":"counter","metric":"money_total","target":100000000},
	{"id":"magnate_gummy","name":"Magnate Gummy","desc":"Genera $1.000.000.000 en total.","icon":"👑","cat":"cantidad","kind":"counter","metric":"money_total","target":1000000000},
	{"id":"imperio_dulce","name":"Imperio Dulce","desc":"Genera $10.000.000.000 en total.","icon":"💎","cat":"cantidad","kind":"counter","metric":"money_total","target":10000000000},

	# --- CANTIDAD: Jackpots -------------------------------------------------
	{"id":"gran_venta_inicial","name":"Gran Venta","desc":"Consigue 5 Jackpots.","icon":"⭐","cat":"cantidad","kind":"counter","metric":"jackpots","target":5},
	{"id":"suerte_de_bruja","name":"Suerte de Bruja","desc":"Consigue 25 Jackpots.","icon":"⭐","cat":"cantidad","kind":"counter","metric":"jackpots","target":25},
	{"id":"favorito_de_fortuna","name":"Favorito de la Fortuna","desc":"Consigue 100 Jackpots.","icon":"🌟","cat":"cantidad","kind":"counter","metric":"jackpots","target":100},
	{"id":"rey_de_la_fortuna","name":"Rey de la Fortuna","desc":"Consigue 500 Jackpots.","icon":"👑","cat":"cantidad","kind":"counter","metric":"jackpots","target":500},

	# --- CANTIDAD: Gomitas doradas -----------------------------------------
	{"id":"brillo_dorado","name":"Brillo Dorado","desc":"Produce 5 gomitas doradas.","icon":"✨","cat":"cantidad","kind":"counter","metric":"golden_gummies","target":5},
	{"id":"dulce_oro","name":"Dulce Oro","desc":"Produce 25 gomitas doradas.","icon":"✨","cat":"cantidad","kind":"counter","metric":"golden_gummies","target":25},
	{"id":"dorado_total","name":"Dorado Total","desc":"Produce 100 gomitas doradas.","icon":"🥇","cat":"cantidad","kind":"counter","metric":"golden_gummies","target":100},
	{"id":"dorado_legendario","name":"Leyenda Dorada","desc":"Produce 250 gomitas doradas.","icon":"🥇","cat":"cantidad","kind":"counter","metric":"golden_gummies","target":250},

	# --- CANTIDAD: Críticos ------------------------------------------------
	{"id":"impacto_preciso","name":"Impacto Preciso","desc":"Asesta 25 golpes críticos.","icon":"💥","cat":"cantidad","kind":"counter","metric":"crits","target":25},
	{"id":"impacto_critico","name":"Impacto Crítico","desc":"Asesta 250 golpes críticos.","icon":"💥","cat":"cantidad","kind":"counter","metric":"crits","target":250},
	{"id":"asesino_silencioso","name":"Pulso Impecable","desc":"Asesta 1.000 golpes críticos.","icon":"🎯","cat":"cantidad","kind":"counter","metric":"crits","target":1000},
	{"id":"leyenda_critica","name":"Leyenda Crítica","desc":"Asesta 5.000 golpes críticos.","icon":"💥","cat":"cantidad","kind":"counter","metric":"crits","target":5000},

	# --- CANTIDAD: Obstáculos golpeados (gracioso) --------------------------
	{"id":"dulce_tropiezo","name":"Dulce Tropiezo","desc":"Golpea 50 caramelos endurecidos... ¿en serio?","icon":"🪨","cat":"gracioso","kind":"counter","metric":"candies_hit","target":50},
	{"id":"futbolista_sabotaje","name":"Gelatina Saboteada","desc":"Golpea 250 caramelos endurecidos.","icon":"🧱","cat":"gracioso","kind":"counter","metric":"candies_hit","target":250},
	{"id":"caramelo_implacable","name":"Caramelo Implacable","desc":"Golpea 1.000 caramelos endurecidos.","icon":"🪨","cat":"gracioso","kind":"counter","metric":"candies_hit","target":1000},

	# --- CANTIDAD: Quiebras del negocio (gracioso) --------------------------
	{"id":"primera_quiebra","name":"Primera Quiebra","desc":"Tu negocio quiebra por primera vez.","icon":"💸","cat":"gracioso","kind":"counter","metric":"runs_bankrupt","target":1},
	{"id":"empresario_riesgoso","name":"Empresario Riesgoso","desc":"Quiebra 10 negocios.","icon":"🎲","cat":"gracioso","kind":"counter","metric":"runs_bankrupt","target":10},
	{"id":"fundador_masoquista","name":"Fundador Masoquista","desc":"Quiebra 50 negocios.","icon":"😵","cat":"gracioso","kind":"counter","metric":"runs_bankrupt","target":50},

	# --- CANTIDAD: Racha máxima --------------------------------------------
	{"id":"racha_de_10","name":"Diez en Fila","desc":"Alcanza una racha de 10 gomitas.","icon":"🔥","cat":"objetivo","kind":"counter","metric":"max_streak","target":10},
	{"id":"racha_de_20","name":"Vigésima Racha","desc":"Alcanza una racha de 20 gomitas.","icon":"🔥","cat":"objetivo","kind":"counter","metric":"max_streak","target":20},
	{"id":"racha_de_30","name":"Racha de 30","desc":"Alcanza una racha de 30 gomitas.","icon":"🔥","cat":"objetivo","kind":"counter","metric":"max_streak","target":30},
	{"id":"imparable","name":"Imparable","desc":"Alcanza una racha de 50 gomitas.","icon":"🥵","cat":"objetivo","kind":"counter","metric":"max_streak","target":50},

	# --- CANTIDAD: Veces que se rompió la racha (gracioso) ------------------
	{"id":"se_me_fue","name":"Se Me Fue","desc":"Rompe tu racha por primera vez.","icon":"🍂","cat":"gracioso","kind":"counter","metric":"streak_broke","target":1},
	{"id":"corredor_de_tropezones","name":"Tropiezo Recurrente","desc":"Rompe la racha 50 veces.","icon":"🪨","cat":"gracioso","kind":"counter","metric":"streak_broke","target":50},

	# --- CANTIDAD: Reputación/prestigio ------------------------------------
	{"id":"primera_estrella","name":"Comerciante Neófito","desc":"Acumula 15 puntos de reputación.","icon":"⭐","cat":"cantidad","kind":"counter","metric":"prestige_earned","target":15},
	{"id":"honorable","name":"Comerciante Honorable","desc":"Acumula 100 puntos de reputación.","icon":"🌟","cat":"cantidad","kind":"counter","metric":"prestige_earned","target":100},
	{"id":"leyenda_del_mercado","name":"Leyenda del Mercado","desc":"Acumula 500 puntos de reputación.","icon":"🏆","cat":"cantidad","kind":"counter","metric":"prestige_earned","target":500},
	{"id":"imperio_reputacion","name":"Imperio de Reputación","desc":"Acumula 1.000 puntos de reputación.","icon":"🌌","cat":"cantidad","kind":"counter","metric":"prestige_earned","target":1000},
	{"id":"inversor","name":"Inversor","desc":"Gasta 20 puntos de reputación en mejoras de prestigio.","icon":"🏦","cat":"cantidad","kind":"counter","metric":"prestige_spent","target":20},
	{"id":"magnate","name":"Magnate de Prestigio","desc":"Gasta 200 puntos de reputación.","icon":"🎓","cat":"cantidad","kind":"counter","metric":"prestige_spent","target":200},
	{"id":"magnate_total","name":"Especulador Máximo","desc":"Gasta 1.000 puntos de reputación.","icon":"👑","cat":"cantidad","kind":"counter","metric":"prestige_spent","target":1000},

	# --- CANTIDAD: Herramientas --------------------------------------------
	{"id":"utensilios","name":"Utensilios Varios","desc":"Desbloquea 3 herramientas distintas.","icon":"🍴","cat":"cantidad","kind":"counter","metric":"tools_owned","target":3},
	{"id":"utillaje_gummy","name":"Utillaje Gummy","desc":"Desbloquea 5 herramientas distintas.","icon":"🛠️","cat":"cantidad","kind":"counter","metric":"tools_owned","target":5},
	{"id":"coleccionista_armas","name":"Utillaje Completo","desc":"Desbloquea las 10 herramientas.","icon":"🪚","cat":"cantidad","kind":"counter","metric":"tools_owned","target":10},
	{"id":"procesado_extremo","name":"Procesado Extremo","desc":"Equipa Crazy Hammer, la herramienta definitiva.","icon":"🪚","cat":"objetivo","kind":"flag","flag":"equipped_crazy_hammer"},

	# --- CANTIDAD: Recetas desbloqueadas -----------------------------------
	{"id":"recetario_inicial","name":"Recetario Inicial","desc":"Desbloquea 5 recetas distintas.","icon":"📖","cat":"cantidad","kind":"counter","metric":"recipes_unlocked","target":5},
	{"id":"recetario_experto","name":"Recetario Experto","desc":"Desbloquea 15 recetas distintas.","icon":"📖","cat":"cantidad","kind":"counter","metric":"recipes_unlocked","target":15},
	{"id":"recetario_completo","name":"Recetario Completo","desc":"Desbloquea las 20 recetas.","icon":"📖","cat":"cantidad","kind":"counter","metric":"recipes_unlocked","target":20},

	# --- CANTIDAD: Comodines descubiertos -----------------------------------
	{"id":"baraja_inicial","name":"Manos Amigas","desc":"Descubre 10 comodines distintos.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":10},
	{"id":"baraja_surtida","name":"Baraja Surtida","desc":"Descubre 30 comodines distintos.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":30},
	{"id":"cartomantico","name":"Cartomántico","desc":"Descubre 60 comodines distintos.","icon":"🔮","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":60},
	{"id":"coleccionista_cartas","name":"Coleccionista de Cartas","desc":"Descubre 100 comodines distintos.","icon":"🂠","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":100},

	# --- OBJETIVO: Días perfectos ------------------------------------------
	{"id":"dia_perfecto","name":"Día Perfecto","desc":"Completa 5 días sin tocar caramelo endurecido.","icon":"💯","cat":"objetivo","kind":"counter","metric":"clean_days","target":5},
	{"id":"semana_perfecta","name":"Semana Perfecta","desc":"Completa 20 días sin tocar caramelo endurecido.","icon":"✨","cat":"objetivo","kind":"counter","metric":"clean_days","target":20},
	{"id":"purista","name":"Purista","desc":"Completa un día con los Puños equipados al terminar.","icon":"👊","cat":"estilo","kind":"flag","flag":"day_with_fists"},
	{"id":"sin_rincon_dark","name":"Soldado de Hierro","desc":"Completa un día con Crazy Hammer equipado.","icon":"⚙️","cat":"estilo","kind":"flag","flag":"day_with_crazy_hammer"},

	# --- ESTILO: Formas de jugar -------------------------------------------
	{"id":"paciente","name":"Paciente","desc":"Completa un día con el Cuchillo de Confitero equipado.","icon":"🍴","cat":"estilo","kind":"flag","flag":"day_with_confectioner_knife"},
	{"id":"triturador_experto","name":"Triturador Experto","desc":"Completa un día con el Hacha Trituradora equipada.","icon":"🔪","cat":"estilo","kind":"flag","flag":"day_with_shredder_axe"},
	{"id":"golpe_hidraulico","name":"Golpe Hidráulico","desc":"Completa un día con el Martillo Hidráulico equipado.","icon":"🪓","cat":"estilo","kind":"flag","flag":"day_with_hydraulic_hammer"},
	{"id":"maestro_crusher","name":"Maestro Crusher","desc":"Completa un día con Gummy Crusher equipado.","icon":"⚔️","cat":"estilo","kind":"flag","flag":"day_with_gummy_crusher"},
	{"id":"herramienta_fiel","name":"Herramienta Fiel","desc":"Completa un día sin cambiar de herramienta desde el fin del día anterior.","icon":"🔒","cat":"estilo","kind":"flag","flag":"day_unchanged_tool"},

	# --- ESTILO: Suerte / doradas ------------------------------------------
	{"id":"bingo","name":"Bingo Dorado","desc":"Consigue un Jackpot con una gomita dorada.","icon":"🍀","cat":"estilo","kind":"flag","flag":"golden_jackpot"},
	{"id":"doble_dorado","name":"Doble Dorado","desc":"Produce dos gomitas doradas en un mismo día.","icon":"✨","cat":"estilo","kind":"counter","metric":"golden_gummies_in_one_day","target":2},
	{"id":"suerte_critica","name":"Suerte Crítica","desc":"Consigue 3 críticos en un mismo día.","icon":"💥","cat":"estilo","kind":"counter","metric":"crits_in_one_day","target":3},

	# --- ESTILO: Compras / inversión ---------------------------------------
	{"id":"comprador","name":"Comprador Compulsivo","desc":"Compra 5 mejoras del mercado en total.","icon":"🛒","cat":"estilo","kind":"counter","metric":"upgrades_bought_run","target":5},
	{"id":"megacomprador","name":"Megacomprador","desc":"Compra 20 mejoras del mercado en total.","icon":"🛍️","cat":"estilo","kind":"counter","metric":"upgrades_bought_run","target":20},
	{"id":"especulador","name":"Especulador","desc":"Mejora Potencia, Resistencia, Golpe de Suerte y Negociación en un mismo negocio.","icon":"📈","cat":"estilo","kind":"flag","flag":"bought_all_upgrade_types"},
	{"id":"ritmo_dulce","name":"Ritmo Dulce","desc":"Compra 3 niveles de Ritmo en un mismo negocio.","icon":"🚀","cat":"estilo","kind":"counter","metric":"launch_upgrades_run","target":3},

	# --- CANTIDAD: Actualizaciones de prestigio ----------------------------
	{"id":"maestria","name":"Maestría","desc":"Compra tu primera mejora de prestigio.","icon":"🎖️","cat":"cantidad","kind":"counter","metric":"prestige_bought","target":1},
	{"id":"polimata","name":"Polímata","desc":"Compra 25 mejoras de prestigio.","icon":"🎓","cat":"cantidad","kind":"counter","metric":"prestige_bought","target":25},
	{"id":"erudito","name":"Erudito Prestigioso","desc":"Compra 100 mejoras de prestigio.","icon":"🥇","cat":"cantidad","kind":"counter","metric":"prestige_bought","target":100},

	# --- OBJETIVO: Comodines raros/epicos/legendarios ----------------------
	{"id":"ojo_para_lo_raro","name":"Ojo para lo Raro","desc":"Elige 5 comodines Raros en total.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_rare","target":5},
	{"id":"afortunado","name":"Afortunado","desc":"Elige 3 comodines Épicos en total.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_epic","target":3},
	{"id":"mucho_peak","name":"Poder Épico","desc":"Elige un comodín Legendario.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_legendary","target":1},
	{"id":"mito_gummy","name":"Mito Gummy","desc":"Elige un comodín Mítico.","icon":"👼","cat":"secreto","kind":"flag","flag":"discover_mythic"},

	# --- SECRETO / EASTER EGGS ----------------------------------------
	{"id":"estado_de_creencias","name":"Estado Mental","desc":"Asesta un crítico sin haber golpeado caramelo endurecido ese día.","icon":"🧘","cat":"secreto","kind":"flag","flag":"esoteric_calm"},
	{"id":"meta_ultimo_instante","name":"Rápido y Furioso","desc":"Alcanza la meta del día cuando quedan 5 segundos o menos.","icon":"⏱️","cat":"secreto","kind":"flag","flag":"beat_day_rushed"},
	{"id":"deuda_cero","name":"Deuda Cero","desc":"Completa un día con la resistencia agotada.","icon":"⚡","cat":"secreto","kind":"flag","flag":"day_finished_empty"},
	{"id":"astuta_economia","name":"Astuta Economía","desc":"Supera un día (a partir del 2º) sin comprar NINGUNA mejora del mercado en el negocio.","icon":"🐷","cat":"secreto","kind":"flag","flag":"no_prestige_spent_run"},
	{"id":"tranquilo_juego","name":"Racha Campeona","desc":"Consigue una racha de 15 gomitas.","icon":"👀","cat":"secreto","kind":"flag","flag":"blind_streak"},
	{"id":"cinco_en_uno","name":"Cinco en Uno","desc":"Rompe 5 cubos con un solo trazo.","icon":"💥","cat":"estilo","kind":"counter","metric":"multi_break_5","target":1},
	{"id":"dulce_contraste","name":"Dulce Contraste","desc":"Produce una gomita dorada y una normal en el mismo día.","icon":"🍬","cat":"estilo","kind":"flag","flag":"golden_and_normal_day"},

	# --- RANDOM / SITUACIONALES ---------------------------------------

	# --- MÁS CANTIDAD ------------------------------------------------------
	{"id":"seis_ceros","name":"Primer Millón","desc":"Genera $1.000.000 en TOTAL en un solo negocio.","icon":"💎","cat":"cantidad","kind":"counter","metric":"run_money_total","target":1000000},
	{"id":"tiburon_de_lujo","name":"Tiburón de Lujo","desc":"Produce 50 unidades de Tiburón Gummy Premium en total.","icon":"🍬","cat":"secreto","kind":"counter","metric":"produced_shark_premium","target":50},
	{"id":"pez_de_lujo","name":"Pez de Lujo","desc":"Produce 5 unidades de Pez Gummy Premium.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_fish_premium","target":5},
	{"id":"rey_gummy","name":"Rey Gummy","desc":"Produce 3 unidades de Osito Gummy Corona, la receta más cara.","icon":"🌌","cat":"secreto","kind":"counter","metric":"produced_bear_crown","target":3},
	{"id":"dragon_de_lujo","name":"Dragón de Lujo","desc":"Produce 5 unidades de Dragón Gummy Premium.","icon":"💎","cat":"objetivo","kind":"counter","metric":"produced_dragon_premium","target":5},
	{"id":"dulce_dragon","name":"Dulce Dragón","desc":"Produce 5 unidades de Dragón Gummy.","icon":"💎","cat":"objetivo","kind":"counter","metric":"produced_dragon","target":5},
	{"id":"unicornio_de_lujo","name":"Unicornio de Lujo","desc":"Produce 5 unidades de Unicornio Gummy Premium.","icon":"🍬","cat":"secreto","kind":"counter","metric":"produced_unicorn_premium","target":5},
	{"id":"dulce_corazon","name":"Dulce Corazón","desc":"Produce 25 unidades de Corazón Gummy.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_heart","target":25},
	{"id":"corazon_de_lujo","name":"Corazón de Lujo","desc":"Produce 25 unidades de Corazón Gummy Premium.","icon":"🌅","cat":"objetivo","kind":"counter","metric":"produced_heart_premium","target":25},
	{"id":"dulce_pez","name":"Dulce Pez","desc":"Produce 25 unidades de Pez Gummy.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_fish","target":25},
	{"id":"botella_de_lujo","name":"Botella de Lujo","desc":"Produce 25 unidades de Botella Gummy Premium.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_bottle_premium","target":25},
	{"id":"aro_de_lujo","name":"Aro de Lujo","desc":"Produce 100 unidades de Aro Gummy Premium.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_ring_premium","target":100},
	{"id":"dulce_gusano","name":"Dulce Gusano","desc":"Produce 100 unidades de Gusano Gummy.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_worm","target":100},
	{"id":"gusano_de_lujo","name":"Gusano de Lujo","desc":"Produce 100 unidades de Gusano Gummy Premium.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_worm_premium","target":100},
	{"id":"dulce_botella","name":"Dulce Botella","desc":"Produce 100 unidades de Botella Gummy.","icon":"💎","cat":"objetivo","kind":"counter","metric":"produced_bottle","target":100},
	{"id":"dulce_aro","name":"Dulce Aro","desc":"Produce 100 unidades de Aro Gummy.","icon":"🍬","cat":"secreto","kind":"counter","metric":"produced_ring","target":100},
	{"id":"dulce_unicornio","name":"Dulce Unicornio","desc":"Produce 5 unidades de Unicornio Gummy.","icon":"☁️","cat":"objetivo","kind":"counter","metric":"produced_unicorn","target":5},
	{"id":"cocodrilo_de_lujo","name":"Cocodrilo de Lujo","desc":"Produce 5 unidades de Cocodrilo Gummy Premium.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_crocodile_premium","target":5},
	{"id":"dulce_cocodrilo","name":"Dulce Cocodrilo","desc":"Produce 5 unidades de Cocodrilo Gummy.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_crocodile","target":5},
	{"id":"dulce_tiburon","name":"Dulce Tiburón","desc":"Produce 5 unidades de Tiburón Gummy.","icon":"🍬","cat":"objetivo","kind":"counter","metric":"produced_shark","target":5},
	{"id":"osito_preferido","name":"Osito Preferido","desc":"Produce 200 unidades de Osito Gummy Clásico.","icon":"💎","cat":"secreto","kind":"counter","metric":"produced_bear_classic","target":200},
	{"id":"combinador_dorado","name":"Combinador Dorado","desc":"Ten 2 cubos de gomita dorada vivos en pantalla a la vez.","icon":"✨","cat":"secreto","kind":"counter","metric":"golden_on_screen_2","target":1},
	{"id":"origen","name":"Origen","desc":"Produce 100 gomitas con los Puños en un mismo negocio.","icon":"👊","cat":"gracioso","kind":"flag","flag":"produced_with_fists"},

	# --- MÁS: vars/cositas ----------------------------------------------
	{"id":"dulce_duo","name":"Dulce Dúo","desc":"Produce Osito Gummy Clásico y Gusano Gummy Premium y completa ese día.","icon":"🍬","cat":"estilo","kind":"flag","flag":"bear_and_premium_worm_day"},
	{"id":"total_dias_media","name":"Medio Centenar","desc":"Completa 50 días en total acumulados.","icon":"📆","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":50},
	{"id":"total_dias_cien","name":"Cien Días Jugados","desc":"Completa 100 días en total acumulados.","icon":"📆","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":100},
	{"id":"total_dias_doscientos","name":"Bicamarón","desc":"Completa 200 días en total acumulados.","icon":"🗓️","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":200},
	{"id":"total_dias_quinientos","name":"Medio Milenio","desc":"Completa 500 días en total acumulados.","icon":"🗓️","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":500},
]

func _ready() -> void:
	_load_from_save()
	# Desbloqueo retroactivo: si el jugador tenía progreso guardado de ANTES de
	# añadirse un logro, se desbloquea al arrancar SIN notificación (el HUD aún
	# no está listo y no tendría sentido spamear toasts en el menú).
	evaluate_all(true)

func _process(delta: float) -> void:
	if not _save_pending:
		return
	_save_timer -= delta
	if _save_timer <= 0.0:
		_save_pending = false
		SaveManager.save_to_disk()

# Forza el guardado inmediato al cerrar/poner en segundo plano el juego.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _save_pending:
			_save_pending = false
			SaveManager.save_to_disk()

# ---------------------------------------------------------------------------
# Persistencia
# ---------------------------------------------------------------------------
func _load_from_save() -> void:
	if not SaveManager.save_data.has(SAVE_KEY):
		SaveManager.save_data[SAVE_KEY] = {"unlocked": [], "metrics": {}, "flags": {}}

func get_unlocked_ids() -> Array:
	return SaveManager.save_data[SAVE_KEY]["unlocked"]

func get_metrics() -> Dictionary:
	return SaveManager.save_data[SAVE_KEY]["metrics"]

func get_flags() -> Dictionary:
	return SaveManager.save_data[SAVE_KEY]["flags"]

func _persist() -> void:
	_save_pending = true
	_save_timer = SAVE_DEBOUNCE

func reset_all() -> void:
	SaveManager.save_data[SAVE_KEY] = {"unlocked": [], "metrics": {}, "flags": {}}
	_save_pending = false
	_save_timer = 0.0
	SaveManager.save_to_disk()

# ---------------------------------------------------------------------------
# Métricas (progreso) 
# ---------------------------------------------------------------------------
func get_metric(key: String) -> float:
	return float(get_metrics().get(key, 0.0))

func record_metric(key: String, amount: float = 1.0) -> void:
	var metrics := get_metrics()
	metrics[key] = get_metric(key) + amount
	_persist()
	_evaluate_affected(key)

func set_metric(key: String, value: float) -> void:
	var metrics := get_metrics()
	metrics[key] = float(value)
	_persist()
	_evaluate_affected(key)

func get_flag(key: String) -> bool:
	return bool(get_flags().get(key, false))

func set_flag(key: String) -> void:
	if get_flag(key):
		return
	var flags := get_flags()
	flags[key] = true
	_persist()
	_evaluate_flag(key)

# Re-evalúa los logros counter que dependen de la métrica {name}.
func _evaluate_affected(metric_name: String) -> void:
	for def in DEFINITIONS:
		if def.get("kind", "counter") == "counter" and def.get("metric", "") == metric_name:
			_check(def)

# Re-evalúa los logros flag que dependen del flag {name}.
func _evaluate_flag(flag_name: String) -> void:
	for def in DEFINITIONS:
		if def.get("kind", "") == "flag" and def.get("flag", "") == flag_name:
			_check(def)

# Re-evalúa TODOS los logros (se llama al cargar y al marcar un flag global).
func evaluate_all(suppress_notifications: bool = false) -> void:
	var previous: bool = _suppress_notifications
	_suppress_notifications = suppress_notifications
	for def in DEFINITIONS:
		_check(def)
	_suppress_notifications = previous

func is_unlocked(id: String) -> bool:
	return id in get_unlocked_ids()

# Comprueba un logro y lo desbloquea si procede. No hace nada si ya está.
func _check(def: Dictionary) -> void:
	var id: String = str(def.get("id", ""))
	if is_unlocked(id):
		return
	var done: bool = false
	if def.get("kind", "counter") == "counter":
		done = get_metric(str(def.get("metric", ""))) >= float(def.get("target", 1))
	else:
		done = get_flag(str(def.get("flag", "")))
	if done:
		var unlocked := get_unlocked_ids()
		unlocked.append(id)
		_persist()
		if not _suppress_notifications:
			achievement_unlocked.emit(id, def)

# Progreso de un logro para la UI: devuelve (progreso, target, desbloqueado).
# Para los "flag" devuelve (1, 1, desbloqueado) (no tienen barra).
func get_progress(id: String) -> Dictionary:
	var unlocked: bool = is_unlocked(id)
	for def in DEFINITIONS:
		if str(def.get("id", "")) != id:
			continue
		if def.get("kind", "counter") == "counter":
			return {"progress": get_metric(str(def.get("metric", ""))), "target": float(def.get("target", 1)), "unlocked": unlocked}
		return {"progress": 1.0, "target": 1.0, "unlocked": unlocked}
	return {"progress": 0.0, "target": 1.0, "unlocked": unlocked}

# Muestra el progreso como texto ("fraction" o "value").
func get_progress_text(id: String) -> String:
	var p := get_progress(id)
	if p["unlocked"]:
		return "COMPLETADO"
	if p["target"] <= 1.0:
		return "PENDIENTE"
	var cur: float = p["progress"]
	var tgt: float = p["target"]
	if tgt >= 1000.0 or cur >= 1000.0:
		return UiTheme.format_money(cur) + " / " + UiTheme.format_money(tgt)
	return str(int(round(cur))) + " / " + str(int(round(tgt)))
