# Crazy Gummy — informe global de la app

> **Documento único de referencia.** Fusiona la guía del proyecto, el informe del
> referencia técnica anterior de cartas (Parte II) y los informes históricos de comodines y
> logros (Parte III). **Estado auditado y verificado: 6 de octubre de 2026,
> después de la migración interna definitiva.**
>
> La arquitectura activa usa cubos, recetas, gomitas y herramientas. Las
> equivalencias anteriores viven solo en el conversor de guardados y en los
> anexos históricos de la Parte III. El código y los recursos actuales prevalecen
> sobre cualquier documento antiguo.
>
> **Actualización visual: 6 de octubre de 2026.** Rediseño integral «confitería
> nocturna» aplicado a Theme, componentes, pantallas y arte especial; véanse §M,
> «Crazy Gummy UI Design System» y la validación posterior en §Q. La Parte II se
> conserva como snapshot anterior, con geometría todavía válida y arte sustituido.

---

## Parte I — Guía del proyecto (estado actual)

**Integración 3D definitiva posterior:** los 28 GLB numerados ya están conectados
al gameplay mediante `RecipeVisualLibrary`, `GummyVisual` y `Projectile3D`.
El mapeo completo vigente y la validación están en
[`../CRAZY_GUMMY_PROJECT_GUIDE.md`](../CRAZY_GUMMY_PROJECT_GUIDE.md).
El cubo 6 se asigna solo al tier 20; los cubos fuente 5 y 6 tienen bytes idénticos.

**Estado auditado y verificado: 6 de octubre de 2026, después de la migración interna definitiva.** Esta es la referencia principal para el próximo rediseño visual. La arquitectura activa usa cubos, recetas, gomitas y herramientas. Las equivalencias anteriores viven solo en el conversor de guardados y la documentación histórica. El código y los recursos actuales prevalecen sobre informes/especificaciones anteriores.

## A. Juego y fantasía funcional

Crazy Gummy es un juego incremental de habilidad por partidas/negocios, para móvil en vertical. El jugador **desliza para golpear cubos de gelatina**, reduce su dureza y, al romperlos, revela una gomita y obtiene dinero. No hay producción automática fuera de la partida ni simulación de ingredientes, empleados o máquinas.

Loop: **cubo → golpes → gomita + recompensa → meta diaria → comodín → mercado → siguiente día**. Las **recetas** permiten que aparezcan gomitas de mayor categoría; las herramientas aumentan la potencia y las mejoras/comodines modifican las estadísticas. El objetivo inicial es completar 100 días; se puede continuar después.

El negocio termina al agotar tiempo o resistencia sin cumplir la meta, al no poder pagar el impuesto o al salir (incluidos los créditos). Todas las salidas registran la run una sola vez. Si ya se completó el día100, el resultado es **NEGOCIO EXITOSO**, incluso al perder un día posterior; antes de esa meta se distingue salida voluntaria de quiebra. La nueva partida empieza con Osito Gummy Clásico y Puños. La reputación, mejoras de prestigio, descubrimientos y logros son permanentes; dinero, recetas/herramientas disponibles y comodines activos pertenecen a la partida actual.

## B. Arquitectura y responsabilidades

- **Godot 4.x / GDScript**, GL Compatibility. `project.godot` declara 4.7; la verificación se hizo con **4.7.2**. Las instrucciones antiguas que citan 4.5 no describen la configuración actual.
- Entrada: `scenes/Main.tscn` + `scripts/Main.gd`. Todas las pantallas permanecen instanciadas; se alterna su visibilidad. No se usa un cambio de escena para navegar.
- `scripts/game/` / `scenes/game/`: interacción, proyectiles 2D, movimiento y presentación 3D.
- `scripts/ui/` / `scenes/ui/`: HUD, pantallas y componentes. Los cuatro componentes con escena propia están en `scenes/ui/components/`.
- `scripts/models/`: Resources de datos y catálogos. `data/catalog.tres` referencia **20 recetas, 10 herramientas, 5 mejoras temporales y 5 permanentes**. No sustituirlo por un listado de carpetas: las rutas remapeadas de exportación necesitan referencias explícitas.
- `data/balance.tres`: constantes reales de balance. `BalanceData.gd` es el respaldo si falla la carga. Los valores de `.tres` mandan.
- `assets/crazy_gummy/materials/palette.tres`: catálogo exclusivamente visual de 20 acabados y oro; lee `unlock_order`, no cambia economía ni colisiones.

### Los siete autoloads (orden en `project.godot`)

| Autoload / script en `scripts/autoload/` | Responsabilidad y conexiones |
|---|---|
| `SaveManager.gd` | JSON permanente; reputación, niveles, descubrimientos, métricas/logros. Señales `data_loaded`, `data_saved`, `prestige_changed`. |
| `StatsManager.gd` | Catálogos, niveles temporales, comodines, fórmulas y cachés. `stats_updated` refresca HUD/tiendas. |
| `SoundManager.gd` | Pool de 8 reproductores SFX procedurales; reproductor Music; contextos menú/juego. |
| `GameManager.gd` | Partida, día, reloj, resistencia, dinero, meta y racha. Emite cambios y fin de día/partida. |
| `UiTheme.gd` | Instala Theme global, formato de cifras, estilos auxiliares y microanimaciones/confeti. |
| `SettingsManager.gd` | Volúmenes Master/Music/SFX en ConfigFile independiente. |
| `AchievementManager.gd` | 121 definiciones, condiciones, persistencia diferida y señal de desbloqueo. |

`scripts/models/SaveMigration.gd` es un **conversor estático**, no un octavo autoload. Traduce datos anteriores antes de que los consuman los sistemas activos.

Flujo de datos: `catalog.tres` → `StatsManager` / `RecipeDatabase` → `BlockSpawner` / tiendas. El trazo de `SwipeController` → `GummyBlock.take_damage()` → `GummyBlock.die()` → `GameManager.register_gummy_produced()` → dinero/racha/logros/señales → HUD. El espejo 3D escucha impactos/destrucción; **no calcula recompensas**.

## C. Mapa completo de pantallas y navegación

Las rutas de la tabla son relativas a `scenes/ui/`; el script controlador correspondiente tiene el mismo nombre en `scripts/ui/` salvo donde se indica. Todos los modales principales usan Theme compartido, oscurecedor de pantalla completa y `Panel` con `ContentSizedModal.gd`.

| Pantalla / escena | Apertura y cierre | Contenido y particularidades |
|---|---|---|
| Menú / `MainMenu.tscn` | Inicio, salida de resultados o créditos. Jugar emite `start_game_requested`; `Main` abre juego y comienza un negocio nuevo. | Fondo vectorial gummy nocturno, icono aportado por el usuario, título Crazy Gummy, frases rotatorias, Jugar, Prestigio, Progreso, Logros, Comodines, Ajustes, versión dinámica. |
| Juego / `../Main.tscn` + `HUD.tscn` | Desde Jugar; permanece debajo de modales durante el negocio. `Main` limpia proyectiles al terminar día/partida. | `GameWorld`, fondo artístico neutro, espejo 3D y HUD. La gomita revelada es visual; no se recoge con un segundo gesto. |
| Pausa / `HUD/PausePanel` | Botón Pausa → `pause_turn()`. Continuar → `resume_turn()`. | Tarjeta con día, Continuar, Ajustes y Salir; alterna PauseVBox/SettingsVBox. No cambia `SceneTree.paused`. |
| Ajustes del menú / `MainMenu/SettingsPanel` | Ajustes; Volver oculta panel y confirmación de reset. | `SettingsSection` reutilizada y Reiniciar progreso. |
| Ajustes de pausa / `HUD/PausePanel/Card/SettingsVBox` | Desde Pausa; Volver regresa a opciones de pausa. | Mismos sliders y guardado que el menú. |
| Confirmación / `ConfirmDialog.tscn` | `open(título, mensaje, aceptar, cancelar)` desde reset o renuncia. | Scrim + Card + botones. Cancelar oculta; aceptar oculta y emite `confirmed`. Dos instancias independientes. |
| Datos / `StatsModal.tscn` | Desde HUD o mercado. `Main` pausa si está PLAYING. X/Cerrar emite `modal_closed` y reanuda si corresponde. | Scroll → StatsVBox → rejilla de 11 stats + acceso a comodines activos. |
| Resumen y elección / `CardSelectionModal.tscn` | `order_completed`; tras créditos si se elige continuar. No tiene cierre libre. | Dinero conseguido, impuesto, ganancia, próxima meta y 3 `CardFlipWidget`. Paga el impuesto al abrir. Elegir una carta cierra y emite `card_chosen` → mercado. Protección contra doble selección. |
| Mercado / `RunUpgradeModal.tscn` | Tras elegir comodín. X **también comienza el siguiente día**, igual que Continuar. | Pestañas **Mejoras, Recetas, Herramientas**, dinero y Datos. Construye tarjetas anticipadamente y las reutiliza al comprar/abrir. |
| Prestigio / `PrestigeShopModal.tscn` | Menú → Prestigio; X lo oculta, vuelve al menú subyacente. | Saldo de reputación + rejilla de 5 `ShopCard`; consulta solo stats permanentes, aunque queden datos temporales del negocio anterior. |
| Progreso / `ProgressModal.tscn` | Menú → Progreso; X. | Mejor día frente a 100, negocios iniciados, gomitas producidas y comodines descubiertos. Solo lectura. |
| Galería / `CardsModal.tscn` | Menú: descubrimientos históricos. Datos: cartas activas, incluidas repeticiones. X; cierra tooltip al ocultarse/redimensionarse. | Rejilla de miniaturas, leyenda de rarezas y estado vacío. Hover PC/toque móvil muestran texto mediante `CardTooltip`, no una ventana de detalle. |
| Logros / `AchievementsModal.tscn` | Menú → Logros; X/Cerrar. | Antes de desbloquear `centenario`, solo logros conseguidos; después muestra todos. Un listado en TabContainer, con filas creadas en lotes de 14/frame, barra solo para counters con target > 1. |
| Resultados / `ResultsModal.tscn` | `run_ended` por derrota, salida o impuesto impagable. Continuar → menú. | NEGOCIO EXITOSO si completó `win_day`; NEGOCIO FINALIZADO por salida voluntaria anterior; NEGOCIO EN QUIEBRA por derrota anterior. Días realmente completados, dinero, gomitas, Jackpots, doradas y reputación ya ganada. |
| Créditos / `CreditsModal.tscn` | Solo al completar **`win_day`**. Continuar → resumen/elección del día actual; Salir → cierre registrado y resultados exitosos. | Día, cuota, autor JvWyatt y dos acciones. Días posteriores usan el resumen normal, sin repetir créditos. |

El enum real es `MENU`, `PLAYING`, `ORDER_CLEARED_CARD_SELECT`, `RUN_UPGRADES_OPEN`, `STATS_OPEN`, `RESULTS`. **No todos esos estados se asignan al abrir una UI**: el flujo efectivo combina `current_state`, `is_round_active` y visibilidad. Por ejemplo, abrir Datos pausa sin cambiar PLAYING; el mercado sigue al estado de fin de día. No diseñar navegación suponiendo que cada modal equivale a un estado del enum.

## D. Jerarquía de UI y componentes reutilizados

Jerarquía relevante de `Main`:

- `Background`, `GummyBackground`, `GoalCelebration`: fondo oscuro, escenario vectorial neutro y confeti detrás del gameplay.
- `MainMenu`: `BG`, `CenterVBox/TitleVBox`, `ButtonsVBox/NavigationGrid` (2 columnas), `SettingsPanel`, versión.
- `GameWorld`: `BlockSpawner`, `SwipeController`, `HUDLayer/HUD`.
- `Projectile3DLayer/Viewport`: SubViewportContainer full rect, `stretch=true`, viewport transparente con mundo 3D independiente. `Main` instancia `Projectile3DWorld` dentro.
- `Modals`: **CanvasLayer 50**, con las nueve pantallas modales instanciadas.
- `SafeAreaLayout`: lista explícita de NodePaths a paneles, HUD, menú y confirmaciones.

HUD:

- `TopContainer/VBox`: TopHBox (día/negocio), MoneyBar (dinero/meta o Bonus), Resources (TimeBar/EnergyBar), Telemetry (StreakRing y RatePanel).
- Anillo de racha **96×96**, aro dibujado en `StreakRing.gd`; contador central y progreso hacia el próximo hito. HUD controla el multiplicador que vuela hacia RatePanel.
- `BottomContainer`: únicamente Datos y Pausa. El nombre de herramienta y la
  potencia se retiraron del HUD por petición del usuario.
- `ToastLayer/AchToast`: **CanvasLayer 10**, cola de avisos de logros, por encima del HUD pero debajo de Modals 50.
- `MilestoneLabel` / `MultiplierFlyLabel`: mensajes centrales temporales y multiplicador animado.
- `PausePanel` y `PauseConfirmDialog`: overlays dentro del HUD.

| Componente | Ruta / responsabilidad | Reutilización y límites actuales |
|---|---|---|
| `ShopCard` | `scenes/ui/components/ShopCard.tscn` + script | Mejoras temporales y prestigio. Icono, nombre, nivel, stat actual, incremento y compra. Alto mínimo 224; botón 48. La tienda conserva referencias a las tarjetas. |
| `CollectionCard` | `scenes/ui/components/CollectionCard.tscn` + script | Recetas/herramientas. **Frente puramente visual**: ilustración/emoji oficial en área cuadrada + velo y POR DESCUBRIR como estado visual (sin nombre, descripción, stats, precio ni texto informativo). **Reverso con toda la info y jerarquía**: nombre (Body en recetas, CardTitle en herramientas), datos, descripción opcional y el botón de acción (comprar/equipar/estado) dentro de la cara girada. Ancho mínimo 180, altura natural del cuadrado. Toque gira; arrastre no. Las **comprables** (cadena desbloqueada) voltean veladas para mostrar precio y botón; las **bloqueadas de cadena** no voltean (el velo no revela contenido). Borde diferencia comprable, comprado y equipado. |
| `StatCard` | `scenes/ui/components/StatCard.tscn` + script | Datos y Progreso. Icono, título, valor y tooltip; mínimo de alto 100, valor con elipsis. |
| `CardFlipWidget` | `scripts/ui/CardFlipWidget.gd` (sin escena propia) | PICK: elección, reverso desplazable y botón Elegir fuera del marco. THUMBNAIL: galería sin reverso. DETAIL existe en código, no se usa en el flujo actual. Mismo arte para todas las cartas. |
| `CardTooltip` | `scenes/ui/components/CardTooltip.tscn` + script | Hover y toque de comodines. Ancho preferido 300, margen 12, reposiciona dentro de pantalla y tiene temporizador de cierre. |
| `SettingsSection` | `scenes/ui/SettingsSection.tscn` + script | Menú y pausa. General/Música/Efectos, sliders y valores porcentuales; `sync()` al abrir. |
| `ConfirmDialog` | `scenes/ui/ConfirmDialog.tscn` + script | Reset permanente y renuncia. Presentación compartida, mensajes y callbacks independientes. |
| `ResponsiveGrid` | `scripts/ui/ResponsiveGrid.gd` | Columnas por ancho disponible, última fila centrada y tamaño uniforme opcional. Mejoras/prestigio: min240, máx2, separación16; colecciones: min180, máx4, altura natural del arte cuadrado más acción, separación8; galería: min144, máx3. Datos crea su grid (min240, máx2, separación10). |
| `ContentSizedModal` | `scripts/ui/ContentSizedModal.gd` | Panel de altura natural, centrado y limitado a 88% del alto seguro, salvo mínimo del contenido. En mercado mide la pestaña Mejoras como referencia para que no salte de altura. |
| `TouchScrollContainer` | `scripts/ui/TouchScrollContainer.gd` | Scroll con dedo incluso si empieza sobre un botón; umbral 8 px. Consume arrastres para no comprar al soltar, conserva manejo de barras. También se adjunta a scrolls creados por código. |

