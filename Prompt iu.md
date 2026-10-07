# CRAZY GUMMY — REDISEÑO VISUAL INTEGRAL

## MISIÓN

Vas a trabajar directamente sobre un proyecto existente en Godot 4.x llamado:

# CRAZY GUMMY

La migración temática e interna desde el proyecto anterior YA TERMINÓ.

Crazy Gummy ya utiliza conceptualmente y, salvo compatibilidad documentada, también internamente:

- cubos de gelatina;
- gomitas;
- recetas;
- herramientas;
- potencia;
- dureza;
- resistencia;
- ritmo;
- comodines;
- mejoras;
- prestigio;
- reputación;
- Jackpot;
- gomitas doradas;
- Caramelo Endurecido;
- etc.

NO vuelvas a realizar la migración temática.

NO vuelvas a renombrar sistemas por iniciativa propia.

Esta segunda fase tiene una misión diferente:

> **Crazy Gummy ya ES Crazy Gummy.  
> Ahora haz que PAREZCA Crazy Gummy.**

Quiero transformar la interfaz funcional actual en una interfaz de videojuego móvil con identidad visual propia, reconocible y profesional basada en gomitas, gelatina, azúcar y caramelos.

Debes actuar simultáneamente como:

- Senior Game UI/UX Designer;
- Game UI Artist;
- Technical UI Artist;
- Godot UI Engineer.

Tienes amplia libertad artística.

Pero esa libertad termina donde comienzan:

- gameplay;
- balance;
- economía;
- persistencia;
- IDs;
- datos;
- navegación;
- condiciones;
- fórmulas;
- comportamiento funcional.

---

# 1. FUENTE DE VERDAD OBLIGATORIA

ANTES DE MODIFICAR NADA, localiza y lee COMPLETO:

`CRAZY_GUMMY_PROJECT_GUIDE.md`

Puede existir con una variante del nombre equivalente. Utiliza la versión MÁS RECIENTE.

## ESTA GUÍA ES LA FUENTE PRINCIPAL DE VERDAD DEL PROYECTO

Fue generada después de la migración interna definitiva.

Contiene el estado real de:

- arquitectura;
- pantallas;
- navegación;
- jerarquía UI;
- HUD;
- componentes reutilizables;
- responsive;
- safe areas;
- Theme;
- tipografía;
- gameplay;
- recetas;
- herramientas;
- comodines;
- rarezas;
- mejoras;
- prestigio;
- estadísticas;
- logros;
- assets;
- persistencia;
- migración;
- deuda conocida;
- pruebas.

Si encuentras documentación anterior que contradice esta guía:

**la guía actual prevalece.**

Y si la guía difiere del código activo actual:

1. investiga la diferencia;
2. considera el código/Resources actuales como implementación real;
3. no cambies comportamiento para obligarlo a coincidir con documentación antigua;
4. documenta cualquier discrepancia relevante.

---

# 2. AUDITORÍA ANTES DE DISEÑAR

NO empieces cambiando colores inmediatamente.

Primero inspecciona el sistema visual completo.

Revisa:

- `Main.tscn`;
- HUD;
- menú principal;
- gameplay;
- mercado;
- Mejoras;
- Recetas;
- Herramientas;
- selección de comodines;
- galería de comodines;
- Prestigio;
- Progreso;
- Datos/Estadísticas;
- Logros;
- Resultados;
- Créditos;
- Ajustes;
- Pausa;
- confirmaciones;
- tooltips;
- toast de logros;
- barras;
- tarjetas;
- botones;
- tabs;
- modales;
- componentes reutilizables;
- UI creada dinámicamente;
- Theme;
- TypographyTheme;
- UiTheme;
- overrides locales;
- iconos;
- emojis;
- fondos;
- assets provisionales;
- assets heredados;
- shaders/materiales relevantes;
- animaciones.

Debes comprender primero:

**qué es global, qué es reutilizable y qué es específico.**

No quiero 15 pantallas rediseñadas independientemente.

Quiero UN sistema visual Crazy Gummy aplicado a todo el juego.

---

# 3. DOCUMENTA TU MAPA DE TRABAJO

Antes de hacer cambios grandes, genera internamente un inventario breve de:

