# Crazy Gummy — integración 3D definitiva

Actualizado: 7 de octubre de 2026. Arquitectura general y balance:
[`docs/INFORME_GLOBAL.md`](docs/INFORME_GLOBAL.md).

## Cierre y registro del negocio

Todas las salidas pasan por `GameManager.end_run()`; `end_run_failed()` delega
en ese mismo cierre con motivo de derrota. Se registra una sola vez el último
día realmente completado y la producción, sin conceder reputación duplicada.
Salir desde créditos también cierra la run y muestra resultados antes del menú.

Completar `win_day` (100) marca el negocio como **exitoso**: salir o perder
después mantiene ese resultado. Antes de completar esa meta, la salida voluntaria
se muestra como **NEGOCIO FINALIZADO** y la derrota como **NEGOCIO EN QUIEBRA**.
Los créditos aparecen solo al completar el día100; continuar mantiene la run
y los días posteriores usan su resumen real. No cambia el esquema de guardado.
Regresión: `tests/test_run_completion.gd`, **67 comprobaciones, 0 fallos**:
salida de créditos, continuidad al101, salida tras125, derrota antes/después100,
impuesto impagable tras victoria, persistencia y protección contra doble cierre.

## Sistema activo

`BlockSpawner` → `GummyBlock` → `Projectile3DWorld` → `Projectile3D` →
`GummyVisual.setup(radius, appearance, golden, recipe_id)`.
`scripts/models/RecipeVisualLibrary.gd` centraliza los 28 GLB con referencias
`preload` explícitas, incluidas como dependencias de exportación.

El cubo se instancia en `Cube/Model` y la gomita en `Product/Model`. Al golpear,
se deforma el padre visual; al destruir, desaparece el cubo y se revela el producto
con el movimiento `Ballistic` heredado. Los modelos se centran y escalan mediante
transformaciones, sin modificar vértices. Los cocodrilos tienen giro Y de 90°
para mostrar el perfil de su geometría longitudinal al eje Z.

## Mapeo implementado

Gomitas: **`assets/crazy_gummy/gummies/`**. Cubos:
**`assets/crazy_gummy/cubes/`**. Orden de `RecipeDatabase` / `data/catalog.tres`.

| Tier | ID canónico | GLB de gomita | GLB de cubo |
|---:|---|---|---|
| 1 | `bear_classic` | `gummy_01_bear.glb` | `cube_01_classic.glb` |
| 2 | `ring` | `gummy_02_ring.glb` | `cube_01_classic.glb` |
| 3 | `ring_premium` | `gummy_03_ring_premium.glb` | `cube_01_classic.glb` |
| 4 | `worm` | `gummy_04_worm.glb` | `cube_01_classic.glb` |
| 5 | `worm_premium` | `gummy_05_worm_premium.glb` | `cube_02_wavy.glb` |
| 6 | `bottle` | `gummy_06_bottle.glb` | `cube_02_wavy.glb` |
| 7 | `bottle_premium` | `gummy_07_bottle_premium.glb` | `cube_02_wavy.glb` |
| 8 | `heart` | `gummy_08_heart.glb` | `cube_02_wavy.glb` |
| 9 | `heart_premium` | `gummy_09_heart_premium.glb` | `cube_03_faceted.glb` |
| 10 | `fish` | `gummy_10_fish.glb` | `cube_03_faceted.glb` |
| 11 | `fish_premium` | `gummy_11_fish_premium.glb` | `cube_03_faceted.glb` |
| 12 | `crocodile` | `gummy_12_crocodile.glb` | `cube_03_faceted.glb` |
| 13 | `crocodile_premium` | `gummy_13_crocodile_premium.glb` | `cube_04_relief.glb` |
| 14 | `shark` | `gummy_14_shark.glb` | `cube_04_relief.glb` |
| 15 | `shark_premium` | `gummy_15_shark_premium.glb` | `cube_04_relief.glb` |
| 16 | `dragon` | `gummy_16_dragon.glb` | `cube_04_relief.glb` |
| 17 | `dragon_premium` | `gummy_17_dragon_premium.glb` | `cube_05_crown.glb` |
| 18 | `unicorn` | `gummy_18_unicorn.glb` | `cube_05_crown.glb` |
| 19 | `unicorn_premium` | `gummy_19_unicorn_premium.glb` | `cube_05_crown.glb` |
| 20 | `bear_crown` | `gummy_20_bear_crown.glb` | **`cube_06_crown_exclusive.glb`** |

Las fuentes `g1–g20`, `c1–c6`, `o1–o2` se renombraron conservando los bytes,
verificado con SHA-256. Los pares 4/5, 6/7, 10/11 y 12/13 contienen geometría
idéntica; se conservan sus archivos y referencias individuales. Las demás
variantes Premium conservan su GLB propio.

