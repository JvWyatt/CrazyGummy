extends RefCounted
## Dos atlas vectoriales: misma escala, padding y acabado; sin datos de gameplay.
const SYMBOLS: Texture2D = preload("res://assets/crazy_gummy/ui/icons/symbols.svg")
const TOOLS: Texture2D = preload("res://assets/crazy_gummy/ui/icons/tools.svg")
const TOOL_IDS := ["tool_fists", "tool_confectioner_knife", "tool_confectioner_hatchet", "tool_gummy_hammer", "tool_sugar_mallet", "tool_shredder_axe", "tool_candy_crusher", "tool_hydraulic_hammer", "tool_gummy_crusher", "tool_crazy_hammer"]
const KEYS := ["prestige", "progress", "achievement", "card", "settings", "stats", "power", "energy", "rate", "recipe", "money", "lock"]

static func texture(key: String) -> Texture2D:
	var tool_index: int = TOOL_IDS.find(key)
	var index: int = tool_index if tool_index >= 0 else KEYS.find(key)
	if index < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = TOOLS if tool_index >= 0 else SYMBOLS
	atlas.region = Rect2(index * 64, 0, 64, 64)
	return atlas

static func for_title(title: String) -> String:
	if "Suerte" in title or "Jackpot" in title or "Fortuna" in title or "dorada" in title:
		return "prestige"
	if "Potencia" in title or "Maestría" in title or "crítico" in title:
		return "power"
	if "Resistencia" in title or "Experiencia" in title or "golpe" in title:
		return "energy"
	if "Ritmo" in title:
		return "rate"
	if "Ganancias" in title or "Negociación" in title or "Proveedor" in title or "Recompensa" in title:
		return "money"
	if "comodines" in title or "Comodines" in title:
		return "card"
	if "Gomitas" in title or "Dureza" in title:
		return "recipe"
	return "progress"

static func replace_label(label: Label, key: String) -> void:
	var icon := label.get_node_or_null("GummyIcon") as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = "GummyIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		label.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = ""
	label.custom_minimum_size = Vector2(32, 32)
	icon.texture = texture(key)
