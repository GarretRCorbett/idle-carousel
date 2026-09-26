# Tier outlines and purple UI options — 2026-09-25

**Recommendation for Garret's review: ink outlines on Grey–Red, ivory on Charcoal; palette A, Purple Garden.** Applied on `codex/tier-outlines-palette` only. These are options, not a recorded design decision. Background/scenery, tier hue order, balance, production scenes and player-facing text are unchanged. All pictures are Godot renders using existing art.

**What to open.** `compare_hud.png` and `compare_title.png` place A left/B right at native 1280×720 resolution per frame. Individual originals are `purple_garden_hud.png`, `purple_garden_title.png`, `gilded_plum_hud.png`, `gilded_plum_title.png`. HUDs instantiate **Game.tscn**, run two seeded Yellow-tier waves for 34 frames at fixed 10 fps, and use debug Gold/kill-gate setup; they show the recommended outlines during actual gameplay. `outlines_leaf.png`, `outlines_stick.png`, `outlines_rock.png`, `outlines_boulder.png` each compare all six tiers × three outlines × four real background crops. Small enemies show native size above 2× detail; Boulder is native size. `park_crop_source.png` records the unchanged background used. Each `*_accessibility.png` shows button states and tier swatches in standard vision/deuteranopia/protanopia; each `*_contrast.md` contains numerical measurements.

**Outline findings.** A = ink **#292333**, B = ivory **#FFF4DC**, C = tier tint darkened 68% in sRGB. Ink separates the first five tiers from pavement, brick, stone and lawn; ivory washes out around Yellow on pale surfaces. Tier-derived edges are softer but lose interior separation on Red/Charcoal. Ivory gives Charcoal its distinctive readable rim. Keep the existing outline masks: approximately 1.46 px Leaf, 1.88 px Stick, 1.67 px Rock and 4.58 px Boulder at game size (5 source pixels × sprite scale). No new sprite files or thickness changes.

| Tier | Retained tint | Option C edge |
|---|---|---|
| Grey | #99999E | #313133 |
| Green | #9EE659 | #33491D |
| Yellow | #FFE04D | #524818 |
| Orange | #FF942E | #522F0F |
| Red | #F24038 | #4E1412 |
| Charcoal | #33333B | #101013 |

**Palette roles (exact resource colors; texture multiplication makes button faces darker).**

| Role | A: Purple Garden | B: Gilded Plum |
|---|---|---|
| Primary: Play/Boost/Challenge/Buy | #70568B | #DDB96A |
| Secondary: Send/Settings/Quit/Sell | #286466 | #70568B |
| Danger: Crank/Give up/Clear | #993F4F | #993F4F |
| Success/health | #79C9AE | #A6C98A |
| Currency/progress gold | #DDB96A | #DDB96A |
| Opaque panel / border | #30283E / #B6A3CD | #342838 / #DDB96A |
| Body / secondary & danger button text | #FFF4DC | #FFF4DC |
| Primary text | #FFF4DC | #292333 |
| Muted & disabled text / disabled fill | #C6BDD0 / #514958 | same |
| Focus & Overdrive highlight | #F4D995 | #E8C9F5 |
| Ink / track | #292333 / #211C2B | same |
| Idle / hover tabs | #493B59 / #604B74 | same |

A uses analogous violet/plum/lavender neutrals with cool teal actions and warm gold accents; B emphasizes the traditional violet–gold complementary pairing. These are adjusted artistic harmonies, not exact HSV wheel intervals. Both keep broad surfaces dark and quiet, readable text light, and saturated accents small. A reserves gold for value/progress; B gives purchases stronger value contrast but competes more with currency. Hover/press darken fills by 8%/16%; B's gold primary lightens instead. Kenney texture bevels remain, with a visible focus ring. Title text is cream with ink edging.

**Contrast and color vision.** Using [WCAG's linear-sRGB contrast method](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum), sampled normal button faces are A **#604A7E / #22565C / #833648** (primary/secondary/danger), yielding **6.92 / 7.50 / 7.43:1**. B faces **#BDA060 / #604A7E / #833648** yield **6.03 / 6.92 / 7.43:1**. Hover/pressed states improve those ratios; disabled text is **5.57:1**. Body/panel is **12.83:1 A, 12.76:1 B**; muted/panel **7.73/7.69:1**. These pairs exceed the 4.5:1 normal-text reference; this is not a whole-game accessibility certification (existing dimmed locked rows/pips are outside those measurements).

[Machado's model](https://pubmed.ncbi.nlm.nih.gov/19834201/) at severity 1.0 predicts Green/Yellow luminance ratios of only **1.23:1 deuteranopia / 1.06:1 protanopia**. Orange/Red also converge toward ochre. A's teal/red become subdued grey/olive under protanopia; purple remains blue. Labels and fixed control positions still distinguish actions. Preserve numbered tier pips: [color alone is insufficient](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html). Mixed-tier enemies can still be confused; a future per-enemy tier marker would require Garret's design choice. The hue order is preserved here.

**Changes and reproduction.** Six `resources/tiers/*.tres` plus `scripts/tier_data.gd` enable/document outlines. `scripts/ui_palette.gd`, two `resources/ui_palettes/*.tres`, `tools/build_ui_theme.gd`, generated `assets/ui/game_theme.tres`, `scripts/hud.gd` and `scripts/main_menu.gd` implement semantic colors. `tools/_style/{StyleStudy.tscn,style_study.gd,render_study.ps1}` reproduce this folder and restore A. Run `powershell -File tools/_style/render_study.ps1` from this worktree; it imports first and runs `tools/check.bat` last. Capture uses SubViewport PNG saves, avoiding redundant movie frames/audio. For editor review, open/save the temporary `StyleStudy.tscn` once if retaining it. Validation: Godot 4.7.2, full script/scene check and **340 tests passed**.

## Garret's picks (2026-09-25)
- **Palette A, Purple Garden**, and its title screen (cream title).
- **Anything that spends Gold uses gold** (B's primary): shop buy buttons are the `BuyButton` variation (gold fill, ink text).
- **Challenge uses the danger color** (like Give up).
- **Outlines: tier shade** (option C) on Grey–Red; Charcoal keeps ivory. Ink was his second choice.
- Later: switchable UI palettes per theme (the palettes are already separate `UiPalette` resources).
- Rendered result: `chosen_hud.png`.
