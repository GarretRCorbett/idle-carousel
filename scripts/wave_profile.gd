class_name WaveProfile
extends Resource
## How one tier's waves are made: how often, how many, from how many
## directions, and which enemies with what odds. Lives inside a TierData.
##
## A wave is rolled one enemy at a time: each pick is weighted among the
## entries that are unlocked (enough kills in this tier), have weight above 0,
## and are under their cap for this wave. So the weights aren't exact
## percentages once a cap is reached.

## Seconds between waves in this tier.
@export_range(1.0, 600.0, 0.5, "suffix:s") var interval_seconds: float = 10.0
@export_range(1, 50, 1) var min_enemies: int = 3
@export_range(1, 50, 1) var max_enemies: int = 5
## Clusters per wave, each from its own direction, evenly spread round.
@export_range(1, 8, 1) var directions: int = 1
@export var entries: Array[WaveEntry] = []


## The entries for one wave, in spawn order. `kills` = kills so far in this
## tier (for unlocks). Pure apart from the RNG, so tests can seed it.
func roll(random: RandomNumberGenerator, kills: int) -> Array[WaveEntry]:
	var picks: Array[WaveEntry] = []
	var taken: Dictionary[WaveEntry, int] = {}
	var count := random.randi_range(mini(min_enemies, max_enemies), maxi(min_enemies, max_enemies))
	for i in count:
		var pick := _pick(random, kills, taken)
		if pick == null:
			break  # can't happen with a valid profile (it has a filler)
		taken[pick] = taken.get(pick, 0) + 1
		picks.append(pick)
	return picks


func _pick(random: RandomNumberGenerator, kills: int, taken: Dictionary[WaveEntry, int]) -> WaveEntry:
	var open: Array[WaveEntry] = []
	var total := 0.0
	for entry in entries:
		if entry == null or entry.weight <= 0.0 or kills < entry.unlock_after_kills:
			continue
		if entry.max_per_wave > 0 and taken.get(entry, 0) >= entry.max_per_wave:
			continue
		open.append(entry)
		total += entry.weight
	if open.is_empty():
		return null
	var roll_value := random.randf() * total
	for entry in open:
		roll_value -= entry.weight
		if roll_value < 0.0:
			return entry
	return open.back()  # float round-off at the very top


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	if not is_finite(interval_seconds) or interval_seconds <= 0.0:
		problems.append("interval_seconds must be above 0")
	if min_enemies < 1 or min_enemies > max_enemies:
		problems.append("need 1 <= min_enemies <= max_enemies")
	if directions < 1:
		problems.append("directions must be at least 1")
	var has_filler := false
	for entry in entries:
		if entry == null:
			problems.append("empty entry")
			continue
		if entry.enemy_scene == null:
			problems.append("entry has no enemy_scene")
		if not is_finite(entry.weight) or entry.weight < 0.0:
			problems.append("weights must be finite and 0 or more")
		if entry.max_per_wave < 0 or entry.unlock_after_kills < 0:
			problems.append("caps and unlocks can't be negative")
		has_filler = has_filler or entry.is_filler()
	# Otherwise a wave could run out of things to pick (memo O8).
	if not has_filler:
		problems.append("needs an entry that's always unlocked, has weight, and has no cap")
	return problems
