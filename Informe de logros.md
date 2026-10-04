# Informe de logros

> Inventario completo y verificable del sistema de logros de **Crazy Fruit**.
> Fuente única de verdad: `scripts/autoload/AchievementManager.gd` (`DEFINITIONS`, 121 entradas).
> Todo lo que sigue se ha extraído del código, no de la interfaz: los objetivos,
> las condiciones y las ubicaciones donde se registra cada progreso.
>
> Este documento es **descriptivo**: no modifica ni rebalancea ningún logro.

## 1. Resumen

| Dato | Valor |
|---|---|
| Logros totales | **121** (101 de tipo `counter` + 20 de tipo `flag`) |
| Métricas distintas | 29 (+1 dinámica: `cut_<id_de_fruta>`) |
| Flags distintos | 20 |
| Categorías en uso | 5 (cantidad, objetivo, estilo, gracioso, secreto) |
| Categorías definidas sin usar | `aleatorio`, `easter_egg` (ver §7) |
| IDs duplicados | Ninguno |
| Logros inalcanzables | Ninguno por código (ver matices en §7) |

| Categoría | Logros | Icono |
|---|---|---|
| Cantidad | 59 | 🔢 |
| Objetivos | 24 | 🎯 |
| Estilo de juego | 17 | 🎮 |
| Graciosos | 9 | 😂 |
| Secretos | 12 | 🤫 |

### Cómo funciona el sistema

- **`kind: "counter"`** — progreso gradual. La UI lee `metrics[métrica]` y muestra barra
  cuando `objetivo > 1`. Cada vez que la métrica cambia se re-evalúan **todos** los logros
  que la usan (`_evaluate_affected`), de modo que los tramos intermedios se desbloquean
  solos aunque el jugador salte varios de golpe.
- **`kind: "flag"`** — logro binario. Se desbloquea al marcar su flag con `set_flag()`.
- **Persistencia** — `SaveManager.save_data["achievements"] = {unlocked, metrics, flags}`.
  El guardado es diferido con *debounce* de 0.5 s (`SAVE_DEBOUNCE`) para no escribir en
  disco 60+ veces por segundo durante rachas largas.
- **Desbloqueo retroactivo** — al arrancar, `evaluate_all(true)` comprueba todos los logros
  en silencio: si el jugador tenía progreso guardado de una versión anterior, se desbloquea
  sin toast (el HUD aún no está listo).
- **Notificación** — `signal achievement_unlocked(id, def)`; el HUD encola los avisos y los
  muestra de uno en uno (nunca se pisan ni se pierden).

### Semántica de las métricas (importante)

No todas las métricas se suman igual: eso cambia qué significa "progreso" en cada logro.

| Semántica | Métricas | Se resetea |
|---|---|---|
| **Acumulado permanente** | `fruits_cut`, `money_total`, `jackpots`, `crits`, `golden_fruits`, `stones_hit`, `streak_broke`, `runs_bankrupt`, `clean_days`, `days_completed_total`, `prestige_earned`, `prestige_spent`, `prestige_bought`, `cards_rare`, `cards_epic`, `cards_legendary`, `upgrades_bought_run`, `multi_cut_5` | Nunca (salvo `reset_all()`) |
| **Pico del día** | `crits_in_one_day`, `golden_fruits_in_one_day` | Cada día nuevo |
| **Pico del negocio** | `launch_upgrades_run`, `run_money_total` | Cada negocio nuevo |
| **Máximo histórico** | `best_day`, `max_streak`, `knives_owned`, `fruits_unlocked`, `cards_discovered` | Nunca (solo sube) |
| **Dinámica por fruta** | `cut_<id>` (20 frutas) | Nunca |

> `upgrades_bought_run` está registrada con `record_metric` (acumulada) pese a su nombre
> "run": cuenta el total histórico de mejoras compradas, no las del negocio actual.

---

## 2. Logros de cantidad (59)