- componentes globales;
- estilos reutilizables;
- elementos que deben resolverse mediante Theme;
- elementos que necesitan StyleBox;
- elementos candidatos a 9-slice;
- elementos que realmente necesitan un asset;
- elementos provisionales que deben sustituirse;
- elementos que deben mantenerse;
- elementos creados por código que también deben actualizarse.

No necesito que detengas el trabajo esperando aprobación.

Este inventario es para evitar rediseños duplicados o inconsistentes.

---

# 4. OBJETIVO ARTÍSTICO

Crazy Gummy debe tener una identidad visual reconocible incluso si ocultamos el logo.

Debe evocar:

- gomitas;
- gelatina;
- caramelos;
- azúcar;
- translucidez;
- elasticidad;
- suavidad;
- brillo;
- volumen;
- color;
- recompensa;
- satisfacción.

Pero NO quiero una interfaz infantil genérica.

Tampoco quiero simplemente:

- botones rosados;
- emojis;
- esquinas redondeadas;
- un fondo lleno de caramelos.

Quiero una dirección artística real.

Debe sentirse:

**dulce + táctil + pulido + moderno + divertido + legible.**

---

# 5. PRINCIPIO VISUAL: GUMMY SIN SACRIFICAR UX

Puedes utilizar:

- superficies suaves;
- esquinas redondeadas;
- volumen;
- highlights;
- sombras suaves;
- translucidez controlada;
- reflejos;
- gradientes;
- bordes luminosos;
- detalles azucarados;
- burbujas;
- pequeñas imperfecciones de gelatina;
- profundidad;
- capas;
- squash/stretch;
- wobble;
- elasticidad.

Pero NO conviertas cada elemento en una gomita transparente.

La interfaz debe seguir siendo extremadamente legible.

Usa el lenguaje gummy estratégicamente.

---

# 6. CREA UN CRAZY GUMMY UI DESIGN SYSTEM

Antes de propagar el rediseño, establece un sistema visual reutilizable.

Define coherentemente:

## Color

- fondo;
- superficie primaria;
- superficie secundaria;
- superficie elevada;
- texto principal;
- texto secundario;
- acento principal;
- acento premium;
- éxito;
- advertencia;
- peligro;
- disabled;
- rarezas.

## Forma

Define:

- radios;
- bordes;
- profundidad;
- sombras;
- highlights;
- separación;
- padding.

## Tipografía

Respeta el sistema de roles existente.

No disperses tamaños arbitrarios.

## Componentes

Define familias para:

- botones;
- paneles;
- cards;
- modales;
- tabs;
- barras;
- badges;
- iconos;
- tooltips;
- notificaciones.

## Motion

Define un lenguaje coherente para:

- hover;
- pressed;
- apertura;
- cierre;
- compra;
- desbloqueo;
- Bonus;
- rareza;
- racha;
- logro.

---

# 7. NO RECONSTRUYAS UNA ARQUITECTURA QUE YA FUNCIONA

El proyecto ya posee:

- Containers;
- ResponsiveGrid;
- ContentSizedModal;
- TouchScrollContainer;
- SafeAreaLayout;
- Theme centralizado;
- componentes reutilizables;
- layouts responsive.

CONSERVA ESTA ARQUITECTURA siempre que sea posible.

No sustituyas Containers por coordenadas manuales.

No hardcodees posiciones para 720×1280.

No reconstruyas una pantalla funcional simplemente porque prefieres otra jerarquía de nodos.

Puedes modificar estructura cuando exista una razón UX/técnica clara, pero debe seguir siendo responsive.

---

# 8. RESOLUCIONES OBLIGATORIAS

Debes conservar compatibilidad como mínimo con:

- 720×960;
- 720×1280;
- 720×1600;
- 960×1280.

La orientación es vertical.

El proyecto utiliza `keep_width`.

NO asumas altura fija.

Prueba todas estas resoluciones durante el trabajo y al finalizar.

---

# 9. SAFE AREAS

Respeta completamente el sistema existente de safe areas.

No coloques información crítica o controles interactivos en zonas inseguras.

Si introduces nuevos paneles importantes, verifica si deben añadirse a `SafeAreaLayout`.

---

# 10. TOUCH PRIMERO

Crazy Gummy es un juego móvil.

Diseña pensando primero en dedo, no ratón.

Mantén hit areas cómodas.

No reduzcas controles importantes por estética.