**Particularidad de las fuentes:** `c5` y `c6` también son idénticos byte por
byte. Se conservan como Corona / Corona Exclusivo según la convención solicitada.
La referencia al archivo 6 es exclusiva del tier 20; los assets recibidos no
contienen una diferencia geométrica entre ambos.

## Caramelo Duro

- Entero: `assets/crazy_gummy/Obstaculos/obstacle_hard_candy.glb`.
- Roto: `assets/crazy_gummy/Obstaculos/obstacle_hard_candy_broken.glb`.

El spawner conserva radio, frecuencia, trayectoria y penalización. Su espejo usa
el GLB entero y oculta el dibujo 2D. `Obstacle.candy_broken` notifica al espejo
antes de eliminar el objeto lógico. Se muestra el GLB roto **completo e intacto**,
hereda velocidad, cae y se libera al escapar. No se divide ni espeja la malla;
se conservan las tres piezas originales. Dinero y racha mantienen su lógica.
Ambos modelos usan el acabado previo `ui/effects/hardened_candy.tres`.

## Materiales y provisionales

`materials/palette.tres` sigue resolviendo el acabado por `unlock_order`. Cubo y
gomita comparten material por instancia: mismos ocho colores aleatorios,
translucidez, shaders, azúcar de tiers 5/7/10/13/17/20 y oro opaco. La textura
JPEG embebida original del osito se extrajo como dependencia de importación de
Godot; el material de gameplay sigue siendo el existente.

Los wrappers `cubes/cube.tscn` / `gummies/bear.tscn` apuntan ahora a los definitivos
del tier 1. `GummyVisual.tscn` ya no instancia los modelos provisionales.
`Projectile3D` ya no contiene el cargador histórico de esferas/mitades generadas.
`assets/models/gummy/cubo.glb` y `osito.glb` quedaron aislados en
`Papelera/assets/models/gummy/` (ver siguiente sección).

## Tarjetas de Recetas/Herramientas y de colección

Capa visual de las tarjetas "más arte y menos overlay", con contrato claro
frente/reverso:

- `scenes/ui/components/CollectionCard.tscn`: **frente puramente visual** — la
  ilustración/emoji oficial en un área cuadrada, sin nombre, descripción,
  estadísticas, precio ni ningún texto informativo. El estado visual (velo +
  `POR DESCUBRIR`) sí va en el frente. El **reverso** concentra toda la
  información con jerarquía: nombre, datos, descripción opcional y el **botón de
  acción (precio/comprar/equipar/estado)** como última fila de la cara girada.
- `scripts/ui/CollectionCard.gd`: `set_locked(locked, hint, revealable)` —
  las **comprables** (cadena desbloqueada) voltean veladas para mostrar su
  precio y botón; las **bloqueadas de cadena** no voltean (el velo no revela
  contenido futuro). El toque gira la tarjeta; el arrastre no.
- Frente sin texto: el nombre ya no se superpone al arte; el rol tipográfico
  (`Body` recetas / `CardTitle` herramientas) se conserva en el reverso.
- Regresión: `tests/test_collection_art.gd`, **1269 comprobaciones, 0 fallos**
  (frente sin texto, arte cuadrado y dominante, acción en el reverso, comprable
  voltea con precio, bloqueada de cadena no voltea, toque/arrastre).

## Formato global de números

Todo valor numérico visible para el jugador se muestra con **máximo 1 decimal,
sin excepciones** (`UiTheme.format_stat` es el único formateador; `format_money`
añade sufijos K/M/B/T/Qa/Qi/Sx/Sp y también usa un decimal). La antigua
excepción de precisión 2/3 decimal de Jackpot (`format_jackpot`) se eliminó;
todos sus usos pasaron a `format_stat`. El redondeo es solo de presentación:
los cálculos internos conservan su precisión real. Conteos enteros (días,
gomitas, logros, tiempo en segundos) se mantienen sin decimales.

## Saneamiento y Papelera

Retirada de legacy y de código muerto, sin tocar gameplay. Regla: antes de
mover un recurso se auditan referencias (`res://` en `.gd/.tscn/.tres/.cfg`),
escenas, preloads, strings, tests y `project.godot`.

- **`Papelera/`** (con `.gdignore`): cuarentena de 213 archivos, preservando la
  ruta original y con manifiesto en `Papelera/README_PAPELERA.md`. Godot la
  ignora por completo; nada de allí es `res://` válido.
- **Legado Crazy Fruit restaurado y aislado:** `assets/fruits/` (21),
  `data/fruits/` (20), `data/knives/` (10), scripts `Fruit*/KnifeData/JuiceSplash`,
  5 escenas `Fruit*`, `assets/card/{Joker2,back}.png`. El sistema activo usa
  `GummyBlock`/recetas con IDs canónicos; `SaveMigration` aísla los aliases.