| # | Logro | Descripción | Condición | Objetivo |
|---|---|---|---|---|
| 1 | 🍊 **Aprendiz de Corte**<br>`aprendiz_de_corte` | Corta 250 frutas en total. | métrica `fruits_cut` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:321` | 250 |
| 2 | 🍉 **Recolector de Frutas**<br>`recolector` | Corta 1.000 frutas. | métrica `fruits_cut` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:321` | 1.000 |
| 3 | 🥝 **Cosechador Experto**<br>`cosechador_experto` | Corta 5.000 frutas. | métrica `fruits_cut` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:321` | 5.000 |
| 4 | 🍍 **Maestro del Corte**<br>`maestro_del_corte` | Corta 10.000 frutas. | métrica `fruits_cut` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:321` | 10.000 |
| 5 | 🏆 **Leyenda Frutal**<br>`leyenda_frutal` | Corta 100.000 frutas. | métrica `fruits_cut` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:321` | 100.000 |
| 6 | 🌌 **Dios del Corte**<br>`dios_del_corte` | Corta 500.000 frutas. | métrica `fruits_cut` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:321` | 500.000 |
| 7 | 📅 **Primer Día**<br>`primer_dia` | Completa tu primer día de cliente. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 1 |
| 8 | 🗓️ **Media Quincena**<br>`quincena` | Llega al día 15. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 15 |
| 9 | 📆 **Mes Entero**<br>`mes_entero` | Llega al día 30. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 30 |
| 10 | 📆 **Cincuentón Frutal**<br>`mes_y_medio` | Llega al día 50. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 50 |
| 11 | 🚀 **Siglo y Medio**<br>`centenario_cincuenta` | Llega al día 150. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 150 |
| 12 | 🌠 **Bicentenario**<br>`bicentenario` | Llega al día 200. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 200 |
| 13 | ♾️ **Tricentenario**<br>`tricentenario` | Llega al día 300. | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 300 |
| 14 | 💰 **Primeros Beneficios**<br>`alcanzando_metas` | Genera $100.000 en total. | métrica `money_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:322` | 100.000 |
| 15 | 💵 **Milionario Frutal**<br>`milionario_frutal` | Genera $1.000.000 en total. | métrica `money_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:322` | 1.000.000 |
| 16 | 🏦 **Gran Inversor**<br>`inversor_fruta` | Genera $10.000.000 en total. | métrica `money_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:322` | 10.000.000 |
| 17 | 🏛️ **Empresario**<br>`empresario` | Genera $100.000.000 en total. | métrica `money_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:322` | 100.000.000 |
| 18 | 👑 **Magnate Frutal**<br>`magnate_frutal` | Genera $1.000.000.000 en total. | métrica `money_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:322` | 1.000.000.000 |
| 19 | 💎 **Tycoon Frutal**<br>`tycoon_frutal` | Genera $10.000.000.000 en total. | métrica `money_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:322` | 10.000.000.000 |
| 20 | ⭐ **Gran Venta**<br>`gran_venta_inicial` | Consigue 5 Jackpots. | métrica `jackpots` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:328` | 5 |
| 21 | ⭐ **Suerte de Bruja**<br>`suerte_de_bruja` | Consigue 25 Jackpots. | métrica `jackpots` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:328` | 25 |
| 22 | 🌟 **Favorito de la Fortuna**<br>`favorito_de_fortuna` | Consigue 100 Jackpots. | métrica `jackpots` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:328` | 100 |
| 23 | 👑 **Rey de la Fortuna**<br>`rey_de_la_fortuna` | Consigue 500 Jackpots. | métrica `jackpots` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:328` | 500 |
| 24 | ✨ **Brillo Dorado**<br>`brillo_dorado` | Corta 5 frutas doradas. | métrica `golden_fruits` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:333` | 5 |
| 25 | ✨ **Cosecha Doradita**<br>`cosecha_doradita` | Corta 25 frutas doradas. | métrica `golden_fruits` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:333` | 25 |
| 26 | 🥇 **Dorado Total**<br>`dorado_total` | Corta 100 frutas doradas. | métrica `golden_fruits` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:333` | 100 |
| 27 | 🥇 **Leyenda Dorada**<br>`dorado_legendario` | Corta 250 frutas doradas. | métrica `golden_fruits` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:333` | 250 |
| 28 | 💥 **Filo Afilado**<br>`afilador` | Asesta 25 golpes críticos. | métrica `crits` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:151` | 25 |
| 29 | 💥 **Filo Crítico**<br>`filo_critico` | Asesta 250 golpes críticos. | métrica `crits` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:151` | 250 |
| 30 | 🗡️ **Asesino Silencioso**<br>`asesino_silencioso` | Asesta 1.000 golpes críticos. | métrica `crits` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:151` | 1.000 |
| 31 | 🗡️ **Leyenda Crítica**<br>`leyenda_critica` | Asesta 5.000 golpes críticos. | métrica `crits` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:151` | 5.000 |
| 32 | ⭐ **Comerciante Neófito**<br>`primera_estrella` | Acumula 15 puntos de reputación. | métrica `prestige_earned` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:412` | 15 |
| 33 | 🌟 **Comerciante Honorable**<br>`honorable` | Acumula 100 puntos de reputación. | métrica `prestige_earned` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:412` | 100 |
| 34 | 🏆 **Leyenda del Mercado**<br>`leyenda_del_mercado` | Acumula 500 puntos de reputación. | métrica `prestige_earned` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:412` | 500 |
| 35 | 🌌 **Imperio de Reputación**<br>`imperio_reputacion` | Acumula 1.000 puntos de reputación. | métrica `prestige_earned` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:412` | 1.000 |
| 36 | 🏦 **Inversor**<br>`inversor` | Gasta 20 puntos de reputación en mejoras de prestigio. | métrica `prestige_spent` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:538` | 20 |
| 37 | 🎓 **Magnate de Prestigio**<br>`magnate` | Gasta 200 puntos de reputación. | métrica `prestige_spent` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:538` | 200 |
| 38 | 👑 **Especulador Máximo**<br>`magnate_total` | Gasta 1.000 puntos de reputación. | métrica `prestige_spent` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:538` | 1.000 |
| 39 | 🍴 **Utensilios Varios**<br>`utensilios` | Desbloquea 3 armas distintas. | métrica `knives_owned` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:380` | 3 |
| 40 | 🔪 **Arsenal Frutal**<br>`arsenal_frutal` | Desbloquea 5 armas distintas. | métrica `knives_owned` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:380` | 5 |
| 41 | 🪚 **Coleccionista de Armas**<br>`coleccionista_armas` | Desbloquea todas las armas. | métrica `knives_owned` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:380` | 10 |
| 42 | 🧺 **Frutero**<br>`frutero` | Desbloquea 5 frutas distintas. | métrica `fruits_unlocked` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:371` | 5 |
| 43 | 👨‍🌾 **Granjero**<br>`granjero` | Desbloquea 15 frutas distintas. | métrica `fruits_unlocked` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:371` | 15 |
| 44 | 🌳 **Huerta Completa**<br>`huerta_completa` | Desbloquea todas las frutas. | métrica `fruits_unlocked` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:371` | 20 |
| 45 | 🃏 **Manos Amigas**<br>`baraja_inicial` | Descubre 10 comodines distintos. | métrica `cards_discovered` (máximo **histórico**)<br>`scripts/autoload/StatsManager.gd:440` | 10 |
| 46 | 🃏 **Baraja Surtida**<br>`baraja_surtida` | Descubre 30 comodines distintos. | métrica `cards_discovered` (máximo **histórico**)<br>`scripts/autoload/StatsManager.gd:440` | 30 |
| 47 | 🔮 **Cartomántico**<br>`cartomantico` | Descubre 60 comodines distintos. | métrica `cards_discovered` (máximo **histórico**)<br>`scripts/autoload/StatsManager.gd:440` | 60 |
| 48 | 🂠 **Coleccionista de Cartas**<br>`coleccionista_cartas` | Descubre todos los comodines. | métrica `cards_discovered` (máximo **histórico**)<br>`scripts/autoload/StatsManager.gd:440` | 100 |
| 49 | 🎖️ **Maestría**<br>`maestria` | Compra tu primera mejora de prestigio. | métrica `prestige_bought` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:539` | 1 |
| 50 | 🎓 **Polímata**<br>`polimata` | Compra 25 mejoras de prestigio. | métrica `prestige_bought` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:539` | 25 |
| 51 | 🥇 **Erudito Prestigioso**<br>`erudito` | Compra 100 mejoras de prestigio. | métrica `prestige_bought` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:539` | 100 |
| 52 | 🃏 **Ojo para lo Raro**<br>`ojo_para_lo_raro` | Descubre 5 comodines Raros. | métrica `cards_rare` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:443` | 5 |
| 53 | 🃏 **Afortunado**<br>`afortunado` | Descubre 3 comodines Épicos. | métrica `cards_epic` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:445` | 3 |
| 54 | 🃏 **Poder Épico**<br>`mucho_peak` | Descubre un comodín Legendario. | métrica `cards_legendary` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:447` | 1 |
| 55 | 💎 **Primer Millón**<br>`seis_ceros` | Genera $1.000.000 en TOTAL en un solo negocio. | métrica `run_money_total` (pico **del negocio**)<br>`scripts/autoload/GameManager.gd:496` | 1.000.000 |
| 56 | 📆 **Medio Centenar**<br>`total_dias_media` | Completa 50 días en total acumulados. | métrica `days_completed_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:414` | 50 |
| 57 | 📆 **Cien Días Jugados**<br>`total_dias_cien` | Completa 100 días en total acumulados. | métrica `days_completed_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:414` | 100 |
| 58 | 🗓️ **Bicamarón**<br>`total_dias_doscientos` | Completa 200 días en total acumulados. | métrica `days_completed_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:414` | 200 |
| 59 | 🗓️ **Medio Milenio**<br>`total_dias_quinientos` | Completa 500 días en total acumulados. | métrica `days_completed_total` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:414` | 500 |

