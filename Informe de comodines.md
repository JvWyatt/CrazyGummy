# Informe de comodines

> Inventario completo y verificable del catálogo de comodines (cartas) de **Crazy Fruit**.
> Fuente única de verdad: `scripts/models/CardDatabase.gd` (`ALL_CARDS`, 108 entradas).
> Los datos (nombre, efecto, rareza, `effect_type` y `effect_value`) se han extraído del
> código y contrastado con `StatsManager._apply_card_effect()`, que es quien los aplica.
>
> Este documento es **descriptivo**: no modifica ni rebalancea ninguna carta.

## 1. Resumen

| Dato | Valor |
|---|---|
| Cartas totales | **108** |
| Distribución | 63 Común · 29 Rara · 9 Épica · 5 Legendaria · 2 Mítico |
| Opciones por día completado | **3** (`CardDatabase.get_random_cards(3)`) |
| Selección | **Uniforme al azar**, sin pesos forzados ni filtros |
| Repetición | Permitida: no se excluyen las cartas ya activas |
| Duración del efecto | **Temporal**: dura hasta que quiebra el negocio (`StatsManager.reset_run_stats()`) |
| Rastro permanente | Solo el **descubrimiento** (`SaveManager.discover_card`) y los logros asociados |
| Ids / títulos duplicados | Ninguno |

### Probabilidades reales del sorteo

| Rareza | Cartas | Por carta | Al menos 1 entre 3 |
|---|---|---|---|
| Común | 63 | 58.3% | 92.8% |
| Rara | 29 | 26.9% | 60.9% |
| Épica | 9 | 8.3% | 23.0% |
| Legendaria | 5 | 4.6% | 13.3% |
| Mítico | 2 | 1.9% | 5.5% |

> Con 3 cartas por día, la probabilidad de ver **al menos una Mítica** es del 5.5% (algo
> más de 1 día de cada 18) y la de ver **al menos una Legendaria** es del 13.3% (1 de cada
> 7-8 días). Las 2 cartas Míticas son, además, las más escasas del juego.

## 2. Ciclo de vida de un comodín

1. Al completar un pedido, `CardSelectionModal.open_modal()` cobra el impuesto del día y
   llama a `CardDatabase.get_random_cards(3)`.
2. El jugador elige 1 de las 3 → `StatsManager.apply_card_upgrade(id, effect_type, effect_value, title)`.
3. `apply_card_upgrade` registra el descubrimiento permanente, actualiza las métricas de
   logros de rareza (`cards_rare`, `cards_epic`, `cards_legendary`, `cards_discovered`) y
   llama a `_apply_card_effect()`, que **acumula** el valor en el multiplicador o
   acumulado correspondiente.
4. Los efectos suman entre sí: dos cartas de `damage` +5% dan +10% mientras dure el negocio.
5. Al quebrar el negocio, `StatsManager.reset_run_stats()` devuelve todos los
   multiplicadores a `1.0`. En la galería sobreviven los descubiertos.

## 3. Catálogo completo

Ordenado por rareza y, dentro de cada rareza, por el bloque tal y como aparece en el código.


