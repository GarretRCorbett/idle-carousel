class_name UpgradeShop
extends PanelContainer
## One row per upgrade from the catalog, always listed in catalog order so rows
## never shift under the cursor. Upgrades have levels (e.g. 1 to 10); each row
## shows level pips, the next level's price, and a fill bar toward that price.
## Row states:
##   LOCKED      prerequisite not bought: dimmed, shows what it needs
##   SAVING      Gold below the next price: fill bar shows progress
##   AFFORDABLE  buy button enabled, bar full
##   MAXED       every level bought: marked done, no bar

enum RowState { LOCKED, SAVING, AFFORDABLE, MAXED }

# Wording (Garret's text).
## Buy button text; %d is the next level's price.
@export var cost_format: String = "%d"
## Shown on locked rows; %s is the prerequisite's name.
@export var requires_format: String = "Requires %s"
## Button text once every level is bought.
@export var maxed_mark: String = "✓"

@export_group("Look")
@export var locked_modulate: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var maxed_modulate: Color = Color(1.0, 1.0, 1.0, 0.7)
@export var row_separation: int = 4
@export var progress_bar_height: float = 6.0

@onready var _rows: VBoxContainer = %UpgradeRows

var _rows_by_id: Dictionary[StringName, ShopRow] = {}


class ShopRow:
	var root: VBoxContainer
	var status: Label
	var pips: LevelPips
	var button: Button
	var progress: ProgressBar


func _ready() -> void:
	for upgrade in UpgradeManager.get_definitions():
		_rows_by_id[upgrade.id] = _build_row(upgrade)
	GameState.gold_changed.connect(func(_b: float, _d: float) -> void: _refresh())
	GameState.run_reset.connect(_refresh)
	UpgradeManager.upgrade_purchased.connect(func(_id: StringName) -> void: _refresh())
	_refresh()


## The state a row should show right now.
static func get_row_state(id: StringName) -> RowState:
	if UpgradeManager.is_maxed(id):
		return RowState.MAXED
	var upgrade := UpgradeManager.get_definition(id)
	if upgrade.prerequisite_id != &"" and not UpgradeManager.is_purchased(upgrade.prerequisite_id):
		return RowState.LOCKED
	return RowState.AFFORDABLE if UpgradeManager.can_purchase(id) else RowState.SAVING


func _build_row(upgrade: UpgradeData) -> ShopRow:
	var row := ShopRow.new()
	row.root = VBoxContainer.new()
	row.root.name = String(upgrade.id)
	row.root.add_theme_constant_override("separation", row_separation)
	row.root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_label(upgrade.display_name, false))
	text.add_child(_label(upgrade.description, true))
	row.pips = LevelPips.new()
	row.pips.max_level = upgrade.max_level
	row.pips.visible = upgrade.max_level > 1
	text.add_child(row.pips)
	row.status = _label("", true)
	text.add_child(row.status)

	row.button = Button.new()
	row.button.custom_minimum_size = Vector2(72, 0)
	row.button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.button.focus_mode = Control.FOCUS_NONE
	row.button.pressed.connect(UpgradeManager.purchase.bind(upgrade.id))
	line.add_child(text)
	line.add_child(row.button)

	row.progress = ProgressBar.new()
	row.progress.custom_minimum_size = Vector2(0, progress_bar_height)
	row.progress.show_percentage = false
	row.progress.max_value = 1.0
	row.progress.mouse_filter = Control.MOUSE_FILTER_IGNORE

	row.root.add_child(line)
	row.root.add_child(row.progress)
	_rows.add_child(row.root)
	return row


func _label(text: String, wraps: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wraps:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _refresh() -> void:
	for id in _rows_by_id:
		var row := _rows_by_id[id]
		var upgrade := UpgradeManager.get_definition(id)
		var state := get_row_state(id)
		var cost := UpgradeManager.get_cost(id)
		row.pips.level = UpgradeManager.get_level(id)
		row.button.disabled = state != RowState.AFFORDABLE
		row.button.text = maxed_mark if state == RowState.MAXED else cost_format % cost
		row.progress.visible = state != RowState.MAXED
		row.progress.value = clampf(GameState.get_gold() / cost, 0.0, 1.0) if cost > 0.0 else 1.0
		row.status.visible = state == RowState.LOCKED
		if state == RowState.LOCKED:
			var prerequisite := UpgradeManager.get_definition(upgrade.prerequisite_id)
			row.status.text = requires_format % prerequisite.display_name
		match state:
			RowState.LOCKED:
				row.root.modulate = locked_modulate
			RowState.MAXED:
				row.root.modulate = maxed_modulate
			_:
				row.root.modulate = Color.WHITE
