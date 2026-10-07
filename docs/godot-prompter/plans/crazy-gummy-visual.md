# Rediseño integral — mapa de implementación

Referencia: `docs/INFORME_GLOBAL.md` (guía consolidada vigente). El árbol local
contiene la migración previa; este trabajo continúa sobre esos archivos.

## Inventario y dirección

- Global: TypographyTheme y UiTheme; tres roles tipográficos conservados.
- Theme: superficies tinta ciruela, texto perla, acción aqua, feedback coral,
  éxito menta; oro exclusivamente premium/Bonus. Tabs, barras, sliders,
  scrollbars, scrim y familias ModalPanel/Card/CompactCard/StatPanel/ToastPanel.
- StyleBoxFlat: paneles y tarjetas informativas con borde perlado y sombra.
- 9-slice: una superficie vectorial gelatinosa para todos los botones y estados.
  El control fija las medidas; el SVG no impone su tamaño mínimo.
- Assets: fondos vectoriales diferenciados menú/juego, anverso y reverso 11:16,
  atlas de iconos de navegación/estadísticas y atlas coherente de 10 herramientas.
- Mantener: Containers, ResponsiveGrid, ContentSizedModal, SafeAreaLayout,
  TouchScrollContainer, dimensiones táctiles, flip, navegación y todo dato.
- Sustituir presentación: fondo heredado, damero, Joker2/back, emojis de herramientas
  y componentes, esfera gris. Conservar archivos anteriores como fallback/historia.
- Dinámicos: CardFlipWidget (rareza en texto y motivos además de color), ShopCard,
  CollectionCard (estados de compra), StatCard, filas de logros, tooltip y toast.
- Motion: presión inmediata, retorno corto elástico, apertura existente, compra
  y hitos puntuales; sin animaciones decorativas permanentes ni RNG añadido.

## Orden y validación

1. Theme + componentes; Mercado como piloto con sus tres pestañas.
2. Menú/HUD y propagación a todos los modales y contenido generado.
3. Arte especial y polish.
4. Regresiones existentes con XDG_DATA_HOME independiente, capturas renderizadas
   en 720×960, 720×1280, 720×1600 y 960×1280, revisión de estados/textos grandes.
5. Actualizar informe global preservando documentación técnica e historia.

## Cierre

Implementado y validado en Godot4.7.2. Las12 regresiones aplicables pasan;
layout final7200 checks y touch35. Revisión renderizada del Main real:56
capturas (14 estados ×4 tamaños), además de capturas de escenas/reversos.
Correcciones encontradas en QA: mínimo del scrollbar, grosor de pistas,
contraste Bonus, nombre/potencia del HUD y estado vacío de Logros.
Design System documentado en el informe global y assets en el README del kit.