Las rutas actuales son **`TabContainer/Recetas` y `TabContainer/Herramientas`**. Escena, scripts, pruebas y referencias dinámicas se migraron conjuntamente; los títulos coinciden con los nombres de nodo.

## E. Sistemas y comportamiento que afecta a UI

### Interacción, cubos y producto

`SwipeController._unhandled_input()` maneja dedo/ratón. Un segmento cruza un círculo lógico; no basta dejar el dedo dentro: para otro golpe debe salir y volver a entrar. Distancia mínima de trazo 12 px, cooldown del cubo 0,08 s. Cada golpe consume resistencia global, independiente de la herramienta. Potencia final reduce `current_hp`; crítico aplica el multiplicador fijo **×1,5**, probabilidad inicial 0.

`BlockSpawner` elige **uniformemente entre todas las recetas disponibles**, no solo la última. Aparecen a ritmo base 1 cubo/s, trayectoria parabólica con rebotes laterales, máximo 8 lanzamientos por frame del acumulador. Escape por debajo de la pantalla libera el cubo **sin recompensa y sin romper racha**. Caramelo Endurecido usa otro temporizador aleatorio de 1–2 s.

`RecipeDatabase.create_block_recipe()` duplica el Resource base: dureza = floor(base × modificador de dureza); recompensas = base × modificador min/max; radio se duplica. `GummyBlock.tscn` escala ×1,5; la presentación reduce modelo ×0,75 pero **el hitbox conserva su escala lógica**.

`Projectile3DWorld` espeja cada cubo/obstáculo en `Projectile3D`. La cámara ortográfica ajusta su tamaño al viewport y mapea posiciones 2D 1:1. `Projectile3D` usa `GummyVisual.tscn` para todos los tiers y pasa el ID canónico a `RecipeVisualLibrary`: instancia el cubo y la gomita definitivos. Impacto, fragmentos y movimiento heredado conservados; no altera vida/recompensa.

### Catálogo oficial de cubos y obstáculos

| Variante de cubo | Estado real |
|---|---|
| Cubo Gummy Clásico | `cubes/cube_01_classic.glb`, tiers 1–4. |
| Cubo Gummy Ondulado | `cubes/cube_02_wavy.glb`, tiers 5–8. |
| Cubo Gummy Facetado | `cubes/cube_03_faceted.glb`, tiers 9–12. |
| Cubo Gummy con Relieve | `cubes/cube_04_relief.glb`, tiers 13–16. |
| Cubo Gummy Corona | `cubes/cube_05_crown.glb`, tiers 17–19. |
| Cubo Gummy Corona Exclusivo | `cubes/cube_06_crown_exclusive.glb`, solo tier 20. |

Prefijo de rutas: `assets/crazy_gummy/`. Se conserva la secuencia de 20 recetas y sus tamaños/acabados. El label muestra la variante real (✨ si es dorado). Los GLB fuente 5/6 son idénticos; la exclusividad del 6 corresponde a su asignación.

Obstáculos: **Caramelo Duro** es el peligro activo (`Obstacle`, APIs `setup_obstacle`/`break_candy`, grupo `obstacles`). Usa `Obstaculos/obstacle_hard_candy.glb`; al romperse por comodín, la señal `candy_broken` revela `obstacle_hard_candy_broken.glb` completo, que cae y se libera al escapar. Ambos usan el acabado opaco lacado previo burdeos/crema. El objeto lógico se libera como antes, sin nueva recompensa ni penalización.

### Dinero, meta, impuesto y Bonus

- Partida: `run_money` es saldo gastable; `order_progress` es dinero generado en el día; no son siempre la misma cifra.
- Meta: día 1 = $0; día N >= 2 = **10 × 1,21^(N−2) × modificador de meta**.
- Límite fijo: **60 s** por día, no mejorable. El día acaba al agotarse tiempo o resistencia; alcanzar la meta **no lo termina inmediatamente**.
- Recompensa normal: aleatoria entre min/max del recurso de runtime. Premio final = base × multiplicador de ganancias × multiplicador de racha. `register_gummy_produced()` incrementa racha antes de calcular el premio.
- Al cruzar la meta, señal `order_goal_reached` una vez: HUD dorado, confeti y **Bonus = max(0, order_progress − order_target)**. En día 1 se activa con la primera recompensa.
- Al abrir la elección, se descuenta el **impuesto**, igual a la meta del día, del saldo. Ganancia del resumen = conseguido − impuesto. No inventar otro coste ni sustituirlo por ingredientes.
- El HUD antes del Bonus usa saldo `run_money / meta`, mientras la barra sigue `order_progress`. Preservar esta distinción en un rediseño.

### Gomita dorada y Jackpot

`is_golden` se decide al crear el cubo. Probabilidad base **0%**; comodines la suman. Tanto el cubo como el osito usan oro opaco. La dorada garantiza Jackpot: máximo de recompensa × multiplicador Jackpot × **2 extra**, después ganancias y racha. Jackpot normal tiene base **1%** y multiplicador **×2**. Son sistemas distintos: probabilidad de crítico, de Jackpot y de dorada no se deben fusionar.

### Racha, caramelo endurecido y multiplicador

Cada cubo roto/gomita producida suma 1. Los golpes que no rompen y los cubos escapados no suman ni rompen. Hitos: **10 → ×1,10; 50 → ×1,20; 100 → ×1,30; 250 → ×1,50; 500 → ×2; 1000 → ×2,50**. Desde ahí +1 al multiplicador por cada 1000 gomitas adicionales. Los comodines añaden su bonus al multiplicador.

Golpear Caramelo Endurecido normalmente rompe la racha y resta `max(1, resistencia máxima × 0,10)`. `first_candy_free` evita el consumo del primer caramelo endurecido del día, **pero rompe la racha**. `candy_break_chance` permite destruirlo sin consumo ni ruptura de racha; el impacto sigue contando para los logros de obstáculos/día limpio. Racha se reinicia entre días, excepto con Racha Eterna. No hay un máximo de racha de 50.

### Desbloqueos y herramientas

Recetas y herramientas se compran **en cadena**: requiere la anterior, ordenada por `unlock_order`, y suficiente saldo; `unlock_order` no es un requisito de día. Desbloquear recetas no equipa un producto: amplía el conjunto aleatorio del lanzador. Comprar herramienta la equipa; las ya compradas pueden equiparse sin coste.

La secuencia real de herramientas está en `data/tools/<ID>.tres`. IDs canónicos nuevos, con compatibilidad de guardados; orden, precios, potencia y condiciones de logros conservados:

| Orden | Nombre oficial | ID canónico | Potencia base |
|---:|---|---|---:|
| 1 | Puños | `tool_fists` | 5 |
| 2 | Cuchillo de Confitero | `tool_confectioner_knife` | 10 |
| 3 | Hachuela de Confitero | `tool_confectioner_hatchet` | 15 |
| 4 | Martillo Gummy | `tool_gummy_hammer` | 20 |
| 5 | Mazo de Azúcar | `tool_sugar_mallet` | 25 |
| 6 | Hacha Trituradora | `tool_shredder_axe` | 35 |
| 7 | Triturador de Caramelo | `tool_candy_crusher` | 50 |
| 8 | Martillo Hidráulico | `tool_hydraulic_hammer` | 70 |
| 9 | Gummy Crusher | `tool_gummy_crusher` | 95 |
| 10 | Crazy Hammer | `tool_crazy_hammer` | 130 |

Las herramientas de la colección usan las diez ilustraciones proporcionadas por
el usuario (`Armas/A1–A10.jpeg`), procesadas como PNG por ID canónico. El atlas
vectorial y los emojis de Resources se conservan únicamente como fallback.
Los logros se presentan con nombre y estado textual, y el toast usa el símbolo
compartido de trofeo. El comodín Puño Firme es independiente de la herramienta Puños.

## F. Diccionario oficial

| Concepto mecánico | Nombre visible oficial | Nombre interno relevante | Notas |
|---|---|---|---|
| Objetivo interactivo antes de romperse | Cubo de gelatina / Cubo Gummy Clásico | `GummyBlock`, `recipe_data`, grupo `gummy_blocks` | Label del mundo del modelo provisional: Cubo Gummy Clásico. Catálogo de cinco variantes en §E. |
| Producto de un cubo roto | Gomita | `register_gummy_produced`, `gummies_produced` | Una producción por destrucción; no por cada golpe. |
| Compra de producto desbloqueado | Receta | `run_unlocked_recipes`, `unlock_recipe_this_run` | Disponible solo en el negocio; descubrimiento permanente separado. |
| Daño por impacto | Potencia | `damage`, `get_final_damage()` | Potencia de herramienta y final tienen fuentes distintas. |
| Vida máxima/restante del cubo | Dureza | `max_hp`, `current_hp`, `block_hardness` | Dureza de cubos en Datos es **un modificador ×**, no HP absoluto. |
| Recurso del jugador para golpear | Resistencia | `energy_max`, `current_energy`, `energy_cost` | Distinto de dureza; coste por golpe. |
| Multiplicador de crítico | Potencia crítica | `critical_damage_multiplier` | ×1,5 fijo actualmente. |
| Frecuencia de aparición | Ritmo / cubos/s | `launch_rate`, `launch_speed` | No es gomitas/s completadas ni velocidad de vuelo. |
| Pago base aleatorio del producto | Recompensa mínima/máxima | `min_reward`, `max_reward`, `reward_min/max` | Rangos $ en recetas; factores × en Datos. |
| Factor de dinero ganado | Ganancias | `money`, `get_final_money_multiplier()` | No confundir con el saldo gastable. |
| Saldo temporal | Dinero ($) | `run_money` | Se pierde al empezar negocio nuevo. |
| Umbral diario / pago final | Meta / Impuesto | `order_target` | Mismo importe, dos funciones en el flujo. Cuota es sinónimo en créditos. |
| Categoría de producto | Tier de receta | `unlock_order` | 20 categorías; no son 20 días ni niveles de mejora. |
| Partida / ronda | Negocio / Día | `run_*`, `current_order` | `order`/pedido es histórico; no hay sistema de pedidos interactivo. |
| Cadena de productos sin golpear caramelo endurecido | Racha | `current_streak` | Cuenta gomitas producidas. |
| Factor de cadena | Multiplicador de racha | `get_streak_multiplier`, `streak_bonus` | Factor de ganancias adicional. |
| Carta de efecto temporal | Comodín | `CardDatabase`, `active_cards` | Rarezas: Común, Rara, Épica, Legendaria, Mítico. |
| Compras repetibles temporales | Mejoras | `run_upgrade_levels` | Se reinician por negocio; niveles infinitos. |
| Mejoras permanentes | Prestigio | `prestige_levels` | No requiere un botón de reset/prestigiar. |
| Moneda permanente | Reputación (⭐, Rep.) | `prestige_points` | Se gana por día completado. |
| Dinero por encima de la meta | Bonus | `daily_goal_reached`, `get_order_bonus()` | No es otra moneda ni una nueva tirada aleatoria. |
| Premio especial | Jackpot | `jackpot`, `is_jackpot` | Gran Venta es un nombre de logro compatible. |
| Variante especial | Gomita dorada | `is_golden`, `golden_gummy_chance` | Cubo dorado anuncia la gomita dorada. |
| Obstáculo activo | Caramelo Endurecido | `Obstacle`, `candies_hit` | Sin recompensa; excepciones por comodines. |
| Resultado de romper el obstáculo | Caramelo Endurecido Roto | `break_candy`, `candy_break_chance` | Feedback y eliminación; modelo roto pendiente. |

## G. Las 20 recetas

`display_name` guarda los nombres oficiales completos. Las tarjetas usan veinte ilustraciones2D del usuario (`Recetas/G1–G20.jpeg`); el gameplay usa los veinte GLB definitivos de `gummies/gummy_01_bear.glb` a `gummy_20_bear_crown.glb`, con el acabado existente por tier. Premium identifica un tier existente: no añade moneda, mecánica ni compra especial. La variación visual de color no cambia identidad/ID. Los nombres de materiales describen acabados, no nombres de producto.

Cada ID corresponde a **`data/recipes/<ID>.tres`**, indexado en `data/catalog.tres`. Valores **base**, sin comodines, ganancias, Jackpot ni racha:

| Tier | Receta / gomita | ID canónico | Precio $ | Dureza base | Recompensa base $ | Acabado provisional en `assets/crazy_gummy/materials/` |
|---:|---|---|---:|---:|---|---|
| 1 | Osito Gummy Clásico | `bear_classic` | 0 | 20 | 0,1–1 | `gummy/01_ruby.tres` |
| 2 | Aro Gummy | `ring` | 75 | 38 | 1–2 | `gummy/02_honey.tres` |
| 3 | Aro Gummy Premium | `ring_premium` | 113 | 72 | 2–4 | `gummy/03_coral_satin.tres` |
| 4 | Gusano Gummy | `worm` | 169 | 137 | 4–8 | `gummy/04_dark_glaze.tres` |
| 5 | Gusano Gummy Premium | `worm_premium` | 253 | 261 | 8–16 | `sugar/05_sugar_coating.tres` |
| 6 | Botella Gummy | `bottle` | 380 | 495 | 16–32 | `gummy/06_green_glass.tres` |
| 7 | Botella Gummy Premium | `bottle_premium` | 570 | 941 | 32–64 | `sugar/07_mint_frost.tres` |
| 8 | Corazón Gummy | `heart` | 854 | 1788 | 64–128 | `gummy/08_jade_ribbons.tres` |
| 9 | Corazón Gummy Premium | `heart_premium` | 1281 | 3397 | 128–256 | `gummy/09_sunset_gradient.tres` |
| 10 | Pez Gummy | `fish` | 1922 | 6454 | 256–512 | `sugar/10_sour_sugar.tres` |
| 11 | Pez Gummy Premium | `fish_premium` | 2883 | 12262 | 512–1024 | `gummy/11_bicolor_layers.tres` |
| 12 | Cocodrilo Gummy | `crocodile` | 4325 | 23298 | 1024–2048 | `gummy/12_aqua_crystal.tres` |
| 13 | Cocodrilo Gummy Premium | `crocodile_premium` | 6487 | 44266 | 2048–4096 | `sugar/13_amber_frost.tres` |
| 14 | Tiburón Gummy | `shark` | 9731 | 84106 | 4096–8192 | `gummy/14_tropical_marble.tres` |
| 15 | Tiburón Gummy Premium | `shark_premium` | 14596 | 159801 | 8192–16384 | `gummy/15_pearl.tres` |
| 16 | Dragón Gummy | `dragon` | 21895 | 303623 | 16384–32768 | `gummy/16_emerald_depth.tres` |
| 17 | Dragón Gummy Premium | `dragon_premium` | 32842 | 576883 | 32768–65536 | `sugar/17_amethyst_sugar.tres` |
| 18 | Unicornio Gummy | `unicorn` | 49263 | 1096077 | 65536–131072 | `gummy/18_cotton_candy.tres` |
| 19 | Unicornio Gummy Premium | `unicorn_premium` | 73895 | 2082547 | 131072–262144 | `gummy/19_amber_veins.tres` |
| 20 | Osito Gummy Corona | `bear_crown` | 110842 | 3956839 | 262144–524288 | `sugar/20_cosmic_sparkle.tres` |