### Común — 63 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Filo Ligero** | +3% daño | `damage` | `0.03` | daño |
| 2 | 🃏 **Filo de Acero** | +5% daño | `damage` | `0.05` | daño |
| 3 | 🃏 **Puño Firme** | +7% daño | `damage` | `0.07` | daño |
| 4 | 🃏 **Pulso** | +4% daño | `damage` | `0.04` | daño |
| 5 | 🃏 **Filo Afilado** | +6% daño | `damage` | `0.06` | daño |
| 6 | 🃏 **Golpe Letal** | +5.5% daño | `damage` | `0.055` | daño |
| 7 | 🃏 **Buen Aguante** | +3% resistencia máxima | `energy_max` | `0.03` | resistencia máxima |
| 8 | 🃏 **Piernas Firmes** | +4% resistencia máxima | `energy_max` | `0.04` | resistencia máxima |
| 9 | 🃏 **Segundo Aliento** | +5% resistencia máxima | `energy_max` | `0.05` | resistencia máxima |
| 10 | 🃏 **Vigor Rápido** | +6% resistencia máxima | `energy_max` | `0.06` | resistencia máxima |
| 11 | 🃏 **Refuerzo** | +3.5% resistencia máxima | `energy_max` | `0.035` | resistencia máxima |
| 12 | 🃏 **Resistencia Extra** | +5.5% resistencia máxima | `energy_max` | `0.055` | resistencia máxima |
| 13 | 🃏 **Cosecha Segura** | +3% recompensa mínima | `reward_min` | `0.03` | recompensa mínima |
| 14 | 🃏 **Fruto Fresco** | +4% recompensa mínima | `reward_min` | `0.04` | recompensa mínima |
| 15 | 🃏 **Buen Reparto** | +5% recompensa mínima | `reward_min` | `0.05` | recompensa mínima |
| 16 | 🃏 **Cosecha Ligera** | +3.5% recompensa mínima | `reward_min` | `0.035` | recompensa mínima |
| 17 | 🃏 **Suelo Fertil** | +5.5% recompensa mínima | `reward_min` | `0.055` | recompensa mínima |
| 18 | 🃏 **Fruta Valiosa** | +3% recompensa máxima | `reward_max` | `0.03` | recompensa máxima |
| 19 | 🃏 **Jugo Maduro** | +4% recompensa máxima | `reward_max` | `0.04` | recompensa máxima |
| 20 | 🃏 **Cosecha Doble** | +5% recompensa máxima | `reward_max` | `0.05` | recompensa máxima |
| 21 | 🃏 **Cosecha Plena** | +3.5% recompensa máxima | `reward_max` | `0.035` | recompensa máxima |
| 22 | 🃏 **Cosecha Amplia** | +5.5% recompensa máxima | `reward_max` | `0.055` | recompensa máxima |
| 23 | 🃏 **Pequeña Fortuna** | +0.3% probabilidad de Jackpot | `jackpot` | `0.003` | probabilidad de Jackpot |
| 24 | 🃏 **Buena Estrella** | +0.25% probabilidad de Jackpot | `jackpot` | `0.0025` | probabilidad de Jackpot |
| 25 | 🃏 **Premio Mayor** | +0.1x multiplicador de Jackpot | `jackpot_multiplier` | `0.1` | multiplicador de Jackpot |
| 26 | 🃏 **Buen Negocio** | +3% multiplicador de ganancias | `money` | `0.03` | multiplicador de ganancias |
| 27 | 🃏 **Monedero** | +4% multiplicador de ganancias | `money` | `0.04` | multiplicador de ganancias |
| 28 | 🃏 **Bolsa Rellena** | +5% multiplicador de ganancias | `money` | `0.05` | multiplicador de ganancias |
| 29 | 🃏 **Bolsa Doblada** | +3.5% multiplicador de ganancias | `money` | `0.035` | multiplicador de ganancias |
| 30 | 🃏 **Mercado Furioso** | +5.5% multiplicador de ganancias | `money` | `0.055` | multiplicador de ganancias |
| 31 | 🃏 **Riqueza** | +6% multiplicador de ganancias | `money` | `0.06` | multiplicador de ganancias |
| 32 | 🃏 **Punto Preciso** | +1% probabilidad de Crítico | `crit_chance` | `0.01` | probabilidad de crítico |
| 33 | 🃏 **Foco** | +2% probabilidad de Crítico | `crit_chance` | `0.02` | probabilidad de crítico |
| 34 | 🃏 **Filigrana** | +3% probabilidad de Crítico | `crit_chance` | `0.03` | probabilidad de crítico |
| 35 | 🃏 **Golpe Firme** | +1.5% probabilidad de Crítico | `crit_chance` | `0.015` | probabilidad de crítico |
| 36 | 🃏 **Mano Certera** | +1.2% probabilidad de Crítico | `crit_chance` | `0.012` | probabilidad de crítico |
| 37 | 🃏 **Puntería** | +2.5% probabilidad de Crítico | `crit_chance` | `0.025` | probabilidad de crítico |
| 38 | 🃏 **Ritmo Constante** | +3% frecuencia de lanzamiento | `launch_rate` | `0.03` | frecuencia de lanzamiento |
| 39 | 🃏 **Viento Leve** | +4% frecuencia de lanzamiento | `launch_rate` | `0.04` | frecuencia de lanzamiento |
| 40 | 🃏 **Rayo** | +5% frecuencia de lanzamiento | `launch_rate` | `0.05` | frecuencia de lanzamiento |
| 41 | 🃏 **Giro Veloz** | +3.5% frecuencia de lanzamiento | `launch_rate` | `0.035` | frecuencia de lanzamiento |
| 42 | 🃏 **Tormenta Ligera** | +5.5% frecuencia de lanzamiento | `launch_rate` | `0.055` | frecuencia de lanzamiento |
| 43 | 🃏 **Filo en el Viento** | +2.5% frecuencia de lanzamiento | `launch_rate` | `0.025` | frecuencia de lanzamiento |
| 44 | 🃏 **Fruta Delicada** | -3% vida de las frutas | `fruit_hp` | `-0.03` | vida de frutas |
| 45 | 🃏 **Fruta Frágil** | -4% vida de las frutas | `fruit_hp` | `-0.04` | vida de frutas |
| 46 | 🃏 **Armas Baratas** | -3% precio de armas | `weapon_price` | `-0.03` | precio de armas |
| 47 | 🃏 **Rebaja** | -4% precio de armas | `weapon_price` | `-0.04` | precio de armas |
| 48 | 🃏 **Compra Mayorista** | -5% precio de armas | `weapon_price` | `-0.05` | precio de armas |
| 49 | 🃏 **Frutas Baratas** | -3% precio de frutas | `fruit_price` | `-0.03` | precio de frutas |
| 50 | 🃏 **Oferta** | -4% precio de frutas | `fruit_price` | `-0.04` | precio de frutas |
| 51 | 🃏 **Venta al Por Mayor** | -5% precio de frutas | `fruit_price` | `-0.05` | precio de frutas |
| 52 | 🃏 **Mejoras Baratas** | -3% precio de mejoras | `upgrade_price` | `-0.03` | precio de mejoras |
| 53 | 🃏 **Cambio Justo** | -4% precio de mejoras | `upgrade_price` | `-0.04` | precio de mejoras |
| 54 | 🃏 **Ahorro Mayor** | -5% precio de mejoras | `upgrade_price` | `-0.05` | precio de mejoras |
| 55 | 🃏 **Buen Progreso** | -3% objetivo de dinero del día | `order_target` | `-0.03` | objetivo del día |
| 56 | 🃏 **Día Corto** | -4% objetivo de dinero del día | `order_target` | `-0.04` | objetivo del día |
| 57 | 🃏 **Día Bueno** | -5% objetivo de dinero del día | `order_target` | `-0.05` | objetivo del día |
| 58 | 🃏 **Cortes Ligeros** | -4% energía por golpe | `energy_cost` | `-0.04` | energía por golpe |
| 59 | 🃏 **Mano Suave** | -6% energía por golpe | `energy_cost` | `-0.06` | energía por golpe |
| 60 | 🃏 **Brillo Dorado** | +0.05% de Probabilidad de Fruta Dorada | `golden_fruit_chance` | `0.0005` | probabilidad de fruta dorada |
| 61 | 🃏 **Toque Brillante** | +0.1% de Probabilidad de Fruta Dorada | `golden_fruit_chance` | `0.001` | probabilidad de fruta dorada |
| 62 | 🃏 **Filo del Experto** | +6.5% daño | `damage` | `0.065` | daño |
| 63 | 🃏 **Cadena de Cortes** | +x0.1 al multiplicador de racha | `streak_bonus` | `0.1` | multiplicador de racha |

