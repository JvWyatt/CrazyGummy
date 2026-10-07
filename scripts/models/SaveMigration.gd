class_name SaveMigration
extends RefCounted
## Única frontera de compatibilidad con los guardados de Crazy Fruit y la fase temática.
## No depende de autoloads ni de los catálogos: puede ejecutarse antes de cargarlos.

const CURRENT_VERSION: int = 3
const LEGACY_SAVE_FILE_PATH: String = "user://fruit_cutter_save.json"
const LEGACY_APP_NAMES: Array[String] = ["Crazy Fruit", "Fruit Cutter"]

static func legacy_save_paths() -> Array[String]:
	var paths: Array[String] = [LEGACY_SAVE_FILE_PATH]
	# En escritorio, user:// cambia de carpeta cuando cambia el nombre de app.
	# Android/iOS usan el sandbox de la instalación; no buscar fuera de él.
	if OS.get_name() in ["Linux", "Windows", "macOS"]:
		var app_root: String = OS.get_user_data_dir().get_base_dir()
		for app_name: String in LEGACY_APP_NAMES:
			paths.append(app_root.path_join(app_name).path_join(LEGACY_SAVE_FILE_PATH.get_file()))
	return paths

const RECIPE_IDS: Dictionary = {
	"strawberry": "bear_classic", "banana": "ring", "peach": "ring_premium",
	"cherry": "worm", "orange": "worm_premium", "apple": "bottle",
	"pear": "bottle_premium", "kiwi": "heart", "mango": "heart_premium",
	"lemon": "fish", "watermelon": "fish_premium", "melon": "crocodile",
	"pineapple": "crocodile_premium", "papaya": "shark", "coconut": "shark_premium",
	"avocado": "dragon", "dragon_fruit": "dragon_premium", "guava": "unicorn",
	"quince": "unicorn_premium", "pumpkin": "bear_crown",
}
const TOOL_IDS: Dictionary = {
	"weapon_fist": "tool_fists", "weapon_fork": "tool_confectioner_knife",
	"weapon_table_knife": "tool_confectioner_hatchet", "weapon_scissors": "tool_gummy_hammer",
	"weapon_box_cutter": "tool_sugar_mallet", "weapon_knife": "tool_shredder_axe",
	"weapon_machete": "tool_candy_crusher", "weapon_axe": "tool_hydraulic_hammer",
	"weapon_sword": "tool_gummy_crusher", "weapon_chainsaw": "tool_crazy_hammer",
}
const SAVE_KEYS: Dictionary = {
	"unlocked_fruits": "unlocked_recipes", "unlocked_knives": "unlocked_tools",
	"equipped_knife": "equipped_tool", "total_fruits_cut": "total_gummies_produced",
}
const METRIC_KEYS: Dictionary = {
	"fruits_cut": "gummies_produced", "golden_fruits": "golden_gummies",
	"golden_fruits_in_one_day": "golden_gummies_in_one_day", "fruits_unlocked": "recipes_unlocked",
	"knives_owned": "tools_owned", "multi_cut_5": "multi_break_5", "stones_hit": "candies_hit",
}
const FLAG_KEYS: Dictionary = {
	"day_with_fist": "day_with_fists", "day_with_fork": "day_with_confectioner_knife",
	"day_with_knife": "day_with_shredder_axe", "day_with_axe": "day_with_hydraulic_hammer",
	"day_with_sword": "day_with_gummy_crusher", "day_with_top_knife": "day_with_crazy_hammer",
	"used_chainsaw": "equipped_crazy_hammer", "started_with_fist": "produced_with_fists",
	"day_unchanged_weapon": "day_unchanged_tool", "fresa_y_naranja_day": "bear_and_premium_worm_day",
}
const ACHIEVEMENT_IDS: Dictionary = {
	"aprendiz_de_corte": "aprendiz_de_gelatina", "cosechador_experto": "experto_en_gelatina",
	"maestro_del_corte": "maestro_del_impacto", "leyenda_frutal": "leyenda_gummy", "dios_del_corte": "universo_de_gomitas",
	"milionario_frutal": "millonario_gummy", "inversor_fruta": "gran_inversor", "magnate_frutal": "magnate_gummy", "tycoon_frutal": "imperio_dulce",
	"cosecha_doradita": "dulce_oro", "arsenal_frutal": "utillaje_gummy", "lider_de_corte": "procesado_extremo",
	"frutero": "recetario_inicial", "granjero": "recetario_experto", "huerta_completa": "recetario_completo",
	"cuchillero": "triturador_experto", "hachador": "golpe_hidraulico", "espadachin": "maestro_crusher", "central_frutal": "herramienta_fiel",
	"cosecha_doblada": "ritmo_dulce", "dios_frutal": "mito_gummy", "fruta_termina_rapido": "meta_ultimo_instante", "fruits_and_breaks": "dulce_contraste",
	"cocoo": "tiburon_de_lujo", "sandia_gigante": "pez_de_lujo", "calabaza_mago": "rey_gummy",
	"pitahaya": "dragon_de_lujo", "aguacate": "dulce_dragon", "membrillo": "unicornio_de_lujo", "kiwi": "dulce_corazon",
	"mango": "corazon_de_lujo", "limon": "dulce_pez", "pera": "botella_de_lujo", "durazno": "aro_de_lujo",
	"cereza": "dulce_gusano", "naranja": "gusano_de_lujo", "manzana": "dulce_botella", "banana_dorada": "dulce_aro",
	"guayaba": "dulce_unicornio", "piña": "cocodrilo_de_lujo", "melón": "dulce_cocodrilo", "papaya": "dulce_tiburon",
	"fresa_preferida": "osito_preferido", "fresa_y_naranja": "dulce_duo", "afilador": "impacto_preciso", "filo_critico": "impacto_critico",
	"coleccionista_piedras": "dulce_tropiezo", "cantero_implacable": "caramelo_implacable",
}
const CARD_IDS: Dictionary = {
	"card_filo_ligero": "card_impacto_ligero", "card_filo_de_acero": "card_impacto_de_acero",
	"card_filo_afilado": "card_impacto_preciso", "card_golpe_letal": "card_golpe_intenso",
	"card_cosecha_segura": "card_dulce_seguro", "card_fruto_fresco": "card_gomita_fresca",
	"card_cosecha_ligera": "card_dulce_ligero", "card_suelo_fertil": "card_receta_fiable",
	"card_fruta_valiosa": "card_gomita_valiosa", "card_jugo_maduro": "card_gelatina_selecta",
	"card_cosecha_doble": "card_dulce_premio", "card_cosecha_plena": "card_dulce_pleno", "card_cosecha_amplia": "card_dulce_sorpresa",
	"card_filo_en_el_viento": "card_gelatina_al_vuelo", "card_fruta_delicada": "card_cubo_delicado", "card_fruta_frágil": "card_cubo_frágil",
	"card_armas_baratas": "card_herramientas_baratas", "card_frutas_baratas": "card_recetas_baratas",
	"card_cortes_ligeros": "card_golpes_ligeros", "card_filo_del_experto": "card_impacto_experto", "card_cadena_de_cortes": "card_cadena_de_gomitas",
	"card_filo_superior": "card_impacto_superior", "card_filo_devastador": "card_impacto_devastador",
	"card_cosecha_rica": "card_receta_rica", "card_cosecha_abundante": "card_receta_generosa",
	"card_cosecha_mayor": "card_gomita_selecta", "card_cosecha_exuberante": "card_gomita_exuberante",
	"card_golpe_mortal": "card_golpe_vibrante", "card_tormenta_de_frutas": "card_tormenta_de_cubos",
	"card_fruta_frágil_ii": "card_cubo_frágil_ii", "card_fruta_rompible": "card_gelatina_blanda",
	"card_cosecha_dorada": "card_gelatina_dorada", "card_corte_eficiente": "card_golpe_eficiente",
	"card_mayorista_de_armas": "card_buen_utillaje", "card_filo_supremo": "card_impacto_supremo",
	"card_cosecha_torrencial": "card_dulce_diluvio", "card_rompepiedras": "card_rompecaramelos", "card_filazo_épico": "card_impacto_colosal",
}

