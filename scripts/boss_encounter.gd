class_name BossEncounter
extends Node
## Runs one boss fight: the timer, the boss's summons (capped, no rewards),
## the required split children, and the win or the end of the attempt. Game
## creates it, ticks it (advance), and does the actual adding and removing of
## enemies through the two request signals, so every enemy still joins and
## leaves the world the normal way.
##
## Rules (Garret, 2026-09-24/25): a timed fight; failure (timeout or Give up)
## costs only time: Gold, unlocks and kill-gate progress stay, and retrying is
## free. First win: big Gold + the next tier. Repeat wins: smaller Gold.

## Add this enemy to the world (Game queues it for the next tick).
signal enemy_spawn_requested(enemy: EnemyBase)
## Take this enemy out of the world with no rewards.
signal enemy_removal_requested(enemy: EnemyBase)
signal started(tier_rank: int)
## Every tick during a fight.
signal time_changed(seconds_left: float)
## The boss's health, 0..1, when it changes.
signal boss_health_changed(fraction: float)
## After the boss body dies: required children still alive.
signal remaining_changed(count: int)
## The fight is over. first_clear: this win unlocked the next tier.
signal ended(victory: bool, first_clear: bool)

enum Phase { IDLE, FIGHTING, CLEANUP }

## At most this many summons alive or waiting to join; extra ones are dropped
## (never saved up for later).
@export_range(0, 500, 1) var max_summons: int = 45
## Bosses that fly in start this far from the center, from a random side
## (bosses with their own path, like Leaf Storm, place themselves).
@export_range(100.0, 1000.0, 1.0, "suffix:px") var spawn_radius: float = 420.0

## The carousel center, in the enemy layer's space. Set by Game.
var spawn_center: Vector2 = Vector2.ZERO
## Picks where bosses come from; seeded per run (GameState's run seed).
var rng := RandomNumberGenerator.new()

var _phase: Phase = Phase.IDLE
var _tier: TierData
var _boss: EnemyBoss
var _time_left: float = 0.0
## Everything this fight added (boss, summons, children), to remove at the end.
var _members: Array[EnemyBase] = []
## Split children still alive, by instance ID.
var _required: Dictionary[int, EnemyBase] = {}
var _health_shown: float = -1.0


func is_active() -> bool:
	return _phase != Phase.IDLE


func get_phase() -> Phase:
	return _phase


func get_tier() -> TierData:
	return _tier


func get_boss() -> EnemyBoss:
	return _boss


func get_time_left() -> float:
	return _time_left


func get_required_left() -> int:
	return _required.size()


## True if `tier`'s boss can be challenged now: no fight running, and its kill
## gate met (or the boss already beaten: re-fights need no new kills).
static func can_challenge(tier: TierData) -> bool:
	if tier == null or tier.boss == null or GameState.is_boss_active():
		return false
	return GameState.is_boss_beaten(tier.rank) or GameState.get_tier_kills(tier.rank) >= tier.boss.kills_required


## Starts the fight. Returns false if it can't start now.
func start(tier: TierData) -> bool:
	if is_active() or not can_challenge(tier):
		return false
	var boss := tier.boss.scene.instantiate() as EnemyBoss
	if boss == null:
		push_error("Boss scene for %s isn't an EnemyBoss" % tier.tier_id)
		return false
	_tier = tier
	_boss = boss
	_boss.position = spawn_center + Vector2.from_angle(rng.randf_range(-PI, PI)) * spawn_radius
	_boss.encounter_role = EnemyBase.EncounterRole.BOSS
	_boss.configure(tier, 1.0)
	_boss.summon_requested.connect(_on_summon_requested)
	_boss.died.connect(_on_boss_died)
	_members = [_boss]
	_required.clear()
	_time_left = tier.boss.time_limit_seconds
	_health_shown = -1.0
	_phase = Phase.FIGHTING
	GameState.set_boss_active(true)
	started.emit(tier.rank)
	enemy_spawn_requested.emit(_boss)
	return true


## Game calls this every tick.
func advance(delta: float) -> void:
	if not is_active():
		return
	_time_left = maxf(0.0, _time_left - delta)
	time_changed.emit(_time_left)
	if _phase == Phase.FIGHTING and is_instance_valid(_boss) and _boss.get_max_health() > 0.0:
		var fraction := _boss.get_health() / _boss.get_max_health()
		if not is_equal_approx(fraction, _health_shown):
			_health_shown = fraction
			boss_health_changed.emit(fraction)
	if _time_left <= 0.0:
		_finish(false)


## Ends the attempt now (the strip's two-step Give up).
func give_up() -> void:
	if is_active():
		_finish(false)


## A new run: forget the fight without paying anything. Game already drops
## queued enemies on a new run.
func reset() -> void:
	rng.seed = GameState.get_run_seed() + 104729
	_phase = Phase.IDLE
	_members.clear()
	_required.clear()
	_boss = null
	_tier = null


func _on_summon_requested(enemies: Array[EnemyBase]) -> void:
	var live := _count_live_summons()
	for enemy in enemies:
		if _phase != Phase.FIGHTING or live >= max_summons:
			enemy.free()
			continue
		enemy.encounter_role = EnemyBase.EncounterRole.SUMMON
		enemy.configure(_tier, 1.0)
		_members.append(enemy)
		live += 1
		enemy_spawn_requested.emit(enemy)


func _count_live_summons() -> int:
	var live := 0
	var kept: Array[EnemyBase] = []
	for member in _members:
		# Waiting to join still counts (it's active); dead or removed ones don't.
		if not is_instance_valid(member) or not member.is_active():
			continue
		kept.append(member)
		if member.encounter_role == EnemyBase.EncounterRole.SUMMON:
			live += 1
	_members = kept
	return live


func _on_boss_died(_enemy: EnemyBase, _killer: Node) -> void:
	if _phase != Phase.FIGHTING:
		return
	_phase = Phase.CLEANUP
	boss_health_changed.emit(0.0)
	var child_tier := _boss.split_tier if _boss.split_tier != null else _tier
	for child in _boss.make_death_split():
		child.encounter_role = EnemyBase.EncounterRole.REQUIRED
		child.configure(child_tier, 1.0)
		child.died.connect(_on_required_died)
		_required[child.get_instance_id()] = child
		_members.append(child)
		enemy_spawn_requested.emit(child)
	remaining_changed.emit(_required.size())
	if _required.is_empty():
		_finish(true)


func _on_required_died(enemy: EnemyBase, _killer: Node) -> void:
	if not _required.erase(enemy.get_instance_id()):
		return
	remaining_changed.emit(_required.size())
	if _required.is_empty() and _phase == Phase.CLEANUP:
		_finish(true)


## Pays for a win, removes everything the fight added, and hands control back.
func _finish(victory: bool) -> void:
	var tier := _tier
	var first_clear := false
	_phase = Phase.IDLE
	if victory:
		first_clear = GameState.record_boss_victory(tier.rank)
		GameState.earn_gold(tier.boss.first_clear_gold if first_clear else tier.boss.repeat_clear_gold)
	var leftovers := _members.duplicate()
	_members.clear()
	_required.clear()
	_boss = null
	for member in leftovers:
		if is_instance_valid(member) and not member.is_removed():
			enemy_removal_requested.emit(member)
	GameState.set_boss_active(false)
	ended.emit(victory, first_clear)