### Rara — 29 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Filo Superior** | +9% daño | `damage` | `0.09` | daño |
| 2 | 🃏 **Filo Devastador** | +12% daño | `damage` | `0.12` | daño |
| 3 | 🃏 **Reserva Extra** | +9% resistencia máxima | `energy_max` | `0.09` | resistencia máxima |
| 4 | 🃏 **Reserva Titánica** | +12% resistencia máxima | `energy_max` | `0.12` | resistencia máxima |
| 5 | 🃏 **Cosecha Rica** | +9% recompensa mínima | `reward_min` | `0.09` | recompensa mínima |
| 6 | 🃏 **Cosecha Abundante** | +12% recompensa mínima | `reward_min` | `0.12` | recompensa mínima |
| 7 | 🃏 **Cosecha Mayor** | +9% recompensa máxima | `reward_max` | `0.09` | recompensa máxima |
| 8 | 🃏 **Cosecha Exuberante** | +12% recompensa máxima | `reward_max` | `0.12` | recompensa máxima |
| 9 | 🃏 **Fortuna Creciente** | +0.6% probabilidad de Jackpot | `jackpot` | `0.006` | probabilidad de Jackpot |
| 10 | 🃏 **Fortuna Dorada** | +1% probabilidad de Jackpot | `jackpot` | `0.01` | probabilidad de Jackpot |
| 11 | 🃏 **Jackpot Mejorado** | +0.3x multiplicador de Jackpot | `jackpot_multiplier` | `0.3` | multiplicador de Jackpot |
| 12 | 🃏 **Negocio Próspero** | +9% multiplicador de ganancias | `money` | `0.09` | multiplicador de ganancias |
| 13 | 🃏 **Mercado Dorado** | +12% multiplicador de ganancias | `money` | `0.12` | multiplicador de ganancias |
| 14 | 🃏 **Golpe Certero** | +3.5% probabilidad de Crítico | `crit_chance` | `0.035` | probabilidad de crítico |
| 15 | 🃏 **Golpe Mortal** | +4.5% probabilidad de Crítico | `crit_chance` | `0.045` | probabilidad de crítico |
| 16 | 🃏 **Ritmo Fuerte** | +9% frecuencia de lanzamiento | `launch_rate` | `0.09` | frecuencia de lanzamiento |
| 17 | 🃏 **Tormenta de Frutas** | +12% frecuencia de lanzamiento | `launch_rate` | `0.12` | frecuencia de lanzamiento |
| 18 | 🃏 **Fruta Frágil II** | -7% vida de las frutas | `fruit_hp` | `-0.07` | vida de frutas |
| 19 | 🃏 **Fruta Rompible** | -10% vida de las frutas | `fruit_hp` | `-0.1` | vida de frutas |
| 20 | 🃏 **Toque Dorado** | +0.2% de Probabilidad de Fruta Dorada | `golden_fruit_chance` | `0.002` | probabilidad de fruta dorada |
| 21 | 🃏 **Cosecha Dorada** | +0.3% de Probabilidad de Fruta Dorada | `golden_fruit_chance` | `0.003` | probabilidad de fruta dorada |
| 22 | 🃏 **Corte Eficiente** | -12% energía por golpe | `energy_cost` | `-0.12` | energía por golpe |
| 23 | 🃏 **Día Favorable** | -8% objetivo de dinero del día | `order_target` | `-0.08` | objetivo del día |
| 24 | 🃏 **Comerciante** | -6% precio de armas, frutas y mejoras | `all_prices` | `-0.06` | precios (armas + frutas + mejoras) |
| 25 | 🃏 **Mayorista de Armas** | -8% precio de armas | `weapon_price` | `-0.08` | precio de armas |
| 26 | 🃏 **Cesta de Ofertas** | -8% precio de frutas | `fruit_price` | `-0.08` | precio de frutas |
| 27 | 🃏 **Tecnología de Punta** | -8% precio de mejoras | `upgrade_price` | `-0.08` | precio de mejoras |
| 28 | 🃏 **Ritmo de Campeón** | +x0.2 al multiplicador de racha | `streak_bonus` | `0.2` | multiplicador de racha |
| 29 | 🃏 **Pie Firme** | La primera piedra del día no quita resistencia | `first_stone_free` | `1` | primera piedra del día gratis |

