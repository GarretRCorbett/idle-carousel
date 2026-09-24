class_name SoundEffect
extends Resource
## One named sound (e.g. &"coin"): its variations and how loud it plays.
## Listed in res://resources/audio/sound_bank.tres; tune volumes there.

@export var id: StringName = &""
## A random one plays each time, so repeated sounds don't feel robotic.
@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db: float = 0.0
## Random pitch up or down by up to this factor (1.08 = ±8%). 1 = none.
@export_range(1.0, 2.0, 0.01) var random_pitch: float = 1.06
## How many copies can overlap (rapid coins, hits).
@export_range(1, 16, 1) var max_polyphony: int = 4
