# Modales compactos, tooltips y estadísticas globales

## Información de comodines

Hover y toque usan la misma escena `scenes/ui/components/CardTooltip.tscn`:
texto Body, un fondo ligero y ningún botón, pestaña o ventana de detalle.
Al tocar, se muestra cerca de la carta, se limita a los bordes de la pantalla
y desaparece al volver a interactuar o al terminar su temporizador.

Editables en el Inspector: `preferred_width`, `edge_padding`, `anchor_gap`
y `DismissTimer.wait_time`. El fondo se edita en el StyleBox de esta escena.

## Altura de los modales

Los paneles utilizan `ContentSizedModal.gd`, que mide su contenido real,
incluyendo la pestaña activa y el contenido dentro de ScrollContainers.

- Si cabe, el panel se reduce a su altura natural y se centra verticalmente.
- Si no cabe, su altura se limita a la pantalla y se conserva el scroll.
- Añadir tarjetas o filas de logros recalcula el tamaño automáticamente.
- La adaptación del área segura delega los insets al panel para evitar que
  el centrado sobrescriba márgenes del móvil.

En cada nodo Panel/Card del Inspector se pueden ajustar `max_height_ratio`,
`minimum_height` y `extra_padding`. Anchors horizontales y estilos mantienen
su configuración en la escena.

El mercado utiliza `tab_height_reference = VBox/TabContainer/Mejoras` para
que Frutería y Armas mantengan la altura compacta de Mejoras al cambiar de
pestaña. Su contenido adicional se desplaza dentro de esa misma ventana.

Las tarjetas de frutas y armas tienen proporción **1:1**, incluyendo la acción
de compra. En sus ItemsGrid se edita `card_aspect_ratio = 1.0`, el ancho
preferente, el máximo de columnas y la separación. El padding y la distribución
interna se editan en `CollectionCard.tscn`. El botón de desbloqueo muestra el
precio en una sola línea para aprovechar el espacio de la tarjeta cuadrada.

## Datos de las tiendas

- Frutas: nombre, vida y ganancias mínima/máxima.
- Armas: nombre y daño.
- Las frutas no tienen una propiedad individual de jackpot.
- Las armas no tienen una propiedad individual de gasto de resistencia.

La probabilidad de jackpot procede de las estadísticas globales de mejoras,
prestigio y comodines. La resistencia por corte es común a todas las armas:

`base_energy_cost × resistance_cost_multiplier × card_energy_cost_multiplier`

Los dos primeros parámetros se editan en `data/balance.tres`. Se conserva
el gasto inicial de 1.0 por corte; cambiar de arma ya no modifica ese gasto.
Vida, ganancias y daño siguen siendo características de cada objeto.

## Textos

- Resultados muestra únicamente la reputación obtenida.
- Progreso: **Completa 100 días**.
- Logros: **completados / COMPLETADO**, también en las notificaciones.
- Se elimina el aviso de que la lista restante se revela al superar el objetivo.

Las pruebas de tiendas incluyen todas las armas y sus bonificaciones globales.
Las pruebas de UI comprueban centrado, altura compacta, tooltips dentro de
pantalla y cuatro proporciones de viewport.
