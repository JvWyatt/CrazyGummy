# Crazy Gummy — prueba provisional de materiales

Las 20 recetas usan IDs canónicos en `data/recipes/`, con balance y progresión conservados.
Sus nombres visibles ya pertenecen a Crazy Gummy; consulta
`../../docs/INFORME_GLOBAL.md` para el informe global de la app (recetas, sistemas y cartas).

El catálogo de 20 productos ahora va de **Osito Gummy Clásico** a **Osito Gummy Corona**,
con las familias y variantes Premium definidas en la guía. Los nombres de acabados
de materiales no son nombres de producto. Las cinco variantes de cubo están
registradas para el futuro arte; el modelo actual sigue siendo el clásico para
todos los tiers. Caramelo Endurecido es el obstáculo;
Caramelo Endurecido Roto es el resultado del comodín, sin nueva mecánica.

`icon.png` es el logo del menú (`MainMenu/CenterVBox/TitleVBox/Logo`).
`icon.jpg` es el icono de la aplicación y del launcher principal/foreground
de Android, con referencias independientes del menú. `icon_source.jpg`,
`launcher_foreground.svg` y `Icon.svg` (plantilla de 17 MB) fueron **retirados a
`Papelera/`** durante la limpieza de assets; `launcher_background.svg` sigue
activo como fondo del icono adaptable.
`Projectile3D` lee únicamente `RecipeData.unlock_order` y el estado dorado existente
para seleccionar un material de `materials/palette.tres`.

## Organización

- `cubes/cube.tscn`: wrapper del tier 1 que apunta al **GLB definitivo**
  `cubes/cube_01_classic.glb` (sin copiar ni mover modelos).
- `gummies/bear.tscn`: wrapper del tier 1 que apunta al **GLB definitivo**
  `gummies/gummy_01_bear.glb`. Ambos wrappers se conservan sin referencias
  activas como punto de entrada a los modelos.
- `materials/gummy/`: 14 materiales lisos/combinados y el shader gummy común.
- `materials/sugar/`: 6 acabados azucarados; usan el mismo shader gummy.
- `materials/gold/`: shader y material de oro metálico opaco.
- `materials/palette.tres`: catálogo visual ordenado de los 20 tiers y el oro.
- `effects/fragment_mesh.tres`: cuadritos de las partículas existentes.
- `Obstaculos/obstacle_hard_candy.glb` y `obstacle_hard_candy_broken.glb`:
  Caramelo Endurecido entero y roto («Caramelo Duro Roto»).
- `cubes/` (6 GLB) y `gummies/` (20 GLB): modelos **definitivos** numerados con
  sus ilustraciones base de `Recetas/` y `Armas/`, todas protegidas.
- Fondo translúcido de prueba (`backgrounds/`) retirado; el gameplay usa
  `ui/backgrounds/gameplay.svg` y el menú `ui/backgrounds/menu.svg`.

Los provisionales `assets/models/gummy/cubo.glb`/`osito.glb` fueron **retirados
a `Papelera/`**; los PNG de respaldo viven en una carpeta opcional inexistente
(`assets/provisional/recipe_sprites/`, gancho canónico de `BlockSpriteFallback`).
No hay recursos nuevos de obstáculos: su esfera y su
flujo original se mantienen.

## Distribución de variantes

Los colores de la tabla son referencias del diseño base. **En gameplay los cubos
normales eligen un color aleatorio de la paleta en cada spawn**, manteniendo el
acabado, azúcar, transparencia y patrón de su tier. Los materiales bicolor
usan como segundo tono otro color de esa misma paleta fija. El osito y las
partículas heredan el resultado; los dorados conservan siempre el oro metálico.

## Paleta normal fija

Cada color tiene probabilidad **1/8 (12,5%)**; la selección usa exclusivamente el
generador visual, sin cambiar tiradas de gameplay. No se generan componentes RGB
ni nuevos tonos HSV. El dorado queda fuera de esta paleta y conserva su sistema.

| Color | Hex |
|---|---|
| Rojo | `#F2384A` |
| Naranja | `#FF8A24` |
| Amarillo | `#FFD83D` |
| Verde lima | `#72D94C` |
| Aqua | `#20E6C1` |
| Azul | `#32A8F0` |
| Violeta | `#9B55E7` |
| Rosa | `#FF65A3` |

El aqua se ilumina por el albedo saturado y los reflejos del material: el shader
normal no usa emisión ni bioluminiscencia. El osito no vuelve a seleccionar color;
comparte el material del cubo, y las partículas reciben su `current_color` exacto.

