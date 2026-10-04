# Tipografía global — Title, Subtitle y Body

## Un solo punto de edición

Abre `themes/ui01_theme.tres` en el Inspector. En **Tipografía global** aparecen:

| Rol | Uso | Tamaño provisional |
|---|---|---|
| **Title** | Marca, títulos de pantallas, celebraciones | 30 |
| **Subtitle** | Nombres de tarjetas, cifras destacadas, subtítulos | 22 |
| **Body** | Descripciones, botones, barras, pestañas, tooltips | 18 |

Cada rol es un `TypographyStyle` con estos campos:

- **Font**: sustituye aquí la fuente provisional por la definitiva.
- **Font Size**, **Color** y **Weight**.
- **Letter Spacing**, **Word Spacing** y **Line Spacing**.
- **Outline Size** y **Outline Color**.

El peso usa el eje `wght` cuando la fuente es variable. Para fuentes estáticas
se aplica engrosado sintético al solicitar un peso superior al original. Para
un acabado definitivo conviene asignar el archivo del peso deseado o una
fuente variable que incluya ese peso.

`TypographyTheme.gd` genera las entradas del Theme desde estos tres recursos,
tanto en el editor como en ejecución. El proyecto también utiliza este Theme
como **GUI → Theme → Custom**, de modo que los nuevos controles heredan Body.

## Herencia y variantes

Las variantes existentes se mantienen como alias de los tres roles:

- `TitleLabel` → Title.
- `SubtitleLabel`, `CardTitle`, `ValueLabel`, `JokerTitle` → Subtitle.
- `CaptionLabel`, `JokerDescription` → Body.
- Button, TabContainer/TabBar, RichTextLabel y TooltipLabel → Body.

Las fuentes y los tamaños no están configurados individualmente en las escenas
ni mediante overrides en sus scripts. La tipografía de las etiquetas de frutas
y del texto flotante también utiliza el tema global.

Los colores de estados y de contraste de botones siguen en el Theme; el color
de rareza y el feedback de gameplay son estados visuales, no fuentes distintas.
Los emojis usan el fallback local Noto Emoji. Su escala de icono se configura
globalmente en `TypographyMetrics/icon_size`; son representación gráfica, no
un cuarto estilo de texto.

**Para cambiar la tipografía futura:** reemplaza Font en Title, Subtitle y Body
y guarda el Theme. No es necesario abrir cada pantalla o componente.

## Ajustes de esta iteración

- Frontales de cartas de elección limpios; nombre y descripción solo en el reverso.
- Comodines activos y descubiertos sin flip: tooltip al hacer hover en PC y
  el mismo tooltip de texto al tocar en móvil.
- Tarjetas reducidas conservando la distribución y los botones táctiles.
- Frutería con emojis provisionales; los bloqueos no indican nombres anteriores.
- Racha y frutas/s equilibradas mediante espacios flexibles 1:2:1 en el HUD.
- Jackpot: dos decimales en prestigio (`7.77`) y tres en mejoras (`0.777`).
  Se mantiene la precisión original de todos los cálculos y probabilidades.

La última iteración se describe en [modales compactos y estadísticas globales](compact-modals-and-item-stats.md).

## Comprobaciones

```bash
XDG_DATA_HOME=/tmp/crazyfruit-type godot --headless --path . --script tests/test_typography.gd
XDG_DATA_HOME=/tmp/crazyfruit-ui godot --headless --path . --script tests/test_ui_layout.gd
XDG_DATA_HOME=/tmp/crazyfruit-shop godot --headless --path . --script tests/test_shop_stats.gd
```

Las pruebas verifican sustitución de fuentes, tamaños, color, peso y espaciados;
herencia de controles reales; interacción de las cartas; presentación del
jackpot sin alterar la economía; geometría del HUD y layouts a cuatro proporciones.
