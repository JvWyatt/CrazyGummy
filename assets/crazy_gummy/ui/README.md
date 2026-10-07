# Crazy Gummy — kit UI

Arte vectorial original para la dirección **confitería nocturna**. Sin texto
funcional horneado. El control determina tamaño; el asset se adapta.

- `buttons/gel_surface.svg`: superficie 96×48 compartida por botones. 9-slice:
  izquierda/derecha 26, arriba/abajo 20. Colores/estados en GummyDesignSystem.
- `backgrounds/menu.svg`: composición expresiva 720×1600 con espacio central.
- `backgrounds/gameplay.svg`: escenario neutro 720×1600 con detalle periférico.
- `cards/front.svg`, `back.svg`: 352×512 (11:16); arte compartido, rareza y textos
  añadidos por Godot, no por la imagen. CardFlipWidget conserva su geometría.
- `icons/symbols.svg`: atlas 12×64 px; navegación y categorías informativas.
- `icons/tools.svg`: atlas 10×64 px; orden canónico, luz superior, mango aqua y
  cabeza perlada. Respaldo: las tarjetas activas ahora utilizan arte proporcionado
  en `collection/*.png`.
- `collection/*.png`:30 ilustraciones del usuario para10 herramientas y20 recetas.
  Solo se retira gris exterior; azul y objeto se conservan. CollectionArt comparte
  las texturas y CollectionCard usa un frente cuadrado con nombre superpuesto.
- `icons/slider_thumb.svg`: perilla 32×32; el target táctil sigue siendo 56 de alto.
- `effects/hardened_candy.*`: acabado 3D opaco compartido para el obstáculo; no
  transparencia de pantalla, TIME, RNG, nuevas colisiones ni mecánicas.

Estilos: `scripts/ui/GummyDesignSystem.gd`, instalados por el TypographyTheme
existente. El reflejo `GummySurface.gd` es estático y no captura input. Detalles y
reglas para futuras pantallas en `docs/INFORME_GLOBAL.md`, sección Design System.
