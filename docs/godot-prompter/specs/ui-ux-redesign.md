# Crazy Fruit — pasada UI/UX móvil

## Diagnóstico de la UI anterior

La arquitectura existente era aprovechable: tema global, Containers, scroll
táctil, ResponsiveGrid, tarjetas compartidas y señales de gameplay. Se ha
conservado ese flujo y la lógica de economía, desbloqueos y comodines.

Los principales problemas detectados:

- HUD: tres barras con idéntica jerarquía, etiquetas pequeñas y contadores
  redundantes; combo y producción ocupaban piezas separadas sobre el área de corte.
- Menú: acciones de importancia muy distinta en una sola columna; el reinicio
  permanente tenía demasiada presencia junto a Jugar.
- Modales: rectángulos centrados de altura fija y encabezados demasiado largos
  compitiendo con saldo y cierre.
- Tiendas: descripciones de 10–13 px y tarjetas construidas íntegramente en código.
- Colección: requisitos de bloqueo disponibles únicamente en tooltips, poco útiles
  en una pantalla táctil.
- Estadísticas: nombres redundantes desplazaban el protagonismo de las cifras.
- Comodines: botones pequeños y descripciones susceptibles de quedar recortadas.
- Iconos Unicode: dependencia de las fuentes del dispositivo, con glifos ausentes
  detectados durante la revisión de capturas reales.

## Dirección visual

**Arcade frutal sobre azul tinta.** Se conserva la ilustración del menú y la
tipografía cartoon para marca, títulos y nombres de tarjetas. Roboto concentra
el trabajo de lectura: cifras, botones, descripciones y etiquetas.

- Mango/dorado: objetivo, recompensa y acción principal.
- Menta: ganancias, progreso y logro conseguido.
- Azul: estamina.
- Coral: tiempo y urgencia.
- Superficies oscuras, marcos redondeados, sombra contenida y separación regular.
- Los estados siempre usan texto además del color: EN USO, DISPONIBLE,
  POR DESCUBRIR, DESBLOQUEAR y MEJORAR.

Escala tipográfica habitual: 18 px para texto auxiliar, 20 px para cuerpo y
acciones, 22 px para nombres, 30 px para cifras importantes y 32 px para títulos.
Son unidades de diseño del viewport 720, escaladas por `canvas_items`.

**Actualización:** esta escala se ha sustituido por tres roles globales editables:
Title (30), Subtitle (22) y Body (18). Consulta la [guía de tipografía](global-typography.md).

## Cambios por pantalla

### HUD

Un bloque superior contiene día/negocio, objetivo de dinero dominante, tiempo y
estamina en paralelo, y una fila de combo/producción/multiplicador. El anillo de
racha mantiene su progreso y el feedback existente. El reloj expresa segundos
restantes; la barra comunica la proporción, evitando repetir el tiempo total.
El arma y las acciones secundarias forman una zona inferior anclada al borde.

### Menú

Ilustración y marca, reto, Jugar dominante, cuadrícula 2×2 de navegación y Ajustes.
Reiniciar progreso está dentro de Ajustes. La entrada utiliza opacidad para no
alterar los offsets de los anchors mientras se anima.

### Mercado y prestigio

Encabezados cortos, saldos legibles y cierre de 56 unidades. Grids automáticos de
hasta dos columnas con 240 unidades de ancho preferente. Cada mejora presenta
nombre, nivel, valor actual, incremento y acción de compra. Prestigio explica que
sus mejoras son permanentes. El valor comprado recibe un pulso breve.

Frutería y armas usan la misma escena de colección: arte, nombre, pista para girar
y acción. Las frutas utilizan emojis provisionales. El bloqueo conserva el
misterio del objeto sin mostrar nombres de requisitos anteriores.
Un arrastre para navegar no se interpreta como un giro.

### Comodines

Galería de miniaturas compactas, hasta tres columnas y descripción breve. Las cartas
de selección ajustan su ancho al espacio disponible. El nombre aparece en el
reverso; los reversos de selección pueden desplazarse para leer la descripción completa.
Los comodines activos y descubiertos no se giran: hover en PC, toque en móvil.
Elegir sigue siendo una acción separada del giro y utiliza el tema principal.

### Estadísticas y progreso

Cifras grandes en tarjetas compartidas y nombres resumidos, manteniendo unidades
`x` y `%`. Progreso añade el hito de 100 días con barra y récord; muestra negocios
iniciados, frutas históricas y comodines descubiertos, evitando repetir el récord.

### Logros, resultados, pausa, ajustes y confirmaciones