---

## 3. Logros de objetivo (24)

| # | Logro | Descripción | Condición | Objetivo |
|---|---|---|---|---|
| 1 | 🎬 **Centenario**<br>`centenario` | Llega al día 100 (la meta). | métrica `best_day` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:413` | 100 |
| 2 | 🔥 **Diez en Fila**<br>`racha_de_10` | Alcanza una racha de 10 cortes seguidos. | métrica `max_streak` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:186` | 10 |
| 3 | 🔥 **Vigésima Racha**<br>`racha_de_20` | Alcanza una racha de 20 cortes seguidos. | métrica `max_streak` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:186` | 20 |
| 4 | 🔥 **Racha de 30**<br>`racha_de_30` | Alcanza una racha de 30 cortes seguidos. | métrica `max_streak` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:186` | 30 |
| 5 | 🥵 **Imparable**<br>`imparable` | Alcanza la racha máxima de 50 cortes seguidos. | métrica `max_streak` (máximo **histórico**)<br>`scripts/autoload/GameManager.gd:186` | 50 |
| 6 | 💯 **Día Perfecto**<br>`dia_perfecto` | Completa 5 días sin tocar NI UNA piedra. | métrica `clean_days` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:416` | 5 |
| 7 | ✨ **Semana Perfecta**<br>`semana_perfecta` | Completa 20 días sin tocar ninguna piedra. | métrica `clean_days` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:416` | 20 |
| 8 | 🍉 **Sandía Gigante**<br>`sandia_gigante` | Corta 5 Sandías. | métrica `cut_watermelon` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 9 | 🍈 **Pitahaya Encendida**<br>`pitahaya` | Corta 5 Pitahayas (Fruta del Dragón). | métrica `cut_dragon_fruit` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 10 | 🥑 **Aguacate Real**<br>`aguacate` | Corta 5 Aguacates. | métrica `cut_avocado` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 11 | 🥝 **Kiwi Moderno**<br>`kiwi` | Corta 25 Kiwis. | métrica `cut_kiwi` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 25 |
| 12 | 🥭 **Mango Tropical**<br>`mango` | Corta 25 Mangos. | métrica `cut_mango` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 25 |
| 13 | 🍋 **Limón Fresco**<br>`limon` | Corta 25 Limones. | métrica `cut_lemon` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 25 |
| 14 | 🍐 **Pera Madura**<br>`pera` | Corta 25 Peras. | métrica `cut_pear` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 25 |
| 15 | 🍑 **Melocotón Dulce**<br>`durazno` | Corta 100 Melocotones. | métrica `cut_peach` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 100 |
| 16 | 🍒 **Cereza Redonda**<br>`cereza` | Corta 100 Cerezas. | métrica `cut_cherry` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 100 |
| 17 | 🍊 **Naranja Ácida**<br>`naranja` | Corta 100 Naranjas. | métrica `cut_orange` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 100 |
| 18 | 🍎 **Manzana Crujiente**<br>`manzana` | Corta 100 Manzanas. | métrica `cut_apple` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 100 |
| 19 | 🥝 **Guayaba Exótica**<br>`guayaba` | Corta 5 Guayabas. | métrica `cut_guava` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 20 | 🍍 **Piña Madura**<br>`piña` | Corta 5 Piñas. | métrica `cut_pineapple` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 21 | 🍈 **Melón Jugoso**<br>`melón` | Corta 5 Melones. | métrica `cut_melon` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 22 | 🥭 **Papaya Tropical**<br>`papaya` | Corta 5 Papayas. | métrica `cut_papaya` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 23 | 🚀 **Más Allá de la Meta**<br>`mas_alla` | Supera el día 100 (101+). | flag `surpassed_day_100` → `scripts/autoload/GameManager.gd:456`| Binario |
| 24 | 🪚 **Líder de Corte**<br>`lider_de_corte` | Corta con la Motosierra (el arma definitiva). | flag `used_chainsaw` → `scripts/autoload/GameManager.gd:389`| Binario |