Especialmente:

- Comprar;
- Elegir;
- Continuar;
- Jugar;
- cerrar;
- Pausa;
- Datos;
- navegación;
- tabs.

El estado `pressed` es más importante que `hover`.

---

# 11. THEME

El proyecto posee un Theme centralizado.

EVOLUCIÓNALO.

No crees cientos de overrides locales.

Utiliza:

- Theme;
- Theme Type Variations;
- StyleBoxFlat;
- StyleBoxTexture;
- Gradient;
- shaders UI cuando tengan sentido;
- recursos reutilizables.

Centraliza todo lo razonablemente posible.

---

# 12. NO TE LIMITES AL THEME

La guía documenta elementos con overrides o generación por código.

Inspecciona especialmente:

- toast;
- barras;
- CompactCard;
- rarezas;
- modulaciones;
- CardFlipWidget;
- StreakRing;
- GummyVisual;
- controles generados dinámicamente.

Editar únicamente el `.tres` del Theme NO constituye un rediseño completo.

---

# 13. ASSETS — TIENES PERMISO PARA CREARLOS

Tienes permiso para generar o crear los assets visuales que necesites.

NO me pidas que produzca manualmente cada textura.

Pero no generes imágenes por costumbre.

Antes de crear un asset pregúntate:

1. ¿Puede resolverse mejor con Theme?
2. ¿Puede resolverse con StyleBox?
3. ¿Puede ser vectorial?
4. ¿Puede ser un shader/material?
5. ¿Necesita realmente raster?
6. ¿Puede reutilizarse?
7. ¿Debe ser 9-slice?

Si una imagen es realmente la mejor solución:

**créala.**

---

# 14. REGLA FUNDAMENTAL DE ASSETS

> EL CONTROL DETERMINA EL TAMAÑO.
> EL ASSET SE ADAPTA AL CONTROL.

Nunca permitas que un PNG obligue al botón a adoptar dimensiones incorrectas.

Utiliza cuando corresponda:

- NinePatchRect;
- StyleBoxTexture;
- 9-slice;
- stretch modes;
- margins;
- anchors;
- Containers.

Evita completamente:

- esquinas deformadas;
- bordes estirados;
- clipping;
- imágenes aplastadas;
- botones que solo funcionan en una resolución.

---

# 15. TEXTO NO HORNEADO

NO generes imágenes que contengan texto dinámico o funcional como:

- Jugar;
- Comprar;
- Elegir;
- Continuar;
- Prestigio;
- precio;
- nivel;
- estadísticas;
- nombres de recetas;
- nombres de herramientas.

El texto debe seguir siendo texto real de Godot.

---

# 16. UI KIT

Si aporta valor, crea una pequeña biblioteca reutilizable bajo una estructura organizada como:

`assets/crazy_gummy/ui/`

con categorías únicamente cuando sean necesarias, por ejemplo:

- `buttons/`
- `panels/`
- `cards/`
- `icons/`
- `backgrounds/`
- `decorations/`
- `effects/`

No crees carpetas vacías.

No dupliques assets.

Un buen asset reutilizable vale más que veinte PNG casi iguales.

---

# 17. TIPOGRAFÍA

Respeta los roles tipográficos existentes.

Puedes ajustar el sistema global si mejora el diseño.

Mantén:

- fuente display para personalidad;
- fuente Body para lectura;
- jerarquía clara.

NO reduzcas globalmente la fuente para solucionar un único texto largo.

Resuelve esos casos mediante layout.

Prueba nombres largos reales.

---

# 18. PALETA

Construye una paleta que conviva con gomitas de muchos colores.

IMPORTANTE:

El color de una gomita NO identifica permanentemente una receta.

Por tanto, la interfaz no puede depender de:

"rojo = receta X".

La UI debe proporcionar una base suficientemente estable para que gomitas:

- rojas;
- azules;
- verdes;
- aqua;
- amarillas;
- rosas;
- moradas;

continúen destacando.

---

# 19. DORADO

El dorado debe conservar significado especial.

Úsalo para:

- Bonus;
- premios;
- premium;
- doradas;
- elementos realmente importantes.

NO conviertas toda la interfaz en dorada.

---

# 20. MENÚ PRINCIPAL

Rediseña el menú para que sea la primera declaración visual de Crazy Gummy.

