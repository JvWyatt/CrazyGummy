# Guía de Assets — Crazy Fruit

Estándares de formato, tamaño y peso para TODO asset del proyecto.
Referencia de pantalla: **720x1280 portrait** (Android, densidad xxxhdpi ≈ ×3).
Objetivo de APK: **< 80 MB** (hoy ~150 MB por los `.glb`).

---

## 1. Resumen rápido

| Tipo | Carpeta | Formato | Resolución/Dimensiones | Peso máx | Compresión Godot |
|---|---|---|---|---|---|
| Icono de fruta 2D | `assets/fruits/*.png` | PNG RGBA | **128x128** | 4 KB | ETC2/ASTC |
| Textura de jugo | `assets/fruits/juice/<id>.png` | PNG RGBA (transp.) | **256x256** | 32 KB | ETC2/ASTC |
| Fondos | `assets/ui/backgrounds/*` | PNG RGBA / JPG | **max 1080x1920** | 200 KB | ETC2/ASTC |
| Iconos UI | `assets/ui/icons/*.png` | PNG RGBA | **256x256** (cuadrado) | 30 KB | ETC2/ASTC |
| Paneles (9-slice) | `assets/ui/panels/*.png` | PNG RGBA | 900**x**1240 máx, en 4x4 slice | 25 KB | ETC2/ASTC |
| Fuentes | `assets/fonts/**/*.ttf` | TTF variable | 1 fuente por estilo | 350 KB | GM+MSDF |
| Modelo fruta ENTERA | `assets/models/whole/<id>.glb` | glTF (.glb + Draco) | **≤ 2 M tris, texturas ≤ 1024²** | 2 MB | — |
| Modelo fruta ROTA | `assets/models/broken/<id>.glb` | glTF (.glb + Draco) | **≤ 2 M tris, texturas ≤ 1024²** | 2 MB | — |
| Piedra | `assets/models/rock.glb` | glTF (.glb + Draco) | ≤ 1 M tris, texturas ≤ 512² | 1 MB | — |
| Música | `assets/music/*.ogg` | OGG Vorbis | 44.1 kHz estéreo | ~2 MB/min | — |
| SFX | — (generados por código) | — | — | — | — |
| Splash / boot | `assets/ui/backgrounds/splash.png` | PNG | 720x1280 | 150 KB | ETC2/ASTC |

> Regla de oro: **1 píxel de dibujo ≈ 3 px de export** (xxxhdpi). Un icono que en
> pantalla mide 48 px se exporta a 144 px de lado; redondéalo a potencia de 2
> (128/256) para VRAM y compression.

---

## 2. Frutas 2D — `assets/fruits/*.png`

- **Formato:** PNG RGBA, fondo transparente, cuadrado.
- **Resolución:** 128x128 (mín. 64x64). HOY: `apple.png`=92x92 y
  `watermelon.png`=124x124 → **unifica a 128x128 todas**.
- **Peso:** ≤ 4 KB por fruta (sin ruido, sin degradados con banding).
- **Contenido:** un emoji/silueta de la fruta centrada ocupando ~80% del canvas.
- **Nombrado:** `{id}.png` = clave de `FruitDatabase.gd`
  (strawberry, banana, peach, cherry, orange, apple, pear, kiwi, mango, lemon,
  watermelon, melon, pineapple, papaya, coconut, avocado, dragon_fruit, guava,
  quince, pumpkin).

## 3. Textura de jugo — `assets/fruits/juice/{id}.png`

- **Formato:** PNG RGBA, fondo transparente, **silueta blanca** o con su color (no
  mezclar: el `modulate` de `JuiceSplash` asume una u otra).
- **Resolución:** 256x256. La escala final es normalizada por código (~4.8-19.2 px
  por partícula), así que 128 o 512 también valen.
- **Peso:** ≤ 32 KB.
- **Sin anti-aliasing "sucio":** deja bordes suaves pero sin halos grises.

## 4. UI — `assets/ui/`

### 4.1 Fondos — `backgrounds/`
- **Rango máx.:** 1080x1920 (suficiente para xxxhdpi). Para un fondo a pantalla
  completa en 720x1280 basta **720x1280**; usa 1080x1920 solo si tiene detalle.
- **Sin canal alfa** (el fondo lo tapa todo) → **JPG/WebP ~≤200 KB**. HOY:
  `menu_bg.png` = 1080x1920 RGBA 380 KB → conviértelo a JPG (≈100 KB) o pásalo a
  `720x1280` (≈90 KB). `logo.png` (380x380, 158 KB) → 256x256, ≤50 KB.
- **Splash de arranque:** crea `splash.png` 720x1280 y configúralo en
  `application/boot_splash/*`; tapa el logo de Godot y hace el arranque más
  agradable.

### 4.2 Iconos — `icons/`
- **Estándar: 256x256 cuadrados** (los que ya lo están: money, settings, stats,
  streak0-4… ✅).
- **HOY:** varios NO son cuadrados (prestige 579x526, Joker 558x447, play 550x454,
  info 497x534, confirm 563x536, energy 390x530, close 490x535, cards 431x525).
  → Reescala todos a 256x256 con el arte centrado.