La dorada no es un tier 21: usa la misma receta con `gold/metallic_gold.tres`. Los precios de recetas/herramientas se modifican y redondean a int en `StatsManager.get_recipe_price/get_tool_price`.

## H. Comodines: catálogo actual

**108**, distribución **63 Común / 29 Rara / 9 Épica / 5 Legendaria / 2 Mítico**. Se sortean 3 distintos uniformemente por elección, sin pesos; pueden repetirse entre días. Se elige 1, se acumula el efecto y se registra su descubrimiento. Duración: negocio actual; se reinician en `reset_run_stats()` al empezar otro.

Referencia común **CD = `scripts/models/CardDatabase.gd::_build_cards()`**; el orden dentro de cada rareza es el de esta tabla. La columna técnica identifica `effect_type`; el consumidor es `StatsManager._apply_card_effect()` y sus getters. Los iconos de datos siguen siendo 🃏 como fallback; el arte UI compartido activo es `assets/crazy_gummy/ui/cards/front.svg` / `back.svg`.

**Los porcentajes de probabilidad son puntos porcentuales (p.p.)**, no incrementos relativos. Los bonos de cartas al mismo acumulador se **suman**, no se multiplican entre sí. Los efectos porcentuales de potencia, resistencia, ganancias, ritmo, recompensa y descuentos suman al factor inicial 1. Los bonus de Jackpot/racha suman al valor correspondiente.

| Nombre | Rareza | Efecto | Stat afectada | Referencia técnica CD |
|---|---|---|---|---|
| Impacto Ligero | Común | +3% | Potencia | `damage` |
| Impacto de Acero | Común | +5% | Potencia | `damage` |
| Puño Firme | Común | +7% | Potencia | `damage` |
| Pulso | Común | +4% | Potencia | `damage` |
| Impacto Preciso | Común | +6% | Potencia | `damage` |
| Golpe Intenso | Común | +5,5% | Potencia | `damage` |
| Buen Aguante | Común | +3% | Resistencia máxima | `energy_max` |
| Piernas Firmes | Común | +4% | Resistencia máxima | `energy_max` |
| Segundo Aliento | Común | +5% | Resistencia máxima | `energy_max` |
| Vigor Rápido | Común | +6% | Resistencia máxima | `energy_max` |
| Refuerzo | Común | +3,5% | Resistencia máxima | `energy_max` |
| Resistencia Extra | Común | +5,5% | Resistencia máxima | `energy_max` |
| Dulce Seguro | Común | +3% | Recompensa mínima | `reward_min` |
| Gomita Fresca | Común | +4% | Recompensa mínima | `reward_min` |
| Buen Reparto | Común | +5% | Recompensa mínima | `reward_min` |
| Dulce Ligero | Común | +3,5% | Recompensa mínima | `reward_min` |
| Receta Fiable | Común | +5,5% | Recompensa mínima | `reward_min` |
| Gomita Valiosa | Común | +3% | Recompensa máxima | `reward_max` |
| Gelatina Selecta | Común | +4% | Recompensa máxima | `reward_max` |
| Dulce Premio | Común | +5% | Recompensa máxima | `reward_max` |
| Dulce Pleno | Común | +3,5% | Recompensa máxima | `reward_max` |
| Dulce Sorpresa | Común | +5,5% | Recompensa máxima | `reward_max` |
| Pequeña Fortuna | Común | +0,3 p.p. | Prob. Jackpot | `jackpot` |
| Buena Estrella | Común | +0,25 p.p. | Prob. Jackpot | `jackpot` |
| Premio Mayor | Común | +0,1× | Premio Jackpot | `jackpot_multiplier` |
| Buen Negocio | Común | +3% | Ganancias | `money` |
| Monedero | Común | +4% | Ganancias | `money` |
| Bolsa Rellena | Común | +5% | Ganancias | `money` |
| Bolsa Doblada | Común | +3,5% | Ganancias | `money` |
| Mercado Furioso | Común | +5,5% | Ganancias | `money` |
| Riqueza | Común | +6% | Ganancias | `money` |
| Punto Preciso | Común | +1 p.p. | Prob. crítico | `crit_chance` |
| Foco | Común | +2 p.p. | Prob. crítico | `crit_chance` |
| Filigrana | Común | +3 p.p. | Prob. crítico | `crit_chance` |
| Golpe Firme | Común | +1,5 p.p. | Prob. crítico | `crit_chance` |
| Mano Certera | Común | +1,2 p.p. | Prob. crítico | `crit_chance` |
| Puntería | Común | +2,5 p.p. | Prob. crítico | `crit_chance` |
| Ritmo Constante | Común | +3% | Ritmo | `launch_rate` |
| Viento Leve | Común | +4% | Ritmo | `launch_rate` |
| Rayo | Común | +5% | Ritmo | `launch_rate` |
| Giro Veloz | Común | +3,5% | Ritmo | `launch_rate` |
| Tormenta Ligera | Común | +5,5% | Ritmo | `launch_rate` |
| Gelatina al Vuelo | Común | +2,5% | Ritmo | `launch_rate` |
| Cubo Delicado | Común | −3% | Dureza | `block_hardness` |
| Cubo Frágil | Común | −4% | Dureza | `block_hardness` |
| Herramientas Baratas | Común | −3% | Precio herramientas | `tool_price` |
| Rebaja | Común | −4% | Precio herramientas | `tool_price` |
| Compra Mayorista | Común | −5% | Precio herramientas | `tool_price` |
| Recetas Baratas | Común | −3% | Precio recetas | `recipe_price` |
| Oferta | Común | −4% | Precio recetas | `recipe_price` |
| Venta al Por Mayor | Común | −5% | Precio recetas | `recipe_price` |
| Mejoras Baratas | Común | −3% | Precio mejoras | `upgrade_price` |
| Cambio Justo | Común | −4% | Precio mejoras | `upgrade_price` |
| Ahorro Mayor | Común | −5% | Precio mejoras | `upgrade_price` |
| Buen Progreso | Común | −3% | Meta diaria | `order_target` |
| Día Corto | Común | −4% | Meta diaria, no duración | `order_target` |
| Día Bueno | Común | −5% | Meta diaria | `order_target` |
| Golpes Ligeros | Común | −4% | Coste por golpe | `energy_cost` |
| Mano Suave | Común | −6% | Coste por golpe | `energy_cost` |
| Brillo Dorado | Común | +0,05 p.p. | Prob. dorada | `golden_gummy_chance` |
| Toque Brillante | Común | +0,1 p.p. | Prob. dorada | `golden_gummy_chance` |
| Impacto Experto | Común | +6,5% | Potencia | `damage` |
| Cadena de Gomitas | Común | +0,1× | Multiplicador racha | `streak_bonus` |
| Impacto Superior | Rara | +9% | Potencia | `damage` |
| Impacto Devastador | Rara | +12% | Potencia | `damage` |
| Reserva Extra | Rara | +9% | Resistencia máxima | `energy_max` |
| Reserva Titánica | Rara | +12% | Resistencia máxima | `energy_max` |
| Receta Rica | Rara | +9% | Recompensa mínima | `reward_min` |
| Receta Generosa | Rara | +12% | Recompensa mínima | `reward_min` |
| Gomita Selecta | Rara | +9% | Recompensa máxima | `reward_max` |
| Gomita Exuberante | Rara | +12% | Recompensa máxima | `reward_max` |
| Fortuna Creciente | Rara | +0,6 p.p. | Prob. Jackpot | `jackpot` |
| Fortuna Dorada | Rara | +1 p.p. | Prob. Jackpot | `jackpot` |
| Jackpot Mejorado | Rara | +0,3× | Premio Jackpot | `jackpot_multiplier` |
| Negocio Próspero | Rara | +9% | Ganancias | `money` |
| Mercado Dorado | Rara | +12% | Ganancias | `money` |
| Golpe Certero | Rara | +3,5 p.p. | Prob. crítico | `crit_chance` |
| Golpe Vibrante | Rara | +4,5 p.p. | Prob. crítico | `crit_chance` |
| Ritmo Fuerte | Rara | +9% | Ritmo | `launch_rate` |
| Tormenta de Cubos | Rara | +12% | Ritmo | `launch_rate` |
| Cubo Frágil II | Rara | −7% | Dureza | `block_hardness` |
| Gelatina Blanda | Rara | −10% | Dureza | `block_hardness` |
| Toque Dorado | Rara | +0,2 p.p. | Prob. dorada | `golden_gummy_chance` |
| Gelatina Dorada | Rara | +0,3 p.p. | Prob. dorada | `golden_gummy_chance` |
| Golpe Eficiente | Rara | −12% | Coste por golpe | `energy_cost` |
| Día Favorable | Rara | −8% | Meta diaria | `order_target` |
| Comerciante | Rara | −6% en las tres tiendas | Precios herramientas/recetas/mejoras | `all_prices` |
| Buen Utillaje | Rara | −8% | Precio herramientas | `tool_price` |
| Cesta de Ofertas | Rara | −8% | Precio recetas | `recipe_price` |
| Tecnología de Punta | Rara | −8% | Precio mejoras | `upgrade_price` |
| Ritmo de Campeón | Rara | +0,2× | Multiplicador racha | `streak_bonus` |
| Pie Firme | Rara | Primer caramelo endurecido del día no consume resistencia | Protección de resistencia, no racha | `first_candy_free` |
| Impacto Supremo | Épica | +18% | Potencia | `damage` |
| Fortuna Suprema | Épica | +1,5 p.p. | Prob. Jackpot | `jackpot` |
| Golpe Perfecto | Épica | +8 p.p. | Prob. crítico | `crit_chance` |
| Dulce Diluvio | Épica | +18% | Recompensa máxima | `reward_max` |
| Coloso | Épica | +18% | Resistencia máxima | `energy_max` |
| Meteoro | Épica | +18% | Ritmo | `launch_rate` |
| Leyenda Dorada | Épica | +0,6 p.p. | Prob. dorada | `golden_gummy_chance` |
| Furia de la Racha | Épica | +0,5× | Multiplicador racha | `streak_bonus` |
| Rompecaramelos | Épica | +1 p.p. | Prob. romper caramelo endurecido | `candy_break_chance` |
| Impacto Colosal | Legendaria | +28% | Potencia | `damage` |
| Jackpot Legendario | Legendaria | +1× | Premio Jackpot | `jackpot_multiplier` |
| Tormenta Perfecta | Legendaria | +28% | Ritmo | `launch_rate` |
| Racha Infinita | Legendaria | +1× | Multiplicador racha | `streak_bonus` |
| Demoledor | Legendaria | +3 p.p. | Prob. romper caramelo endurecido | `candy_break_chance` |
| Divinidad | Mítico | +12 p.p. | Prob. crítico | `crit_chance` |
| Racha Eterna | Mítico | Conserva conteo entre días | Continuidad racha, no inmunidad a obstáculos | `streak_keep` |

`_card()` acepta `card_id`: los IDs activos usan la identidad actual (ej. `card_cubo_frágil`, `card_impacto_colosal`). Las equivalencias anteriores están aisladas en `SaveMigration.CARD_IDS`. Las cartas sin ID explícito lo generan desde el título: si se cambia su título en el futuro, fijar su **ID canónico actual**, sin reintroducir aliases en el catálogo. La galería resuelve por ID desde el catálogo actual.

Hay soporte interno para `prestige` y `multi`, pero **ninguna carta actual usa esos efectos**. Por eso la reputación diaria actual es 1, aunque el código permite bonus si un futuro catálogo lo introdujera. No prometerlos en UI.

## I. Mejoras temporales

Definidas en `data/run_upgrades/<ID>.tres`, `RunUpgradeData.gd`; compras en `RunUpgradeModal`, fórmulas en `StatsManager`. Todas empiezan en nivel 0, sin límite de niveles; precio **$5 × 1,5^nivel × factor de precio de mejoras**, con precisión interna de 0,01.

| Nombre | ID | Efecto real por compra |
|---|---|---|
| Potencia | `damage` | Siguiente = actual ×1,05; bajo 10, mínimo de incremento +1. Se conserva precisión, sin redondear la stat. |
| Resistencia | `energy_max` | ×1,05 resistencia máxima. Base 100. |
| Golpe de Suerte | `luck` | +0,1 p.p. de Jackpot. |
| Negociación | `money` | ×1,05 ganancias. |
| Ritmo | `launch_rate` | ×1,05 cubos/s; no cambia velocidad balística ni frecuencia de caramelo endurecido. |

ShopCard muestra el valor final actual y el incremento real. Los textos de efecto se construyen desde `balance`, no solo desde `desc` del Resource.

## J. Prestigio

Reputación se acredita **al completar un día** en `GameManager._on_day_completed()`: `1 + StatsManager.get_prestige_per_day_bonus()`. Se guarda inmediatamente; el resumen de derrota solo la informa. No hay una acción de prestigio que reinicie voluntariamente todo el progreso.

`data/prestige/<ID>.tres` + `PrestigeUpgradeData.gd`; compras en `StatsManager.buy_prestige_upgrade()`, UI en `PrestigeShopModal`. Niveles permanentes infinitos, precio base × **1,5^nivel**, redondeado a 0,01.

| Nombre | ID | Coste base ⭐ | Efecto por nivel |
|---|---|---:|---|
| Maestría | `experience` | 3 | ×1,10 potencia inicial de los Puños (base 5). |
| Experiencia | `expert_hand` | 3 | ×1,10 resistencia máxima (base 100). |
| Buen Proveedor | `good_provider` | 3 | ×1,10 ganancias (base ×1). |
| Buena Fortuna | `good_fortune` | 5 | +1 p.p. Jackpot (base 1%). |
| Ritmo Veloz | `launch_speed` | 5 | ×1,10 ritmo (base 1 cubo/s). |