Debe comunicar inmediatamente la identidad del juego.

Puedes sustituir el fondo provisional.

Puedes introducir:

- cubos;
- gomitas;
- formas gelatinosas;
- burbujas;
- caramelos;
- profundidad;
- iluminación;
- decoración flotante.

Pero el foco debe continuar siendo:

- logo;
- Jugar;
- navegación.

La decoración debe ignorar input.

---

# 21. GAMEPLAY — PRIORIDAD DE LEGIBILIDAD

El gameplay debe recibir identidad Crazy Gummy SIN quedar saturado.

Durante una partida ya existen:

- cubos;
- gomitas;
- partículas;
- movimiento;
- trazos;
- obstáculos.

Por tanto:

**HUD más limpio que menú/mercado.**

Mantén claramente accesibles:

- día;
- negocio;
- dinero;
- meta/Bonus;
- tiempo;
- resistencia;
- racha;
- ritmo;
- herramienta;
- potencia;
- Datos;
- Pausa.

No elimines información funcional.

---

# 22. DINERO / META / BONUS

No confundas visualmente:

- saldo;
- progreso generado;
- meta;
- Bonus.

Son conceptos diferentes.

Diseña una barra clara y atractiva.

Cuando se alcance la meta, el estado Bonus puede transformarse visualmente mediante:

- dorado;
- glow;
- pulso;
- confeti existente;
- cambio de acabado;
- pequeño feedback gummy.

No cambies su lógica.

---

# 23. TIEMPO Y RESISTENCIA

Deben distinguirse visualmente sin depender exclusivamente de leer el texto.

Mantén alta legibilidad durante gameplay rápido.

No los hagas tan ornamentados que el valor deje de ser protagonista.

---

# 24. RACHA

El anillo de racha es un elemento ideal para identidad Crazy Gummy.

Conserva:

- contador;
- progreso;
- hitos;
- multiplicador.

Puedes convertir visualmente el anillo en:

- gelatina;
- líquido;
- azúcar;
- aro gummy;
- brillo dinámico.

Utiliza feedback en hitos:

- pulso;
- squash;
- pequeño rebote;
- glow;
- partículas discretas.

El multiplicador temporal debe continuar siendo muy perceptible.

---

# 25. RITMO

`cubos/s` debe seguir significando RITMO.

No lo conviertas visualmente en "gomitas producidas por segundo".

Diferéncialo de racha.

---

# 26. HERRAMIENTA + POTENCIA

El HUD inferior debe comunicar inmediatamente:

- herramienta equipada;
- potencia;
- Datos;
- Pausa.

Los nombres oficiales ya existen.

NO los cambies.

Los emojis/iconos actuales pueden ser sustituidos.

---

# 27. ICONOS DE HERRAMIENTAS

Las 10 herramientas deben compartir UN lenguaje visual.

Si creas iconos definitivos:

- misma perspectiva;
- mismo framing;
- misma iluminación;
- mismo grosor visual;
- misma escala aparente;
- mismo padding;
- misma dirección artística.

Desde Puños hasta Crazy Hammer deben parecer parte de la misma progresión.

No cambies estadísticas ni IDs.

---

# 28. MERCADO — PANTALLA PILOTO

Utiliza preferiblemente el Mercado como primera implementación completa del Design System.

Es una excelente pantalla piloto porque combina:

- tabs;
- dinero;
- cards;
- botones;
- scroll;
- precios;
- estados;
- contenido reutilizable.

Sus tres pestañas son:

- Mejoras;
- Recetas;
- Herramientas.

NO cambies estos nombres.

Haz que el Mercado parezca parte de un negocio/mundo Crazy Gummy sin convertirlo necesariamente en una tienda física literal.

---

# 29. SHOPCARD

`ShopCard` es reutilizable.

Preserva su arquitectura.

Debe mostrar claramente:

- icono;
- nombre;
- nivel;
- valor actual;
- incremento;
- precio;
- disponibilidad.

Mejora muchísimo su acabado visual.

La compra debe sentirse satisfactoria.

No dupliques el componente solo para Prestigio.

---

# 30. COLLECTIONCARD

Se reutiliza en:

- Recetas;
- Herramientas.

Conserva:

- frente;
- reverso;
- estados;
- giro;
- botón;
- scroll/touch correcto.