---

## 4. Logros de estilo de juego (17)

| # | Logro | Descripción | Condición | Objetivo |
|---|---|---|---|---|
| 1 | ✨ **Doble Dorado**<br>`doble_dorado` | Corta dos frutas doradas en un mismo día. | métrica `golden_fruits_in_one_day` (pico **del día**)<br>`scripts/autoload/GameManager.gd:336` | 2 |
| 2 | 💥 **Suerte Crítica**<br>`suerte_critica` | Consigue 3 críticos en un mismo día. | métrica `crits_in_one_day` (pico **del día**)<br>`scripts/game/SwipeController.gd:154` | 3 |
| 3 | 🛒 **Comprador Compulsivo**<br>`comprador` | Compra 5 mejoras del mercado en un mismo negocio. | métrica `upgrades_bought_run` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:422` | 5 |
| 4 | 🛍️ **Megacomprador**<br>`megacomprador` | Compra 20 mejoras del mercado en un mismo negocio. | métrica `upgrades_bought_run` (acumulado **permanente**)<br>`scripts/autoload/StatsManager.gd:422` | 20 |
| 5 | 🚀 **Cosecha Doble**<br>`cosecha_doblada` | Aumenta la frecuencia de lanzamiento (Cosecha Veloz) 3 veces en un negocio. | métrica `launch_upgrades_run` (pico **del negocio**)<br>`scripts/autoload/StatsManager.gd:424` | 3 |
| 6 | ✂️ **Cinco en Uno**<br>`cinco_en_uno` | Corta 5 frutas con un solo trazo. | métrica `multi_cut_5` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:163` | 1 |
| 7 | 👊 **Purista**<br>`purista` | Completa un día equipando solo el Puño. | flag `day_with_fist` → `scripts/autoload/GameManager.gd:420`| Binario |
| 8 | ⚙️ **Soldado de Hierro**<br>`sin_rincon_dark` | Completa un día con la Motosierra equipada. | flag `day_with_top_knife` → `scripts/autoload/GameManager.gd:430`| Binario |
| 9 | 🍴 **Paciente**<br>`paciente` | Completa un día con el Tenedor equipado. | flag `day_with_fork` → `scripts/autoload/GameManager.gd:422`| Binario |
| 10 | 🔪 **Cuchillero**<br>`cuchillero` | Completa un día con un Cuchillo equipado. | flag `day_with_knife` → `scripts/autoload/GameManager.gd:424`| Binario |
| 11 | 🪓 **Hachador**<br>`hachador` | Completa un día con un Hacha equipada. | flag `day_with_axe` → `scripts/autoload/GameManager.gd:426`| Binario |
| 12 | ⚔️ **Espadachín**<br>`espadachin` | Completa un día con una Espada equipada. | flag `day_with_sword` → `scripts/autoload/GameManager.gd:428`| Binario |
| 13 | 🔒 **Hachero Total**<br>`central_frutal` | Completa un día sin cambiar de arma. | flag `day_unchanged_weapon` → `scripts/autoload/GameManager.gd:441`| Binario |
| 14 | 🍀 **Bingo Dorado**<br>`bingo` | Consigue un Jackpot con una fruta dorada. | flag `golden_jackpot` → `scripts/autoload/GameManager.gd:330`| Binario |
| 15 | 📈 **Especulador**<br>`especulador` | Compra una mejora de DAÑO, VIDA, SUERTE y DINERO en el mismo negocio. | flag `bought_all_upgrade_types` → `scripts/autoload/StatsManager.gd:426`| Binario |
| 16 | 🍞 **Fruta y Pan**<br>`fruits_and_breaks` | Corta una fruta DORADA Y una normal en el mismo día. | flag `golden_and_normal_day` → `scripts/autoload/GameManager.gd:338`, `scripts/autoload/GameManager.gd:342`| Binario |
| 17 | 🍊 **Colores de Verano**<br>`fresa_y_naranja` | Corta una Fresa y una Naranja en el mismo día. | flag `fresa_y_naranja_day` → `scripts/autoload/GameManager.gd:436`| Binario |

