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
	# Pool común: 63 cartas de efecto único y magnitud moderada/baja.
	# --------------------------------------------------------------------------
	cards.append(_card("Impacto Ligero", "+3% potencia", common, "damage", 0.03, "card_impacto_ligero"))
	cards.append(_card("Impacto de Acero", "+5% potencia", common, "damage", 0.05, "card_impacto_de_acero"))
	cards.append(_card("Puño Firme", "+7% potencia", common, "damage", 0.07))
	cards.append(_card("Pulso", "+4% potencia", common, "damage", 0.04))
	cards.append(_card("Impacto Preciso", "+6% potencia", common, "damage", 0.06, "card_impacto_preciso"))
	cards.append(_card("Golpe Intenso", "+5.5% potencia", common, "damage", 0.055, "card_golpe_intenso"))
	cards.append(_card("Buen Aguante", "+3% resistencia máxima", common, "energy_max", 0.03))
	cards.append(_card("Piernas Firmes", "+4% resistencia máxima", common, "energy_max", 0.04))
	cards.append(_card("Segundo Aliento", "+5% resistencia máxima", common, "energy_max", 0.05))
	cards.append(_card("Vigor Rápido", "+6% resistencia máxima", common, "energy_max", 0.06))
	cards.append(_card("Refuerzo", "+3.5% resistencia máxima", common, "energy_max", 0.035))
	cards.append(_card("Resistencia Extra", "+5.5% resistencia máxima", common, "energy_max", 0.055))
	cards.append(_card("Dulce Seguro", "+3% recompensa mínima", common, "reward_min", 0.03, "card_dulce_seguro"))
	cards.append(_card("Gomita Fresca", "+4% recompensa mínima", common, "reward_min", 0.04, "card_gomita_fresca"))
	cards.append(_card("Buen Reparto", "+5% recompensa mínima", common, "reward_min", 0.05))
	cards.append(_card("Dulce Ligero", "+3.5% recompensa mínima", common, "reward_min", 0.035, "card_dulce_ligero"))
	cards.append(_card("Receta Fiable", "+5.5% recompensa mínima", common, "reward_min", 0.055, "card_receta_fiable"))
	cards.append(_card("Gomita Valiosa", "+3% recompensa máxima", common, "reward_max", 0.03, "card_gomita_valiosa"))
	cards.append(_card("Gelatina Selecta", "+4% recompensa máxima", common, "reward_max", 0.04, "card_gelatina_selecta"))
	cards.append(_card("Dulce Premio", "+5% recompensa máxima", common, "reward_max", 0.05, "card_dulce_premio"))
	cards.append(_card("Dulce Pleno", "+3.5% recompensa máxima", common, "reward_max", 0.035, "card_dulce_pleno"))
	cards.append(_card("Dulce Sorpresa", "+5.5% recompensa máxima", common, "reward_max", 0.055, "card_dulce_sorpresa"))
	cards.append(_card("Pequeña Fortuna", "+0.3 p.p. probabilidad de Jackpot", common, "jackpot", 0.003))
	cards.append(_card("Buena Estrella", "+0.25 p.p. probabilidad de Jackpot", common, "jackpot", 0.0025))
	cards.append(_card("Premio Mayor", "+0.1x multiplicador de Jackpot", common, "jackpot_multiplier", 0.1))
	cards.append(_card("Buen Negocio", "+3% multiplicador de ganancias", common, "money", 0.03))
	cards.append(_card("Monedero", "+4% multiplicador de ganancias", common, "money", 0.04))
	cards.append(_card("Bolsa Rellena", "+5% multiplicador de ganancias", common, "money", 0.05))
	cards.append(_card("Bolsa Doblada", "+3.5% multiplicador de ganancias", common, "money", 0.035))
	cards.append(_card("Mercado Furioso", "+5.5% multiplicador de ganancias", common, "money", 0.055))
	cards.append(_card("Riqueza", "+6% multiplicador de ganancias", common, "money", 0.06))
	cards.append(_card("Punto Preciso", "+1 p.p. probabilidad de crítico", common, "crit_chance", 0.01))
	cards.append(_card("Foco", "+2 p.p. probabilidad de crítico", common, "crit_chance", 0.02))
	cards.append(_card("Filigrana", "+3 p.p. probabilidad de crítico", common, "crit_chance", 0.03))
	cards.append(_card("Golpe Firme", "+1.5 p.p. probabilidad de crítico", common, "crit_chance", 0.015))
	cards.append(_card("Mano Certera", "+1.2 p.p. probabilidad de crítico", common, "crit_chance", 0.012))
	cards.append(_card("Puntería", "+2.5 p.p. probabilidad de crítico", common, "crit_chance", 0.025))
	cards.append(_card("Ritmo Constante", "+3% ritmo de cubos", common, "launch_rate", 0.03))
	cards.append(_card("Viento Leve", "+4% ritmo de cubos", common, "launch_rate", 0.04))
	cards.append(_card("Rayo", "+5% ritmo de cubos", common, "launch_rate", 0.05))
	cards.append(_card("Giro Veloz", "+3.5% ritmo de cubos", common, "launch_rate", 0.035))
	cards.append(_card("Tormenta Ligera", "+5.5% ritmo de cubos", common, "launch_rate", 0.055))
	cards.append(_card("Gelatina al Vuelo", "+2.5% ritmo de cubos", common, "launch_rate", 0.025, "card_gelatina_al_vuelo"))
	cards.append(_card("Cubo Delicado", "-3% dureza de cubos", common, "block_hardness", -0.03, "card_cubo_delicado"))
	cards.append(_card("Cubo Frágil", "-4% dureza de cubos", common, "block_hardness", -0.04, "card_cubo_frágil"))
	cards.append(_card("Herramientas Baratas", "-3% precio de herramientas", common, "tool_price", -0.03, "card_herramientas_baratas"))
	cards.append(_card("Rebaja", "-4% precio de herramientas", common, "tool_price", -0.04))
	cards.append(_card("Compra Mayorista", "-5% precio de herramientas", common, "tool_price", -0.05))
	cards.append(_card("Recetas Baratas", "-3% precio de recetas", common, "recipe_price", -0.03, "card_recetas_baratas"))
	cards.append(_card("Oferta", "-4% precio de recetas", common, "recipe_price", -0.04))
	cards.append(_card("Venta al Por Mayor", "-5% precio de recetas", common, "recipe_price", -0.05))
	cards.append(_card("Mejoras Baratas", "-3% precio de mejoras", common, "upgrade_price", -0.03))
	cards.append(_card("Cambio Justo", "-4% precio de mejoras", common, "upgrade_price", -0.04))
	cards.append(_card("Ahorro Mayor", "-5% precio de mejoras", common, "upgrade_price", -0.05))
	cards.append(_card("Buen Progreso", "-3% objetivo de dinero del día", common, "order_target", -0.03))
	cards.append(_card("Día Corto", "-4% objetivo de dinero del día", common, "order_target", -0.04))
	cards.append(_card("Día Bueno", "-5% objetivo de dinero del día", common, "order_target", -0.05))
	cards.append(_card("Golpes Ligeros", "-4% coste de resistencia por golpe", common, "energy_cost", -0.04, "card_golpes_ligeros"))
	cards.append(_card("Mano Suave", "-6% coste de resistencia por golpe", common, "energy_cost", -0.06))
	cards.append(_card("Brillo Dorado", "+0.05 p.p. probabilidad de gomita dorada", common, "golden_gummy_chance", 0.0005))
	cards.append(_card("Toque Brillante", "+0.1 p.p. probabilidad de gomita dorada", common, "golden_gummy_chance", 0.001))
	cards.append(_card("Impacto Experto", "+6.5% potencia", common, "damage", 0.065, "card_impacto_experto"))
	cards.append(_card("Cadena de Gomitas", "+x0.1 al multiplicador de racha", common, "streak_bonus", 0.1, "card_cadena_de_gomitas"))

	# --------------------------------------------------------------------------
	# Pool raro: 29 cartas de efecto único y magnitud mayor.
	# --------------------------------------------------------------------------
	cards.append(_card("Impacto Superior", "+9% potencia", rare, "damage", 0.09, "card_impacto_superior"))
	cards.append(_card("Impacto Devastador", "+12% potencia", rare, "damage", 0.12, "card_impacto_devastador"))
	cards.append(_card("Reserva Extra", "+9% resistencia máxima", rare, "energy_max", 0.09))
	cards.append(_card("Reserva Titánica", "+12% resistencia máxima", rare, "energy_max", 0.12))
	cards.append(_card("Receta Rica", "+9% recompensa mínima", rare, "reward_min", 0.09, "card_receta_rica"))
	cards.append(_card("Receta Generosa", "+12% recompensa mínima", rare, "reward_min", 0.12, "card_receta_generosa"))
	cards.append(_card("Gomita Selecta", "+9% recompensa máxima", rare, "reward_max", 0.09, "card_gomita_selecta"))
	cards.append(_card("Gomita Exuberante", "+12% recompensa máxima", rare, "reward_max", 0.12, "card_gomita_exuberante"))
	cards.append(_card("Fortuna Creciente", "+0.6 p.p. probabilidad de Jackpot", rare, "jackpot", 0.006))
	cards.append(_card("Fortuna Dorada", "+1 p.p. probabilidad de Jackpot", rare, "jackpot", 0.01))
	cards.append(_card("Jackpot Mejorado", "+0.3x multiplicador de Jackpot", rare, "jackpot_multiplier", 0.3))
	cards.append(_card("Negocio Próspero", "+9% multiplicador de ganancias", rare, "money", 0.09))
	cards.append(_card("Mercado Dorado", "+12% multiplicador de ganancias", rare, "money", 0.12))
	cards.append(_card("Golpe Certero", "+3.5 p.p. probabilidad de crítico", rare, "crit_chance", 0.035))
	cards.append(_card("Golpe Vibrante", "+4.5 p.p. probabilidad de crítico", rare, "crit_chance", 0.045, "card_golpe_vibrante"))
	cards.append(_card("Ritmo Fuerte", "+9% ritmo de cubos", rare, "launch_rate", 0.09))
	cards.append(_card("Tormenta de Cubos", "+12% ritmo de cubos", rare, "launch_rate", 0.12, "card_tormenta_de_cubos"))
	cards.append(_card("Cubo Frágil II", "-7% dureza de cubos", rare, "block_hardness", -0.07, "card_cubo_frágil_ii"))
	cards.append(_card("Gelatina Blanda", "-10% dureza de cubos", rare, "block_hardness", -0.10, "card_gelatina_blanda"))
	cards.append(_card("Toque Dorado", "+0.2 p.p. probabilidad de gomita dorada", rare, "golden_gummy_chance", 0.002))
	cards.append(_card("Gelatina Dorada", "+0.3 p.p. probabilidad de gomita dorada", rare, "golden_gummy_chance", 0.003, "card_gelatina_dorada"))
	cards.append(_card("Golpe Eficiente", "-12% coste de resistencia por golpe", rare, "energy_cost", -0.12, "card_golpe_eficiente"))
	cards.append(_card("Día Favorable", "-8% objetivo de dinero del día", rare, "order_target", -0.08))
	cards.append(_card("Comerciante", "-6% precio de herramientas, recetas y mejoras", rare, "all_prices", -0.06))
	cards.append(_card("Buen Utillaje", "-8% precio de herramientas", rare, "tool_price", -0.08, "card_buen_utillaje"))
	cards.append(_card("Cesta de Ofertas", "-8% precio de recetas", rare, "recipe_price", -0.08))
	cards.append(_card("Tecnología de Punta", "-8% precio de mejoras", rare, "upgrade_price", -0.08))
	cards.append(_card("Ritmo de Campeón", "+x0.2 al multiplicador de racha", rare, "streak_bonus", 0.2))
	cards.append(_card("Pie Firme", "El primer caramelo endurecido del día no quita resistencia", rare, "first_candy_free", 1))

	# --------------------------------------------------------------------------
	# Pool épico: 9 cartas de magnitud alta.
	# --------------------------------------------------------------------------
	cards.append(_card("Impacto Supremo", "+18% potencia", epic, "damage", 0.18, "card_impacto_supremo"))
	cards.append(_card("Fortuna Suprema", "+1.5 p.p. probabilidad de Jackpot", epic, "jackpot", 0.015))
	cards.append(_card("Golpe Perfecto", "+8 p.p. probabilidad de crítico", epic, "crit_chance", 0.08))
	cards.append(_card("Dulce Diluvio", "+18% recompensa máxima", epic, "reward_max", 0.18, "card_dulce_diluvio"))
	cards.append(_card("Coloso", "+18% resistencia máxima", epic, "energy_max", 0.18))
	cards.append(_card("Meteoro", "+18% ritmo de cubos", epic, "launch_rate", 0.18))
	cards.append(_card("Leyenda Dorada", "+0.6 p.p. probabilidad de gomita dorada", epic, "golden_gummy_chance", 0.006))
	cards.append(_card("Furia de la Racha", "+x0.5 al multiplicador de racha", epic, "streak_bonus", 0.5))
	cards.append(_card("Rompecaramelos", "+1 p.p. probabilidad de romper caramelo endurecido", epic, "candy_break_chance", 0.01, "card_rompecaramelos"))

	# --------------------------------------------------------------------------
	# Pool legendario: 5 cartas de magnitud muy alta.
	# --------------------------------------------------------------------------
	cards.append(_card("Impacto Colosal", "+28% potencia", legendary, "damage", 0.28, "card_impacto_colosal"))
	cards.append(_card("Jackpot Legendario", "+1x multiplicador de Jackpot", legendary, "jackpot_multiplier", 1.0))
	cards.append(_card("Tormenta Perfecta", "+28% ritmo de cubos", legendary, "launch_rate", 0.28))
	cards.append(_card("Racha Infinita", "+x1.0 al multiplicador de racha", legendary, "streak_bonus", 1.0))
	cards.append(_card("Demoledor", "+3 p.p. probabilidad de romper caramelo endurecido", legendary, "candy_break_chance", 0.03))

	# --------------------------------------------------------------------------
	# Pool mítico: 2 cartas.
	# --------------------------------------------------------------------------
	cards.append(_card("Divinidad", "+12 p.p. probabilidad de crítico", mythic, "crit_chance", 0.12))
	cards.append(_card("Racha Eterna", "Mantiene el conteo de racha entre días", mythic, "streak_keep", 1))
	return cards

# Los IDs activos son canónicos; SaveMigration traduce descubrimientos antiguos.
static func _card(title: String, desc: String, rarity: String, effect_type: String, effect_value: float, card_id: String = "") -> Dictionary:
	return {"id": card_id if not card_id.is_empty() else "card_" + title.to_lower().replace(" ", "_"), "title": title, "desc": desc, "icon": "🃏", "rarity": rarity, "color": rarity_color(rarity), "effect_type": effect_type, "effect_value": effect_value}

static func rarity_color(rarity: String) -> Color:
	match rarity:
		"Común": return Color(0.3, 0.7, 1.0)
		"Rara": return Color(0.3, 0.9, 0.4)
		"Épica": return Color(0.8, 0.4, 1.0)
		"Legendaria": return Color(1.0, 0.75, 0.1)
		"Mítico": return Color("#FF2020")
		_: return Color(1.0, 0.4, 0.8)

# Probabilidad por SIMPLE DISTRIBUCIÓN: como el pool está bien balanceado
# (63 Común / 29 Rara / 9 Épica / 5 Legendaria / 2 Mítico), el azar puro ya
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