`get_permanent_stat()` consulta base y niveles guardados, nunca el arma del negocio/comodines/mejoras temporales. Mantener esa separación al reutilizar componentes.

## K. Logros

Fuente: **`scripts/autoload/AchievementManager.gd::DEFINITIONS`**, 121 entradas (101 counters, 20 flags). Cada definición incluye `id`, `name`, `desc`, `icon`, `cat`, `kind` y `metric/target` o `flag`. No hay recompensas económicas por desbloquearlos: progreso persistente y notificación.

- Emisores: `GameManager` (producción/días/racha/equipamiento), `StatsManager` (compras/comodines), `SwipeController` (críticos/obstáculos/multirruptura), `BlockSpawner` (dos doradas vivas).
- Guardado: `achievements.unlocked`, `metrics`, `flags`; debounce 0,5 s y flush al cerrar/pausar app. Evaluación retroactiva silenciosa al iniciar.
- `produced_<recipe_id>` cuenta gomitas del producto correspondiente de §G. Los IDs, claves de métricas y flags vinculados a la temática anterior se migraron; sus umbrales y condiciones se mantuvieron.
- `upgrades_bought_run` es **acumulado histórico**, pese a su nombre: Comprador Compulsivo/Megacomprador dicen ahora 5/20 compras **en total**.
- `cards_rare/epic/legendary` cuentan elecciones, incluso repetidas, no solo descubrimientos nuevos. Los textos dicen **Elige**. `cards_discovered` sí cuenta IDs únicos.
- Coleccionista de Cartas requiere **100**, aunque hay 108: el texto dice 100, no toda la baraja. No cambiar condición para corregir el texto.
- Procesado Extremo salta al **equipar** Crazy Hammer (`tool_crazy_hammer`); Purista consulta Puños al terminar el día, no exclusividad toda la ronda. Herramienta Fiel incluye cambios en el mercado desde el día anterior. Los logros comprueban los IDs canónicos de §E.
- Rápido y Furioso comprueba **cruzar la meta** con <=5 s, no terminar la ronda; Estado Mental es asestar crítico sin golpear antes caramelo endurecido; Racha Campeona solo requiere racha 15, no seguimiento de mirada.
- `produced_ring` cuenta Aro Gummy normal o dorado. El logro `dulce_aro` no exige variante dorada. Dulce Dúo exige Osito Gummy Clásico + Gusano Gummy Premium y completar ese día.

La UI muestra counters con progreso/barra cuando target >1; flags no tienen progreso gradual. Los IDs anteriores solo se aceptan al importar guardados.

## L. Estadísticas visibles: fuente, significado y formato

En esta tabla **SM = StatsManager**, **GM = GameManager**. **Regla global de presentación: todo valor numérico visible con máximo 1 decimal, sin excepciones.** `UiTheme.format_stat` siempre usa un decimal; `format_money` un decimal y sufijos K/M/B/T/Qa/Qi/Sx/Sp. Los formatos son solo visuales, nunca entradas de cálculo (la precisión interna se conserva intacta).

| Nombre oficial | Fuente y significado | Formato / ubicación |
|---|---|---|
| Potencia | `SM.get_final_damage`: herramienta × factor mercado × cartas ×1,1^Maestría | 1 decimal en mercado; base en reverso de herramienta. Retirada del HUD junto al nombre de herramienta. Prestigio: `get_permanent_stat(experience)`. |
| Resistencia | `GM.current_energy`, máximo `SM.get_final_max_energy`: 100 ×1,05^mercado × cartas ×1,1^Experiencia | HUD actual/máximo con ceil enteros; máximo 1 decimal en tiendas. |
| Coste por golpe | `SM.get_final_energy_cost`: 1 × resistance_cost_multiplier × cartas | 1 decimal en Datos; es resistencia consumida. |
| Prob. de crítico | `SM.get_final_critical_chance`: suma de cartas | 1 decimal %, Datos. |
| Potencia crítica | `SM.get_final_critical_multiplier`: balance fijo 1,5 | x1,5, Datos. |
| Dureza de cubos | `SM.get_block_hardness_multiplier`: factor de cartas, base ×1 | 1 decimal × en Datos; HP absoluto en reverso de receta, barra restante sobre cubo. |
| Recompensa mínima | `SM.get_recipe_min_reward_multiplier`: cartas × reward_rebalance_multiplier | 1 decimal × en Datos; mínimo base $ en reverso de receta. |
| Recompensa máxima | `SM.get_recipe_max_reward_multiplier`: cartas × reward_rebalance_multiplier | 1 decimal × en Datos; máximo base $ en reverso de receta. |
| Ganancias | `SM.get_final_money_multiplier`: 1,05^mercado × cartas ×1,1^Buen Proveedor | × y 1 decimal, Datos/mercado/prestigio. No incluye racha. |
| Prob. de Jackpot | `SM.get_final_jackpot_bonus`: 0,01 + nivel luck ×0,001 + cartas + Buena Fortuna ×0,01 | % 1 decimal en todas las superficies (Datos, mercado, prestigio, tarjetas). |
| Premio Jackpot | `SM.get_final_jackpot_multiplier`: 2 + cartas | 1 decimal ×, Datos. Dorada aplica ×2 extra fuera de este getter. |
| Prob. gomita dorada | `SM.get_golden_gummy_chance`: base 0 + cartas | 1 decimal %, Datos. Puede redondear a 0,0% un bonus muy pequeño. |
| Prob. romper caramelo | `SM.get_candy_break_chance`: suma cartas | 1 decimal %, Datos. |
| Ritmo | `SM.get_final_launch_rate`: 1 ×1,05^mercado × cartas ×1,1^Ritmo Veloz | 1 decimal cubos/s, HUD/mercado/prestigio. |
| Racha | `GM.current_streak` | Entero en anillo; progress ratio entre hitos. |
| Multiplicador de racha | `GM.get_streak_multiplier`: hito + cartas | x y 1 decimal, HUD/anuncio volante. |
| Dinero / meta | `GM.run_money`, `GM.order_target`; barra usa `order_progress` | $ + `format_money`, HUD/mercado. |
| Bonus | `GM.get_order_bonus`: excedente del día | +$ + `format_money`, HUD tras meta cumplida. |
| Tiempo | `GM.round_time_left`; máximo 60 s | ceil segundos y barra, HUD. |
| Día / negocio | `GM.current_order` / `save_data.days_started` | Enteros, HUD, pausa y resumen. `days_started` aumenta al iniciar negocio, no cada día. |
| Conseguido / impuesto / ganancia / próxima meta | `order_progress`, `order_target`, diferencia, `get_order_target_for(actual+1)` | $ + sufijos, resumen de elección. |
| Reputación | `SaveManager.get_prestige_points`, `prestige_earned_this_run` | ⭐/Rep. + `format_money`, tienda permanente y resultados. |
| Días completados / ganancias generadas | `run_ended` summary `completed_orders` / `money_generated` | Entero / $ + sufijos en resultados; dinero generado no es saldo final. |
| Gomitas producidas / Jackpots / gomitas doradas | summary `gummies_produced`, `jackpots`, `golden_gummies` | Enteros en resultados. Progreso usa `total_gummies_produced` formateado con sufijos. |
| Mejor día / negocios iniciados / comodines descubiertos | save `best_clients_in_day`, `days_started`, `get_discovered_cards().size()` | Día frente a100 y barra; contador; cantidad/108, Progreso. |
| Nivel / precio de mejora | `run_upgrade_levels` o `prestige_levels`; coste geométrico | Entero / $ o ⭐ con sufijos, ShopCard. |
| Logros completados / progreso | `get_unlocked_ids`, `get_progress`, `get_progress_text` | Conteo y barra o COMPLETADO/PENDIENTE; cantidades grandes con sufijos. |
| Rarezas de comodines | conteo de entradas de galería, incluidas repeticiones activas | RichText con colores por rareza, CardsModal. |

El reverso de recetas muestra **Dureza** y el **rango monetario de recompensa en una línea ($mínimo – $máximo)**, además del botón de acción: son datos base, no los ajustes runtime. Se mantiene el rango compacto y el rol Body para nombres completos. El frente queda libre de texto (solo arte + estado). Los descuentos aparecen en los botones; los factores de precio/meta y protecciones de cartas no tienen tarjetas individuales en Datos, se consultan en comodines/precios reales.

## M. Sistema visual actual

### Theme, fuentes y estilos

- **Único Theme**: `themes/ui01_theme.tres`, un `TypographyTheme` con script `scripts/ui/TypographyTheme.gd`. `UiTheme` lo instala también en la raíz; escenas lo referencian explícitamente.
- Roles `TypographyStyle`: **Title 30 px SkitserCartoon** (`assets/fonts/display-ttf/SkitserCartoon.ttf`), **Subtitle 22 px Roboto peso600**, **Body 18 px Roboto-Regular** (`assets/fonts/roboto/Roboto-Regular.ttf`). Fallback `assets/fonts/NotoEmoji.ttf`. IconLabel 32 px. Colores aqua/perla; tamaños y fuentes conservados.
- Variantes de títulos, subtítulos, cuerpo, valores, cartas y tooltips se regeneran desde esos tres roles; no insertar fuentes/tamaños independientes en cada pantalla.
- `GummyDesignSystem.gd` regenera acabados sobre el mismo Theme desde `TypographyTheme.refresh_typography()`, tanto en editor como en runtime. No añade otro Theme ni autoload. `StyleBoxFlat`: paneles/cards/modales, pestañas, barras, scrollbars y pistas de sliders. `StyleBoxTexture`: botones gelatinosos con 9-slice compartido. PrimaryButton aqua, DangerButton burdeos, PremiumButton oro.
- ToastPanel, CompactCard, TooltipPanel y HardnessBar reemplazan los overrides de presentación anteriores. CollectionCard duplica solo el panel para el estado de disponibilidad; CardFlipWidget duplica el marco para la rareza. GummySurface añade reflejos estáticos sin input ni proceso por frame.
- **StyleBoxTexture activo:** `ui/buttons/gel_surface.svg`, 96×48, márgenes 26/20/26/20. No usa NinePatchRect; los PNG de `assets/ui/panels/` siguen sin referencias activas.
- `UiTheme` centraliza Motion (hover 101%, presión 98,5%×96% en 60 ms, retorno 160 ms, fade/escala de modales, pulsos de labels), confeti y formato. Registro seguro de botones dinámicos mediante WeakRef diferido después de node_added. CardFlipWidget/StreakRing/GummyVisual conservan sus animaciones propias. El toast vuelve a escala 1 tras el overshoot.

### Resolución, contenedores y entrada

- Base **720×1280**, `canvas_items`, `keep_width`, orientación portrait. El alto puede crecer en dispositivos alargados; no asumir un viewport fijo de 1280.
- Roots de UI full rect; paneles suelen ocupar ancho entre anchors0,05–0,95 (otras escenas usan0,04/0,06/0,08). VBox/HBox/ScrollContainer distribuyen contenido; `ContentSizedModal` centra y limita altura.
- `SafeAreaLayout` convierte safe area Android/iOS a coordenadas del viewport y suma márgenes sobre offsets originales, sin acumularlos. Los targets se declaran en `Main.tscn`; añadir panel nuevo requiere revisarlos.
- Botones del menú: Jugar/navegación mínimo88 px, Ajustes52; cierres56×56; acciones48–60. Los tamaños mínimos y estados disabled/focus son funcionales.
- Decoración y espejo 3D ignoran input. Los overlays lo interceptan; el gameplay usa `_unhandled_input`.
- CardFlipWidget usa aspecto11:16 (352×512), ancho base180, máximo220 en elección, miniatura144, marco2 y padding6; elegir56 de alto separado10. Reverso en ScrollContainer conserva el marco, no aumenta su tamaño por texto largo.
- El arte activo ahora es SVG 352×512 con la misma proporción; nombre de rareza
  y uno a cinco rombos se superponen como texto Godot. El HUD muestra Saldo/Meta
  explícitos, Bonus con tinta oscura sobre oro y racha coral. El HUD inferior
  contiene solo Datos/Pausa, sin bloque de herramienta/potencia.
- La regresión UI verifica **720×960, 720×1280, 720×1600 y 960×1280**, texto, reversos, modales, scroll, safe areas y tipografía.

### Arte de gameplay y audio

`RecipeVisualLibrary` referencia seis cubos, veinte gomitas y dos obstáculos definitivos en `assets/crazy_gummy/`. `GummyVisual` instancia la pareja por ID canónico. Los wrappers cube.tscn/bear.tscn también apuntan ahora al tier1 definitivo; cubo/osito provisionales quedan sin uso activo. Materiales conservados:14 lisos/combinados +6 azucarados, shader `gummy/gummy.gdshader`; oro en `gold/gold.gdshader`. Ocho colores por instancia, RNG visual independiente, cubo/gomita comparten acabado. Opacidad0,80 o0,90 azucaradas; oro opaco.

`SoundManager` produce SFX por código, sin frases ni nombres temáticos audibles. `play_stroke()` reproduce el sonido del trazo. Intenta cargar `assets/music/main_loop.ogg` y `game_loop.ogg`; si faltan queda en silencio, **no genera música fallback**, aunque algunos comentarios antiguos lo sugieren. Volúmenes persistidos por `SettingsManager`.

## N. Assets heredados y provisionales