### Épica — 9 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Filo Supremo** | +18% daño | `damage` | `0.18` | daño |
| 2 | 🃏 **Fortuna Suprema** | +1.5% probabilidad de Jackpot | `jackpot` | `0.015` | probabilidad de Jackpot |
| 3 | 🃏 **Golpe Perfecto** | +8% probabilidad de Crítico | `crit_chance` | `0.08` | probabilidad de crítico |
| 4 | 🃏 **Cosecha Torrencial** | +18% recompensa máxima | `reward_max` | `0.18` | recompensa máxima |
| 5 | 🃏 **Coloso** | +18% resistencia máxima | `energy_max` | `0.18` | resistencia máxima |
| 6 | 🃏 **Meteoro** | +18% frecuencia de lanzamiento | `launch_rate` | `0.18` | frecuencia de lanzamiento |
| 7 | 🃏 **Leyenda Dorada** | +0.6% de Probabilidad de Fruta Dorada | `golden_fruit_chance` | `0.006` | probabilidad de fruta dorada |
| 8 | 🃏 **Furia de la Racha** | +x0.5 al multiplicador de racha | `streak_bonus` | `0.5` | multiplicador de racha |
| 9 | 🃏 **Rompepiedras** | +1% probabilidad de romper una piedra | `stone_break_chance` | `0.01` | probabilidad de romper piedra |

