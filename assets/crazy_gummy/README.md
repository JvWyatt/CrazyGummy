# Crazy Gummy — prueba provisional de materiales

Las 20 frutas conservan sus identificadores, nombres, datos y progresión.
`Fruit3D` lee únicamente `FruitData.unlock_order` y el estado dorado existente
para seleccionar un material de `materials/palette.tres`.

## Organización

- `cubes/cube.tscn`: referencia al **cubo existente**, sin copiar ni mover su GLB.
- `gummies/bear.tscn`: referencia al **osito existente**, sin nuevos modelos.
- `materials/gummy/`: 14 materiales lisos/combinados y el shader gummy común.
- `materials/sugar/`: 6 acabados azucarados; usan el mismo shader gummy.
- `materials/gold/`: shader y material de oro metálico opaco.
- `materials/palette.tres`: catálogo visual ordenado de los 20 tiers y el oro.
- `effects/fragment_mesh.tres`: cuadritos de las partículas existentes.

Los originales siguen en `assets/models/gummy/`. Los assets antiguos de frutas
permanecen disponibles. No hay recursos nuevos de obstáculos: su esfera y su
flujo original se mantienen.

## Distribución de variantes

Los colores de la tabla son referencias del diseño base. **En gameplay los cubos
normales eligen un color aleatorio de la paleta en cada spawn**, manteniendo el
acabado, azúcar, transparencia y patrón de su tier. Los materiales bicolor
desplazan también el segundo tono para conservar su contraste. El osito y las
partículas heredan el resultado; los dorados conservan siempre el oro metálico.

| Tier | Fruta interna | Apariencia provisional |
|---:|---|---|
| 1 | strawberry / Fresa | Rubí rojo liso y brillante |
| 2 | banana / Banana | Amarillo miel brillante |
| 3 | peach / Melocotón | Degradado coral–melocotón satinado |
| 4 | cherry / Cereza | Cereza oscura glaseada |
| 5 | orange / Naranja | Mandarina azucarada |
| 6 | apple / Manzana | Verde manzana cristalino |
| 7 | pear / Pera | Degradado menta escarchado |
| 8 | kiwi / Kiwi | Cintas jade–lima |
| 9 | mango / Mango | Degradado tropical naranja–amarillo |
| 10 | lemon / Limón | Amarillo ácido azucarado |
| 11 | watermelon / Sandía | Capas rosa–verde |
| 12 | melon / Melón | Turquesa cristalino, mayor translucidez |
| 13 | pineapple / Piña | Ámbar claro escarchado |
| 14 | papaya / Papaya | Marmoleado naranja–frambuesa |
| 15 | coconut / Coco | Perla crema con reflejo azul, no metálica |
| 16 | avocado / Aguacate | Degradado esmeralda profundo |
| 17 | dragon_fruit / Pitahaya | Amatista–magenta marmoleada con azúcar |
| 18 | guava / Guayaba | Cintas rosa–celeste |
| 19 | quince / Membrillo | Ámbar translúcido con vetas claras, no metálico |
| 20 | pumpkin / Calabaza | Violeta–turquesa iridiscente escarchado |
| Especial | Cualquier fruta dorada | Cubo y osito de oro metálico opaco |

## Edición y rendimiento

Editar cada `.tres` desde el Inspector: `primary_color`, `secondary_color`,
`opacity`, `surface_roughness`, `internal_glow`, `pattern_mode`, `pattern_scale`,
`pattern_mix`, `sugar_amount` y `sugar_scale`. Los modos de patrón son:
0 liso, 1 degradado, 2 cintas, 3 marmoleado y 4 nácar/iridiscencia.

El cubo y el osito reciben **exactamente el mismo material**. Cada spawn normal
usa una copia del acabado base para su color aleatorio, sin modificar los
recursos de tier. Los dorados comparten el material de oro sin recolorearlo.
En `GummyVisual.tscn`, `palette` permite editar los colores y
`randomize_material_color` desactivar temporalmente la variación para comparar
los colores base del catálogo. La selección usa el RNG visual independiente.

Las gomitas usan opacidad 0,84–0,95, brillo especular, borde suave y absorción/
iluminación interior simulada. El azúcar usa un hash procedural, variaciones
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
idéntico cubo/osito, variante dorada para las 20 frutas, datos intactos, wobble,
transformación, materiales por instancia y esfera del obstáculo.

Para una lámina comparativa externa (crear previamente `/tmp/opencode`):

```bash
XDG_DATA_HOME=/tmp/opencode/gummy-20-render godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script tests/test_gummy_materials.gd -- --capture
```

Se guarda `/tmp/opencode/gummy_20_materials.png`; la lámina usa tamaños uniformes
solo para comparar materiales, sin cambiar las escalas del gameplay.