| Ruta | Estado | Uso real / trabajo visual pendiente |
|---|---|---|
| `assets/crazy_gummy/icon.png` | Logo activo del menú | Solo MainMenu/CenterVBox/TitleVBox/Logo; independiente del launcher. |
| `assets/crazy_gummy/icon.jpg` | Icono activo de aplicación/launcher | project.godot y launcher principal/foreground de Android; el menú sigue usando el PNG. |
| `assets/crazy_gummy/icon_source.jpg` | Retirado a `Papelera/` | Original histórico de la fase anterior; el launcher actual usa `icon.jpg`. |
| `assets/crazy_gummy/launcher_foreground.svg` | Retirado a `Papelera/` | Sustituido por el PNG; el SVG de icono anterior ya no está en el proyecto. |
| `assets/crazy_gummy/launcher_background.svg` | Compatible, provisional activo | Fondo del icono adaptable Android. |
| `assets/icon_app.png` | Retirado a `Papelera/` | Heredado con texto Crazy Fruit; sin referencia activa. No reutilizarlo en la próxima UI. |
| `android/icons/main_192x192.png`, `adaptive_foreground_432x432.png`, `adaptive_background_432x432.png` | Heredados pendientes, **fuera del preset activo** | Iconos anteriores. Principal/foreground llevan Crazy Fruit incrustado. |
| `assets/ui/backgrounds/logo.png` | Retirado a `Papelera/` | Logo frutal anterior; sustituido en MainMenu por el PNG nuevo del usuario. |
| `assets/ui/backgrounds/menu_bg.png` | Retirado a `Papelera/` | El menú activo usa `assets/crazy_gummy/ui/backgrounds/menu.svg`. |
| `assets/provisional/recipe_sprites/*.png` (20 sprites) y `golden_ring.png` | Respaldo opcional retirado en limpieza de assets | `BlockSpriteFallback.OPTIONAL_SPRITE_DIR` + `OPTIONAL_SPRITE_IDS` conservan el gancho canónico para arte opcional (directorio inexistente). Si falta una textura, no la carga ni calcula su ancho: limpia el sprite previo y oculta el anillo. Nodo Visual en `GummyBlock.tscn` **oculto**; gameplay activo usa cubos3D. CollectionCard resuelve su arte desde CollectionArt, sin depender de estos sprites. |
| `Projectile3D.gd`: cargador histórico de whole/broken y esferas | Retirado | Se sustituyó por referencias explícitas a los modelos definitivos; no genera ni espeja mallas. |
| `GelatinSplash.gd`: `assets/provisional/gelatin_splashes/<id>.png` o `.svg` | Ruta opcional canónica | Fallback2D genera gotas si no existe textura. Presentación gummy activa marca `custom_hit_particles` y usa fragmentos3D. |
| `assets/models/gummy/*` | Retirados a `Papelera/` | Originales de pruebas (cubo/osito GLB + texturas); ya no se referencian desde escenas activas, ni siquiera desde `cube.tscn`/`bear.tscn`. |
| `assets/crazy_gummy/cubes/`, `gummies/`, `Obstaculos/`, `materials/`, `effects/` | Activos |28 GLB definitivos numerados; acabados y efectos existentes conservados. Véase CRAZY_GUMMY_PROJECT_GUIDE.md. |
| `assets/crazy_gummy/backgrounds/translucency_test.png` | Retirado en limpieza de assets | Gameplay activo usa `assets/crazy_gummy/ui/backgrounds/gameplay.svg`. |
| `assets/card/Joker2.png`, `back.png` | Sustituidos y retirados a `Papelera/` | CardFlipWidget usa front.svg/back.svg del kit nuevo; idéntica proporción 11:16. |
| `assets/ui/icons/*.png` | Retirados a `Papelera/` | MainMenu sustituye sus iconos por AtlasTextures de `ui/icons/symbols.svg`. |
| `assets/ui/panels/*.png` | Retirados a `Papelera/` en limpieza de assets | Paneles previos (HUD/card/dark/settings/premium); ningún NinePatch/StyleBoxTexture activo los consume. |
| `assets/crazy_gummy/Armas/A1–A10.jpeg`, `Recetas/G1–G20.jpeg` | Fuentes de arte del usuario, intactas | Orden equivalente a las tablas oficiales de herramientas/recetas. No se cargan en las tarjetas. |
| `assets/crazy_gummy/ui/collection/*.png` | Arte UI activo |30 PNG con lado máximo512; se elimina solo gris exterior. Azul/objeto conservados, transparencia fuera de la placa azul. Referencias explícitas compartidas en CollectionArt.gd. |
| Emojis 🍬, 🧊, herramientas, ⭐/💰 y logros | Sustituido/compatible provisional | Iconos de datos y labels; frutas visibles de recetas/logros/HUD se migraron. Posteriormente sustituibles por iconos definitivos sin cambiar IDs. |

## O. Particularidades y deuda verificable para rediseño

1. **Cierre de negocio corregido:** créditos solo al completar `win_day`; continuar usa `current_order` y mantiene la run abierta. Salir desde créditos o pausa llama `GameManager.end_run()`. `completed_orders_run` guarda el último día completado, incluido el día recién ganado antes de avanzar. El cierre idempotente registra récord/producción una sola vez; completar `win_day` conserva el resultado exitoso frente a derrotas posteriores. Solo una derrota anterior a esa victoria incrementa `runs_bankrupt`.
2. **Progreso usa constantes100** en barra/rótulos, mientras GameManager toma `balance.win_day`. Coinciden ahora. Logro centenario también usa target100. No hacer win_day configurable solo desde UI sin entender estas referencias.
3. **Precisión visual**: regla global de máximo 1 decimal en todo valor mostrado, sin excepciones ni formatos por pantalla (la antigua precisión 2/3 decimal de Jackpot quedó eliminada: `format_jackpot` ya no existe y todo pasa por `UiTheme.format_stat`). Pequeños bonus dorados pueden verse como0,0%. El redondeo es solo de presentación: los cálculos internos conservan su precisión real.
4. **Fuentes y estilo dinámico**: los acabados globales se regeneran sobre Theme; CollectionCard y CardFlipWidget conservan duplicados de StyleBox para estado/rareza. Iconos, filas de logros y labels se generan también en runtime; usar helpers compartidos para futuras pantallas.
5. **Espacio de texto acotado**: Face de CollectionCard recorta; CardFlipWidget conserva proporción y desplaza reverso. `GummyBlock/NameLabel` tiene offsets de ancho160 y no autowrap. Esto exige textos cortos/iconografía adecuada; no hay fallo de clipping de las pantallas en las resoluciones verificadas.
6. **StatCard ignora el parámetro `_value_color` de setup**, y usa el Theme actual. No dar por hecho que un color pasado por el modal se renderiza.
7. **Documentación histórica no es balance actual**: los antiguos informes/especificaciones/guía de assets incluyen nombres, líneas, recomendaciones y porcentajes anteriores. En especial no borrar Roboto: ahora es fuente activa. Los encabezados los marcan como históricos.
8. La prueba existente `test_daily_bonus.gd` pasa38 checks pero el motor informa4 instancias filtradas al salir del test; no aparece en el arranque normal ni en las pruebas de migración. No se modificó el sistema por ese diagnóstico.

## P. Guardado y reglas de seguridad

### Tamaño y nombres visibles de proyectiles

Cubos y caramelos usan la misma base, tomada del clásico: radio lógico de 60 px y diámetro visual de 90 px en el canvas de referencia. Cada lanzamiento elige un factor uniforme entre 0,5× y 1,5×: radio lógico 30–90 px y diámetro visual 45–135 px. `BlockSpawner` expone `projectile_base_radius`, `projectile_size_min` y `projectile_size_max`; su RNG de tamaño es independiente. La escala visual y el área de golpe siguen el tamaño seleccionado, independientemente de la receta. Las dimensiones importadas de cada modelo se normalizan.

Nombres visibles compactos: cubos «Clásico», «Ondulado», «Facetado», «Relieve», «Corona» y variantes «+»; recetas «Osito», «Aro», «Gusano», etc., con «+» para premium y «Osito Corona» para la final. Herramientas básicas: «Cuchillo», «Hachuela», «Martillo», «Mazo» y «Triturador»; las demás conservan sus calificativos distintivos. Los IDs permanecen canónicos.

- Archivo permanente y partida suspendida: **`user://crazy_gummy_save.json`**, esquema **version 3**, escritura temporal + rename. `config/name` permanece Crazy Gummy: el directorio actual de usuario no se cambió. El lector importa versiones anteriores mediante el conversor descrito abajo.
- Claves actuales: `version`, `prestige_points`, `prestige_levels`, `unlocked_tools`, `unlocked_recipes`, `discovered_cards`, `equipped_tool`, `high_score_order`, `total_gummies_produced`, `total_reputation_earned`, `days_started`, `best_clients_in_day`, `achievements.{unlocked,metrics,flags}`. Se fusionan claves conocidas al cargar. Los descubrimientos son históricos, no disponibilidad de la nueva partida.
- `active_run` guarda una instantánea independiente del negocio: día, cuota, saldo, resistencia, reloj, racha, desbloqueos, herramienta, mejoras, comodines y contadores diarios. Guardar y salir desde Pausa o Mercado vuelve al menú sin derrota ni recompensas finales. Continuar restaura la ronda o el Mercado; los objetos físicos en vuelo se regeneran. La selección de carta no ofrece esta salida para evitar saltarse la elección. Una derrota o finalización real invalida `active_run`; Nueva partida pide confirmación antes de reemplazarla. Los saves anteriores siguen siendo compatibles y no ofrecen Continuar hasta guardar una partida.
- Ajustes: **`user://settings.cfg`**, sección `audio` con `master`, `music`, `sfx`; no se borra con Reiniciar progreso. Debounce0,5 s.
- Android: nombre visible Crazy Gummy. La identidad de instalación se conserva por compatibilidad; ver la excepción en la sección de migración.
- **No modificar balance en un trabajo visual**: números de `.tres`, fórmulas, RNG de gameplay, precios, probabilidades, metas, desbloqueo en cadena, resistencia/tiempo, racha y condiciones de logros.
- Conservar los **IDs canónicos** de recetas/herramientas/logros/cartas, acentos y tipos de efectos. Cambios futuros de ID persistente requieren otra migración de esquema, nunca aliases antiguos en la lógica activa. Cambiar un título no debe cambiar su ID actual.
- Conservar grupos `gummy_blocks`/`obstacles`, señales `block_hit`, `block_destroyed`, `gummy_produced_event`, `run_tool_equipped` y keys de summary `gummies_produced`/`golden_gummies` salvo migración completa de sus consumidores.
- Conservar rutas y nombres de nodos `@onready`, catálogo, UID/`ext_resource`, callbacks y targets de safe area. Las escenas actuales usan `BlockSpawner`, `Projectile3DLayer`, `GummiesLabel`, `Recetas` y `Herramientas`. `ToolInfoLabel` se retiró del HUD con sus referencias de script por petición del usuario. Renombrar otros nodos requiere rastrear escenas/scripts/pruebas y strings dinámicos.
- Resources compartidos: duplicar datos runtime/materiales por instancia antes de modificar. Un acabado de tier no debe mutar globalmente desde un cubo; el RNG visual debe permanecer separado del gameplay.
- `StatsManager.invalidate_stat_cache()` es necesario antes de refrescar stats tras cambios de entradas. Mantener separación entre stats permanentes y de partida.
- Comprar debe descontar/aplicar **una sola vez**; preservar guard de selección, botones disabled, captura de IDs/precios actualizados y comportamiento toque vs arrastre.
- Reset permanente debe seguir bajo ConfirmDialog; renuncia también. X del mercado comienza próximo día; no convertirlo en cierre genérico sin considerar el flujo.

## Migración desde Crazy Fruit

La fase interna reemplazó los conceptos anteriores según su función; no fue una sustitución indiscriminada de palabras. Las dependencias incluyen nodos, grupos, señales, strings de `load`/`preload`, resources, tests y serialización. HUD, ShopCard, AchievementManager, SettingsManager, enums genéricos y fórmulas conservaron sus responsabilidades.

| Concepto/ruta anterior | Arquitectura actual |
|---|---|
| `Fruit.gd/.tscn`, clase `Fruit` | `scripts/game/GummyBlock.gd`, `scenes/game/GummyBlock.tscn`: cubo golpeable. |
| `FruitSpawner.gd/.tscn` | `scripts/game/BlockSpawner.gd`, `scenes/game/BlockSpawner.tscn`; nodo BlockSpawner, lista active_blocks. |
| `FruitData`, `FruitDatabase`, `data/fruits/` | `RecipeData`, `RecipeDatabase`, `data/recipes/`; los 20 IDs describen productos, de bear_classic a bear_crown. |
| `KnifeData`, `data/knives/`, IDs weapon_* | `ToolData`, `data/tools/`, IDs tool_* según la tabla de §E. |
| `Fruit3D`, `Fruit3DWorld`, `Fruit3DLayer` | `Projectile3D`, `Projectile3DWorld`, `Projectile3DLayer`: espejo compartido de cubos y obstáculos. Scripts/escenas en game/. |
| `FruitVisual`, `JuiceSplash`, `assets/fruits/` | `BlockSpriteFallback`, `GelatinSplash`; imágenes de respaldo bajo assets/provisional/recipe_sprites/ y ruta opcional gelatin_splashes/. |
| grupo fruits, eventos fruit_*, register_fruit_cut | grupo gummy_blocks, block_hit/block_destroyed, gummy_produced_event, register_gummy_produced. |
| stats fruit_hp/fruit_price/golden_fruit_chance y stone_* | block_hardness/recipe_price/golden_gummy_chance y candy_*; valores y operaciones iguales. |

Los nombres de materiales ligados a productos anteriores se cambiaron por nombres de acabado (coral_satin, dark_glaze, sugar_coating, green_glass, sour_sugar, bicolor_layers, amber_frost), conservando los parámetros del shader. Scripts trasladados conservan sus archivos `.uid`; se actualizaron todas las rutas explícitas del catálogo. Los nodos de mercado y sus consumidores se migraron a Recetas/Herramientas.

### Importación de partidas existentes

**Única frontera de aliases:** `scripts/models/SaveMigration.gd`. Sus mapas `RECIPE_IDS`, `TOOL_IDS`, `CARD_IDS`, `ACHIEVEMENT_IDS`, `SAVE_KEYS`, `METRIC_KEYS` y `FLAG_KEYS` contienen todas las equivalencias necesarias.

1. `SaveManager` da prioridad al archivo nuevo. Si no existe, busca `user://fruit_cutter_save.json`; en escritorio también busca las carpetas hermanas de app **Crazy Fruit** y **Fruit Cutter**. Android/iOS permanecen en el sandbox de la instalación.
2. El conversor copia los datos, traduce claves/IDs/métricas/flags y fija version 2. Ejemplos: strawberry → bear_classic, unlocked_fruits → unlocked_recipes, cut_strawberry → produced_bear_classic, card_fruta_frágil → card_cubo_frágil. También se importan los IDs de la primera fase temática.
3. Se conservan saldos, niveles, récords, cantidades, descubrimientos y condiciones. Aliases mezclados no duplican IDs ni progreso: listas únicas, máximo de métricas equivalentes y OR de flags. Los IDs desconocidos se preservan.
4. Se escribe el archivo nuevo con las claves actuales, **sin borrar ni reescribir el original**. La migración es idempotente; al resetear, el archivo canónico sigue teniendo prioridad y no revive la copia antigua.

La lógica activa nunca consulta aliases. Las únicas excepciones verificables fuera del conversor son **la identidad Android `com.crazyfruit.game`** en `export_presets.cfg` (cambiarla produciría otra instalación/sandbox y perdería continuidad) y los fixtures de compatibilidad. Los patrones de términos prohibidos de las pruebas son entradas de validación, no APIs activas.

### Coincidencias restantes clasificadas

| Categoría solicitada | Estado final |
|---|---|
| 1. Error pendiente | Ninguno detectado en scripts, escenas, recursos, rutas activas y nombres de archivo por `test_internal_names.gd`. |
| 2. Compatibilidad necesaria | SaveMigration, su fixture `test_save_compatibility.gd` e identidad Android conservada. |
| 3. Documentación de migración | Esta sección y los informes/especificaciones marcados históricos; no son instrucciones para reintroducir esos nombres. |
| 4. Arte provisional | Sprites de respaldo y logos/iconos anteriores enumerados en §N; sus rutas técnicas actuales ya usan recetas. |
| 5. Coincidencia no relacionada | Palabras de color (p. ej. Naranja), herramientas actuales como confectioner_knife, términos genéricos como milestone/appearance y los patrones negativos de auditoría. |

