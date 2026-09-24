# Codex memo K: fonts for localization (2026-09-24)

> Input, not a decision. Claude verified with fontTools: Kenney Future has 214 glyphs, no Cyrillic, no ą ł ś ż ć ę ń ź ş ğ ı İ œ ✓. Rubik covers all but ✓.

**My recommendation: Rubik for localized European UI, locale-specific Noto Sans families for CJK, and M PLUS Rounded 1c as the friendlier Japanese alternative. Switch the whole UI font per locale; retain fallbacks for coverage gaps.**

1. **Font choices**

All families below use **SIL OFL 1.1**. Sizes are approximate uncompressed files, before Godot caches; static means one weight, variable means multiple weights.

| Family / download | Coverage | Visual fit and approximate size |
|---|---|---|
| [Rubik](https://fonts.google.com/specimen/Rubik) | Latin Extended, Cyrillic, Hebrew, **Arabic in current release** | My closest match: geometric, slightly squared, rounded corners. Variable ≈350 KB; static roughly 100–250 KB. |
| [Nunito](https://fonts.google.com/specimen/Nunito) | Latin Extended, Cyrillic, Vietnamese | Softer, rounder alternative. Variable ≈270 KB; static roughly 100–200 KB. |
| [Varela Round](https://fonts.google.com/specimen/Varela+Round) | Latin Extended, Hebrew, Vietnamese; **no Cyrillic** | Friendly geometry, but less useful here. Regular static ≈130 KB; no variable. |
| [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) | Latin Extended, Cyrillic, Greek; current build also Devanagari | Neutral, dependable. Variable ≈2 MB; static roughly 0.5–0.8 MB. Not universal script coverage. |
| [Noto Sans SC](https://fonts.google.com/specimen/Noto+Sans+SC), [JP](https://fonts.google.com/specimen/Noto+Sans+JP), [KR](https://fonts.google.com/specimen/Noto+Sans+KR), [TC](https://fonts.google.com/specimen/Noto+Sans+TC) | Respectively Simplified Chinese; Japanese kana/kanji; Korean Hangul/Hanja; Traditional Chinese, plus Latin | Clean rather than rounded. Regional variable TTFs: SC ≈17 MB, JP ≈9 MB, KR ≈10 MB; budget ≈5–17 MB per regional static weight, depending on coverage/build. |
| [M PLUS Rounded 1c](https://fonts.google.com/specimen/M+PLUS+Rounded+1c) | Japanese, Latin Extended, Cyrillic, Greek, Hebrew | Best rounded Japanese pairing. Static ≈3.2 MB/weight; no Google Fonts variable. |
| [Zen Maru Gothic](https://fonts.google.com/specimen/Zen+Maru+Gothic) | Japanese, Latin Extended, Cyrillic, Greek | Warmer, more organic. Static ≈3.7 MB/weight; no variable. |
| [Noto Sans Arabic](https://fonts.google.com/noto/specimen/Noto+Sans+Arabic) | Arabic, Latin Extended | Reliable Arabic option. Variable ≈825 KB; static roughly 200–400 KB. |

Coverage/licenses and current file sizes come from [Google Fonts’ source files](https://github.com/google/fonts/tree/main/ofl); static ranges are planning estimates. Japanese families are **not substitutes for Chinese/Korean coverage**.

2. **Kenney’s accents**

“Latin only” does **not** mean ASCII-only: [Kenney’s published Future Narrow release](https://www.dafont.com/kenney-future.font) includes accents and 217 glyphs. However, I could not verify `ą ł ş ğ ã` individually against your exact Future/Future Narrow binaries. Don’t assume complete Polish/Turkish coverage—or assume Portuguese necessarily needs fallback. Audit both binaries before committing; provision Latin Extended now regardless.

3. **Godot mechanics**

`Font.fallbacks` is inherited by `FontFile` and `FontVariation`; configure it on the font assigned to `Theme.default_font`. Fallback supplies missing glyphs, potentially mixing designs within words. **Switch `default_font` when locale changes** for consistent lettering; `FontVariation` packages weight/spacing/fallback choices but does not automatically select locales. Select the appropriate CJK regional font to preserve regional Han forms. [Godot Font API](https://docs.godotengine.org/en/4.7/classes/class_font.html), [Noto deployment guide](https://github.com/notofonts/noto-cjk/blob/main/Sans/README.md).

For ordinary small CJK UI, start with **normal grayscale rendering**; MSDF loses hinting and costs more when generating new glyphs. Prerender frequently used translated strings at actual UI sizes only if needed; avoid preloading entire CJK repertoires. Prerendering does **not** subset the font. [Godot rendering guide](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html).

Disable [`allow_system_fallback`](https://docs.godotengine.org/en/stable/classes/class_fontfile.html#class-fontfile-property-allow-system-fallback) on bundled fonts for Steam consistency. Later, use [fontTools subsetting](https://fonttools.readthedocs.io/en/latest/subset/index.html), preserving shaping features and dynamic characters. Arabic additionally needs RTL/layout testing.

4. **Download now versus later**

Download **Rubik plus its OFL now**, optionally Nunito for comparison. Defer CJK/Arabic until scheduled; links above are download pages. Start with one or two weights. Don’t force translated text into English-style uppercase.

5. **Distribution**

Ship each font’s copyright notice and full OFL text, conveniently in a licenses folder. An on-screen credit is optional. Modified/subset fonts remain OFL; respect Reserved Font Names. Your game need not become open-source. [Official OFL](https://openfontlicense.org/open-font-license-official-text/).

No files changed. Environment policy blocked reading `CLAUDE.md` and local font inspection.