### Legendaria — 5 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Filazo Épico** | +28% daño | `damage` | `0.28` | daño |
| 2 | 🃏 **Jackpot Legendario** | +1x multiplicador de Jackpot | `jackpot_multiplier` | `1` | multiplicador de Jackpot |
| 3 | 🃏 **Tormenta Perfecta** | +28% frecuencia de lanzamiento | `launch_rate` | `0.28` | frecuencia de lanzamiento |
| 4 | 🃏 **Racha Infinita** | +x1.0 al multiplicador de racha | `streak_bonus` | `1` | multiplicador de racha |
| 5 | 🃏 **Demoledor** | +3% probabilidad de romper una piedra | `stone_break_chance` | `0.03` | probabilidad de romper piedra |

### Mítico — 2 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Divinidad** | +12% probabilidad de Crítico | `crit_chance` | `0.12` | probabilidad de crítico |
| 2 | 🃏 **Racha Eterna** | Mantiene el conteo de racha entre días | `streak_keep` | `1` | racha entre días |

---

## 4. Tipos de efecto: código vs. cartas

`StatsManager._apply_card_effect()` reconoce **23** tipos de efecto. Este inventario cruza
cada tipo con las cartas que lo usan y con el consumidor real del valor:

| `effect_type` | Tarjetas | Acumulado en `StatsManager` | Dónde se consume |
|---|---|---|---|
| `all_prices` | 1 | `los 3 multiplicadores de precio` | los tres multiplicadores de precio a la vez |
| `crit_chance` | 10 | `card_crit_chance` | `get_final_critical_chance()` |
| `damage` | 11 | `card_damage_multiplier` | `get_final_damage()` → daño del arma |
| `energy_cost` | 3 | `card_energy_cost_multiplier` | `get_final_energy_cost()` |
| `energy_max` | 9 | `card_energy_multiplier` | `get_final_max_energy()` |
| `first_stone_free` | 1 | `card_first_stone_free` | `has_first_stone_free()` → `SwipeController` |
| `fruit_hp` | 4 | `card_fruit_hp_multiplier` | `get_fruit_max_hp_multiplier()` → `FruitDatabase.create_fruit_resource()` |
| `fruit_price` | 4 | `card_fruit_price_multiplier` | `get_fruit_price()` |
| `golden_fruit_chance` | 5 | `card_golden_fruit_chance` | `get_golden_fruit_chance()` |
| `jackpot` | 5 | `card_jackpot_bonus` | `get_final_jackpot_bonus()` → probabilidad de jackpot |
| `jackpot_multiplier` | 3 | `card_jackpot_multiplier_bonus` | `get_final_jackpot_multiplier()` |
| `launch_rate` | 10 | `card_launch_rate_multiplier` | `get_final_launch_rate()` |
| `money` | 8 | `card_money_multiplier` | `get_final_money_multiplier()` → recompensa por corte |
| `order_target` | 4 | `card_order_target_multiplier` | `get_order_target_multiplier()` → `GameManager.get_order_target_for()` |
| `prestige` | **0** | `card_prestige_bonus` | `get_prestige_per_day_bonus()` → reputación diaria |
| `reward_max` | 8 | `card_reward_max_multiplier` | `get_fruit_max_reward_multiplier()` → `FruitDatabase.create_fruit_resource()` |
| `reward_min` | 7 | `card_reward_min_multiplier` | `get_fruit_min_reward_multiplier()` → `FruitDatabase.create_fruit_resource()` |
| `stone_break_chance` | 2 | `card_stone_break_chance` | `get_stone_break_chance()` → golpe a piedra |
| `streak_bonus` | 4 | `card_streak_bonus` | `get_streak_bonus()` → multiplicadores de racha |
| `streak_keep` | 1 | `card_streak_keep` | `has_streak_keep()` → `advance_to_next_order()` |
| `upgrade_price` | 4 | `card_upgrade_price_multiplier` | `get_upgrade_cost()` (multiplicador global de mejoras) |
| `weapon_price` | 4 | `card_weapon_price_multiplier` | `get_weapon_price()` |

---

## 5. Ocultos, sin usar y matices detectados