Puedes rediseñar completamente su aspecto.

Diferencia claramente:

- bloqueado;
- descubierto;
- comprable;
- comprado;
- equipado.

---

# 31. RECETAS

Existen 20 recetas oficiales.

NO cambies sus nombres.

NO inventes tiers adicionales.

NO asignes arbitrariamente una receta a una forma de cubo si la guía indica que esa asociación todavía está pendiente.

Diseña la interfaz preparada para recibir en el futuro siluetas/modelos definitivos.

---

# 32. SILUETAS DE GOMITAS

La guía documenta que actualmente se reutiliza el osito provisional y que las 20 siluetas definitivas todavía no existen.

Puedes trabajar la UI para soportarlas.

Si esta fase incluye creación de arte definitivo de recetas, conserva:

- IDs;
- orden;
- datos;
- identidad oficial.

NO interpretes color como identidad.

---

# 33. COMODINES — SISTEMA DE CARTAS

Los comodines son una oportunidad visual enorme.

Existen 108.

NO generes automáticamente 108 ilustraciones independientes.

Primero diseña un sistema de cartas.

Debe contemplar:

- marco;
- fondo;
- rareza;
- símbolo/arte;
- reverso;
- nombre;
- efecto;
- selección;
- miniatura;
- tooltip.

Mantén `CardFlipWidget`.

---

# 34. RAREZAS

Rarezas oficiales:

- Común;
- Rara;
- Épica;
- Legendaria;
- Mítico.

Dales una progresión visual clara.

Puedes escalar:

- color;
- brillo;
- borde;
- partículas;
- patrón;
- profundidad;
- animación.

Pero NO dependas exclusivamente del color.

Una carta Mítica debe sentirse inmediatamente más extraordinaria que una Común.

---

# 35. REVERSO DE CARTA

Crea una identidad propia para el reverso Crazy Gummy.

Debe poder reutilizarse.

No necesita contener texto funcional.

Debe funcionar correctamente con la proporción real del sistema.

No rompas el flip.

---

# 36. CARD FLIP

Preserva completamente:

- PICK;
- THUMBNAIL;
- reverso desplazable;
- botón Elegir;
- dimensiones responsive;
- touch.

Puedes mejorar:

- flip;
- profundidad;
- glow;
- rareza;
- squash;
- transición.

Pero no alteres selección ni lógica.

---

# 37. PRESTIGIO

Prestigio representa progreso permanente.

Debe sentirse más importante que Mejoras temporales.

Mantén la misma familia visual Crazy Gummy, pero utiliza una jerarquía premium.

La Reputación ⭐ debe sentirse valiosa.

No inventes un botón de "prestigiar/resetear".

---

# 38. DATOS / ESTADÍSTICAS

Aquí manda la información.

Prioridad absoluta:

**número > decoración.**

Puedes tematizar StatCards, pero no escondas los valores.

Diferencia correctamente:

- %;
- ×;
- $;
- cubos/s;
- valores absolutos;
- probabilidades.

Respeta el formato real documentado.

---

# 39. LOGROS

Hay 121 logros.

Diseña un sistema reutilizable.

Estados:

- pendiente;
- progreso;
- completado.

No diseñes 121 elementos individualmente.

El desbloqueo debe sentirse celebratorio.

---

# 40. TOAST DE LOGROS

Debe:

- aparecer claramente;
- estar por encima del HUD;
- no confundirse con gameplay;
- ser legible;
- sentirse especial.

Puedes usar:

- entrada elástica;
- brillo;
- pequeña explosión;
- confeti ligero;
- squash.

No rompas la cola existente.

---

# 41. PROGRESO

Debe comunicar claramente:

- mejor día / 100;
- negocios iniciados;
- gomitas producidas;
- comodines descubiertos.

Puedes hacer que el camino hacia el día 100 tenga más presencia visual.

No cambies el objetivo.

---

# 42. RESULTADOS

Construye una jerarquía visual clara para:

1. resultado;
2. días;
3. dinero generado;
4. gomitas;
5. Jackpots;
6. doradas;
7. reputación.

No recalcules recompensas desde UI.

---

# 43. CRÉDITOS

Rediseña visualmente.

NO intentes arreglar desde este trabajo las particularidades funcionales posteriores al día 100 documentadas en la guía.

