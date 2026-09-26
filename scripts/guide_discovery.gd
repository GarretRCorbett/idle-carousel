class_name GuideDiscovery
extends Node
## Watches the game for first meetings and records them forever
## (SaveManager.discover), so Park Guide entries unlock (Phase 4 Step 8).
## Game creates one and feeds it what it can't hear itself: enemies as they
## join play, boss fights, events and pickups.
##
## Discovery ids are "<kind>:<stable id>" (mount:wolf, enemy:leaf, tier:green,
## boss:leaf_storm, event:golden_hour, mechanic:overdrive). The kind keeps a
## boss and its body's enemy id (both leaf_storm) from sharing one entry.
## Stable ids only (CLAUDE.md "Themes"): never a display name.

## Tier ranks to tier ids (Game's catalog).
var tier_catalog: TierCatalog


static func mount_key(id: StringName) -> String:
	return "mount:%s" % id


static func enemy_key(id: StringName) -> String:
	return "enemy:%s" % id


static func tier_key(id: StringName) -> String:
	return "tier:%s" % id


static func boss_key(id: StringName) -> String:
	return "boss:%s" % id


static func event_key(id: StringName) -> String:
	return "event:%s" % id


static func mechanic_key(id: StringName) -> String:
	return "mechanic:%s" % id


func _ready() -> void:
	GameState.mounts_changed.connect(_on_mounts_changed)
	GameState.overdrive_changed.connect(_on_overdrive_changed)
	GameState.latch_count_changed.connect(_on_latch_count_changed)
	GameState.stall_changed.connect(_on_stall_changed)
	_on_mounts_changed(GameState.get_mount_roster())


func watch_encounter(encounter: BossEncounter) -> void:
	encounter.started.connect(_on_boss_started)


## Visitors and grabbed pickups (a pickup's token is reported by pickup_appeared).
func watch_events(director: EventDirector) -> void:
	director.event_started.connect(_on_event_started)


## An enemy joined play: its type, and the tier it came in.
func enemy_admitted(enemy: EnemyBase) -> void:
	if enemy.data != null:
		SaveManager.discover(enemy_key(enemy.data.id))
	var tier := tier_catalog.get_tier(enemy.get_tier_rank()) if tier_catalog != null else null
	if tier != null:
		SaveManager.discover(tier_key(tier.tier_id))


## A pickup's token appeared (seeing it counts, even if it fades ungrabbed).
func pickup_appeared(event: EventData) -> void:
	SaveManager.discover(event_key(event.id))


func _on_mounts_changed(roster: Array[StringName]) -> void:
	for id in roster:
		SaveManager.discover(mount_key(id))


func _on_boss_started(tier_rank: int) -> void:
	var tier := tier_catalog.get_tier(tier_rank) if tier_catalog != null else null
	if tier != null and tier.boss != null:
		SaveManager.discover(boss_key(tier.boss.boss_id))


func _on_event_started(event: EventData, _amount: float) -> void:
	SaveManager.discover(event_key(event.id))


func _on_overdrive_changed(active: bool) -> void:
	if active:
		SaveManager.discover(mechanic_key(&"overdrive"))


func _on_latch_count_changed(count: int) -> void:
	if count > 0:
		SaveManager.discover(mechanic_key(&"latch"))


func _on_stall_changed(stalled: bool) -> void:
	if stalled:
		SaveManager.discover(mechanic_key(&"stall"))
