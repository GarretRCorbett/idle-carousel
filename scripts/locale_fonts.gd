class_name LocaleFonts
extends RefCounted
## Picks the whole UI font for a language, so letters never mix fonts inside a
## word. Latin languages keep Kenney Future (Rubik fills rare missing accents);
## Russian switches to Rubik; Chinese/Japanese/Korean use small Noto Sans subsets
## (tools/subset_fonts.py). Fonts are built by tools/build_ui_theme.gd.

const THEME_PATH := "res://assets/ui/game_theme.tres"
const DEFAULT_UI := "res://assets/fonts/ui_font.tres"
const DEFAULT_TITLE := "res://assets/fonts/title_font.tres"
## Language (the part before "_") -> font used for all UI text, titles included.
const BY_LANGUAGE: Dictionary[String, String] = {
	"ru": "res://assets/fonts/ui_font_cyrillic.tres",
	"zh": "res://assets/fonts/ui_font_zh.tres",
	"ja": "res://assets/fonts/ui_font_ja.tres",
	"ko": "res://assets/fonts/ui_font_ko.tres",
}


static func ui_font(locale: String) -> Font:
	var path: String = BY_LANGUAGE.get(locale.get_slice("_", 0), DEFAULT_UI)
	return load(path)


static func title_font(locale: String) -> Font:
	var path: String = BY_LANGUAGE.get(locale.get_slice("_", 0), DEFAULT_TITLE)
	return load(path)


## Swaps the shared theme's font; every themed Control updates.
static func apply(locale: String) -> void:
	var theme := load(THEME_PATH) as Theme
	var font := ui_font(locale)
	if theme != null and theme.default_font != font:
		theme.default_font = font
