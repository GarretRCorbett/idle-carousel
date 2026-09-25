extends Node
## Dev tool, not part of the game: plays a whole run headless with a scripted
## player, using the real game (waves, combat, bosses, shop), and prints when
## each purchase, boss attempt and tier happened. It answers "how long does a
## run take, and where does it stall?" for the pricing pass (Phase 3 Step 8).
##   "$GODOT" --headless --audio-driver Dummy --path . res://tools/economy_sim.tscn
##   "$GODOT" --headless --audio-driver Dummy --path . res://tools/economy_sim.tscn -- 3.0 1.0
## Arguments: hours to simulate (default 4), clicks per second (default 1),
## random seed (default 1; the run seed and waves follow it, so runs repeat),
## clicks per second during boss fights (default: the same as the second).
##
## The scripted player: Auto waves on; clicks the boss, else the enemy nearest
## the carousel; cranks when stalled (never Boosts); follows BUILD_ORDER first
## (saving up for each item; items it can't buy yet for other reasons, like a
## boss gate, wait until they can be bought); fills new mount slots in
## MOUNT_ORDER; otherwise buys the cheapest affordable upgrade from its list;
## challenges a boss as soon as the gate is met (after a loss, waits
## RETRY_WAIT_SECONDS); moves up to each newly unlocked tier. Real players
## do better (Boost, targeting), so treat times as a slightly slow player.

## Mounts it puts in each new slot, in order (the starting Horse is first).
const MOUNT_ORDER: Array[StringName] = [&"wolf", &"wolf", &"giraffe", &"elephant", &"panda"]
## Everything else it may buy, cheapest first. (Boost Power is skipped: the
## scripted player never Boosts.)
const UPGRADES: Array[StringName] = [
	&"carousel_speed", &"click_damage", &"wolf_fang", &"mount_slot", &"ticket_booth",
	&"horse_tier2", &"wolf_tier2", &"giraffe_tier2", &"elephant_tier2", &"panda_tier2",
]
## A plausible player's priorities (GDD early game: speed, then a slot and
## the Wolf). Each is bought in order, saving up for it.
const BUILD_ORDER: Array[StringName] = [
	&"click_damage", &"carousel_speed", &"mount_slot", &"wolf", &"wolf_fang",
	&"carousel_speed", &"click_damage", &"mount_slot", &"wolf", &"wolf_fang",
	&"click_damage", &"carousel_speed", &"click_damage",
	# After Leaf Storm:
	&"mount_slot", &"giraffe", &"ticket_booth", &"wolf_tier2", &"horse_tier2",
	&"mount_slot", &"elephant", &"giraffe_tier2", &"elephant_tier2",
]
const DT := 1.0 / 60.0
## Game seconds simulated per rendered frame (the frame end frees removed enemies).
const SECONDS_PER_FRAME := 5.0
const RETRY_WAIT_SECONDS := 150.0

