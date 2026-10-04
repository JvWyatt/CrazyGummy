class_name ResponsiveGrid
extends Container
# ============================================================================
# ResponsiveGrid: contenedor de rejilla "bento" que reparte sus hijos en varias
# columnas SEGUN el ancho REAL del que dispone (el de su ScrollContainer), en
# lugar de fijar el numero de columnas a mano. Al cambiar el tamano (giro de
# movil, ventana distinta) recoloca las tarjetas.
#
# Dos modos, segun `fixed_columns`:
#   - 0 (por defecto): automatico. Mete otra columna cuando quepa otra tarjeta de
#     `min_card_width`, hasta un tope de `max_columns`.
#   - > 0: EXACTAMENTE ese numero de columnas, siempre. Es lo que usan las
#     tiendas de mejoras y de prestigio (2 columnas), donde el ancho de cada
#     tarjeta se estira para aprovechar todo el hueco.
#
# En ambos modos el ancho sobrante se reparte entre las columnas, de modo que las
# tarjetas ocupan el ancho disponible en vez de dejar hueco a la derecha.
#
# `center_orphan`: cuando la ultima fila queda incompleta (p.ej. 5 tarjetas en 2
# columnas), la tarjeta(s) suelta(s) se CENTRA en esa fila manteniendo el ancho
# de las de arriba, en vez de quedarse pegada a la izquierda.
#
# POR QUE ES UN Container PROPIO y no un GridContainer: GridContainer siempre
# deja la fila incompleta alineada a la izquierda, y no deja elegir el ancho
# por columna. Aqui se hace a mano la llamada a NOTIFICATION_SORT_CHILDREN (el
# patron que documenta Godot para contenedores propios).
#
# Lo usan: tiendas de MEJORAS y de PRESTIGIO (ShopCard), coleccion de
# frutas/armas (CollectionCard), galeria de comodines (CardFlipWidget en
# miniatura) y las secciones de ESTADISTICAS (StatCard).
#
# REVERTIR el diseno en rejilla de cualquier sitio: sustituir este nodo por un
# VBoxContainer en la escena y volver al listado vertical. Los modales no
# dependen de este script (solo hacen add_child/queue_free sobre el
# contenedor), asi que la vuelta atras no toca la logica de compra.
# ============================================================================

# Separacion entre tarjetas. Sustituye a los theme_override_constants que usaba
# el GridContainer, porque al dejar de heredar de el ya no los lee del tema.
@export var h_separation: int = 12
@export var v_separation: int = 12
# Ancho minimo que debe poder tener una tarjeta antes de meter otra columna.
@export var min_card_width: float = 148.0
# Tope de columnas para que en unleves anchos las tarjetas no se queden
# estrechas de mas.
@export var max_columns: int = 4
# Numero EXACTO de columnas. 0 = automatico (segun min_card_width/max_columns).
@export var fixed_columns: int = 0
# Centrar la ultima fila cuando le faltan tarjetas para llenarla.
@export var center_orphan: bool = true
# Igualar todas las celdas; opcional para conservar las otras galerías.
@export var uniform_card_size: bool = false
# Repartir entre filas el alto disponible que sobre por encima del mínimo.
@export var stretch_rows: bool = false
## 0: altura natural. 1: tarjetas cuadradas, incluyendo borde y acción.
@export_range(0.0, 3.0, 0.01) var card_aspect_ratio: float = 0.0

var _last_usable_width: float = -1.0

func _ready() -> void:
	resized.connect(_on_available_width_changed)
	# Si vive en una ScrollContainer que aun esta oculta (pestaña sin abrir), su
	# resized no se dispara al abrirla: hay que escucharlo tambien ahi.
	var parent := get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).resized.connect(_on_available_width_changed)
	# call_deferred: al construirse desde codigo el ancho aun puede ser 0, y las
	# tarjetas llegan despues (asi que hay que enganchar su visibility_changed).
	call_deferred("_rebind_children")

func _on_available_width_changed() -> void:
	var width: float = _usable_width()
	if not is_equal_approx(width, _last_usable_width):
		_last_usable_width = width
		# El alto natural depende del número de columnas y de la proporción.
		update_minimum_size()
	queue_sort()

# Recoloca las tarjetas. Llamarlo solo si se cambian las propiedades a mano en
# tiempo de ejecucion; desde la escena se aplican antes de entrar en el arbol.
func refresh() -> void:
	update_minimum_size()
	_rebind_children()
	queue_sort()

func _rebind_children() -> void:
	for child in get_children():
		var ctrl := child as Control
		if ctrl and not ctrl.visibility_changed.is_connected(queue_sort):
			ctrl.visibility_changed.connect(queue_sort)
	queue_sort()

# --- Hijos visibles ----------------------------------------------------------

func _cards() -> Array[Control]:
	var out: Array[Control] = []
	for child in get_children():
		var ctrl := child as Control
		# Medir también pestañas ocultas cuando sirven de referencia del modal.
		if ctrl and ctrl.visible and not ctrl.is_queued_for_deletion():
			out.append(ctrl)
	return out

# Ancho realmente disponible. Si el grid todavia no tiene tamano (pestaña
# cerrada), se cae al de su ScrollContainer, que si lo tiene.
func _usable_width() -> float:
	if size.x > 0.0:
		return size.x
	var parent := get_parent()
	if parent is ScrollContainer:
		return (parent as ScrollContainer).size.x
	return 0.0

