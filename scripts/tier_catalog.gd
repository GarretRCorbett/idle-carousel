class_name TierCatalog
extends Resource
## Every color tier, in rank order (Grey first). Edit in the Inspector:
## res://resources/tiers/tier_catalog.tres

@export var tiers: Array[TierData] = []


## The tier at `rank`, or null if there isn't one.
func get_tier(rank: int) -> TierData:
	if rank < 0 or rank >= tiers.size():
		return null
	return tiers[rank]


func get_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	for i in tiers.size():
		var tier := tiers[i]
		if tier == null:
			problems.append("catalog entry %d is empty" % i)
			continue
		problems.append_array(tier.get_problems())
		if tier.rank != i:
			problems.append("%s has rank %d but is entry %d" % [tier.tier_id, tier.rank, i])
	return problems
