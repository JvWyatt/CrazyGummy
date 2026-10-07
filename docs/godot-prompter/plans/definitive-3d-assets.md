# Integración definitiva 3D — auditoría y mapa previo

Estado: **auditoría histórica, sustituida por la integración completada**.
La instrucción posterior del usuario confirma c5=Corona y c6=Corona Exclusivo,
con sus fuentes existentes idénticas; se integraron sin modificar geometría.
El mapeo vigente y las pruebas están en `CRAZY_GUMMY_PROJECT_GUIDE.md` en raíz.
El resto de este documento conserva la auditoría anterior, no el estado activo.
Se leyó completo `docs/INFORME_GLOBAL.md` y se contrastó con el código activo.

## Arquitectura comprobada

`RecipeDatabase` y `data/catalog.tres` son el catálogo real; no existe una clase
`RecipeCatalog`. Tampoco existe aún `RecipeVisualLibrary`. `Projectile3D` instancia
`GummyVisual`, que actualmente normaliza cube.tscn/bear.tscn (cubo/osito de prueba),
aplica la paleta de materiales y conserva movimiento mediante `Ballistic`.
El obstáculo activo usa una esfera procedural con material lacado, no gris.
La integración futura centralizará únicamente geometría/transformaciones por ID
en RecipeVisualLibrary, sin modificar RecipeData ni el catálogo económico.

## Inspección de fuentes

24 GLB: 16 gummies, 6 cubes y 2 Obstaculos. Se inspeccionaron estructura glTF,
vértices, triángulos, componentes conectados, materiales y vistas frontal,
lateral y superior con material neutro para distinguir forma de acabado.
Todos contienen un MeshInstance3D con una superficie y un material, sin skins
ni animaciones. Los nombres internos son `tripo_node_<UUID>`; no identifican
la receta. g1 incluye una textura JPEG embebida y su imagen extraída/importada.
El resto no incluye imágenes. No se modificaron los GLB.

| Fuente | Geometría observada | Triángulos |
|---|---|---:|
| g1 | Osito clásico | 9514 |
| g2 | Aro liso | 8700 |
| g3 | Aro con espiral, geometría distinta | 9230 |
| g4-5 | Gusano segmentado, compartido | 9608 |
| g6-7 | Botella, compartida | 8096 |
| g8 | Corazón liso | 8967 |
| g9 | Corazón con relieve, geometría distinta | 9480 |
| g10-11 | Pez, compartido | 9054 |
| g12-13 | Cocodrilo, compartido; eje largo Z, requiere vista lateral | 9504 |
| g14 | Tiburón | 9342 |
| g15 | Tiburón Premium, geometría distinta | 9184 |
| g16 | Dragón | 9770 |
| g17 | Dragón Premium con detalles distintos | 9992 |
| g18 | Unicornio | 9762 |
| g19 | Unicornio Premium con relieve distinto | 8870 |
| g20 | Osito con corona integrada | 9838 |
| c1 | Cubo clásico redondeado | 9806 |
| c2 | Cubo ondulado | 8988 |
| c3 | Cubo facetado | 9460 |
| c4 | Cubo con relieve | 10639 |
| c5 | **Fuente incorrecta: actualmente cubo con corona, duplicado de c6** | 10052 |
| c6 | Cubo con corona, exclusivo del tier 20 | 10052 |
| o1 | Caramelo Duro íntegro con fracturas | 8998 |
| o2 | Caramelo Duro Roto, tres componentes desconectados | 9888 |

o2 presenta 3495/1071/384 vértices topológicamente conectados por componente.
No debe tratarse como dos mitades ni espejarse: se deben extraer sus tres piezas
una sola vez para movimiento visual independiente, conservando la fuente.
Islas menores de g8 y c4 son detalles de esos modelos, no variantes de receta.

## Mapeo confirmado antes de implementar

El usuario confirmó los tramos: c1=1–4, c2=5–8, c3=9–12, c4=13–16,
c5=17–19 (Relieve 2), c6=20 (Corona).
Las rutas siguientes son **nombres propuestos, todavía no implementados**.
Prefijos finales previstos: `assets/crazy_gummy/gummies/` y `cubes/`.

