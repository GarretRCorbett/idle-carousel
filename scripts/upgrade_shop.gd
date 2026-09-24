class_name UpgradeShop
extends PanelContainer
## Builds one row per upgrade from the catalog: name + description on the
## left, a cost button on the right. Rows appear once their prerequisite is
## bought and disappear when purchased. Unaffordable rows are dimmed.

## Button text; %d is the cost. TODO(Garret): text
@export var cost_format: String = "%d"
## Tint for rows you can't afford yet.
@export var unaffordable_modulate: Color = Color(1.0, 1.0, 1.0, 0.45)
@export var row_separation: int = 8

@onready var _rows: VBoxContainer = %UpgradeRows

var _row_by_id: Dictionary[StringName, HBoxContainer] = {}
var _button_by_id: Dictionary[StringName, Button] = {}


func _ready() -> void:
	for upgrade in UpgradeManager.get_definitions():
		_add_row(upgrade)
	GameState.gold_changed.connect(func(_b: float, _d: float) -> void: _refresh())
	GameState.run_reset.connect(_refresh)
	UpgradeManager.upgrade_purchased.connect(func(_id: StringName) -> void: _refresh())
	_refresh()


func _add_row(upgrade: UpgradeData) -> void:
	var row := HBoxContainer.new()
	row.name = String(upgrade.id)
	row.add_theme_constant_override("separation", row_separation)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = upgrade.display_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var desc_label := Label.new()
	desc_label.text = upgrade.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(name_label)
	text.add_child(desc_label)

	var button := Button.new()
	button.text = cost_format % upgrade.cost_gold
	button.custom_minimum_size = Vector2(72, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(UpgradeManager.purchase.bind(upgrade.id))

	row.add_child(text)
	row.add_child(button)
	_rows.add_child(row)
	_row_by_id[upgrade.id] = row
	_button_by_id[upgrade.id] = button


func _refresh() -> void:
	for id in _row_by_id:
		var row := _row_by_id[id]
		row.visible = UpgradeManager.is_visible_in_shop(id)
		var can_buy := UpgradeManager.can_purchase(id)
		_button_by_id[id].disabled = not can_buy
		row.modulate = Color.WHITE if can_buy else unaffordable_modulate