Comparten la superficie modal, los márgenes y la jerarquía tipográfica. Logros
admite textos multilineales y scroll táctil. Resultados destaca la reputación
obtenida. Pausa mantiene Continuar como acción dominante. Sliders con zona táctil
de 56 unidades. Confirmaciones usan botones verticales para acomodar textos largos.

## Qué editar desde el Inspector

| Ajuste | Recurso o escena | Propiedades |
|---|---|---|
| Fuentes globales | `themes/ui01_theme.tres` | Inspector → Tipografía global → Title, Subtitle, Body |
| Paleta y estilos | `themes/ui01_theme.tres` | Theme Editor: colores y StyleBoxFlat |
| Intensidad y duración del feedback | Theme, grupo Motion | hover_scale_percent, pop_start_percent, pulse_peak_percent y duraciones en ms |
| Tarjetas de mejoras | `scenes/ui/components/ShopCard.tscn` | Content separation, minimum sizes, variantes de texto, botón |
| Frutas/armas | `scenes/ui/components/CollectionCard.tscn` | Face minimum size, arte, tipografía, bloqueo, botón, flip_time, tap_slop |
| Tarjeta de estadística | `scenes/ui/components/StatCard.tscn` | Altura mínima, separación, Header, ValueLabel |
| Composición del HUD | `scenes/ui/HUD.tscn` | TopContainer, Resources, Telemetry, BottomContainer y Theme Overrides |
| Anillo de racha | Nodo StreakRing en HUD | Colores, ring_width, inner_width y minimum size |
| Menú | `scenes/ui/MainMenu.tscn` | Anchors de CenterVBox, Logo, NavigationGrid y separaciones |
| Altura/ancho de modales | `scenes/ui/*Modal.tscn`, nodo Panel | max_height_ratio, minimum_height, extra_padding y anchors horizontales |
| Grids de tienda | ItemsGrid en cada pestaña | min_card_width, max_columns, h/v_separation, uniform_card_size |
| Grid de estadísticas | Raíz de `StatsModal.tscn` | card_min_width, max_columns, grid_separation |
| Galería de comodines | Raíz de `CardsModal.tscn` | thumbnail_width, CardsGrid y panel de descripción |
| Cartas seleccionables | Raíz de `CardSelectionModal.tscn` | card_max_width; separación de CardsHBox |
| Textos de comodines | Theme → Subtitle y Body | Los alias JokerTitle/JokerDescription heredan estos roles |
| Área segura | `scenes/Main.tscn`, SafeAreaLayout | targets y preview_insets (izquierda, arriba, derecha, abajo) |

En Godot los equivalentes de RectTransform y Layout Groups son **Control con
anchors/offsets** y **Container**. PanelContainer suma el padding del StyleBox;
VBox/HBox/Grid distribuyen el espacio según los mínimos y Size Flags. El
escalado de Canvas Scaler corresponde a los ajustes de stretch del proyecto.

Se mantiene `canvas_items` + `keep_width`, apropiado para el juego portrait.
SafeAreaLayout transforma el área segura del dispositivo a unidades del viewport
y ajusta los offsets conservando los anchors y los márgenes definidos en escena.
`preview_insets` permite simular un notch y la navegación inferior en escritorio.

## Verificación reproducible

Se ha usado Godot 4.5.2. Las pruebas de integración comprueban escenas reales,
contenido dinámico, pestañas, reversos, detalle, pausa, ajustes, textos largos y
márgenes seguros simulados en 720×960, 720×1280, 720×1600 y 960×1280.

La iteración añade pruebas de tipografía global y mantiene las 72 de tiendas.
También se ha arrancado la escena principal y revisado las capturas renderizadas.

```bash
XDG_DATA_HOME=/tmp/crazyfruit-ui godot --headless --path . --script tests/test_ui_layout.gd
XDG_DATA_HOME=/tmp/crazyfruit-shop godot --headless --path . --script tests/test_shop_stats.gd
```

Las capturas se pueden generar con un servidor gráfico disponible:

```bash
XDG_DATA_HOME=/tmp/crazyfruit-ui godot --path . --script tests/test_ui_layout.gd -- --capture
```

El destino por defecto es `/tmp/opencode`. Las capturas usan un SubViewport para
renderizar las dimensiones exactas sin depender de los límites de la ventana del
escritorio. `--capture-dir=<carpeta existente>` guarda únicamente la serie 720×1280
en la carpeta elegida. Las capturas son una maqueta de integración con datos de
prueba; el HUD se captura sin frutas del mundo y con insets simulados 48/32.

Noto Emoji se incluye como respaldo local de glifos (licencia OFL adjunta). Así
los símbolos no dependen del catálogo de fuentes instalado en Android o Linux.

La revisión automática de geometría complementa la inspección visual; la zona
segura física y el tacto final se deben contrastar en un dispositivo Android real.
