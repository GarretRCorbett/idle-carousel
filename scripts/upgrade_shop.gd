class_name UpgradeShop
extends PanelContainer
## One row per upgrade from the catalog, on its tab (Carousel / Combat / Mounts),
## always listed in catalog order so rows never shift under the cursor. Upgrades have levels (e.g. 1 to 10); each row
## shows level pips, the next level's price, and a fill bar toward that price.
## Row states:
##   LOCKED      prerequisite not bought, or a mount with no empty slot:
##               dimmed, shows what it needs
##   SAVING      Gold below the next price: fill bar shows progress
##   AFFORDABLE  buy button enabled, bar full
##   MAXED       every level bought: marked done, no bar

enum RowState { LOCKED, SAVING, AFFORDABLE, MAXED }

# Wording: translation keys in localization/strings.csv. Placeholders are {0}, {1}...
@export var cost_key: String = "SHOP_COST"
@export var requires_key: String = "SHOP_REQUIRES"
@export var maxed_key: String = "SHOP_MAXED"
@export var needs_slot_key: String = "SHOP_NEEDS_SLOT"
@export var sell_key: String = "SHOP_SELL"
## Tab titles, in UpgradeData.Tab order.
@export var tab_title_keys: PackedStringArray = ["SHOP_TAB_CAROUSEL", "SHOP_TAB_COMBAT", "SHOP_TAB_MOUNTS"]

@export_group("Look")
@export var locked_modulate: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var maxed_modulate: Color = Color(1.0, 1.0, 1.0, 0.7)
@export var row_separation: int = 4
@export var progress_bar_height: float = 6.0

@export var row_list_separation: int = 12

@onready var _tabs: TabContainer = %ShopTabs

var _rows_by_id: Dictionary[StringName, ShopRow] = {}
var _pages: Array[VBoxContainer] = []


class ShopRow:
	var root: VBoxContainer
	var status: Label
	var pips: LevelPips
	var button: Button
	var sell_button: Button
	var progress: ProgressBar


func _ready() -> void:
	for i in UpgradeData.Tab.size():
		var page := VBoxContainer.new()
		page.name = "Tab%d" % i
		page.add_theme_constant_override("separation", row_list_separation)
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tabs.add_child(page)
		# A key: the tab bar translates titles itself.
		_tabs.set_tab_title(i, tab_title_keys[i] if i < tab_title_keys.size() else str(i))
		_pages.append(page)
	_tabs.tab_changed.connect(func(_tab: int) -> void: AudioManager.play_sfx(&"tab"))
	for upgrade in UpgradeManager.get_definitions():
		_rows_by_id[upgrade.id] = _build_row(upgrade)
	GameState.gold_changed.connect(func(_b: float, _d: float) -> void: _refresh())
	GameState.run_reset.connect(_refresh)
	GameState.mounts_changed.connect(func(_r: Array[StringName]) -> void: _refresh())
	UpgradeManager.upgrade_purchased.connect(func(_id: StringName) -> void: _refresh())
	UpgradeManager.upgrade_sold.connect(func(_id: StringName) -> void: _refresh())
	_refresh()


## The state a row should show right now.
static func get_row_state(id: StringName) -> RowState:
	if UpgradeManager.is_maxed(id):
		return RowState.MAXED
	if _locked_reason(id) != LockReason.NONE:
		return RowState.LOCKED
	return RowState.AFFORDABLE if UpgradeManager.can_purchase(id) else RowState.SAVING


enum LockReason { NONE, PREREQUISITE, NO_SLOT }


static func _locked_reason(id: StringName) -> LockReason:
	var upgrade := UpgradeManager.get_definition(id)
	if upgrade.prerequisite_id != &"" and not UpgradeManager.is_purchased(upgrade.prerequisite_id):
		return LockReason.PREREQUISITE
	if upgrade.effect_type == UpgradeData.EffectType.BUY_MOUNT and not GameState.has_free_mount_slot():
		return LockReason.NO_SLOT
	return LockReason.NONE


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
	# Keys: these labels translate themselves, including on a language change.
	text.add_child(_label(upgrade.display_name, false, true))
	text.add_child(_label(upgrade.description, true, true))
	row.pips = LevelPips.new()
	row.pips.max_level = upgrade.max_level
	row.pips.visible = upgrade.max_level > 1
	text.add_child(row.pips)
	row.status = _label("", true)
	text.add_child(row.status)

	row.button = Button.new()
	row.button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.button.custom_minimum_size = Vector2(72, 0)
	row.button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.button.focus_mode = Control.FOCUS_NONE
	row.button.pressed.connect(UpgradeManager.purchase.bind(upgrade.id))
	var buttons := VBoxContainer.new()
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.add_child(row.button)
	if upgrade.sell_refund_fraction > 0.0:
		row.sell_button = Button.new()
		row.sell_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.sell_button.focus_mode = Control.FOCUS_NONE
		row.sell_button.pressed.connect(UpgradeManager.sell.bind(upgrade.id))
		buttons.add_child(row.sell_button)
	line.add_child(text)
	line.add_child(buttons)

	row.progress = ProgressBar.new()
	row.progress.custom_minimum_size = Vector2(0, progress_bar_height)
	row.progress.show_percentage = false
	row.progress.max_value = 1.0
	row.progress.mouse_filter = Control.MOUSE_FILTER_IGNORE

	row.root.add_child(line)
	row.root.add_child(row.progress)
	_pages[upgrade.tab].add_child(row.root)
	return row


## `translates`: the text is a key the label translates itself. Otherwise the
## text arrives already translated and must not be translated again.
func _label(text: String, wraps: bool, translates: bool = false) -> Label:
	var label := Label.new()
	if not translates:
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wraps:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


## Language changed: rebuild the prices, status lines, and sell buttons.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _rows_by_id.is_empty():
		_refresh()


func _refresh() -> void:
	for id in _rows_by_id:
		var row := _rows_by_id[id]
		var upgrade := UpgradeManager.get_definition(id)
		var state := get_row_state(id)
		var cost := UpgradeManager.get_cost(id)
		row.pips.level = UpgradeManager.get_level(id)
		row.button.disabled = state != RowState.AFFORDABLE
		row.button.text = tr(maxed_key) if state == RowState.MAXED else tr(cost_key).format([NumberFormat.gold(cost)])
		row.progress.visible = state != RowState.MAXED
		row.progress.value = clampf(GameState.get_gold() / cost, 0.0, 1.0) if cost > 0.0 else 1.0
		row.status.visible = state == RowState.LOCKED
		if state == RowState.LOCKED:
			if _locked_reason(id) == LockReason.NO_SLOT:
				row.status.text = tr(needs_slot_key)
			else:
				var prerequisite := UpgradeManager.get_definition(upgrade.prerequisite_id)
				row.status.text = tr(requires_key).format([tr(prerequisite.display_name)])
		if row.sell_button != null:
			row.sell_button.disabled = not UpgradeManager.can_sell(id)
			row.sell_button.text = tr(sell_key).format([NumberFormat.gold(UpgradeManager.get_sell_refund(id))])
		match state:
			RowState.LOCKED:
				row.root.modulate = locked_modulate
			RowState.MAXED:
				row.root.modulate = maxed_modulate
			_:
				row.root.modulate = Color.WHITE