Si detectas deuda funcional:

documenta.

No la mezcles con esta migración visual.

---

# 44. MODALES

Todos los modales deben pertenecer a la misma familia visual.

Unifica:

- scrim;
- panel;
- borde;
- título;
- botón cerrar;
- contenido;
- acciones;
- animación.

No diseñes cada modal desde cero.

---

# 45. BOTONES

Crea estados consistentes:

- normal;
- hover;
- pressed;
- hover_pressed;
- disabled;
- focus.

Pressed debe sentirse físicamente presionado.

Puedes utilizar:

- squash;
- desplazamiento;
- cambio de highlight;
- reducción de sombra.

Evita animaciones que retrasen la acción.

---

# 46. MOTION LANGUAGE

Aprovecha la naturaleza gummy.

Puedes utilizar:

- squash;
- stretch;
- overshoot;
- bounce;
- wobble;
- elastic easing.

Pero solo cuando tenga sentido.

NO hagas que toda la interfaz esté moviéndose constantemente.

Movimiento = feedback.

---

# 47. FONDO DE GAMEPLAY

El damero actual es una prueba técnica de translucidez.

SUSTITÚYELO por un fondo artístico Crazy Gummy adecuado.

Debe:

- pertenecer al universo;
- permitir ver correctamente cubos translúcidos;
- no competir con objetos;
- mantener contraste;
- funcionar con todos los colores gummy.

No hagas un fondo extremadamente detallado.

---

# 48. CARAMELO ENDURECIDO

La esfera gris actual es provisional.

Puedes crear/integrar una representación visual coherente de:

**Caramelo Endurecido**

y, si resulta útil visualmente:

**Caramelo Endurecido Roto.**

NO cambies:

- spawn;
- probabilidad;
- colisión;
- penalización;
- racha;
- interacción con comodines.

Solo presentación.

---

# 49. EMOJIS PROVISIONALES

La guía identifica emojis e iconos provisionales.

Sustitúyelos progresivamente cuando puedas producir una iconografía mejor y coherente.

No reemplaces un emoji claro por un icono bonito pero ilegible.

---

# 50. FONDO DEL MENÚ

El fondo del menú puede ser más expresivo que el gameplay.

Debe vender la fantasía Crazy Gummy.

Puede incluir:

- gomitas;
- gelatina;
- cubos;
- burbujas;
- azúcar;
- profundidad;
- formas flotantes;
- iluminación.

No debe perjudicar navegación.

---

# 51. PERFORMANCE

Recuerda:

**juego móvil.**

Evita:

- blur fullscreen permanente;
- shaders UI excesivamente costosos;
- transparencias fullscreen acumuladas;
- partículas excesivas;
- texturas gigantes;
- animaciones procesándose fuera de pantalla.

La calidad no debe depender de fuerza bruta.

---

# 52. NO CAMBIES GAMEPLAY

PROHIBIDO modificar:

- precios;
- potencia;
- dureza;
- resistencia;
- recompensas;
- probabilidades;
- Jackpot;
- doradas;
- racha;
- multiplicadores;
- ritmo;
- metas;
- impuestos;
- tiempo;
- orden de recetas;
- orden de herramientas;
- condiciones de logros;
- rarezas;
- efectos de comodines;
- RNG de gameplay.

Si algo parece incorrecto:

**DOCUMENTA, NO CORRIJAS.**

---

# 53. NO VUELVAS A MIGRAR NOMBRES

La migración interna ya terminó.

No vuelvas a buscar `Fruit` para renombrarlo arbitrariamente.

La guía actual documenta qué excepciones históricas permanecen por compatibilidad.

Respétalas.

En particular:

- SaveMigration;
- fixtures de compatibilidad;
- identidad Android;
- archivos históricos documentados.

No confundas compatibilidad con deuda pendiente.

---

# 54. GUARDADO

El guardado canónico actual está documentado en la guía.

NO cambies:

- schema;
- version;
- IDs;
- claves;
- rutas;
- migración;
- identidad de instalación.

No necesitas tocar SaveManager para hacer una interfaz bonita.

---

# 55. NAVEGACIÓN

NO cambies el flujo.

Especial cuidado:

la X del Mercado también inicia el siguiente día.

NO la conviertas en un cierre genérico porque "una X debería cerrar".

Respeta el comportamiento real documentado.

