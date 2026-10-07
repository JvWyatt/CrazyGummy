# Ilustraciones proporcionadas — armas/herramientas y recetas

Fuentes intactas: `assets/crazy_gummy/Armas/A1–A10.jpeg` y
`assets/crazy_gummy/Recetas/G1–G20.jpeg`, en el orden canónico del catálogo.

**Corrección explícita del usuario: se elimina solo el gris exterior. El fondo
azul se conserva**, junto con toda la ilustración y sus reflejos/materiales.
Los PNG tienen transparencia fuera de la placa azul y un borde descontaminado.

- Lado máximo512px, recorte al contorno azul y padding6px.
- Proporción conservada; sin deformación ni reconstrucción de arte.
- JPEG nunca cargados por las tarjetas; PNG preimportados, compartidos por ID en
  `scripts/ui/CollectionArt.gd`, incluidos mediante referencias explícitas.
- CollectionCard conserva frente/reverso, estados y acción. Arte en todo el frente,
  nombre superpuesto con contorno centrado verticalmente sobre la ilustración,
  con el mismo tamaño/formato en armas y recetas, sobre una banda semitransparente
  que conserva visible la imagen; sin texto «Datos» ni símbolo de giro.
  El panel azul integra el arte con la tarjeta y el toque sigue mostrando el reverso.
- Rejillas existentes con mismas columnas por ancho y separaciones. El frente es
  cuadrado y ocupa únicamente el área del arte; el nombre no reserva altura.
  La altura natural suma solo ese frente, la acción de48px y el padding existente.

Regenerar fuera del juego:

```bash
python tools/prepare_collection_art.py
```

Requiere Pillow, numpy y opencv-python-headless. Hojas de revisión en
`/tmp/opencode/collection_sources.png` y `collection_cutouts.png`.