var _game: Game
var _waves: WaveManager
var _router: ClickRouter
var _hours := 4.0
var _cps := 1.0
var _fight_cps := 1.0
var _t := 0.0
var _next_wave := 0.0
var _next_click := 0.0
var _retry_at := 0.0
var _stalled := 0.0
var _tier_reached: Array[float] = [0.0]
var _done := false
var _build_step := 0
var _boss_health_left := 1.0
var _split_left := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_hours = float(args[0])
	if args.size() > 1:
		_cps = float(args[1])
	seed(int(args[2]) if args.size() > 2 else 1)
	_fight_cps = float(args[3]) if args.size() > 3 else _cps
	_game = (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(_game)
	_waves = _game.get_node("WaveManager") as WaveManager
	_waves.set_auto(false)  # the sim sends timed waves itself (Timer nodes run on real time)
	_router = _game.get_node("World/ClickRouter") as ClickRouter
	_next_wave = _waves.first_wave_delay
	_game.get_encounter().ended.connect(_on_fight_ended)
	_game.get_encounter().boss_health_changed.connect(func(f: float) -> void: _boss_health_left = f)
	_game.get_encounter().remaining_changed.connect(func(n: int) -> void: _split_left = n)
	_game.get_encounter().started.connect(func(_r: int) -> void:
		_boss_health_left = 1.0
		_split_left = 0)
	GameState.boss_beaten.connect(func(rank: int, first: bool) -> void:
		if first:
			_log("TIER %d unlocked (beat %s)" % [rank + 2, _game.tier_catalog.get_tier(rank).boss.boss_id]))
	UpgradeManager.upgrade_purchased.connect(func(id: StringName) -> void:
		_log("buy %-15s lvl %d  (gold left %s)" % [id, UpgradeManager.get_level(id), roundi(GameState.get_gold())]))
	print("time      event")


func _process(_delta: float) -> void:
	if _done:
		return
	var steps := roundi(SECONDS_PER_FRAME / DT)
	for i in steps:
		_step()
		if _t >= _hours * 3600.0 or GameState.get_bosses_beaten() >= _game.tier_catalog.tiers.size():
			_finish()
			return


func _step() -> void:
	_t += DT
	var encounter := _game.get_encounter()
	if not encounter.is_active() and _t >= _next_wave:
		_waves.spawn_wave()
		_next_wave = _t + _waves.get_wave_interval()
	elif encounter.is_active():
		_next_wave = maxf(_next_wave, _t + 1.0)
	_game._physics_process(DT)
	GameState.set_boost_held(GameState.is_stalled())
	if GameState.is_stalled():
		_stalled += DT
	var cps := _fight_cps if GameState.is_boss_active() else _cps
	if cps > 0.0 and _t >= _next_click:
		_next_click = _t + 1.0 / cps
		_click()
	if roundi(_t / DT) % 30 == 0:
		_shop()
		_maybe_challenge()


func _click() -> void:
	var boss := _game.get_encounter().get_boss()
	var target: EnemyBase = boss if boss != null and boss.is_active() else null
	if target == null:
		var best := INF
		var center := (_game.get_node("World/Carousel") as Carousel).global_position
		for child in _game.get_node("World/EnemyLayer").get_children():
			var enemy := child as EnemyBase
			if enemy == null or not enemy.is_active():
				continue
			var d := enemy.global_position.distance_squared_to(center)
			if d < best:
				best = d
				target = enemy
	if target != null:
		_router.route_click(target.global_position)


func _shop() -> void:
	# The build order first: buy the first item that can be bought, and save
	# for it if it's just too expensive.
	while _build_step < BUILD_ORDER.size():
		var item := BUILD_ORDER[_build_step]
		var upgrade := UpgradeManager.get_definition(item)
		if UpgradeManager.is_maxed(item):
			_build_step += 1
			continue
		if UpgradeManager.can_purchase(item):
			UpgradeManager.purchase(item)
			_build_step += 1
			return
		# Blocked by more than Gold (a boss gate, no slot yet): come back later.
		if GameState.is_boss_gated(upgrade) or (upgrade.effect_type == UpgradeData.EffectType.BUY_MOUNT and not GameState.has_free_mount_slot()):
			break
		return  # saving up
	# New slot: fill it with the next mount in the plan.
	var roster := GameState.get_mount_roster()
	if GameState.has_free_mount_slot() and roster.size() - 1 < MOUNT_ORDER.size():
		var next := MOUNT_ORDER[roster.size() - 1]
		if UpgradeManager.can_purchase(next):
			UpgradeManager.purchase(next)
		return
	var cheapest: StringName = &""
	var cheapest_cost := INF
	for id in UPGRADES:
		if UpgradeManager.can_purchase(id) and UpgradeManager.get_cost(id) < cheapest_cost:
			cheapest = id
			cheapest_cost = UpgradeManager.get_cost(id)
	if cheapest != &"":
		UpgradeManager.purchase(cheapest)


func _maybe_challenge() -> void:
	var rank := GameState.get_bosses_beaten()
	if GameState.is_boss_active() or _t < _retry_at or rank >= _game.tier_catalog.tiers.size():
		return
	if GameState.get_selected_tier() != rank:
		if GameState.set_selected_tier(rank):
			_tier_reached.append(_t)
	if BossEncounter.can_challenge(_game.tier_catalog.get_tier(rank)) and _game.challenge_boss():
		_log("challenge %s" % _game.tier_catalog.get_tier(rank).boss.boss_id)


func _on_fight_ended(victory: bool, _first: bool) -> void:
	_log("  -> %s (carousel health %d, boss health left %d%%, split pieces left %d)" % ["WIN" if victory else "LOSS",
			roundi(GameState.get_health()), roundi(_boss_health_left * 100.0), _split_left])
	if not victory:
		_retry_at = _t + RETRY_WAIT_SECONDS


func _finish() -> void:
	_done = true
	print("\n== Summary (%.1f h simulated, %.1f clicks/s, %.1f in fights)" % [_t / 3600.0, _cps, _fight_cps])
	for i in _tier_reached.size():
		print("tier %d reached at %s" % [i + 1, _clock(_tier_reached[i])])
	print("bosses beaten: %d / %d" % [GameState.get_bosses_beaten(), _game.tier_catalog.tiers.size()])
	for rank in GameState.get_bosses_beaten():
		print("  boss %d first clear at %s" % [rank + 1, _clock(GameState.get_boss_clear_time(rank))])
	print("time stalled: %s   gold at end: %d" % [_clock(_stalled), roundi(GameState.get_gold())])
	get_tree().quit()


func _log(text: String) -> void:
	print("%s  %s" % [_clock(_t), text])


static func _clock(seconds: float) -> String:
	var s := roundi(seconds)
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
