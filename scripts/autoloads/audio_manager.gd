extends Node
## Persistent sound players (GDD). play_sfx(&"coin") plays one of that
## effect's variations with a slight random pitch. Effects and volumes live in
## res://resources/audio/sound_bank.tres.
## Game-wide events (purchases, stalls) are wired here; world events (coins,
## hits) are played by Game, and button sounds by the HUD.

const BANK: SoundBank = preload("res://resources/audio/sound_bank.tres")

var _players: Dictionary[StringName, AudioStreamPlayer] = {}
var _was_stalled: bool = false
var _min_interval_msec: Dictionary[StringName, int] = {}
var _last_played_msec: Dictionary[StringName, int] = {}


func _ready() -> void:
	# Keep playing (menu clicks) while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for effect in BANK.effects:
		if effect == null or effect.streams.is_empty():
			continue
		var randomizer := AudioStreamRandomizer.new()
		for i in effect.streams.size():
			randomizer.add_stream(i, effect.streams[i])
		randomizer.random_pitch = effect.random_pitch
		var player := AudioStreamPlayer.new()
		player.name = String(effect.id)
		player.stream = randomizer
		player.volume_db = effect.volume_db
		player.max_polyphony = effect.max_polyphony
		_min_interval_msec[effect.id] = roundi(effect.min_interval_seconds * 1000.0)
		player.bus = &"SFX"
		add_child(player)
		_players[effect.id] = player
	# UpgradeManager loads after this autoload; connect once everything exists.
	_connect_game_events.call_deferred()


func play_sfx(id: StringName) -> void:
	var player: AudioStreamPlayer = _players.get(id)
	if player == null:
		push_warning("No sound effect named %s" % id)
		return
	var now := Time.get_ticks_msec()
	if not should_play(_last_played_msec.get(id, -1000000), now, _min_interval_msec.get(id, 0)):
		return
	_last_played_msec[id] = now
	player.play()


## True unless the last play was less than min_interval_msec ago.
static func should_play(last_msec: int, now_msec: int, min_interval_msec: int) -> bool:
	return min_interval_msec <= 0 or now_msec - last_msec >= min_interval_msec


func has_sfx(id: StringName) -> bool:
	return _players.has(id)


func _connect_game_events() -> void:
	UpgradeManager.upgrade_purchased.connect(func(_id: StringName) -> void: play_sfx(&"purchase"))
	UpgradeManager.upgrade_sold.connect(func(_id: StringName) -> void: play_sfx(&"sell"))
	GameState.stall_changed.connect(_on_stall_changed)


## The clunk when it stalls, the rise when it restarts (not on a fresh run).
func _on_stall_changed(stalled: bool) -> void:
	if stalled:
		play_sfx(&"stall")
	elif _was_stalled:
		play_sfx(&"restart")
	_was_stalled = stalled