---

# 56. TOUCHSCROLLCONTAINER

Preserva el comportamiento existente:

- scroll iniciando sobre botones;
- umbral de arrastre;
- protección contra compra accidental;
- sliders;
- cards.

Prueba touch después del rediseño.

---

# 57. UI DINÁMICA

Inspecciona elementos creados mediante código.

No dejes controles default porque no existían directamente en `.tscn`.

Todo elemento dinámico debe integrarse al Design System.

---

# 58. IMPLEMENTACIÓN POR FASES

Trabaja en este orden:

## FASE 1 — Auditoría

Comprende todo.

## FASE 2 — Design System

Define:

- paleta;
- superficies;
- botones;
- cards;
- paneles;
- tipografía;
- iconografía;
- rarezas;
- motion.

## FASE 3 — Componentes base

Implementa primero:

- Button;
- Panel;
- Modal;
- tabs;
- barras;
- ShopCard;
- CollectionCard;
- StatCard;
- CardFlipWidget.

## FASE 4 — Mercado piloto

Comprueba que el sistema realmente funciona.

## FASE 5 — Propagación

Aplica el sistema a:

- menú;
- HUD;
- comodines;
- prestigio;
- progreso;
- datos;
- logros;
- resultados;
- créditos;
- pausa;
- ajustes;
- confirmaciones.

## FASE 6 — Arte especial

Después:

- iconos;
- fondos;
- obstáculo;
- reverso;
- decoraciones;
- efectos.

## FASE 7 — Polish

Finalmente:

- microanimaciones;
- partículas;
- feedback;
- consistencia.

NO empieces por polish.

---

# 59. NO TE DETENGAS EN EL PILOTO

Mercado es una validación interna.

Una vez comprobado que funciona:

CONTINÚA.

No necesito aprobar pantalla por pantalla.

Tienes libertad artística para completar el rediseño integral.

---

# 60. INSPECCIÓN VISUAL REAL

No confíes únicamente en tests.

Ejecuta el juego.

Inspecciona las pantallas.

Prueba:

- contenido real;
- valores grandes;
- nombres largos;
- estados disabled;
- bloqueados;
- comprados;
- equipados;
- Bonus;
- rarezas;
- scroll;
- modales.

---

# 61. PRUEBA NÚMEROS GRANDES

El juego utiliza sufijos:

- K;
- M;
- B;
- T;
- Qa;
- Qi;
- Sx;
- Sp.

No diseñes componentes que solamente funcionan con números pequeños.

---

# 62. PRUEBAS AUTOMÁTICAS

La guía enumera las regresiones actuales.

Después de cambios importantes ejecuta las relevantes.

Al final ejecuta la suite visual/funcional aplicable.

Especialmente:

- UI layout;
- touch interaction;
- card choice;
- shop stats;
- typography;
- theme migration;
- settings/reset;
- gummy materials/visual si los tocaste;
- daily Bonus.

Utiliza un `XDG_DATA_HOME` aislado por prueba como indica la guía.

---

# 63. NO HAGAS TRAMPA CON LOS TESTS

Si el rediseño rompe una prueba funcional:

CORRIGE EL REDISEÑO.

No modifiques tests simplemente para obtener verde.

Solo actualiza una expectativa si era puramente visual y el nuevo comportamiento mantiene la garantía funcional.

---

# 64. VALIDACIÓN RESPONSIVE FINAL

Inspecciona obligatoriamente:

- 720×960;
- 720×1280;
- 720×1600;
- 960×1280.

Busca:

- clipping;
- solapamiento;
- texto truncado;
- espacios absurdos;
- botones deformados;
- assets estirados;
- scroll innecesario;
- contraste;
- safe areas;
- targets táctiles;
- jerarquía.

Corrige todo lo encontrado.

---

# 65. CONSISTENCIA GLOBAL

Antes de terminar realiza una pasada completa.

NO debe quedar:

- una pantalla con estilo anterior;
- botones default olvidados;
- paneles incompatibles;
- iconografía inconsistente;
- emojis aleatorios mezclados sin intención;
- fondos provisionales activos innecesariamente;
- controles dinámicos sin Theme;
- assets deformados.

---

# 66. ACTUALIZA LA GUÍA

Al finalizar:

actualiza el mismo:

`CRAZY_GUMMY_PROJECT_GUIDE.md`

para que continúe siendo la fuente de verdad.

NO destruyas su información técnica existente.

Actualiza principalmente:

- Sistema visual actual;
- assets activos;
- assets sustituidos;
- componentes;
- Theme;
- iconografía;
- backgrounds;
- shaders UI;
- NinePatch/StyleBoxTexture;
- animaciones;
- organización visual.

---

# 67. AÑADE DESIGN SYSTEM A LA GUÍA

Documenta una sección:

# Crazy Gummy UI Design System

Incluye:

- filosofía;
- paleta;
- roles de color;
- tipografía;
- botones;
- paneles;
- cards;
- barras;
- modales;
- rarezas;
- iconografía;
- motion;
- assets reutilizables;
- reglas de escalado.

Debe servir para diseñar futuras pantallas sin volver a auditar todo el proyecto.

---

# 68. NO BORRES HISTORIA NECESARIA

Puedes retirar del uso visual assets provisionales.

Pero NO elimines automáticamente archivos documentados como necesarios para:

- migración;
- compatibilidad;
- fallback;
- identidad de instalación.

Un asset sin uso visual no necesariamente es basura.

---

# 69. CRITERIOS DE ÉXITO

La tarea termina únicamente cuando se cumplen TODOS:

### IDENTIDAD

Una captura sin logo sigue pareciendo Crazy Gummy.

### COHERENCIA

Todas las pantallas pertenecen al mismo Design System.

### LEGIBILIDAD

Información y números se leen rápidamente.

### GAMEPLAY

El HUD no compite con los cubos.

### TOUCH

Botones, scroll, sliders y cards funcionan correctamente.

### RESPONSIVE

Las cuatro resoluciones objetivo funcionan.

### REUTILIZACIÓN

No existe una montaña de assets duplicados.

### ASSETS

No hay PNG deformados ni texto funcional horneado.

### ESTABILIDAD

Gameplay, balance, economía y guardados permanecen intactos.

### TESTS

Las regresiones funcionales relevantes continúan pasando.

### DOCUMENTACIÓN

La guía refleja fielmente el nuevo estado visual.

---

# 70. LIBERTAD ARTÍSTICA

No necesito que me preguntes:

- qué tono exacto usar;
- qué radio utilizar;
- qué forma debe tener cada botón;
- si debes usar un pequeño brillo;
- si un panel necesita una textura;
- qué animación utilizar para pressed;
- qué decoración pequeña añadir.

TOMA ESAS DECISIONES COMO DISEÑADOR.

Tienes libertad para:

- experimentar;
- crear assets;
- cambiar acabados;
- mejorar jerarquía;
- crear iconografía;
- introducir 9-slice;
- crear shaders ligeros;
- mejorar animaciones;
- sustituir fondos;
- diseñar cartas;
- crear superficies;
- modificar composición visual cuando realmente mejore UX.

No tienes libertad para alterar la lógica.

---

# 71. PRINCIPIO FINAL

No quiero un simple reskin.

No quiero:

> “La misma interfaz default de Godot, pero rosa.”

Tampoco quiero:

> “Una maqueta preciosa que rompió el juego.”

Quiero el punto intermedio correcto:

> **una interfaz diseñada específicamente para Crazy Gummy construida sobre la arquitectura sólida que ya existe.**

Reutiliza.

Centraliza.

Diseña con intención.

Haz que se sienta táctil.

Usa la gelatina como lenguaje visual, no como gimmick.

Permite que los elementos especiales realmente sean especiales.

Mantén limpio el gameplay.

Sé más expresivo en menús, cartas y recompensas.

Crea assets cuando sean la mejor solución.

Usa Godot cuando Godot sea la mejor solución.

No sacrifiques UX por decoración.

No sacrifiques identidad por comodidad.

---

# OBJETIVO FINAL

Primero hicimos que el proyecto dejara de ser Crazy Fruit y se convirtiera realmente en Crazy Gummy.

Esa fase terminó.

Ahora quiero abrir el juego y que, antes incluso de leer el título, su interfaz, sus cartas, sus botones, sus barras, sus fondos, sus iconos, sus animaciones y sus superficies me digan:

# ESTO ES CRAZY GUMMY.

Haz que Crazy Gummy parezca Crazy Gummy.