static func migrate(source: Dictionary) -> Dictionary:
	var result: Dictionary = source.duplicate(true)
	for old_key: String in SAVE_KEYS:
		var new_key: String = SAVE_KEYS[old_key]
		if result.has(old_key):
			if not result.has(new_key):
				result[new_key] = result[old_key]
			elif result[new_key] is Array and result[old_key] is Array:
				result[new_key] = result[new_key] + result[old_key]
			elif result[new_key] is int or result[new_key] is float:
				result[new_key] = maxf(float(result[new_key]), float(result[old_key]))
			result.erase(old_key)
	for key: String in ["unlocked_recipes", "unlocked_tools", "discovered_cards"]:
		if result.get(key) is Array:
			var mapping: Dictionary = RECIPE_IDS if key == "unlocked_recipes" else (TOOL_IDS if key == "unlocked_tools" else CARD_IDS)
			result[key] = _map_ids(result[key], mapping)
	if result.has("equipped_tool"):
		result["equipped_tool"] = TOOL_IDS.get(str(result["equipped_tool"]), result["equipped_tool"])
	if result.get("achievements") is Dictionary:
		var achievements: Dictionary = result["achievements"]
		if achievements.get("unlocked") is Array:
			achievements["unlocked"] = _map_ids(achievements["unlocked"], ACHIEVEMENT_IDS)
		if achievements.get("metrics") is Dictionary:
			var metric_mapping: Dictionary = METRIC_KEYS.duplicate()
			for old_id: String in RECIPE_IDS:
				metric_mapping["cut_" + old_id] = "produced_" + str(RECIPE_IDS[old_id])
			achievements["metrics"] = _map_values(achievements["metrics"], metric_mapping, false)
		if achievements.get("flags") is Dictionary:
			achievements["flags"] = _map_values(achievements["flags"], FLAG_KEYS, true)
	result["version"] = CURRENT_VERSION
	return result

static func _map_ids(ids: Array, mapping: Dictionary) -> Array:
	var mapped: Array = []
	for id: Variant in ids:
		var canonical: Variant = mapping.get(str(id), id)
		if not mapped.has(canonical):
			mapped.append(canonical)
	return mapped

static func _map_values(values: Dictionary, mapping: Dictionary, flags: bool) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in values:
		var canonical: String = str(mapping.get(str(key), key))
		if result.has(canonical):
			# Un save mixto no debe duplicar progreso al cargarlo varias veces.
			result[canonical] = (bool(result[canonical]) or bool(values[key])) if flags else maxf(float(result[canonical]), float(values[key]))
		else:
			result[canonical] = values[key]
	return result