## Q. Validación realizada y cómo repetirla

Se comparó contra una captura del **estado local previo a esta fase**, no solo contra HEAD: operaciones de gameplay/economía/interacción/visualización iguales tras normalizar los renombrados; balance y progresión de20 recetas/10 herramientas iguales; 108 efectos/rarezas/valores y 121 condiciones/targets iguales con IDs traducidos. Se comprobaron las referencias estáticas y parámetros de materiales. El formato persistente sí cambió de manera versionada y se verificó con fixtures antiguos, mixtos, recargas y resets.

Pruebas existentes y nueva regresión (sin addons; scripts `SceneTree`):

| Prueba en `tests/` | Comprobaciones | Resultado / alcance |
|---|---:|---|
| `test_shop_stats.gd` | 114 | 0 fallos; fórmulas, precios, precisión y separación permanente/temporal. |
| `test_ui_layout.gd` | 6839 | 0 fallos; cuatro resoluciones, controles, reversos, safe area, scroll, tipografía. También pasó antes de migrar. |
| `test_card_choice.gd` | 15 | 0 fallos; elección única, flujo y widgets/precios reutilizados. |
| `test_touch_interaction.gd` | 35 | 0 fallos; entrada táctil, giro, scroll sobre botones y barras. |
| `test_daily_bonus.gd` | 38 | 0 fallos; fase Bonus y confeti. Diagnóstico de salida indicado en §O. |
| `test_gummy_materials.gd` | 349 | 0 fallos;20 materiales/modelos, color, oro, partículas, datos y obstáculo. |
| `test_gummy_visual.gd` | 73 | 0 fallos; impacto, revelado y compatibilidad con gameplay. |
| `test_settings_reset.gd` | 10 | 0 fallos; reset desde ajustes. |
| `test_typography.gd` | 97 | 0 fallos; roles de Theme. |
| `test_theme_migration.gd` | 2234 | 0 fallos; vocabulario,108 cartas/121 logros/20 recetas, recarga canónica, gameplay, dorada, racha, compras, resultados, reinicio y créditos→101. |
| `test_save_compatibility.gd` | 278 | 0 fallos; importación completa, aliases mixtos, archivo original intacto, idempotencia, carpetas de escritorio anteriores y reset sin resurrección. |
| `test_internal_names.gd` | 15347 | 0 fallos; nombres activos y referencias estáticas, con excepciones de compatibilidad aisladas. |

Ejecutar desde raíz, sustituyendo `godot` por el binario instalado:

```bash
XDG_DATA_HOME=/tmp/opencode/crazy-gummy-check godot --headless --path . --audio-driver Dummy --script tests/test_theme_migration.gd
```

Usar **un XDG_DATA_HOME aislado por prueba**: varios scripts escriben/resetan guardado. No se generó APK ni se hizo prueba física de dispositivo en esta fase; la validación de interacción y layout es automatizada sobre Godot4.7.2, no una aprobación artística final. `git diff --check` pasó.

### Validación del rediseño visual

**Corrección posterior a limpieza de assets:** `BlockSpriteFallback` quedó
bloqueado contra sprites/anillo ausentes y texturas de ancho cero, y sus rutas
se declararon como directorio opcional (`OPTIONAL_SPRITE_DIR`, ver
`CRAZY_GUMMY_PROJECT_GUIDE.md`). Los provisionales `assets/models/gummy/cubo.glb`
y `osito.glb` con sus texturas basecolor quedaron **retirados a `Papelera/`**:
ya no son dependencias de `cube.tscn`/`bear.tscn`, que apuntan a los GLB
definitivos del tier 1. Los cambios del usuario en iconos, fondos y cartas se
conservan. Regresión añadida `test_sprite_fallback.gd`:8 comprobaciones,0
fallos; materiales349, visual73 y Bonus38 pasan con los sprites provisionales
ausentes. Importación y arranque renderizado del proyecto comprobados sin
errores de recursos ni acceso nulo.

Ejecutada con Godot4.7.2, Compatibility y XDG_DATA_HOME independiente por prueba:

| Regresión | Comprobaciones | Resultado |
|---|---:|---|
| UI layout | 7200 headless finales; 7179 en la pasada gráfica anterior | 0 fallos, cuatro resoluciones |
| Touch interaction | 35 | 0 fallos; incluye arrastre de la barra |
| Card choice | 15 | 0 fallos; transición elección→mercado ~5,8–7,1ms en esta máquina |
| Shop stats | 114 | 0 fallos |
| Typography | 97 | 0 fallos |
| Settings/reset | 10 | 0 fallos |
| Daily Bonus | 38 | 0 fallos; conserva diagnóstico previo de4 instancias al salir |
| Theme migration | 2398 | 0 fallos |
| Save compatibility | 278 | 0 fallos |
| Internal names | 16241 | 0 fallos en la pasada de auditoría posterior a documentación inicial |
| Gummy materials / visual | 349 /73 | 0 fallos |

Se ejecutó el Main real con render OpenGL y se inspeccionaron capturas de
720×960, 720×1280, 720×1600 y 960×1280. `test_ui_layout.gd -- --capture`
produce las pantallas, las tres pestañas y reversos/contenido largo.
`tests/capture_ui_review.gd` complementa con **14 estados ×4 resoluciones**:
menú, ajustes, gameplay con siete colores, Bonus con cifras Sx/Sp, toast, pausa,
Datos, Mercado, estados de herramientas, cinco rarezas, Prestigio, Progreso
con cifras Sp, lista completa de121 logros y Créditos.
Artefactos: **56 capturas** `/tmp/opencode/Review_*.png` y capturas de layout en
la misma carpeta. Arranque directo del proyecto con `--quit-after 120` verificado
con render Compatibility; el icono de ventana2048px conserva el aviso previo de
reducción automática del sistema de ventanas.

Durante revisión se corrigieron: grosor/hit area del scrollbar, pista de sliders,
contraste de Bonus y desaparición del nombre/potencia al usar ellipsis con wrap.
Se conserva el target de sliders de56 px; el scrollbar tiene ancho mínimo8 px
y el desplazamiento desde cualquier parte de la lista continúa funcionando.
`git diff --check` pasó. No se modificaron expectativas funcionales de pruebas.
La revisión es de escritorio renderizado y entrada táctil simulada; no se hizo
exportación Android ni prueba física en dispositivo.

## Crazy Gummy UI Design System

### Filosofía y roles

**Confitería nocturna:** base tinta ciruela, texto perla y gelatina aqua.
El volumen está en acciones/arte; datos y gameplay tienen menor ornamentación.
El color de una gomita sigue sin identificar una receta. El oro se reserva para
Bonus, reputación, premio y rareza Legendaria, nunca para toda la navegación.

| Token Palette | Color | Uso |
|---|---|---|
| color_bg | #141323 | Fondo UI |
| color_panel | #211F36 | Superficie primaria |
| color_row | #2D2945 | Superficie secundaria/elevada |
| color_border | #655C83 | Bordes/separadores |
| color_text | #F8F2FF | Texto de máxima jerarquía |
| color_text_dim | #C1B6D2 | Secundario/disabled |
| color_action | #7CE8D5 | Acción principal, enfoque y equipado |
| color_accent / color_premium | oro, Color(1,0.835,0.29) | Bonus/premium; compatibilidad COLOR_ACCENT |
| color_success | #91E8B8 | Adquirido/progreso |
| color_warning | #FF8FA3 | Racha/advertencia |
| color_danger | #FF788D | Feedback peligro |
| color_disabled | #454057 | Superficie inactiva |
| color_scrim | tinta al76% | Velo modal; no blur |

### Tipografía

Title30/display, Subtitle22/Roboto600 y Body18/Roboto se mantienen como fuentes
de todas las variantes. PremiumTitle deriva de Title con oro; BonusValue deriva
de Subtitle con tinta oscura. CollectionNameTitle/Body quedan reservados en el
Theme pero ya no se usan: el frente de las tarjetas de colección no lleva nombre.
No se usan fuentes ni tamaños locales para hacer
encajar nombres largos. Las recetas usan Body, herramientas CardTitle y reversos
de comodines conservan scroll.

### Familias de componentes

- **Botones:** Button ciruela, PrimaryButton aqua, DangerButton burdeos y
  PremiumButton oro. Normal/hover/pressed/hover_pressed/disabled/focus, misma
  superficie 9-slice y mismo padding24×10. Pressed oscurece y se hunde con motion.
- **Paneles:** ModalPanel radio28/padding24, Card radio20/padding18×16,
  CompactCard radio16/padding10×6, StatPanel radio18, PremiumPanel radio24.
  Bordes2 y sombras suaves de3–12; GummySurface refleja luz en el borde superior.
- **ShopCard:** icono compartido, título, nivel, valor actual, incremento y acción.
  Prestigio reutiliza el mismo componente con PremiumPanel/PremiumButton.
- **CollectionCard:** botón y texto identifican el estado; borde aqua equipado,
  menta adquirido, aqua atenuado comprable, borde tenue bloqueado/descubierto.
  Bloqueados no revelan nombre ni arte; no se cambian condiciones de desbloqueo.
  La variante IllustratedCard integra las imágenes sobre azul#1B3152. Zona de
  arte en todo el frente mediante ArtBox y TextureRect a aspecto conservado,
  nombre superpuesto con contorno centrado verticalmente sobre la ilustración
  (mismo tamaño/formato en armas y recetas), sobre una banda semitransparente
  redondeada (NamePlate, azul oscuro al 50%) que realza el texto sin ocultar el
  arte; y acción externa al Face. No se muestran
  «Datos» ni el símbolo de giro; el toque conserva el reverso. El frente ajusta
  su altura al ancho interior y es cuadrado, sin espacio extra para el nombre;
  mismas columnas/separaciones y arquitectura que la colección anterior.
- **StatCard:** número dominante, título Body, iconos por categoría, tooltip.
  Respeta formatos %,×,$,cubos/s del §L. El argumento value_color sigue sin uso.
- **Tabs:** seleccionada menta oscura con borde aqua; resto tinta/borde ciruela.
  Padding vertical14 conserva área táctil; títulos oficiales sin cambios.
- **Barras:** dinero/progreso menta atenuado, Bonus blanco modulado oro,
  tiempo malva, resistencia verde profundo, racha coral, dureza aqua.
  Tracks oscuros; tiempo y resistencia conservan símbolos y cifras.
- **Modales:** scrim único, ModalPanel, reflejo superior, título display, cierre
  mínimo56 y acciones52–60. Continúa ContentSizedModal/safe areas.
- **Notificaciones/tooltips:** ToastPanel premium, TooltipPanel tinta/aqua.
  Toast mantiene CanvasLayer10 y su cola; tooltips conservan temporizador y límites.

### Cartas y rarezas

Los cinco colores oficiales **no cambian**: Común#4DB3FF, Rara#4DE666,
Épica#CC66FF, Legendaria#FFBF1A, Mítico#FF2020. Se añaden nombre de rareza,
uno/dos/tres/cuatro/cinco rombos, tinte leve del fondo y sombra creciente.
La progresión se reconoce también sin color. Front/back comparten proporción
11:16 y geometría anterior; se conserva PICK/THUMBNAIL, botón fuera del marco,
reverso desplazable y giro. No se crean108 ilustraciones ni nuevas rarezas.

### Iconografía, fondos y assets

`assets/crazy_gummy/ui/README.md` enumera el kit:8 SVG (botón, dos fondos,
dos caras, dos atlas, perilla) y un shader/material de caramelo endurecido.
Los atlas tienen celdas64×64 con padding/luz/escala consistentes. `GummyIcons`
selecciona por ID canónico de herramienta o categoría visual de UI, sin alterar
Resources. Las tarjetas de herramientas/recetas usan ahora30 PNG proporcionados
por el usuario; el molde/atlas vectorial queda como respaldo. No se asignan
nuevas variantes de cubo ni modelos3D desde estas ilustraciones de UI.
Los símbolos inline de tiempo/resistencia y monedas mantienen significado.
Arte anterior queda conservado; modelos de cubo/osito y materiales gummy intactos.

### Motion, escalado y reglas futuras

Movimiento = feedback: hover1,01 (sin hover en disabled), presión inmediata
0,985×0,96/60ms, retorno con overshoot160ms, pop modal96%→100%/240ms,
compra/hito con pulso y toast con entrada elástica seguida de escala1.
Los tweens de una misma propiedad se reemplazan; al ocultar botones se cancelan
y se restauran. Cierre/acciones siguen inmediatos y no retrasan navegación.
GummySurface no procesa frames; el nuevo shader3D no usa TIME ni pantalla.

El **control determina el tamaño**. Botones: StyleBoxTexture con márgenes
26 izquierda/derecha y20 arriba/abajo; no asignar TextureRect como tamaño mínimo
del botón. Iconos: EXPAND_IGNORE_SIZE y KEEP_ASPECT_CENTERED. Fondos: cobertura
con aspecto conservado. Cartas: proporción11:16, padding6 y marco2 sin cambios.
Containers, ResponsiveGrid, TouchScrollContainer, keep_width y SafeAreaLayout
siguen siendo obligatorios; añadir un panel crítico requiere revisar targets.
No introducir texto dinámico horneado ni otro Theme por pantalla.

### Integración de ilustraciones de herramientas y recetas

**Instrucción final del usuario: quitar únicamente gris, conservar azul.**
`tools/prepare_collection_art.py` usa conectividad desde los bordes para retirar
el marco gris sin borrar reflejos plateados/blancos de las ilustraciones.
Descontamina el antialias del perímetro azul/gris, recorta al contorno de la placa,
añade padding6 y limita a512px. No altera los JPEG ni realiza procesado en Godot.
Dependencias de preparación: Pillow, numpy, opencv-python-headless.

`CollectionArt.gd` tiene30 referencias explícitas por ID para exportación segura
y reutilización. Los botones, precios, datos, desbloqueos, selección y flip
permanecen en sus componentes/controladores actuales. Se cambió únicamente la
presentación de CollectionCard y la proporción visual de sus rejillas.

Verificación final del frente compacto: `test_collection_art.gd`1144 headless
/1165 renderizadas,0 fallos, incluidas
transparencia exterior/azul opaco,30 IDs, reutilización, área artística grande,
nombres y botones, bloqueo y toque real sobre ilustración/reverso/arrastre.
Tras compactar el frente y retirar herramienta/potencia del HUD,
`test_ui_layout.gd`6445, card_choice15, touch35 y daily_bonus38 pasan.
Se revisaron capturas de colección y del Main real en las cuatro resoluciones.
En la integración inicial,
card_choice15, touch35, shop_stats114,
typography97 y theme_migration2368 pasan sin fallos. Las dos expectativas
visuales del test de layout se actualizaron (PNG activo y frente cuadrado);
las garantías funcionales de esa prueba se conservan.

