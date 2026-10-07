# Prueba visual Crazy Gummy: fresa

> **Documento histórico**, anterior a la migración de clases, rutas e IDs.
> Para trabajar en el proyecto actual, leer
> [INFORME_GLOBAL.md](../../INFORME_GLOBAL.md).

> Actualización: la presentación se reutiliza ahora en las 20 frutas con un
> catálogo visual por tier. Ver `assets/crazy_gummy/README.md` para materiales,
> distribución y organización. Este documento conserva los detalles del flujo
> original de impacto, partículas y transformación, que sigue siendo el mismo.

La fresa mantiene el identificador `strawberry` y todos sus datos originales.
Su espejo `Fruit3D` instancia `scenes/game/GummyVisual.tscn` como presentación
visual: cubo coloreado → impacto elástico → fragmentos cúbicos → un osito.

## Assets

- `assets/models/gummy/cubo.glb`: modelo entero.
- `assets/models/gummy/osito.glb`: producto terminado.
- Los JPG de esa carpeta los extrae el importador de Godot desde los GLB.
  Son las texturas originales, compartidas por todos los colores.

## Ajustes en el Inspector

Abrir `scenes/game/GummyVisual.tscn`:

- **GummyVisual / Color de gelatina**: paleta, color de respaldo y rugosidad.
  La paleta vacía utiliza el respaldo. Los materiales se duplican por instancia;
  el albedo tiñe las texturas originales sin generar texturas por color.
- **GummyVisual / Impacto**: squash, stretch y sus duraciones. Solo se deforma el
  contenedor `Cube`, nunca la fruta 2D ni el espejo 3D. Cada impacto cancela el
  tween anterior y reinicia desde la forma original. No hay wobble de idle.
  Los ratios de emisión ajustan el área y la profundidad de los fragmentos de
  impacto para que no queden ocultos dentro del modelo.
- **GummyVisual / Producto terminado**: escala relativa, orientación, posición,
  entrada y movimiento de respaldo del osito. Los modelos se centran y normalizan
  al tamaño visual original de la fresa. En juego hereda la velocidad, gravedad,
  paredes y límite de escape del cubo al romperse. Aparece de frente usando
  `product_rotation_degrees` y se balancea solo en Z, con amplitud máxima de
  18 grados y velocidad configurable. No hereda la inclinación 3D del cubo,
  para que la figura permanezca vertical y su cara sea visible durante la caída.
- **Burst**: cantidad, duración, velocidad, gravedad y tamaños de fragmento.
  Por defecto son **36 partículas CPU de 0,45 segundos** al romperse.
- **HitBurst**: por defecto **4 partículas CPU de 0,25 segundos por golpe**.
  Los impactos consecutivos reinician la emisión con una nueva semilla visual.
  Ambos bursts usan materiales propios teñidos directamente con el color del
  cubo; el color de vértices queda blanco y la rampa controla únicamente el fade.
  Son compatibles con GL Compatibility y reducen tamaño/alpha al terminar.
- **Fruit3D / strawberry_visual_scene**: referencia a esta presentación visual.

`GummyVisual.set_color(color)` permite aplicar posteriormente colores especiales
con estos mismos modelos. En esta prueba los colores no determinan el estado
dorado ni ninguna recompensa. La paleta tiene su propio generador aleatorio.

## Integración

`Fruit.take_damage()` conserva el daño, cooldown, sonidos y textos originales y
emite `fruit_hit` para el feedback del espejo. El espejo gummy activa
`custom_hit_particles` para sustituir la salpicadura roja de la fresa por los
cuadritos del color del cubo. Las demás frutas mantienen su salpicadura original.
`Fruit.die()` conserva
íntegramente su cálculo de recompensa y registro de corte. La señal original
`fruit_destroyed` activa `Fruit3D.break_apart()`, que para la fresa muestra el
producto entero y su burst. El producto utiliza una instancia del componente
**Ballistic existente** para continuar la parábola y los rebotes. Se libera el
espejo al salir por abajo, como los cubos, después de terminar las partículas.

Los recursos de frutas, balance, spawner, movimiento, rocas, estadísticas,
progresión, textos y UI mantienen sus valores y lógica originales.

## Verificación

Prueba de integración sin addons, con datos de usuario aislados:

```bash
XDG_DATA_HOME=/tmp/opencode/gummy-test godot --headless --path . --script tests/test_gummy_visual.gd
```

Cubre el spawn real de la fresa, tamaño visual, daño, impactos consecutivos,
recuperación de forma, colisiones, color de ambos bursts por instancia, pocos
fragmentos por golpe, sustitución de salpicaduras rojas, ruptura abundante,
osito único, herencia de gravedad/velocidad/rebotes, desplazamiento y balanceo
frontal incluso cuando el cubo muere tumbado y de espaldas,
limpieza y comparación de recompensas/Jackpot con el flujo sin presentación
gummy, tanto para fresas normales como doradas. Comprueba además otra fruta y
una roca, y que la selección de paleta no consume el RNG global.

Para capturas con renderizado real, ejecutar sin `--headless`:

```bash
XDG_DATA_HOME=/tmp/opencode/gummy-render godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script tests/test_gummy_visual.gd -- --capture
```

La opción guarda `gummy_spawn.png`, `gummy_hit.png`, `gummy_burst.png` y
`gummy_bear.png` en `/tmp/opencode` (la carpeta debe existir).

Verificado con Godot 4.5.1 y renderizador GL Compatibility: **73 comprobaciones,
0 fallos**, incluyendo revisión de las cuatro capturas. La regresión existente
`tests/test_shop_stats.gd` también pasa: **102 comprobaciones, 0 fallos**.