## Acabados por tier

| Tier | ID canónico | Apariencia provisional |
|---:|---|---|
| 1 | bear_classic | Rubí rojo liso y brillante |
| 2 | ring | Amarillo miel brillante |
| 3 | ring_premium | Degradado coral satinado |
| 4 | worm | Glaseado oscuro |
| 5 | worm_premium | Recubrimiento azucarado |
| 6 | bottle | Verde cristalino |
| 7 | bottle_premium | Degradado menta escarchado |
| 8 | heart | Cintas jade–lima |
| 9 | heart_premium | Degradado tropical naranja–amarillo |
| 10 | fish | Amarillo ácido azucarado |
| 11 | fish_premium | Capas rosa–verde |
| 12 | crocodile | Turquesa cristalino, mayor translucidez |
| 13 | crocodile_premium | Ámbar claro escarchado |
| 14 | shark | Marmoleado naranja–rosa |
| 15 | shark_premium | Perla crema con reflejo azul, no metálica |
| 16 | dragon | Degradado esmeralda profundo |
| 17 | dragon_premium | Amatista–magenta marmoleada con azúcar |
| 18 | unicorn | Cintas rosa–celeste |
| 19 | unicorn_premium | Ámbar translúcido con vetas claras, no metálico |
| 20 | bear_crown | Violeta–turquesa iridiscente escarchado |
| Especial | Cualquier receta dorada | Cubo y osito de oro metálico opaco |

## Edición y rendimiento

Editar cada `.tres` desde el Inspector: `primary_color`, `secondary_color`,
`opacity`, `surface_roughness`, `specular_strength`, `rim_strength`, `edge_opacity`,
`volume_contrast`, `pattern_mode`, `pattern_scale`,
`pattern_mix`, `sugar_amount` y `sugar_scale`. Los modos de patrón son:
0 liso, 1 degradado, 2 cintas, 3 marmoleado y 4 nácar/iridiscencia.

El cubo y el osito reciben **exactamente el mismo material**. Cada spawn normal
usa una copia del acabado base para su color aleatorio, sin modificar los
recursos de tier. Los dorados comparten el material de oro sin recolorearlo.
En `GummyVisual.tscn`, `palette` permite editar los colores y
`randomize_material_color` desactivar temporalmente la variación para comparar
los colores base del catálogo. La selección usa el RNG visual independiente.

Las gomitas lisas usan opacidad **0,80 (80%)** y roughness 0,14–0,20; las azucaradas
mantienen una base translúcida con opacidad **0,90 (90%)** y roughness 0,20–0,32.
El brillo especular es ajustable (0,55 por defecto) y los bordes añaden densidad
sin hacer el centro totalmente opaco. Se simula absorción suave **sin emisión**.
Los 8 colores utilizan ese mismo shader base y solo cambian sus parámetros de
color; los acabados de tier existentes se conservan. El azúcar usa un hash procedural, variaciones
de color, roughness y normales; **no hay cristales modelados ni imágenes nuevas**.
No se usan refracción, screen/depth textures, ruido multicapa, animación idle,
luces adicionales ni efectos de postprocesado. El oro usa metallic 1, opacidad
total y reflejos de softbox simulados para el entorno actual sin cambiar sus luces.

El movimiento, tamaño lógico, impacto gelatinoso, partículas y aparición/caída
del osito reutilizan el flujo existente. La paleta aleatoria funciona también
con los 20 acabados nuevos y no modifica estadísticas ni recompensas.

## Verificación

Con `XDG_DATA_HOME` aislado para no afectar la partida:

```bash
XDG_DATA_HOME=/tmp/opencode/gummy-20-tests godot --headless --path . --script tests/test_gummy_materials.gd
XDG_DATA_HOME=/tmp/opencode/gummy-20-flow godot --headless --path . --script tests/test_gummy_visual.gd
```

La prueba de materiales comprueba todos los tiers, modelos compartidos, material
idéntico cubo/osito, variante dorada para las 20 recetas, datos intactos, wobble,
transformación, materiales por instancia y esfera del obstáculo.

Para una lámina comparativa externa (crear previamente `/tmp/opencode`):

```bash
XDG_DATA_HOME=/tmp/opencode/gummy-20-render godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script tests/test_gummy_materials.gd -- --capture
```

Se guardan `/tmp/opencode/gummy_20_materials.png` y
`/tmp/opencode/gummy_fixed_palette.png`; las láminas usan tamaños uniformes
solo para comparar materiales y los 8 colores, sin cambiar las escalas del gameplay.