---

## 5. Logros graciosos (9)

| # | Logro | Descripción | Condición | Objetivo |
|---|---|---|---|---|
| 1 | 🪨 **Coleccionista de Piedras**<br>`coleccionista_piedras` | Golpea 50 piedras... ¿en serio? | métrica `stones_hit` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:186` | 50 |
| 2 | 🧱 **Saboteador Frutal**<br>`futbolista_sabotaje` | Golpea 250 piedras a propósito. | métrica `stones_hit` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:186` | 250 |
| 3 | 🪨 **Cantero Implacable**<br>`cantero_implacable` | Golpea 1.000 piedras. | métrica `stones_hit` (acumulado **permanente**)<br>`scripts/game/SwipeController.gd:186` | 1.000 |
| 4 | 💸 **Primera Quiebra**<br>`primera_quiebra` | Tu negocio quiebra por primera vez. | métrica `runs_bankrupt` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:495` | 1 |
| 5 | 🎲 **Empresario Riesgoso**<br>`empresario_riesgoso` | Quiebra 10 negocios. | métrica `runs_bankrupt` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:495` | 10 |
| 6 | 😵 **Fundador Masoquista**<br>`fundador_masoquista` | Quiebra 50 negocios. | métrica `runs_bankrupt` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:495` | 50 |
| 7 | 🍂 **Se Me Fue**<br>`se_me_fue` | Rompe tu racha por primera vez. | métrica `streak_broke` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:197` | 1 |
| 8 | 🪨 **Tropiezo Recurrente**<br>`corredor_de_tropezones` | Rompe la racha 50 veces. | métrica `streak_broke` (acumulado **permanente**)<br>`scripts/autoload/GameManager.gd:197` | 50 |
| 9 | 👊 **Origen**<br>`origen` | Corta 100 frutas con el Puño equipado. | flag `started_with_fist` → `scripts/autoload/GameManager.gd:347`| Binario |

