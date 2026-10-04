class_name CardDatabase
extends RefCounted
# ============================================================================
# CardDatabase
# ----------------------------------------------------------------------------
# Catálogo de todos los "comodines" (cartas) que el jugador puede elegir al
# completar un pedido (ver CardSelectionModal.gd). Son bonos TEMPORALES que
# se pierden al quebrar el negocio (aplicados en StatsManager._apply_card_effect).
#
# Cada carta tiene una rareza (Común/Rara/Épica/Legendaria/Mítico) que suele
# indicar qué tan fuerte es su efecto, y un "effect_type" que dice QUÉ stat
# modifica (ver la lista de casos en StatsManager._apply_card_effect para el
# significado exacto de cada effect_type). Para cambiar el balance de una
# carta, solo edita el número (effect_value) de su línea _card(...).
# ============================================================================

static var ALL_CARDS: Array[Dictionary] = _build_cards()

# Orden canónico de rarezas (usado por la galería y las estadísticas).
const RARITIES: Array[String] = ["Común", "Rara", "Épica", "Legendaria", "Mítico"]

static func _build_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var common := "Común"
	var rare := "Rara"
	var epic := "Épica"
	var legendary := "Legendaria"
	var mythic := "Mítico"

	# --------------------------------------------------------------------------
	# Pool común: 62 cartas de efecto único y magnitud moderada/baja.
	# --------------------------------------------------------------------------
	cards.append(_card("Filo Ligero", "+3% daño", common, "damage", 0.03))
	cards.append(_card("Filo de Acero", "+5% daño", common, "damage", 0.05))
	cards.append(_card("Puño Firme", "+7% daño", common, "damage", 0.07))
	cards.append(_card("Pulso", "+4% daño", common, "damage", 0.04))
	cards.append(_card("Filo Afilado", "+6% daño", common, "damage", 0.06))
	cards.append(_card("Golpe Letal", "+5.5% daño", common, "damage", 0.055))
	cards.append(_card("Buen Aguante", "+3% resistencia máxima", common, "energy_max", 0.03))
	cards.append(_card("Piernas Firmes", "+4% resistencia máxima", common, "energy_max", 0.04))
	cards.append(_card("Segundo Aliento", "+5% resistencia máxima", common, "energy_max", 0.05))
	cards.append(_card("Vigor Rápido", "+6% resistencia máxima", common, "energy_max", 0.06))
	cards.append(_card("Refuerzo", "+3.5% resistencia máxima", common, "energy_max", 0.035))
	cards.append(_card("Resistencia Extra", "+5.5% resistencia máxima", common, "energy_max", 0.055))
	cards.append(_card("Cosecha Segura", "+3% recompensa mínima", common, "reward_min", 0.03))
	cards.append(_card("Fruto Fresco", "+4% recompensa mínima", common, "reward_min", 0.04))
	cards.append(_card("Buen Reparto", "+5% recompensa mínima", common, "reward_min", 0.05))
	cards.append(_card("Cosecha Ligera", "+3.5% recompensa mínima", common, "reward_min", 0.035))
	cards.append(_card("Suelo Fertil", "+5.5% recompensa mínima", common, "reward_min", 0.055))
	cards.append(_card("Fruta Valiosa", "+3% recompensa máxima", common, "reward_max", 0.03))
	cards.append(_card("Jugo Maduro", "+4% recompensa máxima", common, "reward_max", 0.04))
	cards.append(_card("Cosecha Doble", "+5% recompensa máxima", common, "reward_max", 0.05))
	cards.append(_card("Cosecha Plena", "+3.5% recompensa máxima", common, "reward_max", 0.035))
	cards.append(_card("Cosecha Amplia", "+5.5% recompensa máxima", common, "reward_max", 0.055))
	cards.append(_card("Pequeña Fortuna", "+0.3% probabilidad de Jackpot", common, "jackpot", 0.003))
	cards.append(_card("Buena Estrella", "+0.25% probabilidad de Jackpot", common, "jackpot", 0.0025))
	cards.append(_card("Premio Mayor", "+0.1x multiplicador de Jackpot", common, "jackpot_multiplier", 0.1))
	cards.append(_card("Buen Negocio", "+3% multiplicador de ganancias", common, "money", 0.03))
	cards.append(_card("Monedero", "+4% multiplicador de ganancias", common, "money", 0.04))
	cards.append(_card("Bolsa Rellena", "+5% multiplicador de ganancias", common, "money", 0.05))
	cards.append(_card("Bolsa Doblada", "+3.5% multiplicador de ganancias", common, "money", 0.035))
	cards.append(_card("Mercado Furioso", "+5.5% multiplicador de ganancias", common, "money", 0.055))
	cards.append(_card("Riqueza", "+6% multiplicador de ganancias", common, "money", 0.06))
	cards.append(_card("Punto Preciso", "+1% probabilidad de Crítico", common, "crit_chance", 0.01))
	cards.append(_card("Foco", "+2% probabilidad de Crítico", common, "crit_chance", 0.02))
	cards.append(_card("Filigrana", "+3% probabilidad de Crítico", common, "crit_chance", 0.03))
	cards.append(_card("Golpe Firme", "+1.5% probabilidad de Crítico", common, "crit_chance", 0.015))
	cards.append(_card("Mano Certera", "+1.2% probabilidad de Crítico", common, "crit_chance", 0.012))
	cards.append(_card("Puntería", "+2.5% probabilidad de Crítico", common, "crit_chance", 0.025))
	cards.append(_card("Ritmo Constante", "+3% frecuencia de lanzamiento", common, "launch_rate", 0.03))
	cards.append(_card("Viento Leve", "+4% frecuencia de lanzamiento", common, "launch_rate", 0.04))
	cards.append(_card("Rayo", "+5% frecuencia de lanzamiento", common, "launch_rate", 0.05))
	cards.append(_card("Giro Veloz", "+3.5% frecuencia de lanzamiento", common, "launch_rate", 0.035))
	cards.append(_card("Tormenta Ligera", "+5.5% frecuencia de lanzamiento", common, "launch_rate", 0.055))
	cards.append(_card("Filo en el Viento", "+2.5% frecuencia de lanzamiento", common, "launch_rate", 0.025))
	cards.append(_card("Fruta Delicada", "-3% vida de las frutas", common, "fruit_hp", -0.03))
	cards.append(_card("Fruta Frágil", "-4% vida de las frutas", common, "fruit_hp", -0.04))
	cards.append(_card("Armas Baratas", "-3% precio de armas", common, "weapon_price", -0.03))
	cards.append(_card("Rebaja", "-4% precio de armas", common, "weapon_price", -0.04))
	cards.append(_card("Compra Mayorista", "-5% precio de armas", common, "weapon_price", -0.05))
	cards.append(_card("Frutas Baratas", "-3% precio de frutas", common, "fruit_price", -0.03))
	cards.append(_card("Oferta", "-4% precio de frutas", common, "fruit_price", -0.04))
	cards.append(_card("Venta al Por Mayor", "-5% precio de frutas", common, "fruit_price", -0.05))
	cards.append(_card("Mejoras Baratas", "-3% precio de mejoras", common, "upgrade_price", -0.03))
	cards.append(_card("Cambio Justo", "-4% precio de mejoras", common, "upgrade_price", -0.04))
	cards.append(_card("Ahorro Mayor", "-5% precio de mejoras", common, "upgrade_price", -0.05))
	cards.append(_card("Buen Progreso", "-3% objetivo de dinero del día", common, "order_target", -0.03))
	cards.append(_card("Día Corto", "-4% objetivo de dinero del día", common, "order_target", -0.04))
	cards.append(_card("Día Bueno", "-5% objetivo de dinero del día", common, "order_target", -0.05))
	cards.append(_card("Cortes Ligeros", "-4% energía por golpe", common, "energy_cost", -0.04))
	cards.append(_card("Mano Suave", "-6% energía por golpe", common, "energy_cost", -0.06))
	cards.append(_card("Brillo Dorado", "+0.05% de Probabilidad de Fruta Dorada", common, "golden_fruit_chance", 0.0005))
	cards.append(_card("Toque Brillante", "+0.1% de Probabilidad de Fruta Dorada", common, "golden_fruit_chance", 0.001))
	cards.append(_card("Filo del Experto", "+6.5% daño", common, "damage", 0.065))
	cards.append(_card("Cadena de Cortes", "+x0.1 al multiplicador de racha", common, "streak_bonus", 0.1))

	# --------------------------------------------------------------------------
	# Pool raro: 27 cartas de efecto único y magnitud mayor.
	# --------------------------------------------------------------------------
	cards.append(_card("Filo Superior", "+9% daño", rare, "damage", 0.09))
	cards.append(_card("Filo Devastador", "+12% daño", rare, "damage", 0.12))
	cards.append(_card("Reserva Extra", "+9% resistencia máxima", rare, "energy_max", 0.09))
	cards.append(_card("Reserva Titánica", "+12% resistencia máxima", rare, "energy_max", 0.12))
	cards.append(_card("Cosecha Rica", "+9% recompensa mínima", rare, "reward_min", 0.09))
	cards.append(_card("Cosecha Abundante", "+12% recompensa mínima", rare, "reward_min", 0.12))
	cards.append(_card("Cosecha Mayor", "+9% recompensa máxima", rare, "reward_max", 0.09))
	cards.append(_card("Cosecha Exuberante", "+12% recompensa máxima", rare, "reward_max", 0.12))
	cards.append(_card("Fortuna Creciente", "+0.6% probabilidad de Jackpot", rare, "jackpot", 0.006))
	cards.append(_card("Fortuna Dorada", "+1% probabilidad de Jackpot", rare, "jackpot", 0.01))
	cards.append(_card("Jackpot Mejorado", "+0.3x multiplicador de Jackpot", rare, "jackpot_multiplier", 0.3))
	cards.append(_card("Negocio Próspero", "+9% multiplicador de ganancias", rare, "money", 0.09))
	cards.append(_card("Mercado Dorado", "+12% multiplicador de ganancias", rare, "money", 0.12))
	cards.append(_card("Golpe Certero", "+3.5% probabilidad de Crítico", rare, "crit_chance", 0.035))
	cards.append(_card("Golpe Mortal", "+4.5% probabilidad de Crítico", rare, "crit_chance", 0.045))
	cards.append(_card("Ritmo Fuerte", "+9% frecuencia de lanzamiento", rare, "launch_rate", 0.09))
	cards.append(_card("Tormenta de Frutas", "+12% frecuencia de lanzamiento", rare, "launch_rate", 0.12))
	cards.append(_card("Fruta Frágil II", "-7% vida de las frutas", rare, "fruit_hp", -0.07))
	cards.append(_card("Fruta Rompible", "-10% vida de las frutas", rare, "fruit_hp", -0.10))
	cards.append(_card("Toque Dorado", "+0.2% de Probabilidad de Fruta Dorada", rare, "golden_fruit_chance", 0.002))
	cards.append(_card("Cosecha Dorada", "+0.3% de Probabilidad de Fruta Dorada", rare, "golden_fruit_chance", 0.003))
	cards.append(_card("Corte Eficiente", "-12% energía por golpe", rare, "energy_cost", -0.12))
	cards.append(_card("Día Favorable", "-8% objetivo de dinero del día", rare, "order_target", -0.08))
	cards.append(_card("Comerciante", "-6% precio de armas, frutas y mejoras", rare, "all_prices", -0.06))
	cards.append(_card("Mayorista de Armas", "-8% precio de armas", rare, "weapon_price", -0.08))
	cards.append(_card("Cesta de Ofertas", "-8% precio de frutas", rare, "fruit_price", -0.08))
	cards.append(_card("Tecnología de Punta", "-8% precio de mejoras", rare, "upgrade_price", -0.08))
	cards.append(_card("Ritmo de Campeón", "+x0.2 al multiplicador de racha", rare, "streak_bonus", 0.2))
	cards.append(_card("Pie Firme", "La primera piedra del día no quita resistencia", rare, "first_stone_free", 1))

	# --------------------------------------------------------------------------
	# Pool épico: 7 cartas de magnitud alta.
	# --------------------------------------------------------------------------
	cards.append(_card("Filo Supremo", "+18% daño", epic, "damage", 0.18))
	cards.append(_card("Fortuna Suprema", "+1.5% probabilidad de Jackpot", epic, "jackpot", 0.015))
	cards.append(_card("Golpe Perfecto", "+8% probabilidad de Crítico", epic, "crit_chance", 0.08))
	cards.append(_card("Cosecha Torrencial", "+18% recompensa máxima", epic, "reward_max", 0.18))
	cards.append(_card("Coloso", "+18% resistencia máxima", epic, "energy_max", 0.18))
	cards.append(_card("Meteoro", "+18% frecuencia de lanzamiento", epic, "launch_rate", 0.18))
	cards.append(_card("Leyenda Dorada", "+0.6% de Probabilidad de Fruta Dorada", epic, "golden_fruit_chance", 0.006))
	cards.append(_card("Furia de la Racha", "+x0.5 al multiplicador de racha", epic, "streak_bonus", 0.5))
	cards.append(_card("Rompepiedras", "+1% probabilidad de romper una piedra", epic, "stone_break_chance", 0.01))

	# --------------------------------------------------------------------------
	# Pool legendario: 3 cartas de magnitud muy alta.
	# --------------------------------------------------------------------------
	cards.append(_card("Filazo Épico", "+28% daño", legendary, "damage", 0.28))
	cards.append(_card("Jackpot Legendario", "+1x multiplicador de Jackpot", legendary, "jackpot_multiplier", 1.0))
	cards.append(_card("Tormenta Perfecta", "+28% frecuencia de lanzamiento", legendary, "launch_rate", 0.28))
	cards.append(_card("Racha Infinita", "+x1.0 al multiplicador de racha", legendary, "streak_bonus", 1.0))
	cards.append(_card("Demoledor", "+3% probabilidad de romper una piedra", legendary, "stone_break_chance", 0.03))

	# --------------------------------------------------------------------------
	# Pool mítico: 1 carta (la más poderosa del juego).
	# --------------------------------------------------------------------------
	cards.append(_card("Divinidad", "+12% probabilidad de Crítico", mythic, "crit_chance", 0.12))
	cards.append(_card("Racha Eterna", "Mantiene el conteo de racha entre días", mythic, "streak_keep", 1))
	return cards

