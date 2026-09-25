extends Node
## Dev tool, not part of the game: holds N Leaves on screen with a fast
## carousel and the Wolf, and prints frame and physics timings per stage.
## Run from the project folder (a window opens; vsync is turned off, so the
## machine runs flat out: run it once, not back to back):
##   "$GODOT" --audio-driver Dummy --path . res://tools/stress_test.tscn
##   "$GODOT" --audio-driver Dummy --path . res://tools/stress_test.tscn -- 100,500,1000
## Always silent: sound costs frame time, so FPS only compares between runs
## that both used --audio-driver Dummy. Physics tick times compare either way.
## Leaves here can't die and deal no damage or drag, so the count stays
## fixed, but the Wolf keeps hitting them (flashes, health bars, sounds).
## Numbers depend on the machine; compare runs on the same one.
## Target (planning/phase3/claude_memo_performance.md): write it down here once
## Garret picks one.

const DEFAULT_STAGES: Array[int] = [0, 100, 300, 500, 1000, 2000]
const WARMUP_SECONDS := 3.0
const SAMPLE_SECONDS := 4.0
## Leaves start this far outside the rim, so they latch (and get hit) quickly.
const SPAWN_BAND_PX := 120.0

var _stages: Array[int] = []
var _game: Game
var _layer: Node2D
var _leaf_scene: PackedScene = preload("res://scenes/enemies/Leaf.tscn")
var _data: EnemyData
var _rng := RandomNumberGenerator.new()
var _stage := -1
var _stage_start_usec := 0
var _last_frame_usec := 0
var _sampling := false
var _frame_ms: Array[float] = []
var _tick_ms: Array[float] = []
var _ticks_this_frame := 0
var _ticks_per_frame: Array[int] = []
var _draw_calls: Array[float] = []
var _tick_start_usec := 0


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_stages = _parse_stages()
	_data = (load("res://resources/enemies/leaf.tres") as EnemyData).duplicate()
	_data.base_health = 1.0e9
	_data.damage_per_second = 0.0
	_data.latch_drag = 0.0
	_game = (load("res://scenes/Game.tscn") as PackedScene).instantiate() as Game
	add_child(_game)
	_layer = _game.get_node("World/EnemyLayer")
	# Two helper nodes run first and last every physics tick, timing all of it.
	_add_tick_marker(-1000, _on_tick_start)
	_add_tick_marker(1000, _on_tick_end)
	print("enemies,fps,frame_ms_avg,frame_ms_p99,tick_ms_avg,tick_ms_max,ticks_per_frame_max,draw_calls")


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _stage == -1:
		_setup_run()
		_next_stage(now)
		return
	var elapsed := (now - _stage_start_usec) / 1.0e6
	_sampling = elapsed > WARMUP_SECONDS
	if _sampling:
		_frame_ms.append((now - _last_frame_usec) / 1000.0)
		_ticks_per_frame.append(_ticks_this_frame)
		_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_ticks_this_frame = 0
	_last_frame_usec = now
	if elapsed > WARMUP_SECONDS + SAMPLE_SECONDS:
		_report()
		if _stage + 1 >= _stages.size():
			get_tree().quit()
			return
		_next_stage(now)


func _setup_run() -> void:
	(_game.get_node("WaveManager") as WaveManager).set_auto(false)
	GameState.add_gold(1.0e9)
	for i in 10:
		UpgradeManager.purchase(&"carousel_speed")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"wolf")
	UpgradeManager.purchase(&"mount_slot")
	UpgradeManager.purchase(&"horse")


## Fresh Leaves every stage, spread around the rim.
func _next_stage(now: int) -> void:
	_stage += 1
	for enemy: EnemyBase in _layer.get_children():
		_game._remove_enemy(enemy)
	_rng.seed = 1
	var carousel := _game.get_node("World/Carousel") as Carousel
	var inner := carousel.radius + _data.hitbox_radius + 2.0
	for i in _stages[_stage]:
		var enemy := _leaf_scene.instantiate() as EnemyBase
		enemy.data = _data
		var distance := _rng.randf_range(inner, inner + SPAWN_BAND_PX)
		enemy.position = carousel.position + Vector2.from_angle(_rng.randf() * TAU) * distance
		_game._on_enemy_spawned(enemy)
	# Spawns join at the next tick, so that tick admits the whole stage at
	# once. It's setup, not play: don't sample it.
	_sampling = false
	_frame_ms.clear()
	_tick_ms.clear()
	_ticks_per_frame.clear()
	_draw_calls.clear()
	_stage_start_usec = now
	_last_frame_usec = now


func _report() -> void:
	var frames := _frame_ms.duplicate()
	frames.sort()
	var frame_avg := _average(frames)
	var p99: float = frames[mini(frames.size() - 1, int(frames.size() * 0.99))] if not frames.is_empty() else 0.0
	var tick_max := 0.0
	for t in _tick_ms:
		tick_max = maxf(tick_max, t)
	var ticks_max := 0
	for n in _ticks_per_frame:
		ticks_max = maxi(ticks_max, n)
	print("%d,%.0f,%.2f,%.2f,%.2f,%.2f,%d,%.0f" % [_stages[_stage], 1000.0 / maxf(frame_avg, 0.001),
			frame_avg, p99, _average(_tick_ms), tick_max, ticks_max, _average(_draw_calls)])


func _parse_stages() -> Array[int]:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return DEFAULT_STAGES.duplicate()
	var stages: Array[int] = []
	for part in args[0].split(","):
		stages.append(int(part))
	return stages


func _add_tick_marker(priority: int, callback: Callable) -> void:
	var marker := TickMarker.new()
	marker.process_physics_priority = priority
	marker.ticked.connect(callback)
	add_child(marker)


func _on_tick_start() -> void:
	_tick_start_usec = Time.get_ticks_usec()


func _on_tick_end() -> void:
	_ticks_this_frame += 1
	if _sampling:
		_tick_ms.append((Time.get_ticks_usec() - _tick_start_usec) / 1000.0)


static func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


## Emits once per physics tick at its process_physics_priority.
class TickMarker extends Node:
	signal ticked

	func _physics_process(_delta: float) -> void:
		ticked.emit()
