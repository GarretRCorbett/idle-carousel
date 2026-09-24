"""Builds small CJK fonts containing only the characters the game uses.

Full Noto Sans SC/JP/KR are 9-17 MB each; the game needs a few hundred
characters, so each subset is tens of KB. Re-run whenever
localization/strings.csv changes (tests/test_localization.gd fails if a
language uses a character its font doesn't have):

    pip install fonttools
    python tools/subset_fonts.py

Source fonts (SIL OFL 1.1) live outside the repo in
../kenney_assets/google-fonts/<family>/ (download: github.com/google/fonts, ofl/).
"""
import csv
import pathlib

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = ROOT.parent / "kenney_assets" / "google-fonts"
OUT = ROOT / "assets" / "fonts"
# Heavy, to sit with Kenney Future's thick strokes.
WEIGHT = 700
# column in strings.csv -> (source folder, source file, output file)
FONTS = {
    "zh_CN": ("notosanssc", "NotoSansSC[wght].ttf", "noto_sans_sc_subset.ttf"),
    "ja": ("notosansjp", "NotoSansJP[wght].ttf", "noto_sans_jp_subset.ttf"),
    "ko": ("notosanskr", "NotoSansKR[wght].ttf", "noto_sans_kr_subset.ttf"),
}
# Always kept: printable ASCII (digits, Latin, punctuation) and symbols the UI uses.
ALWAYS = "".join(chr(c) for c in range(0x20, 0x7F)) + "×…—–·•％：（）！？、。「」"


def main() -> None:
    with open(ROOT / "localization" / "strings.csv", encoding="utf-8") as f:
        rows = list(csv.reader(f))
    header = rows[0]
    for column, (folder, source, output) in FONTS.items():
        index = header.index(column)
        chars = set(ALWAYS)
        for row in rows[1:]:
            chars.update(row[index])
        font = TTFont(SOURCES / folder / source)
        font = instancer.instantiateVariableFont(font, {"wght": WEIGHT})
        options = subset.Options()
        options.layout_features = ["*"]  # keep shaping features
        options.name_IDs = ["*"]  # keep copyright/license names (OFL)
        subsetter = subset.Subsetter(options)
        subsetter.populate(text="".join(sorted(chars)))
        subsetter.subset(font)
        font.save(OUT / output)
        print(f"{output}: {len(chars)} characters, {(OUT / output).stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
