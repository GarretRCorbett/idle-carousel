extends Node
## Dev tool, not part of the game: plays tier boss fights headless with a build
## and a clicking rate, and prints how long each took, the lowest carousel
## health, and stall time. Re-run after tuning a boss (its EnemyData .tres,
## BossData .tres, or scene exports) or the mounts:
##   "$GODOT" --headless --audio-driver Dummy --path . res://tools/boss_sim.tscn
## The simulated player clicks the boss (then its required pieces) and cranks
## when stalled; it never Boosts or clicks summons, so real play has more
## tools. Builds are guesses at what a player owns by then (Step 8's economy
## simulator will replace them). Target (step6/step7 plans): a relaxed
## 1.5 clicks/s wins in roughly 60-80% of the timer, with some pressure.

## [label, tier rank, clicks per second, purchases (upgrade id, times)]
const SCENARIOS := [
	["Grey  Leaf Storm: Horse+Wolf", 0, 1.5, [[&"mount_slot", 1], [&"wolf", 1]]],
	["Grey  Leaf Storm: Horse+Wolf, no clicks", 0, 0.0, [[&"mount_slot", 1], [&"wolf", 1]]],
	["Green Stick Giant: 2 Wolves, Giraffe", 1, 1.5,
		[[&"mount_slot", 3], [&"wolf", 2], [&"giraffe", 1], [&"wolf_level", 2], [&"click_damage", 2]]],
	["Yellow Boulder: +Elephant, Wolf star 2", 2, 1.5,
		[[&"mount_slot", 4], [&"wolf", 2], [&"giraffe", 1], [&"elephant", 1],
		[&"wolf_level", 5], [&"click_damage", 4]]],
	["Orange Gilded Gale: +Sloth, Giraffe star 2", 3, 1.5,
		[[&"mount_slot", 5], [&"wolf", 2], [&"giraffe", 1], [&"elephant", 1], [&"sloth", 1],
		[&"wolf_level", 7], [&"giraffe_level", 4], [&"click_damage", 6]]],
	["Red   Ancient Log: Panda build", 4, 1.5,
		[[&"mount_slot", 5], [&"wolf", 2], [&"giraffe", 1], [&"elephant", 1],
		[&"wolf_level", 7], [&"giraffe_level", 4], [&"elephant_level", 4], [&"panda", 1],
		[&"click_damage", 8]]],
	["Charcoal Obsidian: late build", 5, 1.5,
		[[&"mount_slot", 5], [&"wolf", 2], [&"giraffe", 1], [&"elephant", 1],
		[&"wolf_level", 7], [&"giraffe_level", 4], [&"elephant_level", 4], [&"panda", 1],
		[&"panda_level", 4], [&"click_damage", 10]]],
]


func _ready() -> void:
	for s in SCENARIOS:
		_run(s[0], s[1], s[2], s[3])
	get_tree().quit()


func _run(label: String, rank: int, cps: float, purchases: Array) -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	GameState.reset_run()
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	GameState.add_gold(1.0e9)
	GameState.debug_set_bosses_beaten(rank)
	for purchase in purchases:
		for i in purchase[1]:
			if not UpgradeManager.purchase(purchase[0]):
				push_warning("%s: couldn't buy %s" % [label, purchase[0]])
	GameState.set_selected_tier(rank)
	var tier := game.tier_catalog.get_tier(rank)
	for i in tier.boss.kills_required:
		GameState.record_kill(rank)
	var result := [""]
	game.get_encounter().ended.connect(func(v: bool, _f: bool) -> void: result[0] = "WIN " if v else "LOSS")
	game.challenge_boss()
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var dt := 1.0 / 60.0
	var t := 0.0
	var next_click := 0.0
	var min_health := GameState.get_health()
	var stalled := 0.0
	var boss_dead_at := -1.0
	while result[0] == "" and t < 400.0:
		game._physics_process(dt)
		t += dt
		min_health = minf(min_health, GameState.get_health())
		GameState.set_boost_held(GameState.is_stalled())  # crank while stalled
		if GameState.is_stalled():
			stalled += dt
		var encounter := game.get_encounter()
		if boss_dead_at < 0.0 and encounter.get_phase() == BossEncounter.Phase.CLEANUP:
			boss_dead_at = t
		if cps > 0.0 and t >= next_click:
			next_click = t + 1.0 / cps
			var target: EnemyBase = encounter.get_boss()
			if target == null or not target.is_active():
				target = _first_required(game)
			if target != null and target.is_active():
				router.route_click(target.global_position)
	print("%-42s %s %5.1fs of %3ds (%3d%%)  boss dead %5.1fs  min health %5.1f  stalled %4.1fs" % [
			label, result[0], t, tier.boss.time_limit_seconds, roundi(100.0 * t / tier.boss.time_limit_seconds),
			boss_dead_at, min_health, stalled])
	remove_child(game)
	game.free()


func _first_required(game: Game) -> EnemyBase:
	for child in game.get_node("World/EnemyLayer").get_children():
		var enemy := child as EnemyBase
		if enemy != null and enemy.is_active() and enemy.encounter_role == EnemyBase.EncounterRole.REQUIRED:
			return enemy
	return null