---

## 6. Logros secretos / easter eggs (12)

| # | Logro | Descripción | Condición | Objetivo |
|---|---|---|---|---|
| 1 | 🥥 **Coco Loco**<br>`cocoo` | Corta 50 cocos en total. | métrica `cut_coconut` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 50 |
| 2 | 🎃 **Rey Calabaza**<br>`calabaza_mago` | Corta 3 Calabazas (la fruta más cara). | métrica `cut_pumpkin` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 3 |
| 3 | 🍐 **Membrillo Curioso**<br>`membrillo` | Corta 5 Membrillos. | métrica `cut_quince` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 5 |
| 4 | 🍌 **Banana Divina**<br>`banana_dorada` | Corta 100 Bananas. | métrica `cut_banana` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 100 |
| 5 | 🍓 **Fresa Preferida**<br>`fresa_preferida` | Corta 200 Fresas. | métrica `cut_strawberry` (—)<br>`scripts/autoload/GameManager.gd` (dinámica: `"cut_" + fruit_id`) → `record_metric("cut_" + fruit_id)` | 200 |
| 6 | ✨ **Combinador Dorado**<br>`combinador_dorado` | Ten 2 frutas doradas en pantalla a la vez. | métrica `golden_on_screen_2` (—)<br>`scripts/game/FruitSpawner.gd:164` | 1 |
| 7 | 👼 **Dios Frutal**<br>`dios_frutal` | Descubre el comodín Mítico (Divinidad). | flag `discover_mythic` → `scripts/autoload/StatsManager.gd:449`| Binario |
| 8 | 🧘 **Estado Mental**<br>`estado_de_creencias` | Recibe crítica sin golpear ninguna piedra (dificil de probar). | flag `esoteric_calm` → `scripts/game/SwipeController.gd:158`| Binario |
| 9 | ⏱️ **Rápido y Furioso**<br>`fruta_termina_rapido` | Completa un día con menos de 5 segundos en el reloj. | flag `beat_day_rushed` → `scripts/autoload/GameManager.gd:305`| Binario |
| 10 | 🩸 **Deuda Cero**<br>`deuda_cero` | Quedar con energía EN 0 exactamente al completar un día. | flag `day_finished_empty` → `scripts/autoload/GameManager.gd:434`| Binario |
| 11 | 🐷 **Astuta Economía**<br>`astuta_economia` | Supera un día (a partir del 2º) sin comprar NINGUNA mejora del mercado en el negocio. | flag `no_prestige_spent_run` → `scripts/autoload/GameManager.gd:446`| Binario |
| 12 | 👀 **Racha Campeona**<br>`tranquilo_juego` | Consigue una racha de 15 sin mirar la barra de racha. | flag `blind_streak` → `scripts/autoload/GameManager.gd:188`| Binario |
---

