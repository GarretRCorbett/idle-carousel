# Asset Provenance Log

Every asset in the game, where it came from, and its license (GDD: Asset & AI Policy).
Downloaded packs are kept unmodified in `../kenney_assets/` (outside the repo, zips in `_zips/`); only files the game uses are copied here.

| File | Source | Original file | License | Changes | Date |
|---|---|---|---|---|---|
| `sprites/mounts/horse.png` | [Kenney: Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `PNG/Round (outline)/horse.png` | CC0 1.0 | None | 2026-09-24 |
| `sprites/mounts/wolf.png` | [Kenney: Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | `PNG/Round (outline)/dog.png` (stand-in for the Wolf) | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_yellow.png` | [Kenney: UI Pack](https://kenney.nl/assets/ui-pack) | `PNG/Yellow/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_yellow_hover.png` | Kenney: UI Pack | `PNG/Yellow/Default/button_rectangle_depth_gradient.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_yellow_pressed.png` | Kenney: UI Pack | `PNG/Yellow/Default/button_rectangle_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_grey.png` | Kenney: UI Pack | `PNG/Grey/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `ui/button_red.png` | Kenney: UI Pack | `PNG/Red/Default/button_rectangle_depth_flat.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `fonts/kenney_future_narrow.ttf` | [Kenney: Kenney Fonts](https://kenney.nl/assets/kenney-fonts) | `Fonts/Kenney Future Narrow.ttf` | CC0 1.0 | Renamed | 2026-09-24 |
| `fonts/kenney_future.ttf` | Kenney: Kenney Fonts | `Fonts/Kenney Future.ttf` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/grass_tile.png` | [Kenney: Top-down Tanks Remastered](https://kenney.nl/assets/top-down-tanks-remastered) | `PNG/Default size/tileGrass1.png` | CC0 1.0 | Renamed; tinted darker in code | 2026-09-24 |
| `sprites/background/tree_autumn_large.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeBrown_large.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/tree_autumn_small.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeBrown_small.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/tree_green_large.png` | Kenney: Top-down Tanks Remastered | `PNG/Default size/treeGreen_large.png` | CC0 1.0 | Renamed | 2026-09-24 |
| `sprites/background/menu_fall.png` | [Kenney: Background Elements Remastered](https://kenney.nl/assets/background-elements-remastered) | `Backgrounds/backgroundColorFall.png` | CC0 1.0 | Renamed; dimmed in the menu scene | 2026-09-24 |
| `fonts/rubik_variable.ttf` | [Google Fonts: Rubik](https://fonts.google.com/specimen/Rubik) (`github.com/google/fonts/ofl/rubik/Rubik[wght].ttf`) | `Rubik[wght].ttf` | **SIL OFL 1.1** (ship `fonts/rubik_OFL.txt` with the game; credit optional) | Renamed | 2026-09-24 |
| `fonts/ui_font.tres`, `fonts/title_font.tres` | Built by `tools/build_ui_theme.gd`: Kenney Future (Narrow) with Rubik as fallback | | (ours) | | 2026-09-24 |
| `ui/game_theme.tres` | Built by `tools/build_ui_theme.gd` from the files above | | (ours) | | 2026-09-24 |
| `audio/sfx/coin_1.ogg` | [Kenney: Casino Audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-1.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/coin_2.ogg` | [Kenney: Casino Audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-2.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/coin_3.ogg` | [Kenney: Casino Audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-3.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/hit_1.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactSoft_medium_000.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/hit_2.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactSoft_medium_001.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
| `audio/sfx/hit_3.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactSoft_medium_002.ogg` | CC0 1.0 | Renamed | 2026-09-24 |
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
