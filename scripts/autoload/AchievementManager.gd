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
	# --- CANTIDAD: Frutas cortadas -----------------------------------------
	{"id":"aprendiz_de_corte","name":"Aprendiz de Corte","desc":"Corta 250 frutas en total.","icon":"🍊","cat":"cantidad","kind":"counter","metric":"fruits_cut","target":250},
	{"id":"recolector","name":"Recolector de Frutas","desc":"Corta 1.000 frutas.","icon":"🍉","cat":"cantidad","kind":"counter","metric":"fruits_cut","target":1000},
	{"id":"cosechador_experto","name":"Cosechador Experto","desc":"Corta 5.000 frutas.","icon":"🥝","cat":"cantidad","kind":"counter","metric":"fruits_cut","target":5000},
	{"id":"maestro_del_corte","name":"Maestro del Corte","desc":"Corta 10.000 frutas.","icon":"🍍","cat":"cantidad","kind":"counter","metric":"fruits_cut","target":10000},
	{"id":"leyenda_frutal","name":"Leyenda Frutal","desc":"Corta 100.000 frutas.","icon":"🏆","cat":"cantidad","kind":"counter","metric":"fruits_cut","target":100000},
	{"id":"dios_del_corte","name":"Dios del Corte","desc":"Corta 500.000 frutas.","icon":"🌌","cat":"cantidad","kind":"counter","metric":"fruits_cut","target":500000},

	# --- CANTIDAD: Días / pedidos completados (mejor marca) ----------------
	{"id":"primer_dia","name":"Primer Día","desc":"Completa tu primer día de cliente.","icon":"📅","cat":"cantidad","kind":"counter","metric":"best_day","target":1},
	{"id":"quincena","name":"Media Quincena","desc":"Llega al día 15.","icon":"🗓️","cat":"cantidad","kind":"counter","metric":"best_day","target":15},
	{"id":"mes_entero","name":"Mes Entero","desc":"Llega al día 30.","icon":"📆","cat":"cantidad","kind":"counter","metric":"best_day","target":30},
	{"id":"mes_y_medio","name":"Cincuentón Frutal","desc":"Llega al día 50.","icon":"📆","cat":"cantidad","kind":"counter","metric":"best_day","target":50},
	{"id":"centenario","name":"Centenario","desc":"Llega al día 100 (la meta).","icon":"🎬","cat":"objetivo","kind":"counter","metric":"best_day","target":100},
	{"id":"mas_alla","name":"Más Allá de la Meta","desc":"Supera el día 100 (101+).","icon":"🚀","cat":"objetivo","kind":"flag","flag":"surpassed_day_100"},
	{"id":"centenario_cincuenta","name":"Siglo y Medio","desc":"Llega al día 150.","icon":"🚀","cat":"cantidad","kind":"counter","metric":"best_day","target":150},
	{"id":"bicentenario","name":"Bicentenario","desc":"Llega al día 200.","icon":"🌠","cat":"cantidad","kind":"counter","metric":"best_day","target":200},
	{"id":"tricentenario","name":"Tricentenario","desc":"Llega al día 300.","icon":"♾️","cat":"cantidad","kind":"counter","metric":"best_day","target":300},

	# --- CANTIDAD: Dinero generado (acumulado total) ------------------------
	{"id":"alcanzando_metas","name":"Primeros Beneficios","desc":"Genera $100.000 en total.","icon":"💰","cat":"cantidad","kind":"counter","metric":"money_total","target":100000},
	{"id":"milionario_frutal","name":"Milionario Frutal","desc":"Genera $1.000.000 en total.","icon":"💵","cat":"cantidad","kind":"counter","metric":"money_total","target":1000000},
	{"id":"inversor_fruta","name":"Gran Inversor","desc":"Genera $10.000.000 en total.","icon":"🏦","cat":"cantidad","kind":"counter","metric":"money_total","target":10000000},
	{"id":"empresario","name":"Empresario","desc":"Genera $100.000.000 en total.","icon":"🏛️","cat":"cantidad","kind":"counter","metric":"money_total","target":100000000},
	{"id":"magnate_frutal","name":"Magnate Frutal","desc":"Genera $1.000.000.000 en total.","icon":"👑","cat":"cantidad","kind":"counter","metric":"money_total","target":1000000000},
	{"id":"tycoon_frutal","name":"Tycoon Frutal","desc":"Genera $10.000.000.000 en total.","icon":"💎","cat":"cantidad","kind":"counter","metric":"money_total","target":10000000000},

	# --- CANTIDAD: Jackpots -------------------------------------------------
	{"id":"gran_venta_inicial","name":"Gran Venta","desc":"Consigue 5 Jackpots.","icon":"⭐","cat":"cantidad","kind":"counter","metric":"jackpots","target":5},
	{"id":"suerte_de_bruja","name":"Suerte de Bruja","desc":"Consigue 25 Jackpots.","icon":"⭐","cat":"cantidad","kind":"counter","metric":"jackpots","target":25},
	{"id":"favorito_de_fortuna","name":"Favorito de la Fortuna","desc":"Consigue 100 Jackpots.","icon":"🌟","cat":"cantidad","kind":"counter","metric":"jackpots","target":100},
	{"id":"rey_de_la_fortuna","name":"Rey de la Fortuna","desc":"Consigue 500 Jackpots.","icon":"👑","cat":"cantidad","kind":"counter","metric":"jackpots","target":500},

	# --- CANTIDAD: Frutas doradas ------------------------------------------
	{"id":"brillo_dorado","name":"Brillo Dorado","desc":"Corta 5 frutas doradas.","icon":"✨","cat":"cantidad","kind":"counter","metric":"golden_fruits","target":5},
	{"id":"cosecha_doradita","name":"Cosecha Doradita","desc":"Corta 25 frutas doradas.","icon":"✨","cat":"cantidad","kind":"counter","metric":"golden_fruits","target":25},
	{"id":"dorado_total","name":"Dorado Total","desc":"Corta 100 frutas doradas.","icon":"🥇","cat":"cantidad","kind":"counter","metric":"golden_fruits","target":100},
	{"id":"dorado_legendario","name":"Leyenda Dorada","desc":"Corta 250 frutas doradas.","icon":"🥇","cat":"cantidad","kind":"counter","metric":"golden_fruits","target":250},

	# --- CANTIDAD: Críticos ------------------------------------------------
	{"id":"afilador","name":"Filo Afilado","desc":"Asesta 25 golpes críticos.","icon":"💥","cat":"cantidad","kind":"counter","metric":"crits","target":25},
	{"id":"filo_critico","name":"Filo Crítico","desc":"Asesta 250 golpes críticos.","icon":"💥","cat":"cantidad","kind":"counter","metric":"crits","target":250},
	{"id":"asesino_silencioso","name":"Asesino Silencioso","desc":"Asesta 1.000 golpes críticos.","icon":"🗡️","cat":"cantidad","kind":"counter","metric":"crits","target":1000},
	{"id":"leyenda_critica","name":"Leyenda Crítica","desc":"Asesta 5.000 golpes críticos.","icon":"🗡️","cat":"cantidad","kind":"counter","metric":"crits","target":5000},

	# --- CANTIDAD: Obstáculos golpeados (gracioso) --------------------------
	{"id":"coleccionista_piedras","name":"Coleccionista de Piedras","desc":"Golpea 50 piedras... ¿en serio?","icon":"🪨","cat":"gracioso","kind":"counter","metric":"stones_hit","target":50},
	{"id":"futbolista_sabotaje","name":"Saboteador Frutal","desc":"Golpea 250 piedras a propósito.","icon":"🧱","cat":"gracioso","kind":"counter","metric":"stones_hit","target":250},
	{"id":"cantero_implacable","name":"Cantero Implacable","desc":"Golpea 1.000 piedras.","icon":"🪨","cat":"gracioso","kind":"counter","metric":"stones_hit","target":1000},

	# --- CANTIDAD: Quiebras del negocio (gracioso) --------------------------
	{"id":"primera_quiebra","name":"Primera Quiebra","desc":"Tu negocio quiebra por primera vez.","icon":"💸","cat":"gracioso","kind":"counter","metric":"runs_bankrupt","target":1},
	{"id":"empresario_riesgoso","name":"Empresario Riesgoso","desc":"Quiebra 10 negocios.","icon":"🎲","cat":"gracioso","kind":"counter","metric":"runs_bankrupt","target":10},
	{"id":"fundador_masoquista","name":"Fundador Masoquista","desc":"Quiebra 50 negocios.","icon":"😵","cat":"gracioso","kind":"counter","metric":"runs_bankrupt","target":50},

	# --- CANTIDAD: Racha máxima --------------------------------------------
	{"id":"racha_de_10","name":"Diez en Fila","desc":"Alcanza una racha de 10 cortes seguidos.","icon":"🔥","cat":"objetivo","kind":"counter","metric":"max_streak","target":10},
	{"id":"racha_de_20","name":"Vigésima Racha","desc":"Alcanza una racha de 20 cortes seguidos.","icon":"🔥","cat":"objetivo","kind":"counter","metric":"max_streak","target":20},
	{"id":"racha_de_30","name":"Racha de 30","desc":"Alcanza una racha de 30 cortes seguidos.","icon":"🔥","cat":"objetivo","kind":"counter","metric":"max_streak","target":30},
	{"id":"imparable","name":"Imparable","desc":"Alcanza la racha máxima de 50 cortes seguidos.","icon":"🥵","cat":"objetivo","kind":"counter","metric":"max_streak","target":50},

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

	# --- CANTIDAD: Armamento -----------------------------------------------
	{"id":"utensilios","name":"Utensilios Varios","desc":"Desbloquea 3 armas distintas.","icon":"🍴","cat":"cantidad","kind":"counter","metric":"knives_owned","target":3},
	{"id":"arsenal_frutal","name":"Arsenal Frutal","desc":"Desbloquea 5 armas distintas.","icon":"🔪","cat":"cantidad","kind":"counter","metric":"knives_owned","target":5},
	{"id":"coleccionista_armas","name":"Coleccionista de Armas","desc":"Desbloquea todas las armas.","icon":"🪚","cat":"cantidad","kind":"counter","metric":"knives_owned","target":10},
	{"id":"lider_de_corte","name":"Líder de Corte","desc":"Corta con la Motosierra (el arma definitiva).","icon":"🪚","cat":"objetivo","kind":"flag","flag":"used_chainsaw"},

	# --- CANTIDAD: Frutas desbloqueadas ------------------------------------
	{"id":"frutero","name":"Frutero","desc":"Desbloquea 5 frutas distintas.","icon":"🧺","cat":"cantidad","kind":"counter","metric":"fruits_unlocked","target":5},
	{"id":"granjero","name":"Granjero","desc":"Desbloquea 15 frutas distintas.","icon":"👨‍🌾","cat":"cantidad","kind":"counter","metric":"fruits_unlocked","target":15},
	{"id":"huerta_completa","name":"Huerta Completa","desc":"Desbloquea todas las frutas.","icon":"🌳","cat":"cantidad","kind":"counter","metric":"fruits_unlocked","target":20},

	# --- CANTIDAD: Comodines descubiertos -----------------------------------
	{"id":"baraja_inicial","name":"Manos Amigas","desc":"Descubre 10 comodines distintos.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":10},
	{"id":"baraja_surtida","name":"Baraja Surtida","desc":"Descubre 30 comodines distintos.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":30},
	{"id":"cartomantico","name":"Cartomántico","desc":"Descubre 60 comodines distintos.","icon":"🔮","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":60},
	{"id":"coleccionista_cartas","name":"Coleccionista de Cartas","desc":"Descubre todos los comodines.","icon":"🂠","cat":"cantidad","kind":"counter","metric":"cards_discovered","target":100},

	# --- OBJETIVO: Días perfectos ------------------------------------------
	{"id":"dia_perfecto","name":"Día Perfecto","desc":"Completa 5 días sin tocar NI UNA piedra.","icon":"💯","cat":"objetivo","kind":"counter","metric":"clean_days","target":5},
	{"id":"semana_perfecta","name":"Semana Perfecta","desc":"Completa 20 días sin tocar ninguna piedra.","icon":"✨","cat":"objetivo","kind":"counter","metric":"clean_days","target":20},
	{"id":"purista","name":"Purista","desc":"Completa un día equipando solo el Puño.","icon":"👊","cat":"estilo","kind":"flag","flag":"day_with_fist"},
	{"id":"sin_rincon_dark","name":"Soldado de Hierro","desc":"Completa un día con la Motosierra equipada.","icon":"⚙️","cat":"estilo","kind":"flag","flag":"day_with_top_knife"},

	# --- ESTILO: Formas de jugar -------------------------------------------
	{"id":"paciente","name":"Paciente","desc":"Completa un día con el Tenedor equipado.","icon":"🍴","cat":"estilo","kind":"flag","flag":"day_with_fork"},
	{"id":"cuchillero","name":"Cuchillero","desc":"Completa un día con un Cuchillo equipado.","icon":"🔪","cat":"estilo","kind":"flag","flag":"day_with_knife"},
	{"id":"hachador","name":"Hachador","desc":"Completa un día con un Hacha equipada.","icon":"🪓","cat":"estilo","kind":"flag","flag":"day_with_axe"},
	{"id":"espadachin","name":"Espadachín","desc":"Completa un día con una Espada equipada.","icon":"⚔️","cat":"estilo","kind":"flag","flag":"day_with_sword"},
	{"id":"central_frutal","name":"Hachero Total","desc":"Completa un día sin cambiar de arma.","icon":"🔒","cat":"estilo","kind":"flag","flag":"day_unchanged_weapon"},

	# --- ESTILO: Suerte / doradas ------------------------------------------
	{"id":"bingo","name":"Bingo Dorado","desc":"Consigue un Jackpot con una fruta dorada.","icon":"🍀","cat":"estilo","kind":"flag","flag":"golden_jackpot"},
	{"id":"doble_dorado","name":"Doble Dorado","desc":"Corta dos frutas doradas en un mismo día.","icon":"✨","cat":"estilo","kind":"counter","metric":"golden_fruits_in_one_day","target":2},
	{"id":"suerte_critica","name":"Suerte Crítica","desc":"Consigue 3 críticos en un mismo día.","icon":"💥","cat":"estilo","kind":"counter","metric":"crits_in_one_day","target":3},

	# --- ESTILO: Compras / inversión ---------------------------------------
	{"id":"comprador","name":"Comprador Compulsivo","desc":"Compra 5 mejoras del mercado en un mismo negocio.","icon":"🛒","cat":"estilo","kind":"counter","metric":"upgrades_bought_run","target":5},
	{"id":"megacomprador","name":"Megacomprador","desc":"Compra 20 mejoras del mercado en un mismo negocio.","icon":"🛍️","cat":"estilo","kind":"counter","metric":"upgrades_bought_run","target":20},
	{"id":"especulador","name":"Especulador","desc":"Compra una mejora de DAÑO, VIDA, SUERTE y DINERO en el mismo negocio.","icon":"📈","cat":"estilo","kind":"flag","flag":"bought_all_upgrade_types"},
	{"id":"cosecha_doblada","name":"Cosecha Doble","desc":"Aumenta la frecuencia de lanzamiento (Cosecha Veloz) 3 veces en un negocio.","icon":"🚀","cat":"estilo","kind":"counter","metric":"launch_upgrades_run","target":3},

	# --- CANTIDAD: Actualizaciones de prestigio ----------------------------
	{"id":"maestria","name":"Maestría","desc":"Compra tu primera mejora de prestigio.","icon":"🎖️","cat":"cantidad","kind":"counter","metric":"prestige_bought","target":1},
	{"id":"polimata","name":"Polímata","desc":"Compra 25 mejoras de prestigio.","icon":"🎓","cat":"cantidad","kind":"counter","metric":"prestige_bought","target":25},
	{"id":"erudito","name":"Erudito Prestigioso","desc":"Compra 100 mejoras de prestigio.","icon":"🥇","cat":"cantidad","kind":"counter","metric":"prestige_bought","target":100},

	# --- OBJETIVO: Comodines raros/epicos/legendarios ----------------------
	{"id":"ojo_para_lo_raro","name":"Ojo para lo Raro","desc":"Descubre 5 comodines Raros.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_rare","target":5},
	{"id":"afortunado","name":"Afortunado","desc":"Descubre 3 comodines Épicos.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_epic","target":3},
	{"id":"mucho_peak","name":"Poder Épico","desc":"Descubre un comodín Legendario.","icon":"🃏","cat":"cantidad","kind":"counter","metric":"cards_legendary","target":1},
	{"id":"dios_frutal","name":"Dios Frutal","desc":"Descubre el comodín Mítico (Divinidad).","icon":"👼","cat":"secreto","kind":"flag","flag":"discover_mythic"},

	# --- SECRETO / EASTER EGGS ----------------------------------------
	{"id":"estado_de_creencias","name":"Estado Mental","desc":"Recibe crítica sin golpear ninguna piedra (dificil de probar).","icon":"🧘","cat":"secreto","kind":"flag","flag":"esoteric_calm"},
	{"id":"fruta_termina_rapido","name":"Rápido y Furioso","desc":"Completa un día con menos de 5 segundos en el reloj.","icon":"⏱️","cat":"secreto","kind":"flag","flag":"beat_day_rushed"},
	{"id":"deuda_cero","name":"Deuda Cero","desc":"Quedar con energía EN 0 exactamente al completar un día.","icon":"🩸","cat":"secreto","kind":"flag","flag":"day_finished_empty"},
	{"id":"astuta_economia","name":"Astuta Economía","desc":"Supera un día (a partir del 2º) sin comprar NINGUNA mejora del mercado en el negocio.","icon":"🐷","cat":"secreto","kind":"flag","flag":"no_prestige_spent_run"},
	{"id":"tranquilo_juego","name":"Racha Campeona","desc":"Consigue una racha de 15 sin mirar la barra de racha.","icon":"👀","cat":"secreto","kind":"flag","flag":"blind_streak"},
	{"id":"cinco_en_uno","name":"Cinco en Uno","desc":"Corta 5 frutas con un solo trazo.","icon":"✂️","cat":"estilo","kind":"counter","metric":"multi_cut_5","target":1},
	{"id":"fruits_and_breaks","name":"Fruta y Pan","desc":"Corta una fruta DORADA Y una normal en el mismo día.","icon":"🍞","cat":"estilo","kind":"flag","flag":"golden_and_normal_day"},

	# --- RANDOM / SITUACIONALES ---------------------------------------

	# --- MÁS CANTIDAD ------------------------------------------------------
	{"id":"seis_ceros","name":"Primer Millón","desc":"Genera $1.000.000 en TOTAL en un solo negocio.","icon":"💎","cat":"cantidad","kind":"counter","metric":"run_money_total","target":1000000},
	{"id":"cocoo","name":"Coco Loco","desc":"Corta 50 cocos en total.","icon":"🥥","cat":"secreto","kind":"counter","metric":"cut_coconut","target":50},
	{"id":"sandia_gigante","name":"Sandía Gigante","desc":"Corta 5 Sandías.","icon":"🍉","cat":"objetivo","kind":"counter","metric":"cut_watermelon","target":5},
	{"id":"calabaza_mago","name":"Rey Calabaza","desc":"Corta 3 Calabazas (la fruta más cara).","icon":"🎃","cat":"secreto","kind":"counter","metric":"cut_pumpkin","target":3},
	{"id":"pitahaya","name":"Pitahaya Encendida","desc":"Corta 5 Pitahayas (Fruta del Dragón).","icon":"🍈","cat":"objetivo","kind":"counter","metric":"cut_dragon_fruit","target":5},
	{"id":"aguacate","name":"Aguacate Real","desc":"Corta 5 Aguacates.","icon":"🥑","cat":"objetivo","kind":"counter","metric":"cut_avocado","target":5},
	{"id":"membrillo","name":"Membrillo Curioso","desc":"Corta 5 Membrillos.","icon":"🍐","cat":"secreto","kind":"counter","metric":"cut_quince","target":5},
	{"id":"kiwi","name":"Kiwi Moderno","desc":"Corta 25 Kiwis.","icon":"🥝","cat":"objetivo","kind":"counter","metric":"cut_kiwi","target":25},
	{"id":"mango","name":"Mango Tropical","desc":"Corta 25 Mangos.","icon":"🥭","cat":"objetivo","kind":"counter","metric":"cut_mango","target":25},
	{"id":"limon","name":"Limón Fresco","desc":"Corta 25 Limones.","icon":"🍋","cat":"objetivo","kind":"counter","metric":"cut_lemon","target":25},
	{"id":"pera","name":"Pera Madura","desc":"Corta 25 Peras.","icon":"🍐","cat":"objetivo","kind":"counter","metric":"cut_pear","target":25},
	{"id":"durazno","name":"Melocotón Dulce","desc":"Corta 100 Melocotones.","icon":"🍑","cat":"objetivo","kind":"counter","metric":"cut_peach","target":100},
	{"id":"cereza","name":"Cereza Redonda","desc":"Corta 100 Cerezas.","icon":"🍒","cat":"objetivo","kind":"counter","metric":"cut_cherry","target":100},
	{"id":"naranja","name":"Naranja Ácida","desc":"Corta 100 Naranjas.","icon":"🍊","cat":"objetivo","kind":"counter","metric":"cut_orange","target":100},
	{"id":"manzana","name":"Manzana Crujiente","desc":"Corta 100 Manzanas.","icon":"🍎","cat":"objetivo","kind":"counter","metric":"cut_apple","target":100},
	{"id":"banana_dorada","name":"Banana Divina","desc":"Corta 100 Bananas.","icon":"🍌","cat":"secreto","kind":"counter","metric":"cut_banana","target":100},
	{"id":"guayaba","name":"Guayaba Exótica","desc":"Corta 5 Guayabas.","icon":"🥝","cat":"objetivo","kind":"counter","metric":"cut_guava","target":5},
	{"id":"piña","name":"Piña Madura","desc":"Corta 5 Piñas.","icon":"🍍","cat":"objetivo","kind":"counter","metric":"cut_pineapple","target":5},
	{"id":"melón","name":"Melón Jugoso","desc":"Corta 5 Melones.","icon":"🍈","cat":"objetivo","kind":"counter","metric":"cut_melon","target":5},
	{"id":"papaya","name":"Papaya Tropical","desc":"Corta 5 Papayas.","icon":"🥭","cat":"objetivo","kind":"counter","metric":"cut_papaya","target":5},
	{"id":"fresa_preferida","name":"Fresa Preferida","desc":"Corta 200 Fresas.","icon":"🍓","cat":"secreto","kind":"counter","metric":"cut_strawberry","target":200},
	{"id":"combinador_dorado","name":"Combinador Dorado","desc":"Ten 2 frutas doradas en pantalla a la vez.","icon":"✨","cat":"secreto","kind":"counter","metric":"golden_on_screen_2","target":1},
	{"id":"origen","name":"Origen","desc":"Corta 100 frutas con el Puño equipado.","icon":"👊","cat":"gracioso","kind":"flag","flag":"started_with_fist"},

	# --- MÁS: vars/cositas ----------------------------------------------
	{"id":"fresa_y_naranja","name":"Colores de Verano","desc":"Corta una Fresa y una Naranja en el mismo día.","icon":"🍊","cat":"estilo","kind":"flag","flag":"fresa_y_naranja_day"},
	{"id":"total_dias_media","name":"Medio Centenar","desc":"Completa 50 días en total acumulados.","icon":"📆","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":50},
	{"id":"total_dias_cien","name":"Cien Días Jugados","desc":"Completa 100 días en total acumulados.","icon":"📆","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":100},
	{"id":"total_dias_doscientos","name":"Bicamarón","desc":"Completa 200 días en total acumulados.","icon":"🗓️","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":200},
	{"id":"total_dias_quinientos","name":"Medio Milenio","desc":"Completa 500 días en total acumulados.","icon":"🗓️","cat":"cantidad","kind":"counter","metric":"days_completed_total","target":500},
]

# Categorías con su icono (usadas por la pestaña de Logros para agrupar).
const CATEGORY_ICONS := {
	"cantidad":"🔢",
	"objetivo":"🎯",
	"estilo":"🎮",
	"gracioso":"😂",
	"secreto":"🤫",
	"aleatorio":"🎲",
	"easter_egg":"🥚",
}

func get_category_label(cat: String) -> String:
	match cat:
		"cantidad": return "Cantidad"
		"objetivo": return "Objetivos"
		"estilo": return "Estilo de juego"
		"gracioso": return "Graciosos"
		"secreto": return "Secretos"
		"easter_egg": return "Easter Eggs"
		"aleatorio": return "Aleatorios"
	return cat

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
