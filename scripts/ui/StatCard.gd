class_name StatCard
extends PanelContainer
## Presentación editable en scenes/ui/components/StatCard.tscn.

var value_label: Label
var _icon_label: Label
var _name_label: Label

static func create() -> StatCard:
	var card := (load("res://scenes/ui/components/StatCard.tscn") as PackedScene).instantiate() as StatCard
	card._bind_nodes()
	return card

func _ready() -> void:
	_bind_nodes()

func _bind_nodes() -> void:
	value_label = get_node("Content/ValueLabel")
	_icon_label = get_node("Content/Header/IconHolder/IconLabel")
	_name_label = get_node("Content/Header/NameLabel")

func setup(icon: String, title: String, value: String, _value_color: Color) -> void:
	_icon_label.text = icon
	_icon_label.visible = not icon.is_empty()
	_name_label.text = title
	value_label.text = value
	tooltip_text = title + "\n" + value