## 7. Ocultos, sin usar y matizes detectados

### 7.1 La lista completa está oculta hasta el día 100

`AchievementsModal.gd` **filtra los logros no conseguidos** mientras el juego no esté
completado (`_is_game_completed()` comprueba el logro `centenario`). Antes de llegar al
día 100 el modal solo muestra los logros ya desbloqueados; la lista íntegra de 121
entradas (con sus objetivos) solo es visible tras ganar. El resumen también cambia:
antes muestra "🏆 N logros completados", después "🏆 N / 121".

→ **121 logros "ocultos" por diseño**, no por error: son los pendientes sin revelar.

### 7.2 `Rápido y Furioso` no se puede conseguir el día 1

- Definición: `{"id":"fruta_termina_rapido", ..., "flag":"beat_day_rushed"}`.
- Se marca en `scripts/autoload/GameManager.gd:305` con la condición `target_unreached and order_progress >= order_target`.
- El día 1 tiene `order_target == 0.0`, así que `order_progress (0) < order_target (0)` es
  **falso** y el flag nunca se marca: el logro es alcanzable **solo a partir del día 2**.

### 7.3 Cuatro armas sin logro de "estilo"

Los logros de arma se marcan por `match run_equipped_knife` en
`GameManager._on_day_completed()`, y solo cubren 6 de las 10 armas del catálogo:

| Arma | `unlock_order` | Logro de día |
|---|---|---|
| 👊 Puño | 1 | ✅ `purista` |
| 🍴 Tenedor | 2 | ✅ `paciente` |
| 🔪 Cuchillo de mesa | 3 | ❌ **sin logro** |
| ✂️ Tijera | 4 | ❌ **sin logro** |
| 🪒 Cúter | 5 | ❌ **sin logro** |
| 🔪 Cuchillo | 6 | ✅ `cuchillero` |
| 🗡️ Machete | 7 | ❌ **sin logro** |
| 🪓 Hacha | 8 | ✅ `hachador` |
| ⚔️ Espada | 9 | ✅ `espadachin` |
| 🪚 Motosierra | 10 | ✅ `sin_rincon_dark` / `lider_de_corte` |

Los 10 sí cuentan para `coleccionista_armas` (`knives_owned`, objetivo 10).

### 7.4 Objetivo que no cuadra con su descripción

`coleccionista_cartas` — *"Descubre **todos** los comodines"* — tiene
`target: 100` sobre `cards_discovered`, pero el catálogo tiene **108 cartas**
(ver `Informe de comodines.md`). El logro se cumple 8 cartas antes de descubrir todo el
catálogo, y la galería (`CardsModal`) no muestra ningún porcentaje, así que el jugador no
tiene forma de saber que le quedan 8 cartas por descubrir.

### 7.5 Categorías y helpers definidos pero sin usar

| Elemento | Estado |
|---|---|
| `cat: "aleatorio"` | Ningún logro lo usa |
| `cat: "easter_egg"` | Ningún logro lo usa |
| `CATEGORY_ICONS` (7 iconos) | El modal ya **no agrupa** por categoría: muestra una sola pestaña "TODOS LOS LOGROS" |
| `get_category_label()` | Sin llamadas: quedó obsoleto al unificar la lista |

### 7.6 Semántica de `upgrades_bought_run`

`comprador` (5) y `megacomprador` (20) usan `record_metric("upgrades_bought_run")`
en `StatsManager.gd`, es decir **acumulado histórico**, no "en un mismo negocio" como
dice la descripción. Un jugador que reúna 5 compras repartidas en 5 negocios distintos
desbloquea `comprador`.

### 7.7 Logros condicionados a ventanas muy estrechas

| Logro | Condición real | Observación |
|---|---|---|
| `tranquilo_juego` (`blind_streak`) | `current_streak == 15` exacto (`scripts/autoload/GameManager.gd:187`) | Si el jugador llega a 16 sin pasar por el check, no salta; en la práctica el check corre en cada corte |
| `deuda_cero` (`day_finished_empty`) | `current_energy <= 0.0` al completar el día (`GameManager._on_day_completed`) | La energía se recorta en 0 al agotarse, así que es la forma natural de cerrar el día |
| `combinador_dorado` (`golden_on_screen_2`) | 2 frutas doradas simultáneas en pantalla (`scripts/game/FruitSpawner.gd:164`) | Depende del spawner, no del corte |
| `estado_de_creencias` (`esoteric_calm`) | Crítico sin golpear ninguna piedra (`scripts/game/SwipeController.gd:158`) | Depende de la resolución de colisiones, no de la puntuación |
| `cinco_en_uno` (`multi_cut_5`) | 5 frutas en un solo trazo | Registra 1 por evento; objetivo 1 |

### 7.8 Lo que sí está bien — sin fallos de integridad

- Los 121 `id` son únicos y todos los `flag` se marcan en algún punto del código.
- Las 20 métricas `cut_<fruta>` se registran de forma dinámica
  (`record_metric("cut_" + fruit_id)`) y sus 20 ids coinciden exactamente con
  `data/fruits/*.tres`.
- Las metas escalonadas por métrica (`best_day`, `fruits_cut`, `money_total`, `crits`,
  `jackpots`, `golden_fruits`, `stones_hit`, `runs_bankrupt`, `streak_broke`,
  `prestige_*`, `days_completed_total`, `cards_discovered`) no dependen del orden:
  un jugador con progreso guardado desbloquea todas las que ya cumple.