- **Assets provisionales/sin uso:** `assets/models/gummy/*` (cubo/osito GLB),
  `assets/ui/{backgrounds,icons,panels}`, 15 variantes Roboto + Cartoonic,
  `Icon.svg` (17 MB), `icon_app.png`, materiales viejos de gummy/sugar.
- **Código muerto retirado:** `CardFlipWidget.height_for`, `COLOR_CARD_BG`,
  `COLOR_TEXT_DIM`, `_front_panel`/`_back_panel`/`_front_art`;
  `StreakRing.show_multiplier()`+`multiplier_hold` (el aviso del multiplicador lo
  pinta HUD/MultiplierFlyLabel); `ResponsiveGrid.refresh()`;
  `CollectionCard.recipe_texture()`; `AchievementManager.CATEGORY_ICONS`+`get_category_label()`;
  `UiTheme.apply_modal_panel()` y `UiTheme.COLOR_BG`.
- **Conservado a propósito:** señales públicas sin conectores
  (`SaveManager.data_loaded`/`data_saved`, `GameManager.run_tool_equipped`),
  `BlockSpriteFallback` (opt-out 2D con rutas opcionales protegidas por
  `ResourceLoader.exists`) y `SoundManager` (rutas de música protegidas).
- `tests/test_internal_names.gd` ahora audita también `assets/ui` y
  `assets/fonts`; se actualizó al retirar `assets/provisional` y al reescribir
  las rutas del respaldo 2D como directorio opcional.

## Validación ejecutada

### Variedad de tamaños y nombres breves

Todos los cubos y caramelos comparten la base del clásico (diámetro visual 90 px) y varían uniformemente entre 0,5× y 1,5× (45–135 px). Los parámetros están expuestos en `BlockSpawner`; colisión y modelo siguen el tamaño seleccionado. Los nombres visibles eliminan «Cubo Gummy» y «Gummy Premium»: «Clásico +», «Aro +», «Osito», etc. Las herramientas básicas también usan nombres breves.

### Guardar y continuar

El esquema v3 de `user://crazy_gummy_save.json` incluye `active_run`, separado del progreso permanente. «Guardar y salir» en Pausa y Mercado conserva día, saldo, resistencia, reloj, racha, mejoras, comodines, desbloqueos y contadores. «Continuar» restaura la ronda o el Mercado. Nueva partida exige confirmar si existe una partida guardada; perder o finalizar invalida esa instantánea. Los objetos físicos en vuelo se regeneran al continuar.

Validación de esta funcionalidad: `test_run_save.gd` (58 comprobaciones), `test_save_compatibility.gd` (278) y suite completa de 17 pruebas sin fallos. El layout con Continuar visible pasó en 720×960, 720×1280, 720×1600 y 960×1280 (6258 comprobaciones; 6393 con capturas).

Godot **4.7.2**, **Compatibility/OpenGL**, guardado aislado en `/tmp/opencode`:

| Prueba | Comprobaciones | Fallos |
|---|---:|---:|
| `test_definitive_3d.gd` — Main/spawner reales, 20 tiers normales/dorados, producción, Caramelo Duro entero/roto y liberación | 245 | 0 |
| `test_gummy_materials.gd` — geometrías definitivas y parámetros de materiales | 349 | 0 |
| `test_gummy_visual.gd` — impacto, revelado, partículas, movimiento, RNG y recompensas | 73 | 0 |
| `test_shop_stats.gd` — fórmulas y precios de tiendas | 114 | 0 |
| `test_collection_art.gd` — frente visual puro, reverso con acción y volteo comprable | 1269 | 0 |
| `test_internal_names.gd` — nomenclatura activa y referencias estáticas | 19644 | 0 |

Arranque directo de Main renderizado con `--quit-after 120`, sin errores.
`git diff --check` pasó. La auditoría de huellas confirma datos y materiales
intactos; el único archivo cambiado de su lista de gameplay es `GummyBlock.gd`,
por el label que ahora muestra la variante de cubo asignada.
Para repetir las capturas del sistema activo:

```bash
XDG_DATA_HOME=/tmp/opencode/cg-final-assets godot --path . --audio-driver Dummy --script tests/test_definitive_3d.gd -- --capture
```

Evidencia: `/tmp/opencode/definitive_tier_01_cube.png` hasta
`definitive_tier_20_cube.png`, sus correspondientes `_gummy.png`,
`definitive_tier_20_gold.png`, `definitive_hard_candy.png` y
`definitive_hard_candy_broken.png`. Posiciones detenidas solo en el fixture para
inspeccionar las formas dentro del Main real.
La lámina `/tmp/opencode/gummy_20_materials.png` muestra las veinte parejas
sin partículas superpuestas y fue inspeccionada visualmente, junto con las
capturas del cubo exclusivo, osito corona dorado y ambos estados del caramelo.