Capturas reales de todas las páginas de colección en las cuatro resoluciones:
`/tmp/opencode/Collection_Recetas_*.png`, `Collection_Herramientas_*.png`.
Capturas por páginas, incluido `Collection_Flip.png` con el reverso y acción intacta.
Fuentes/procesados completos: `collection_sources.png`, `collection_cutouts.png`.
Detalles de assets y regeneración en `assets/crazy_gummy/ui/collection/README.md`.

El logo del menú usa `res://assets/crazy_gummy/icon.png`, recurso `tex_logo` de
`scenes/ui/MainMenu.tscn`, asignado a `CenterVBox/TitleVBox/Logo` (TextureRect).
El icono de aplicación/launcher usa por separado `res://assets/crazy_gummy/icon.jpg`
en project.godot y en launcher_icons/main_192x192 y adaptive_foreground_432x432.
---

## Parte II — Referencia técnica anterior de las cartas (snapshot conservado)

> Documentado directamente del código el 6 de octubre de2026 **antes del rediseño
> visual**. Se conserva como referencia de geometría/input y trazabilidad del arte
> sustituido. Para arte/estilos activos prevalecen §M y Crazy Gummy UI Design System:
> front.svg/back.svg reemplazan Joker2/back, se añaden badges/rombos/relieve,
> scrim del reverso78%, sombra de rareza y nuevas superficies. La proporción,
> padding, botón exterior, PICK/THUMBNAIL y scroll de reverso siguen vigentes.

### A. Colores de rareza

**Definición única:** `scripts/models/CardDatabase.gd:163-169` (`rarity_color()`), inyectado en cada carta como clave `"color"` al construir el dict (`_card()`, línea 161).

| Rareza | Color principal | HEX | RGB/RGBA | Alpha | Dónde se define | Dónde se aplica |
|---|---|---|---|---|---|---|
| Común | `Color(0.3, 0.7, 1.0)` | `#4DB3FF` | rgba(77, 179, 255, 255) | 1.0 | `CardDatabase.gd:165` | Borde de marco + leyenda de galería |
| Rara | `Color(0.3, 0.9, 0.4)` | `#4DE666` | rgba(77, 230, 102, 255) | 1.0 | `CardDatabase.gd:166` | ídem |
| Épica | `Color(0.8, 0.4, 1.0)` | `#CC66FF` | rgba(204, 102, 255, 255) | 1.0 | `CardDatabase.gd:167` | ídem |
| Legendaria | `Color(1.0, 0.75, 0.1)` | `#FFBF1A` | rgba(255, 191, 26, 255) | 1.0 | `CardDatabase.gd:168` | ídem |
| Mítico | `Color("#FF2020")` | `#FF2020` | rgba(255, 32, 32, 255) | 1.0 | `CardDatabase.gd:169` | ídem |
| Fallback (rareza desconocida) | `Color(1.0, 0.4, 0.8)` | `#FF66CC` | rgba(255, 102, 204, 255) | 1.0 | `CardDatabase.gd:170` | **SIN USO ACTUAL** (no alcanzable con las 5 rarezas) |

(HEX/RGB verificados ejecutando Godot, no aproximados.)

**Uso real del color de rareza — solo 2 aplicaciones:**

| Elemento | ¿Usa color de rareza? | Detalle |
|---|---|---|
| Borde de la carta | **SÍ** | `StyleBoxFlat.border_color`, grosor 2 px, en AMBAS caras y en ambos contextos (`CardFlipWidget._make_card_frame` → `UiTheme.card_style`, `CardFlipWidget.gd:341-348`) |
| Fondo de la carta | NO | Fondo fijo `#1A293D` alpha 1 (`SB_card.bg_color`, `themes/ui01_theme.tres:130`) |
| Nombre (título) | NO | `JokerTitle` fijo: `#F0F5FF` (`ui01_theme.tres:690`) |
| Descripción | NO | `JokerDescription` fijo: `#D6E6F5` (`ui01_theme.tres:683`) |
| Etiqueta de rareza en la carta | NO EXISTE | El nombre de la rareza solo aparece en la leyenda de la galería |
| Leyenda de rarezas (galería) | **SÍ** | RichTextLabel con `[color=#hex]` (`CardsModal.gd:112-114`) |
| Brillo / glow | NO DEFINIDO | No hay ningún efecto de brillo |
| Sombra | NO | `SB_card` no define sombra; el estilo duplicado hereda sombra 0 |
| Partículas | NO | El confeti del modal (`UiTheme.confetti_burst`) usa un degradado fijo arcoíris, no ligado a rareza (`UiTheme.gd:261-267`) |
| Botón ELEGIR | NO | Variante `PrimaryButton` genérica del tema |
| Animación de flip | NO | Solo escala X del marco; sin tinte ni modulate por rareza |
| Tooltip | NO | `CardTooltip` genérico |

**Colores definidos pero sin uso:** `COLOR_CARD_BG` y `COLOR_TEXT_DIM` en
`CardFlipWidget.gd:52-53` no se referencian en ningún sitio — **retirados en la
limpieza de assets** (véase `CRAZY_GUMMY_PROJECT_GUIDE.md`, «Saneamiento y
Papelera»).

**Si una rareza usa más de un color:** ninguna. Cada rareza es 1 solo color, usado exclusivamente en borde + leyenda.

### B. Dimensiones de las cartas

Las cartas NO tienen tamaño fijo: todo se deriva del **ancho pedido** (`set_mode(mode, card_width)`) y de la proporción real de la ilustración.

**Fórmulas reales** (`CardFlipWidget.gd:114-159`):

```
inset      = CARD_FRAME + CARD_PADDING = 2 + 6 = 8 px por lado
art_size   = (ancho − 16) × (512/352)        ← ratio 1.4545 medido de la textura
card_box   = ancho × (art_size.alto + 16)
total PICK = card_box.alto + CARD_GAP(10) + BUTTON_HEIGHT(56)
```

**Contexto 1 — Modal de selección** (`CardSelectionModal.gd:17,75-83`):

- `card_max_width = 220.0` (export range 148–280).
- Ancho real = `min(220, (ancho_del_HBox − 16×2) / 3)`, recalculado en cada `resized`.
- HBox = contenido del panel = `92% del viewport − 48 (margen SB_modal) − 4 (borde)`.
- **En la referencia 720×1280:** HBox = 610.4 → ancho de carta = **192.8 px**.
  - Caja: **192.8 × 273.2 px** (arte 176.8 × 257.2).
  - Widget total: 273.2 + 10 + 56 = **339.2 px** de alto.
- A partir de ~809 px de ancho de pantalla entraría el máximo de 220: caja 220 × 312.7.
- **Separación entre las 3 cartas: 16 px** (`CardsHBox`, `theme_override_constants/separation`, `CardSelectionModal.tscn:140`).

**Contexto 2 — Galería** (`CardsModal.gd:12`, `CardsModal.tscn:84-89`):

- `thumbnail_width = 144.0` (export range 104–240).
- Caja: **144 × 202.2 px** (arte 128 × 186.2). Sin botón → sin gap.
- Rejilla `ResponsiveGrid`: `min_card_width = 144`, `max_columns = 3`, separación **12 px** (defaults `h_separation`/`v_separation`).
- La celda puede ser más ancha que la miniatura; el marco **no se estira** (`SIZE_SHRINK_CENTER`, verificado por `test_ui_layout.gd:124-126`).

**Comportamiento en distintas resoluciones:** implementado. `_resize_cards` se conecta a `resized` del HBox; `ContentSizedModal` reajusta altura del panel; `ResponsiveGrid` recoloca columnas al cambiar el ancho. Ancho mínimo absoluto: **40 px** (clamp en `set_mode`). No hay escalado ni crop de la imagen: `EXPAND_IGNORE_SIZE` + `STRETCH_KEEP_ASPECT_CENTERED`.

**RELACIÓN DE ASPECTO MAESTRA DEL ASSET:**

> **352 : 512 = 11 : 16 = 0.6875** (alto/ancho 1.4545)
>
> Es la proporción exacta de `Joker2.png` y `back.png`, y es la que `CardFlipWidget._art_ratio()` lee de la textura para calcular la caja. La caja del marco NO tiene proporción constante (varía 1.417–1.421 según el ancho por los insets fijos de 8 px), pero **la zona de arte sí siempre mide exactamente 11:16**. El asset se muestra sin deformar nunca.

### C. Estructura visual de la carta

Todo el árbol se genera desde código en `_build_face()`; las escenas solo instancian el widget.

```
CardFlipWidget (Control, mouse_filter PASS, custom_minimum_size = card_box [+ botón])
├── Front (Control, FULL_RECT)              ← visible mientras no está girada
│   └── Column (VBoxContainer, FULL_RECT, separación 10)
│       ├── CardFrame (PanelContainer, SIZE_SHRINK_CENTER/BEGIN, clip_contents,
│       │                custom_minimum_size = card_box, pivot = centro,
│       │                stylebox = SB_card duplicado con border de rareza,
│       │                border 2 px, content margins 8 px)
│       │   └── ArtPanel (Control, EXPAND_FILL, min = art_size, clip_contents)
│       │       ├── [VBox + ArtLabel (Label, variante IconLabel, "🃏", alfa 0.9)]
│       │       │     ← placeholder; se OCULTA al cargar textura (nunca visible hoy)
│       │       └── [TextureRect (código), EXPAND_IGNORE_SIZE,
│       │             KEEP_ASPECT_CENTERED, textura = Joker2.png compartida]
│       └── ChooseButton (Button, "ELEGIR", PrimaryButton, alto 56, FUERA del marco)
│
└── Back (Control, FULL_RECT)               ← solo existe en modo PICK
    └── Column (VBoxContainer, FULL_RECT)
        └── CardFrame (mismo stylebox/mismo tamaño que el Front)
            └── Overlay (Control NO-Container, clip_contents=true, FULL_RECT)
                ├── BackArt (TextureRect, back.png a sangre, FULL_RECT)
                ├── Scrim (ColorRect, Color(0.04,0.05,0.1,0.62), FULL_RECT)
                └── TextScroll (ScrollContainer + TouchScrollContainer,
                │               inset 6 px, sin scroll horizontal, mouse IGNORE)
                │   └── TextBox (VBox, centrado vertical, separación 8)
                │       ├── TitleLabel (Label, variante JokerTitle, autowrap)
                │       └── DescLabel (Label, variante JokerDescription, autowrap)
                │             + hint "⟳ Toca para volver"
└── (CardsModal) CardTooltip (PanelContainer, z_index = 10, hermano del widget)
```

Notas clave:

- **Front:** sin ningún texto encima del arte. El título existe solo como `tooltip_text` nativo (hover de ratón; en THUMBNAIL/DETAIL).
- **Back:** `Overlay` es un `Control` simple y no un Container a propósito — no propaga tamaño mínimo, así que la caja nunca crece por texto largo; el desborde se recorta (`clip_contents`) o se desplaza (scroll).
- Z-order: `Front` y `Back` son hermanos; solo uno visible. `pivot_offset` del `CardFrame` = centro de la caja.
- Todo lo que no es ilustración (marco, fondo, labels, botón, scrim, tooltip) es **UI generada en runtime**; solo la ilustración depende de textura externa.

### D. Front y reverso

| | FRONT (anverso) | REVERSO |
|---|---|---|
| Qué se muestra | Ilustración **compartida** `front.svg` para las 108 cartas (ninguna carta define clave `"image"`; fallback en `configure()`, `CardFlipWidget.gd:199`) + marco de rareza | `back.svg` a sangre + scrim 62% + título + descripción + hint, centrados y con scroll |
| Dimensiones | CardFrame idéntico al reverso (misma caja calculada) | Exactamente la misma caja |
| Misma relación de aspecto | SÍ — ambas caras usan `card_box()` calculado del mismo `art_ratio` | ídem |
| Texturas | `res://assets/crazy_gummy/ui/cards/front.svg` (352×512) | `res://assets/crazy_gummy/ui/cards/back.svg` (352×512) |
| UI superpuesta sobre la imagen | Ninguna en la cara (solo tooltip nativo en hover) | Scrim + TitleLabel + DescLabel + hint + scroll — **toda la info de la carta** |
| Botón | `ELEGIR` colgado FUERA del marco (hermano en `Column`), solo en PICK | igual (no gira) |

**Animación de flip** (`flip()`, solo modo PICK, `CardFlipWidget.gd:215-232`):

1. `scale.x` del `CardFrame`: 1.0 → 0.0, **0.14 s, TRANS_QUAD, EASE_IN**.
2. Callback: intercambia visibilidad Front/Back.
3. `scale.x`: 0.0 → 1.0, **0.16 s, TRANS_QUAD, EASE_OUT**.
4. Pivot = centro del marco; **solo gira la carta**, el botón ELEGIR queda fijo; toques ignorados durante el giro (`mouse_filter IGNORE`). Duración total ≈ 0.30 s. Sin texturas de flip ni shader: es un squash horizontal.
5. En THUMBNAIL no hay reverso construido (`test_ui_layout.gd:135`) y `flip()` está deshabilitado; el toque emite `previewed`.

**Modo DETAIL** está declarado en el enum pero **no se usa en ninguna parte del proyecto**.

### E. Safe area para el arte

**FRONT — cara disponible al 100%:**

```
┌─────────────────────────────┐
│ ▌2px borde rareza + 6px ▐   │  anillo de UI (frame bg #1A293D)
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │      ARTWORK 100%       │ │  zona de ilustración, SIN UI encima
│ │    (Joker2.png hoy)     │ │  (tooltip solo en hover, no dibujado)
│ │                         │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
          [  ELEGIR  ]         ← botón FUERA de la carta
```

- Interior de la caja = zona de arte íntegra. Único anillo: 2 px borde + 6 px de fondo de marco por lado (8 px total por lado) que **no pertenece al asset**.
- No hay nombre, descripción, rareza ni icono pintados sobre el front.

**BACK — cara casi toda cubierta por UI:**

```
┌─────────────────────────────┐
│ ▌2px + 6px (mismo marco) ▐  │
│▓▓▓ back.png (fondo) ▓▓▓▓▓▓▓▓│
│▓▓▓ Scrim 62% oscuro ▓▓▓▓▓▓▓▓│
│▓▓┌───────────────────────┐▓▓│
│▓▓│  TitleLabel (22 px)   │▓▓│  bloque centrado vertical,
│▓▓│  DescLabel (18 px)    │▓▓│  inset 6 px, autowrap + scroll,
│▓▓│  "⟳ Toca para volver" │▓▓│  recorta lo que no cabe
│▓▓└───────────────────────┘▓▓│
└─────────────────────────────┘
```

- El texto se centra verticalmente en un VBox: su altura es **dinámica** (1–5+ líneas), así que no hay banda fija libre — el texto puede ocupar desde el centro hasta casi toda la cara.
- Margen del bloque: 6 px (`BACK_TEXT_INSET`). El scrim cubre el 100% de la cara.
- Conclusión: en el reverso, **toda la superficie debe considerarse zona potencialmente tapada** (scrim + texto dinámico).

