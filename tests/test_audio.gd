extends GdUnitTestSuite
## Every sound the game asks for exists in the sound bank.

const USED: Array[StringName] = [&"coin", &"hit", &"wolf_hit", &"pop", &"latch", &"purchase",
		&"sell", &"stall", &"restart", &"click", &"tab", &"crank"]


func test_every_used_sound_is_in_the_bank() -> void:
	for id in USED:
		assert_bool(AudioManager.has_sfx(id)).override_failure_message("missing sound %s" % id).is_true()


func test_every_bank_entry_has_a_sound() -> void:
	var bank := load("res://resources/audio/sound_bank.tres") as SoundBank
	for effect in bank.effects:
		assert_bool(effect.streams.is_empty()).override_failure_message("%s has no streams" % effect.id).is_false()
		for stream in effect.streams:
			assert_object(stream).is_not_null()


## Rapid sounds (hundreds of hits a second) are thinned to one per interval.
func test_sounds_closer_than_the_interval_are_skipped() -> void:
	var audio := preload("res://scripts/autoloads/audio_manager.gd")
	assert_bool(audio.should_play(1000, 1010, 30)).is_false()
	assert_bool(audio.should_play(1000, 1030, 30)).is_true()
	assert_bool(audio.should_play(1000, 1001, 0)).is_true()
