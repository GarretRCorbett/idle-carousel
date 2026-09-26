# Asset Provenance Log

Every asset in the game, where it came from, and its license (GDD: Asset & AI Policy).
Downloaded packs are kept unmodified in `../kenney_assets/` (outside the repo, zips in `_zips/`); only files the game uses are copied here.

| File | Source | Original file | License | Changes | Date |
|---|---|---|---|---|---|
| `sprites/mounts/horse.png` | [Kenney: Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `PNG/Round (outline)/horse.png` | CC0 1.0 | None | 2026-09-24 |
| `sprites/mounts/wolf.png` | [Kenney: Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `PNG/Round (outline)/dog.png` (stand-in for the Wolf) | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/mounts/giraffe.png` | [Kenney: Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `PNG/Round (outline)/giraffe.png` | CC0 1.0 | None | 2026-09-25 |
| `sprites/mounts/elephant.png` | Kenney: Animal Pack Remastered | `PNG/Round (outline)/elephant.png` | CC0 1.0 | None | 2026-09-25 |
| `sprites/mounts/panda.png` | Kenney: Animal Pack Remastered | `PNG/Round (outline)/panda.png` | CC0 1.0 | None | 2026-09-25 |
| `sprites/mounts/sloth.png` | Kenney: Animal Pack Remastered | `PNG/Round (outline)/sloth.png` | CC0 1.0 | None | 2026-09-25 |
| `sprites/mounts/*_outline.png` (all six mounts) | Made from the mount sprites above by `tools/make_mount_outlines.gd` | The mount sprites above | CC0 1.0 | White silhouette grown 10 px, tinted in game | 2026-09-26 |
| `sprites/enemies/leaf.png` | [Kenney: Foliage Sprites](https://kenney.nl/assets/foliage-sprites) | `PNG/Shaded/sprite_0082.png` | CC0 1.0 | Trimmed, scaled to 96 px, mapped to light grey for tier tinting (`tools/make_tier_sprites.gd`) | 2026-09-25 |
| `sprites/enemies/stick.png` | [Kenney: Foliage Pack](https://kenney.nl/assets/foliage-pack) | `PNG/Default size/foliagePack_022.png` | CC0 1.0 | Same | 2026-09-25 |
| `sprites/enemies/rock.png` | Kenney: Foliage Pack | `PNG/Default size/foliagePack_055.png` | CC0 1.0 | Same | 2026-09-25 |
| `sprites/enemies/*_outline.png` | Built by `tools/make_tier_sprites.gd` from the three sprites above | | CC0 1.0 (derived) | White silhouette grown by 5 px, for the Charcoal tier's outline | 2026-09-25 |
| `ui/button_yellow.png` | [Kenney: UI Pack](https://kenney.nl/assets/ui-pack) | `PNG/Yellow/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_yellow_hover.png` | Kenney: UI Pack | `PNG/Yellow/Default/button_rectangle_depth_gradient.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_yellow_pressed.png` | Kenney: UI Pack | `PNG/Yellow/Default/button_rectangle_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_blue.png` | Kenney: UI Pack | `PNG/Blue/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed; tinted royal blue by the theme | 2026-09-25 |
| `ui/button_blue_hover.png` | Kenney: UI Pack | `PNG/Blue/Default/button_rectangle_depth_gradient.png` | CC0 1.0 | Same | 2026-09-25 |
| `ui/button_blue_pressed.png` | Kenney: UI Pack | `PNG/Blue/Default/button_rectangle_flat.png` | CC0 1.0 | Same | 2026-09-25 |
| `ui/button_grey.png` | Kenney: UI Pack | `PNG/Grey/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_red.png` | Kenney: UI Pack | `PNG/Red/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `fonts/kenney_future_narrow.ttf` | [Kenney: Kenney Fonts](https://kenney.nl/assets/kenney-fonts) | `Fonts/Kenney Future Narrow.ttf` | CC0 1.0 | Renamed | 2026-09-24 |
| `fonts/kenney_future.ttf` | Kenney: Kenney Fonts | `Fonts/Kenney Future.ttf` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/grass_tile.png` | [Kenney: Top-down Tanks Remastered](https://kenney.nl/assets/top-down-tanks-remastered) | `PNG/Default size/tileGrass1.png` | CC0 1.0 | Renamed; tinted darker in code | 2026-09-24 |
| `sprites/background/tree_autumn_large.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeBrown_large.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/tree_autumn_small.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeBrown_small.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/tree_green_small.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeGreen_small.png` | CC0 1.0 | Renamed (palette A: green trees instead of autumn) | 2026-09-25 |
| `sprites/background/tree_green_large.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeGreen_large.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/menu/sky.png` | [Kenney: Background Elements Remastered](https://kenney.nl/assets/background-elements-remastered) | `Backgrounds/backgroundEmpty.png` | CC0 1.0 | Renamed; the title screen's sky | 2026-09-25 |
| `sprites/background/menu/house1.png`, `house2.png`, `house_alt1.png`, `house_alt2.png` | Kenney: Background Elements Remastered | `PNG/Default/house1.png`, `house2.png`, `houseAlt1.png`, `houseAlt2.png` | CC0 1.0 | Renamed; slightly tinted in code | 2026-09-25 |
| `sprites/background/menu/fence_iron.png` | Kenney: Background Elements Remastered | `PNG/Default/fenceIron.png` | CC0 1.0 | Renamed; tinted toward ink blue in code | 2026-09-25 |
| `sprites/background/menu/bush1.png`, `bush3.png`, `bush_alt1.png` | Kenney: Background Elements Remastered | `PNG/Default/bush1.png`, `bush3.png`, `bushAlt1.png` | CC0 1.0 | Renamed | 2026-09-25 |
| `fonts/rubik_variable.ttf` | [Google Fonts: Rubik](https://fonts.google.com/specimen/Rubik) (`github.com/google/fonts/ofl/rubik/Rubik[wght].ttf`) | `Rubik[wght].ttf` | **SIL OFL 1.1** (ship `fonts/rubik_OFL.txt` with the game; credit optional) | Renamed | 2026-09-24 |
| `fonts/noto_sans_sc_subset.ttf` | [Google Fonts: Noto Sans SC](https://fonts.google.com/specimen/Noto+Sans+SC) | `NotoSansSC[wght].ttf` | **SIL OFL 1.1** (ship `fonts/notosanssc_OFL.txt`) | Fixed at weight 700 and subset to the game's characters by `tools/subset_fonts.py` | 2026-09-24 |
| `fonts/noto_sans_jp_subset.ttf` | [Google Fonts: Noto Sans JP](https://fonts.google.com/specimen/Noto+Sans+JP) | `NotoSansJP[wght].ttf` | **SIL OFL 1.1** (ship `fonts/notosansjp_OFL.txt`) | Same | 2026-09-24 |
| `fonts/noto_sans_kr_subset.ttf` | [Google Fonts: Noto Sans KR](https://fonts.google.com/specimen/Noto+Sans+KR) | `NotoSansKR[wght].ttf` | **SIL OFL 1.1** (ship `fonts/notosanskr_OFL.txt`) | Same | 2026-09-24 |
| `fonts/ui_font*.tres`, `fonts/title_font.tres` | Built by `tools/build_ui_theme.gd`: Kenney Future (Narrow) with Rubik as fallback | | (ours) | | 2026-09-24 |
| `ui/game_theme.tres` | Built by `tools/build_ui_theme.gd` from the files above | | (ours) | | 2026-09-24 |
| `audio/sfx/coin_1.ogg` | [Kenney: Casino Audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-1.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/coin_2.ogg` | [Kenney: Casino Audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-2.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/coin_3.ogg` | [Kenney: Casino Audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-3.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/hit_1.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactWood_light_000.ogg` (was impactSoft_medium; swapped for a crisper click) | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/hit_2.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactWood_light_001.ogg` (was impactSoft_medium; swapped for a crisper click) | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/hit_3.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactWood_light_002.ogg` (was impactSoft_medium; swapped for a crisper click) | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/wolf_hit_1.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactPunch_medium_000.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/wolf_hit_2.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactPunch_medium_001.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/pop_1.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/pluck_001.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/pop_2.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/pluck_002.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/latch_1.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/scratch_001.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/latch_2.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/scratch_002.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/purchase.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/confirmation_001.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/sell.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/drop_002.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/stall.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactMetal_heavy_000.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/restart.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/maximize_006.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/click.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/click_002.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/tab.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/switch_002.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/crank.ogg` | [Kenney: Interface Sounds](https://kenney.nl/assets/interface-sounds) | `Audio/tick_001.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `../resources/audio/sound_bank.tres` | Lists the sounds above with volumes (ours) | | | | 2026-09-24 |

## Downloaded packs (in `../kenney_assets/`) with nothing used yet
| Pack | URL | License |
|---|---|---|
| Foliage Sprites | https://kenney.nl/assets/foliage-sprites | CC0 1.0 |
| Foliage Pack | https://kenney.nl/assets/foliage-pack | CC0 1.0 |

Credit line (optional for CC0, but nice): "Art by Kenney (www.kenney.nl)".