### F. Tabla visual de referencia

| Propiedad | Valor actual | Fuente/archivo |
|---|---|---|
| Relación de aspecto (asset maestra) | 352:512 = 11:16 = 0.6875 | `res://assets/crazy_gummy/ui/cards/front.svg`; los antiguos `assets/card/Joker2.png`/`back.png` viven retirados en `Papelera/`; `CardFlipWidget._art_ratio()` |
| Tamaño caja selección (ref. 720×1280) | 192.8 × 273.2 px (arte 176.8 × 257.2) | fórmula `CardFlipWidget.gd:114-138` + `CardSelectionModal.gd:80` |
| Tamaño caja selección (máximo) | 220 × 312.7 px | `card_max_width = 220` |
| Widget selección (con botón) | alto + 66 px (gap 10 + botón 56) | `CARD_GAP`, `BUTTON_HEIGHT` |
| Tamaño miniatura galería | 144 × 202.2 px (arte 128 × 186.2) | `thumbnail_width = 144` |
| Ancho mínimo de carta | 40 px (clamp) | `set_mode()`, `CardFlipWidget.gd:106` |
| Común | `#4DB3FF` | `CardDatabase.gd:165` |
| Rara | `#4DE666` | `CardDatabase.gd:166` |
| Épica | `#CC66FF` | `CardDatabase.gd:167` |
| Legendaria | `#FFBF1A` | `CardDatabase.gd:168` |
| Mítico | `#FF2020` | `CardDatabase.gd:169` |
| Radio de esquinas | 20 px | `SB_card`, `ui01_theme.tres:136-139` |
| Grosor borde de rareza | 2 px | `CARD_FRAME`, `CardFlipWidget.gd:55` |
| Padding marco → arte | 6 px | `CARD_PADDING`, `CardFlipWidget.gd:56` |
| Fondo de la carta | `#1A293D` alpha 1.0 | `SB_card.bg_color`, `ui01_theme.tres:130` |
| Sombra de la carta | 0 (NO DEFINIDO en SB_card) | `ui01_theme.tres:125-139` |
| Separación entre cartas (selección) | 16 px | `CardSelectionModal.tscn:140` |
| Separación en rejilla (galería) | 12 px (h y v) | `ResponsiveGrid.gd:40-41` |
| Gap carta → botón ELEGIR | 10 px | `CARD_GAP` |
| Altura botón ELEGIR | 56 px | `BUTTON_HEIGHT` |
| Scrim del reverso | `Color(0.04, 0.05, 0.1, 0.62)` | `COLOR_BACK_SCRIM`, `CardFlipWidget.gd:63` |
| Inset del texto en reverso | 6 px | `BACK_TEXT_INSET` |
| Área aproximada para artwork (front) | 100% del interior de la caja | `_build_front_art()` |
| Área aproximada para artwork (back) | ~0% libre (scrim 100% + texto dinámico centrado) | `_build_back_art()` |
| Glow / brillo / partículas por rareza | NO DEFINIDO | — |
| Escalado/crop de imagen | NO (KEEP_ASPECT_CENTERED, sin crop) | `CardFlipWidget.gd:487-494` |
| Arte propio por carta | NO IMPLEMENTADO (clave `"image"` soportada pero sin datos) | `CardDatabase._card()`, `CardFlipWidget.gd:199` |
| Modo DETAIL | declarado, sin uso | enum `Presentation` |

### G. Implicaciones para futuros assets

Restricciones técnicas verificadas (sin proponer estilo):

1. **Relación de aspecto obligatoria: 11:16 (352×512 o múltiplos)** para FRONT y REVERSO — es la ratio que el widget calcula de la textura; otra ratio produciría letterbox centrado (nunca crop, nunca deformación).
2. **Ambas caras deben medir exactamente igual** — el flip escala ambas con el mismo `card_box`; cualquier discrepancia se vería en la animación.
3. **No hornear en la imagen:** nombre, descripción, rareza (color/borde/etiqueta), botón ELEGIR, hint de giro, scrim, icono 🃏 y tooltip — todo es UI generada en runtime.
4. **Front:** zona de arte 100% libre; el anillo de 8 px exterior (borde 2 + margen 6) lo pinta la UI, el asset puede ir a sangre completa.
5. **Back:** asumir que quedará cubierto por un velo oscuro al 62% y un bloque de texto centrado de altura dinámica con inset 6 px — la ilustración del reverso debe seguir siendo legible debajo, sin información crítica.
6. **Transparencia:** no requerida; ambas caras se pintan a sangre sobre el fondo del marco (PNG opacos válidos).
7. **Escalado:** desde 144 px (galería) hasta 220 px (selección) de ancho de caja, con extremos exportables de 104–280 px; sin mipmaps especiales ni crop — el asset se ve entero siempre.
8. **Diferencia front/reverso:** hoy ambas son 100% imagen + UI encima en el reverso; el front no lleva overlay y el reverso sí. Un redesign que quiera texto en el front tendría que añadir nodos de UI (no conviene meterlo en el PNG).
9. **108 cartas comparten un solo front hoy**; si se quiere arte único por carta existe el punto de extensión `card_data["image"]`, pero ningún dato lo usa todavía.

---

## Parte III — Anexos históricos

> Los dos documentos siguientes se fusionaron en este archivo. Se conservan íntegros
> como archivo de origen; no son instrucciones para reintroducir terminología antigua.

---

## Anexo A — Informe de comodines (histórico)

> **Anexo histórico.** Contenido original de *Informe de comodines*, conservado aquí tras la
> fusión en el informe global. Los IDs y datos siguen vigentes; los títulos y
> microcopy de época se mantienen sin actualizar y no son la referencia actual.

### 1. Resumen

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

#### Probabilidades reales del sorteo

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

### 2. Ciclo de vida de un comodín

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

### 3. Catálogo completo

Ordenado por rareza y, dentro de cada rareza, por el bloque tal y como aparece en el código.


#### Común — 63 cartas

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

#### Rara — 29 cartas

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

#### Épica — 9 cartas

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

#### Legendaria — 5 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Filazo Épico** | +28% daño | `damage` | `0.28` | daño |
| 2 | 🃏 **Jackpot Legendario** | +1x multiplicador de Jackpot | `jackpot_multiplier` | `1` | multiplicador de Jackpot |
| 3 | 🃏 **Tormenta Perfecta** | +28% frecuencia de lanzamiento | `launch_rate` | `0.28` | frecuencia de lanzamiento |
| 4 | 🃏 **Racha Infinita** | +x1.0 al multiplicador de racha | `streak_bonus` | `1` | multiplicador de racha |
| 5 | 🃏 **Demoledor** | +3% probabilidad de romper una piedra | `stone_break_chance` | `0.03` | probabilidad de romper piedra |

#### Mítico — 2 cartas

| # | Carta | Efecto | `effect_type` | Valor | Suma en |
|---|---|---|---|---|---|
| 1 | 🃏 **Divinidad** | +12% probabilidad de Crítico | `crit_chance` | `0.12` | probabilidad de crítico |
| 2 | 🃏 **Racha Eterna** | Mantiene el conteo de racha entre días | `streak_keep` | `1` | racha entre días |

---

### 4. Tipos de efecto: código vs. cartas

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

### 5. Ocultos, sin usar y matices detectados

#### Cartas "invisibles" / capacidad sin carta

| Capacidad | Estado | Nota |
|---|---|---|
| `effect_type: "prestige"` | **Implementada pero sin ninguna carta** | `card_prestige_bonus` se suma a la reputación diaria (`scripts/autoload/GameManager.gd:409`, `1 ⭐ + bonus`). Es la única rama de `_apply_card_effect()` que ningún comodín puede activar: la reputación por día solo da el punto base. |
| `effect_type: "multi"` | **Soportada por `apply_card_upgrade()`, sin cartas** | El código acepta un `effect_value` con lista de efectos (`for effect in effect_value`), pero ninguna carta del catálogo lo usa. Sirve de base para futuras cartas multi-efecto. |
| `CardSelectionModal._on_card_selected` | Fallback `card_data["effects"]` | Es la otra mitad del soporte "multi": si someday hay cartas multi-efecto, el modal ya lee esa clave. |

#### Comentarios obsoletos en el propio catálogo

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

#### Cartas cuyo repetir no aporta nada

Dos efectos son **booleanos**, no acumulativos: se guardan como `int` y se consultan con
`> 0`. Si vuelven a salir, la segunda copia es inerte:

| Carta | Rareza | Efecto |
|---|---|---|
| `Pie Firme` | Rara | `first_stone_free` → `card_first_stone_free += 1` |
| `Racha Eterna` | Mítico | `streak_keep` → `card_streak_keep += 1` |

Como el sorteo **no excluye** las cartas ya activas, pueden aparecer repetidas: con `Pie Firme`
el jugador puede gastar dos elecciones del día y seguir dispensando **solo** la primera piedra.
Con `Racha Eterna`, obtenerla dos veces no aporta nada extra.

#### Las 2 cartas míticas

| Carta | Efecto | Realidad en juego |
|---|---|---|
| `Divinidad` | +12% probabilidad de crítico | El mayor valor de crítico del juego: por encima del +8% del épica `Golpe Perfecto` y del +4.5% de la rara `Golpe Mortal`. En impacto real depende del arma: el +28% de daño de la legendaria `Filazo Épico` suele pesar más. |
| `Racha Eterna` | Mantiene la racha entre días | Conserva el **contador** de racha al cambiar de día. Sin una carta de `streak_bonus` (`Cadena de Cortes`, `Furia de la Racha`, `Racha Infinita`) el multiplicador se queda en x1.00, así que su beneficio real es no perder el progreso hacia el siguiente hito y no romper la racha al empezar el día siguiente. |

### 6. Resumen de hallazgos

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

---
## Anexo B — Informe de logros (histórico)


> **Anexo histórico.** Contenido original de *Informe de logros*, conservado aquí tras la
> fusión en el informe global. Los IDs y datos siguen vigentes; los títulos y
> microcopy de época se mantienen sin actualizar y no son la referencia actual.

### 1. Resumen

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

#### Cómo funciona el sistema

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

#### Semántica de las métricas (importante)

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

### 2. Logros de cantidad (59)

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

### 3. Logros de objetivo (24)

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

### 4. Logros de estilo de juego (17)

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

### 5. Logros graciosos (9)

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

### 6. Logros secretos / easter eggs (12)

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

### 7. Ocultos, sin usar y matizes detectados

#### 7.1 La lista completa está oculta hasta el día 100

`AchievementsModal.gd` **filtra los logros no conseguidos** mientras el juego no esté
completado (`_is_game_completed()` comprueba el logro `centenario`). Antes de llegar al
día 100 el modal solo muestra los logros ya desbloqueados; la lista íntegra de 121
entradas (con sus objetivos) solo es visible tras ganar. El resumen también cambia:
antes muestra "🏆 N logros completados", después "🏆 N / 121".

→ **121 logros "ocultos" por diseño**, no por error: son los pendientes sin revelar.

#### 7.2 `Rápido y Furioso` no se puede conseguir el día 1

- Definición: `{"id":"fruta_termina_rapido", ..., "flag":"beat_day_rushed"}`.
- Se marca en `scripts/autoload/GameManager.gd:305` con la condición `target_unreached and order_progress >= order_target`.
- El día 1 tiene `order_target == 0.0`, así que `order_progress (0) < order_target (0)` es
  **falso** y el flag nunca se marca: el logro es alcanzable **solo a partir del día 2**.

#### 7.3 Cuatro armas sin logro de "estilo"

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

#### 7.4 Objetivo que no cuadra con su descripción

`coleccionista_cartas` — *"Descubre **todos** los comodines"* — tiene
`target: 100` sobre `cards_discovered`, pero el catálogo tiene **108 cartas**
(ver el anexo «Anexo A — Informe de comodines (histórico)» de este documento;
el original vive retirado en `Papelera/Informe de comodines.md`). El logro se cumple 8 cartas antes de descubrir todo el
catálogo, y la galería (`CardsModal`) no muestra ningún porcentaje, así que el jugador no
tiene forma de saber que le quedan 8 cartas por descubrir.

#### 7.5 Categorías y helpers definidos pero sin usar

| Elemento | Estado |
|---|---|
| `cat: "aleatorio"` | Ningún logro lo usa |
| `cat: "easter_egg"` | Ningún logro lo usa |
| `CATEGORY_ICONS` (7 iconos) | Retirado en limpieza de assets | El modal ya **no agrupa** por categoría: muestra una sola pestaña "TODOS LOS LOGROS" |
| `get_category_label()` | Retirado en limpieza de assets | Sin llamadas: quedó obsoleto al unificar la lista |

#### 7.6 Semántica de `upgrades_bought_run`

`comprador` (5) y `megacomprador` (20) usan `record_metric("upgrades_bought_run")`
en `StatsManager.gd`, es decir **acumulado histórico**, no "en un mismo negocio" como
dice la descripción. Un jugador que reúna 5 compras repartidas en 5 negocios distintos
desbloquea `comprador`.

#### 7.7 Logros condicionados a ventanas muy estrechas

| Logro | Condición real | Observación |
|---|---|---|
| `tranquilo_juego` (`blind_streak`) | `current_streak == 15` exacto (`scripts/autoload/GameManager.gd:187`) | Si el jugador llega a 16 sin pasar por el check, no salta; en la práctica el check corre en cada corte |
| `deuda_cero` (`day_finished_empty`) | `current_energy <= 0.0` al completar el día (`GameManager._on_day_completed`) | La energía se recorta en 0 al agotarse, así que es la forma natural de cerrar el día |
| `combinador_dorado` (`golden_on_screen_2`) | 2 frutas doradas simultáneas en pantalla (`scripts/game/FruitSpawner.gd:164`) | Depende del spawner, no del corte |
| `estado_de_creencias` (`esoteric_calm`) | Crítico sin golpear ninguna piedra (`scripts/game/SwipeController.gd:158`) | Depende de la resolución de colisiones, no de la puntuación |
| `cinco_en_uno` (`multi_cut_5`) | 5 frutas en un solo trazo | Registra 1 por evento; objetivo 1 |

#### 7.8 Lo que sí está bien — sin fallos de integridad

- Los 121 `id` son únicos y todos los `flag` se marcan en algún punto del código.
- Las 20 métricas `cut_<fruta>` se registran de forma dinámica
  (`record_metric("cut_" + fruit_id)`) y sus 20 ids coinciden exactamente con
  `data/fruits/*.tres` (catálogo histórico retirado a `Papelera/data/fruits/`).
- Las metas escalonadas por métrica (`best_day`, `fruits_cut`, `money_total`, `crits`,
  `jackpots`, `golden_fruits`, `stones_hit`, `runs_bankrupt`, `streak_broke`,
  `prestige_*`, `days_completed_total`, `cards_discovered`) no dependen del orden:
  un jugador con progreso guardado desbloquea todas las que ya cumple.
