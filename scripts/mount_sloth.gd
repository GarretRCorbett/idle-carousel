class_name MountSloth
extends MountSweeper
## The defender. Sweeps like the Wolf but deals no damage (base_damage 0):
## every approaching enemy its line passes is slowed (data.slow_multiplier
## for GameState.get_mount_slow_seconds, longer at Tier 2), once per pass. Latched enemies don't move, so it
## leaves them alone.


func apply_sweep(enemy: EnemyBase) -> void:
	if enemy.is_at_rim():
		return
	enemy.apply_slow(data.slow_multiplier, GameState.get_mount_slow_seconds(data))