- **Peso:** ≤ 30 KB. `Joker.png` (135 KB) → comprime/posteriza.
- En pantalla se muestran ~40-60 px, así que 256² es lujo necesario para nitidez
  en pantallas altas; no subas de 256.

### 4.3 Paneles 9-slice — `panels/`
- **Ancho máx.:** 900 px (los HUD/panel_card a 1497 px de ancho exceden el doble
  del canvas base). Los 9-slice solo necesitan `margen + 2 px` de zona central;
  el ancho se estira. HOY: `panel_hud_bottom`/`panel_card` = 1497x367 → recórtalos
  a ~300x367 (zonas: esquinas + centro 1 px).
- **Bordes redondeados**: el radio de esquina debe ser ≥ 4 lambd; márgenes en el
  `NinePatchRect` = radio de esquina.

## 5. Fuentes — `assets/fonts/`

- **Usa 1 fuente por estilo** (display + body). Actualmente solo se pre-cargan
  `SkitserCartoon.ttf` (12 KB) y `Cartoonic*` (257 KB).
- **HOY:** `fonts/roboto/` (2.9 MB, 24 archivos TTF + un PDF) está importado y se
  **incluye entero en el APK sin usarse** → bórralo y elimina sus `.import`.
- **Peso:** ≤ 350 KB por fuente. Prefiere **subconjunto solo del rango usado**
  (latin + emoji fallback al sistema).
- **Import:** GM+MSDF con `multichannel_signed_distance_field=true` para
  redondeos nítidos y bajo coste en móvil.

## 6. Modelos 3D — `assets/models/`  ⚠️ PRIORIDAD

Es lo que infla el APK y ralentiza el primer arranque.

**Estado actual:**
| Archivo | Peso | Objetivo |
|---|---|---|
| `whole/strawberry.glb` | 14.5 MB | ≤ 2 MB |
| `broken/strawberry.glb` | 14.5 MB | ≤ 2 MB |
| `rock.glb` | 9.8 MB | ≤ 1 MB |

**Estándar para cada fruta:**
- **Malla:** ≤ 2.000 tris por fruta (fresa ~800, sandía ~2.000). HOY un 1.5 MB ya
  es alto; 14 MB = malla sin decimar o texturas embebidas gigantes.
- **Texturas embebidas:** ≤ 1024x1024 en posma; exportar diffusa 512² + normal
  512² en JPG (~100-150 KB totales). Las texturas ya existen aparte
  (`*_basecolor/normal/rm.jpg`, 30-120 KB) — re-embed las versiones pequeñas.
- **Opción Draco activada en la exportación glTF** (recorta 60-80%).
- **Delega el dibujado:** si el fallback procedural (esfera) queda aceptable para
  las frutas inactivas, exporta `.glb` solo de la seleccionada y usa
  `exclude_filter` en el preset para dejar fuera el resto durante desarrollo.
- **Sin extra rooms:** un `.glb` = un asset; no meter varios modelos por archivo.

**Reglas de autoría (ya implementadas en `Fruit3D.gd`):**
- Origen en el centro; +Y arriba; +Z hacia cámara.
- Modelo ROTO: 2 nodos/grupos = 2 mitades (sin espejo) → obligatorio para
  asimétricas (banana). Para simétricas basta 1 mitad (el juego espeja).
- Radio real = `radius` de FruitData (2x en runtime).

## 7. Audio — `assets/music/`

- **Música:** OGG Vorbis 44.1 kHz estéreo. Objetivo ~2 MB/min. Dos pistas:
  `main_loop.ogg` (menú) y `game_loop.ogg` (juego). Si `ResourceLoader.exists`
  falla → silencio estable (los `AudioStreamWAV` stream crashean en Android).
- **SFX:** se generan por código (sine/noise/saw). Si los reemplazas por archivos,
  usa OGG mono 22 kHz, ≤ 50 KB cada uno.
- **BAD:** MP3/WAV grandes. **GOOD:** OGG cortos y loopables.

## 8. Configuración de export recomendada

En `Project Settings > Rendering > Textures`:
- `vram_compression/import_etc2_astc=true` (ya activo ✅) — todas las PNG.
- Comprime los PNG grandes con `oxipng`/ImageMagick antes de importar.

En el **preset Android** (`export_presets.cfg`):
- `shader_baker/enabled=true` + **Use Gradle Build** → precocina shaders y evita
  el logo congelado del primer arranque.
- `exclude_filter` para desarrollo: excluir `assets/models/broken/*,
  assets/fonts/roboto/*`.
- `architectures/arm64-v8a=true` (ya activo ✅, no subas ABIs).

## 9. Resumen del plan de optimización actual

1. Reescalar `fruits/*.png` a 128x128.
2. Reescalar iconos UI no cuadrados a 256x256; comprimir `Joker.png`.
3. `menu_bg.png` → 720x1280 (o JPG); `logo.png` → 256x256.
4. Recortar paneles de 1497 px de ancho a 9-slice mínimo.
5. Borrar `fonts/roboto/` (+ `.import`) → −2.9 MB de APK.
6. **Decimar + Draco + texturas 512² los 3 `.glb`** → −40 MB aprox.
7. Crear `splash.png` 720x1280 y configurar `boot_splash`.
8. Activar shader baking (Gradle Build) en el preset.