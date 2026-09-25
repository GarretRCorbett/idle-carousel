class_name EnemyBoss
extends EnemyBase
## Base for tier bosses. A boss is an enemy with a script of its own (how it
## moves and attacks); BossEncounter runs the fight around it: the timer,
## summons, required split children, and the win. Lives in EnemyLayer like
## every enemy.

## The boss wants these enemies added (already positioned, not yet configured).
## BossEncounter decides how many actually join (summon cap) and marks them
## as summons (no Gold, no kill credit).
signal summon_requested(enemies: Array[EnemyBase])

## The tier its split children are (Obsidian Boulder: Red Rocks). Empty = the
## fight's own tier.
@export var split_tier: TierData


## Enemies that appear when the boss dies and must die too before the fight is
## won (Leaf Storm: 4 Grey Leaves). Positioned, not configured. Default: none.
func make_death_split() -> Array[EnemyBase]:
	return []