func _column_count(card_count: int, usable: float) -> int:
	if fixed_columns > 0:
		# Topar tambien por las tarjetas que hay: con una sola no tiene sentido
		# reservar la segunda columna (ni su separacion en el ancho minimo).
		return clampi(card_count, 1, fixed_columns)
	if usable <= 0.0:
		# Sin ancho todavia (pestaña oculta): se supone el layout mas estrecho
		# para no inventar un ancho minimo que luego obligue a scroll horizontal.
		return 1
	# Cuantas tarjetas caben: (n * ancho) + (n - 1) * separacion <= disponible
	var fits: int = int(floor((usable + h_separation) / (min_card_width + h_separation)))
	return clampi(fits, 1, max_columns)

# Reparte las tarjetas en columnas y mide cada columna y cada fila por separado.
func _measure(cards: Array[Control], cols: int) -> Dictionary:
	var col_w := PackedFloat32Array()
	col_w.resize(cols)
	col_w.fill(0.0)
	var row_h := PackedFloat32Array()
	for i in cards.size():
		var col: int = i % cols
		var row: int = int(i / cols)
		var mins: Vector2 = cards[i].get_combined_minimum_size()
		col_w[col] = maxf(col_w[col], mins.x)
		while row_h.size() <= row:
			row_h.append(0.0)
		row_h[row] = maxf(row_h[row], mins.y)
	if uniform_card_size:
		var max_width: float = 0.0
		var max_height: float = 0.0
		for width in col_w:
			max_width = maxf(max_width, width)
		for height in row_h:
			max_height = maxf(max_height, height)
		col_w.fill(max_width)
		row_h.fill(max_height)
	return {"cols": col_w, "rows": row_h}

# Ancho que piden las columnas tal cual estan, sin repartir el sobrante.
func _natural_width(col_w: PackedFloat32Array) -> float:
	var total: float = 0.0
	for w in col_w:
		total += w
	return total + h_separation * float(maxi(col_w.size() - 1, 0))

func _expand_column_widths(col_w: PackedFloat32Array, usable: float) -> void:
	var slack: float = maxf(0.0, usable - _natural_width(col_w))
	if slack <= 0.0:
		return
	var total: float = 0.0
	for width in col_w:
		total += width
	total = maxf(total, 0.001)
	for col in col_w.size():
		col_w[col] += slack * (col_w[col] / total)

func _aspect_row_heights(row_h: PackedFloat32Array, col_w: PackedFloat32Array) -> void:
	if card_aspect_ratio <= 0.0:
		return
	var height: float = 0.0
	for width in col_w:
		height = maxf(height, width / card_aspect_ratio)
	row_h.fill(height)

# --- Tamano minimo ----------------------------------------------------------

func _get_minimum_size() -> Vector2:
	var cards := _cards()
	if cards.is_empty():
		return Vector2.ZERO
	var cols: int = _column_count(cards.size(), _usable_width())
	var measured := _measure(cards, cols)
	var col_w: PackedFloat32Array = measured["cols"]
	var row_h: PackedFloat32Array = measured["rows"]
	var natural_width: float = _natural_width(col_w)
	if card_aspect_ratio > 0.0:
		_expand_column_widths(col_w, _usable_width())
		_aspect_row_heights(row_h, col_w)
	var total_h: float = 0.0
	for h in row_h:
		total_h += h
	total_h += v_separation * float(maxi(row_h.size() - 1, 0))
	return Vector2(natural_width, total_h)

# --- Colocacion -------------------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_cards()

func _sort_cards() -> void:
	var cards := _cards()
	if cards.is_empty():
		return
	var usable: float = _usable_width()
	var cols: int = _column_count(cards.size(), usable)
	var measured := _measure(cards, cols)
	var col_w: PackedFloat32Array = measured["cols"]
	var row_h: PackedFloat32Array = measured["rows"]

	# El ancho sobrante se reparte entre las columnas en proporcion a lo que cada
	# una ya pide: asi las tarjetas aprovechan todo el ancho disponible y las
	# columnas con mas texto no se quedan rezagadas.
	_expand_column_widths(col_w, usable)
	_aspect_row_heights(row_h, col_w)

	# Posicion vertical de cada fila (alto = la tarjeta mas alta de la fila).
	if stretch_rows and card_aspect_ratio <= 0.0:
		var natural_height: float = v_separation * float(maxi(row_h.size() - 1, 0))
		for height in row_h:
			natural_height += height
		var extra_height: float = maxf(0.0, size.y - natural_height) / float(row_h.size())
		for row in row_h.size():
			row_h[row] += extra_height
	var row_y := PackedFloat32Array()
	row_y.resize(row_h.size())
	var acc: float = 0.0
	for row in row_h.size():
		row_y[row] = acc
		acc += row_h[row] + v_separation

	# Posicion horizontal de cada columna.
	var col_x := PackedFloat32Array()
	col_x.resize(cols)
	acc = 0.0
	for col in cols:
		col_x[col] = acc
		acc += col_w[col] + h_separation

	for i in cards.size():
		var col: int = i % cols
		var row: int = int(i / cols)
		var in_row: int = mini(cols, cards.size() - row * cols)
		var x: float = col_x[col]
		# Fila final incompleta: lo que sobra se reparte como margen a los lados
		# de la(s) tarjeta(s) sueltas, que conservan el ancho de las de arriba.
		if center_orphan and in_row < cols:
			var used: float = h_separation * float(in_row - 1)
			for k in in_row:
				used += col_w[k]
			x += maxf(0.0, usable - used) * (float(col) + 0.5) / float(in_row)
		cards[i].position = Vector2(x, row_y[row])
		cards[i].size = Vector2(col_w[col], row_h[row])