### Cartas "invisibles" / capacidad sin carta

| Capacidad | Estado | Nota |
|---|---|---|
| `effect_type: "prestige"` | **Implementada pero sin ninguna carta** | `card_prestige_bonus` se suma a la reputación diaria (`scripts/autoload/GameManager.gd:409`, `1 ⭐ + bonus`). Es la única rama de `_apply_card_effect()` que ningún comodín puede activar: la reputación por día solo da el punto base. |
| `effect_type: "multi"` | **Soportada por `apply_card_upgrade()`, sin cartas** | El código acepta un `effect_value` con lista de efectos (`for effect in effect_value`), pero ninguna carta del catálogo lo usa. Sirve de base para futuras cartas multi-efecto. |
| `CardSelectionModal._on_card_selected` | Fallback `card_data["effects"]` | Es la otra mitad del soporte "multi": si someday hay cartas multi-efecto, el modal ya lee esa clave. |

### Comentarios obsoletos en el propio catálogo

`CardDatabase.gd` sigue describiendo un pool más pequeño del que existe:

| Sitio | Comentado | Real |
|---|---|---|
| Bloque "Pool común" | "62 cartas" | **63** |
| Bloque "Pool raro" | "27 cartas" | **29** |
| Bloque "Pool épico" | "7 cartas" | **9** |
| Bloque "Pool legendario" | "3 cartas" | **5** |
| Bloque "Pool mítico" | "1 carta" | **2** |
| `get_random_cards()` | "62 Común / 27 Rara / 7 Épica / 3 Legendaria / 1 Mítico" | 108 cartas reales |

No afecta al funcionamiento (los comentarios no participan del sorteo), pero desincroniza
el balance documentado del balance real y puede llevar a error al calcular probabilidades.

### Cartas cuyo repetir no aporta nada

Dos efectos son **booleanos**, no acumulativos: se guardan como `int` y se consultan con
`> 0`. Si vuelven a salir, la segunda copia es inerte:

| Carta | Rareza | Efecto |
|---|---|---|
| `Pie Firme` | Rara | `first_stone_free` → `card_first_stone_free += 1` |
| `Racha Eterna` | Mítico | `streak_keep` → `card_streak_keep += 1` |

Como el sorteo **no excluye** las cartas ya activas, pueden aparecer repetidas: con `Pie Firme`
el jugador puede gastar dos elecciones del día y seguir dispensando **solo** la primera piedra.
Con `Racha Eterna`, obtenerla dos veces no aporta nada extra.

### Las 2 cartas míticas

| Carta | Efecto | Realidad en juego |
|---|---|---|
| `Divinidad` | +12% probabilidad de crítico | El mayor valor de crítico del juego: por encima del +8% del épica `Golpe Perfecto` y del +4.5% de la rara `Golpe Mortal`. En impacto real depende del arma: el +28% de daño de la legendaria `Filazo Épico` suele pesar más. |
| `Racha Eterna` | Mantiene la racha entre días | Conserva el **contador** de racha al cambiar de día. Sin una carta de `streak_bonus` (`Cadena de Cortes`, `Furia de la Racha`, `Racha Infinita`) el multiplicador se queda en x1.00, así que su beneficio real es no perder el progreso hacia el siguiente hito y no romper la racha al empezar el día siguiente. |

## 6. Resumen de hallazgos

| Hallazgo | Gravedad | Efecto en juego |
|---|---|---|
| `prestige` implementado sin ninguna carta | Baja | La reputación diaria nunca supera el punto base; mecanismo muerto |
| Soporte `multi` sin cartas | Informativa | Código preparado para cartas multi-efecto |
| Comentarios de pool desfasados (100 cartas comentadas vs 108 reales) | Baja | Solo documentación; desincroniza cualquier ajuste de balance futuro |
| `Pie Firme` / `Racha Eterna` repetibles sin efecto | Media | El jugador gasta una elección del día a cambio de nada |
| El sorteo puede repetir cartas activas | Informativa | Permite acumular muchas cartas del mismo tipo en un mismo día |
| Ningún `effect_type` de carta sin implementar | — | Las 108 cartas hacen algo real y verificable |

**No se ha modificado ni una línea de balance**: este informe es el inventario de referencia
para decidir, si algún día se quiere, qué carta usar para el slot `prestige` o cómo evitar
las repeticiones inertes.
