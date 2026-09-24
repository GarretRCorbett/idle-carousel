class_name NumberFormat
extends RefCounted
## The one place numbers become text (CLAUDE.md: never format inline).
## Below 10,000: whole numbers with a thousands separator ("1,234").
## From 10,000: three significant digits and a suffix ("12.3K", "4.56M").
## Separators and suffixes are translation keys, so each language can set its own.

const COMPACT_FROM := 10000.0
const SUFFIX_KEYS: Array[String] = ["NUM_SUFFIX_K", "NUM_SUFFIX_M", "NUM_SUFFIX_B", "NUM_SUFFIX_T"]


## Gold amounts, prices, and other whole counts.
static func gold(value: float) -> String:
	if not is_finite(value):
		return "?"
	var sign := "-" if value < 0.0 else ""
	var amount := floorf(absf(value))
	if amount < COMPACT_FROM:
		return sign + _group_thousands(str(int(amount)))
	var tier := 0
	while amount >= 1000.0 and tier < SUFFIX_KEYS.size():
		amount /= 1000.0
		tier += 1
	# Three significant digits: 12.3K, 123K; truncated so it never rounds up past the real value.
	var places := 0 if amount >= 100.0 else (1 if amount >= 10.0 else 2)
	var scale := pow(10.0, places)
	var text := String.num(floorf(amount * scale) / scale, places)
	if places > 0:
		text = text.replace(".", TranslationServer.translate("NUM_DECIMAL_SEP"))
	return sign + text + TranslationServer.translate(SUFFIX_KEYS[tier - 1])


## Small decimals like Gold per second (1 decimal) or the speed multiplier (2).
static func decimal(value: float, places: int) -> String:
	if not is_finite(value):
		return "?"
	if absf(value) >= COMPACT_FROM:
		return gold(value)
	var text := String.num(value, places)
	if places > 0 and not "." in text:
		text += "." + "0".repeat(places)
	return text.replace(".", TranslationServer.translate("NUM_DECIMAL_SEP"))


static func _group_thousands(digits: String) -> String:
	var separator := TranslationServer.translate("NUM_THOUSANDS_SEP")
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = separator + out
	return out