static func _card(title: String, desc: String, rarity: String, effect_type: String, effect_value: float) -> Dictionary:
	return {"id": "card_" + title.to_lower().replace(" ", "_"), "title": title, "desc": desc, "icon": "🃏", "rarity": rarity, "color": rarity_color(rarity), "effect_type": effect_type, "effect_value": effect_value}

static func rarity_color(rarity: String) -> Color:
	match rarity:
		"Común": return Color(0.3, 0.7, 1.0)
		"Rara": return Color(0.3, 0.9, 0.4)
		"Épica": return Color(0.8, 0.4, 1.0)
		"Legendaria": return Color(1.0, 0.75, 0.1)
		_: return Color(1.0, 0.4, 0.8)

# Probabilidad por SIMPLE DISTRIBUCIÓN: como el pool está bien balanceado
# (62 Común / 27 Rara / 7 Épica / 3 Legendaria / 1 Mítico), el azar puro ya
# produce la distribución deseada de rarezas. Se elige cada carta uniformemente
# al azar entre el total SIN pesos forzados.
static func get_random_cards(count: int = 3) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	var available: Array[Dictionary] = ALL_CARDS.duplicate()
	var needed: int = mini(count, ALL_CARDS.size())
	while selected.size() < needed and available.size() > 0:
		var pick: Dictionary = available[randi() % available.size()]
		selected.append(pick)
		available.erase(pick)
	return selected