| Tier | Recipe ID | Nombre | Gummy fuente → nombre | Cubo fuente → nombre | Acabado existente |
|---:|---|---|---|---|---|
| 1 | bear_classic | Osito Gummy Clásico | g1 → gummy_bear_classic.glb | c1 → cube_classic.glb | gummy/01_ruby.tres |
| 2 | ring | Aro Gummy | g2 → gummy_ring.glb | c1 → cube_classic.glb | gummy/02_honey.tres |
| 3 | ring_premium | Aro Gummy Premium | g3 → gummy_ring_premium.glb | c1 → cube_classic.glb | gummy/03_coral_satin.tres |
| 4 | worm | Gusano Gummy | g4-5 → gummy_worm.glb | c1 → cube_classic.glb | gummy/04_dark_glaze.tres |
| 5 | worm_premium | Gusano Gummy Premium | g4-5 → gummy_worm.glb | c2 → cube_wavy.glb | sugar/05_sugar_coating.tres |
| 6 | bottle | Botella Gummy | g6-7 → gummy_bottle.glb | c2 → cube_wavy.glb | gummy/06_green_glass.tres |
| 7 | bottle_premium | Botella Gummy Premium | g6-7 → gummy_bottle.glb | c2 → cube_wavy.glb | sugar/07_mint_frost.tres |
| 8 | heart | Corazón Gummy | g8 → gummy_heart.glb | c2 → cube_wavy.glb | gummy/08_jade_ribbons.tres |
| 9 | heart_premium | Corazón Gummy Premium | g9 → gummy_heart_premium.glb | c3 → cube_faceted.glb | gummy/09_sunset_gradient.tres |
| 10 | fish | Pez Gummy | g10-11 → gummy_fish.glb | c3 → cube_faceted.glb | sugar/10_sour_sugar.tres |
| 11 | fish_premium | Pez Gummy Premium | g10-11 → gummy_fish.glb | c3 → cube_faceted.glb | gummy/11_bicolor_layers.tres |
| 12 | crocodile | Cocodrilo Gummy | g12-13 → gummy_crocodile.glb | c3 → cube_faceted.glb | gummy/12_aqua_crystal.tres |
| 13 | crocodile_premium | Cocodrilo Gummy Premium | g12-13 → gummy_crocodile.glb | c4 → cube_relief.glb | sugar/13_amber_frost.tres |
| 14 | shark | Tiburón Gummy | g14 → gummy_shark.glb | c4 → cube_relief.glb | gummy/14_tropical_marble.tres |
| 15 | shark_premium | Tiburón Gummy Premium | g15 → gummy_shark_premium.glb | c4 → cube_relief.glb | gummy/15_pearl.tres |
| 16 | dragon | Dragón Gummy | g16 → gummy_dragon.glb | c4 → cube_relief.glb | gummy/16_emerald_depth.tres |
| 17 | dragon_premium | Dragón Gummy Premium | g17 → gummy_dragon_premium.glb | c5 → cube_relief_2.glb (**pendiente**) | sugar/17_amethyst_sugar.tres |
| 18 | unicorn | Unicornio Gummy | g18 → gummy_unicorn.glb | c5 → cube_relief_2.glb (**pendiente**) | gummy/18_cotton_candy.tres |
| 19 | unicorn_premium | Unicornio Gummy Premium | g19 → gummy_unicorn_premium.glb | c5 → cube_relief_2.glb (**pendiente**) | gummy/19_amber_veins.tres |
| 20 | bear_crown | Osito Gummy Corona | g20 → gummy_bear_crown.glb | c6 → cube_crown.glb (**exclusivo**) | sugar/20_cosmic_sparkle.tres |

Se conservarán las seis recetas azucaradas (5,7,10,13,17,20), los ocho colores
equiprobables mediante RNG visual independiente, los acabados del shader y el
oro opaco sobre la geometría correspondiente. Los pares que tienen GLB propios
distintos no se colapsarán en un único mesh.

## Bloqueo comprobado

Después de dos confirmaciones de sustitución se volvieron a leer los binarios.
En esta copia c5 y c6 todavía tienen la misma SHA-256 completa:
`7f0ab72fe420747cccfd23e2b802c263cb40fcc53683fdb837a9f6bdc8ffb3dc`.
Es necesario recibir el Relieve 2 correcto o su ruta real. No se ha renombrado
ni activado la geometría Corona en los tiers 17–19.

Auditoría reproducible: `tools/inspect_glb_structure.py` y
`tools/audit_3d_assets.gd -- --capture`. Evidencia en
`/tmp/opencode/glb_structure.json`, `asset_3d_audit.png` y cuatro páginas
`asset_3d_audit_0.png`–`asset_3d_audit_3.png`.
La huella previa de datos, materiales y lógica se conserva en
`/tmp/opencode/cg_3d_balance_baseline.json`; la comparación arroja cero cambios.

## Próximos pasos

1. Recibir y auditar el c5 corregido, cerrar el mapa completo.
2. Renombrar fuentes/imports con UIDs y bytes conservados; referencias explícitas.
3. Añadir RecipeVisualLibrary e integrar los modelos en GummyVisual.
4. Conectar la rotura de Obstacle con el espejo, separar las tres piezas visuales.
5. Migrar terminología visible a Caramelo Duro, sin renombrar IDs persistentes.
6. Verificar los 20 tiers normal/oro, todas las familias, RNG, efectos, spawn,
   recompensa, físicas y compatibilidad. Capturar la progresión renderizada.
7. Crear CRAZY_GUMMY_PROJECT_GUIDE.md con rutas reales finales y actualizar el
   informe global para retirar afirmaciones provisionales del estado actual.
