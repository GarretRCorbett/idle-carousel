extends Node
## Dev tool, not part of the game: plays the first boss fight (Leaf Storm)
## headless with a pre-boss build and a clicking rate, and prints how long it
## took, the lowest carousel health, and stall time. Re-run after tuning the
## Storm (resources/enemies/leaf_storm.tres, storm_leaf.tres, the Storm's
## exports) or the pre-boss mounts:
##   "$GODOT" --headless --audio-driver Dummy --path . res://tools/boss_sim.tscn
## The simulated player only clicks the Storm (then its split Leaves) and
## cranks when stalled; it never Boosts or clicks storm leaves, so real play
## has more tools. Target (step6_plan.md): a relaxed 1.5 clicks/s wins in
## 55-75 s with some pressure; no clicking loses.

## [label, Wolves bought, clicks per second]
const SCENARIOS := [
	["Horse+Wolf, 1.5 clicks/s", 1, 1.5],
	["Horse+Wolf, 3 clicks/s", 1, 3.0],
	["Horse+2 Wolves, 1.5 clicks/s", 2, 1.5],
	["Horse+Wolf, no clicks", 1, 0.0],
]

func _ready() -> void:
	for s in SCENARIOS:
		_run(s[0], s[1], s[2])
	get_tree().quit()

func _run(label: String, wolves: int, cps: float) -> void:
	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(game)
	GameState.reset_run()
	(game.get_node("WaveManager") as WaveManager).set_auto(false)
	GameState.add_gold(100000.0)
	for i in wolves:
		UpgradeManager.purchase(&"mount_slot")
		UpgradeManager.purchase(&"wolf")
	for i in 60:
		GameState.record_kill(0)
	var result := [""]
	game.get_encounter().ended.connect(func(v: bool, _f: bool) -> void: result[0] = "WIN" if v else "LOSS")
	game.challenge_boss()
	var router := game.get_node("World/ClickRouter") as ClickRouter
	var dt := 1.0 / 60.0
	var t := 0.0
	var next_click := 0.0
	var min_health := GameState.get_health()
	var stalled := 0.0
	var max_latched := 0
	var boss_dead_at := -1.0
	while result[0] == "" and t < 200.0:
		game._physics_process(dt)
		t += dt
		min_health = minf(min_health, GameState.get_health())
		if GameState.is_stalled():
			stalled += dt
			GameState.set_boost_held(true)  # crank
		else:
			GameState.set_boost_held(false)
		max_latched = maxi(max_latched, GameState.get_latched_count())
		var enc := game.get_encounter()
		if boss_dead_at < 0.0 and enc.get_phase() == BossEncounter.Phase.CLEANUP:
			boss_dead_at = t
		if cps > 0.0 and t >= next_click:
			next_click = t + 1.0 / cps
			var target: EnemyBase = enc.get_boss()
			if target == null or not target.is_active():
				for c in game.get_node("World/EnemyLayer").get_children():
					var e := c as EnemyBase
					if e != null and e.is_active() and e.encounter_role == EnemyBase.EncounterRole.REQUIRED:
						target = e
						break
			if target != null and target.is_active():
				router.route_click(target.global_position)
	print("%-32s %s at %5.1fs  boss dead %5.1fs  min health %5.1f  stalled %4.1fs  max latched %d" % [label, result[0], t, boss_dead_at, min_health, stalled, max_latched])
	remove_child(game)
	game.free()
