# Codex memo U: theming readiness (2026-09-25)

Question (Garret): how hard would themes be later (an original theme-park enemy lineup, Halloween pumpkins, Christmas snowballs) with the code as it is? Memos are input, not decisions.

**Theming is feasible without rewriting combat.** A replacement enemy lineup with unchanged mechanics is **M** work; a complete, selectable Halloween/Christmas presentation is **L** initially. Subsequent themes should mostly be asset, text, and testing work. The strongest foundation already exists; the missing piece is one place to select and apply presentation.

1. **Already theme-friendly**
   - Enemy stats, textures, outlines, and visual size live in `resources/enemies/*.tres` through [EnemyData](../../scripts/enemy_data.gd:6). Visual size is separate from hit/click radii—ideal for replacing a Rock with a snowball while preserving balance. Mount textures likewise live in resources, such as [horse.tres](../../resources/mounts/horse.tres:4).
   - `resources/tiers` combines **TierData** colors/stat multipliers, **WaveProfile** composition, and scene references; `resources/bosses` provides **BossData** names, scenes, gates, and rewards. See [grey.tres](../../resources/tiers/grey.tres:3), [WaveProfile](../../scripts/wave_profile.gd:11), and [BossData](../../scripts/boss_data.gd:7). Spawning is generic.
   - Enemies already have `Visual/Sprite` and `Visual/Outline`; tier tint and hit flash use separate layers ([EnemyBase](../../scripts/enemy_base.gd:304)).
   - UI/boss/upgrade strings use [strings.csv](../../localization/strings.csv:57); sounds use a named [SoundBank](../../resources/audio/sound_bank.tres:25). The UI has a central [theme builder](../../tools/build_ui_theme.gd:18). [ParkBackground](../../scripts/park_background.gd:14), [ParkScenery](../../scripts/park_scenery.gd:11), and [Carousel](../../scripts/carousel.gd:13) expose extensive colors, textures, and layout settings.

2. **What complicates it**
   - There is no theme selector/resolver. Tier resources reference concrete enemy scenes; scenes reference concrete data. Background sprite paths are baked into [Game.tscn](../../scenes/Game.tscn:14) and [MainMenu.tscn](../../scenes/MainMenu.tscn:4). Enemy/mount sprite paths mostly live in `.tres`, **not** `.tscn`.
   - Boss child spawning needs coverage: [EnemyLeafStorm](../../scripts/enemy_leaf_storm.gd:40) defaults to Leaf scenes/data; [EnemyBoulder](../../scripts/enemy_boulder.gd:14) to Rock/grip data; [EnemyObsidianBoulder](../../scripts/enemy_obsidian_boulder.gd:8) to Rock splits. These are overridable exports, but reskinning only the boss body would leave original-looking children.
   - **Behavior and presentation overlap:** Leaf Storm draws wind/warning rings in its combat script ([line 197](../../scripts/enemy_leaf_storm.gd:197)); [EnemyAncientLog](../../scripts/enemy_ancient_log.gd:20) couples armor hits with bark rings; [EnemyStickGiant](../../scripts/enemy_stick_giant.gd:27) combines zigzag movement and visual sway; Boulder combines approach and rolling. **Gilded Gale already reuses EnemyLeafStorm**, with scene overrides ([GildedGale.tscn](../../scenes/enemies/GildedGale.tscn:3)).
   - The UI builder outputs one fixed theme; [LocaleFonts](../../scripts/locale_fonts.gd:8) targets that same file. [AudioManager](../../scripts/autoloads/audio_manager.gd:8) preloads one bank. Theme selection must cover these and scattered feedback colors.
   - `enemy_name` contains English metadata, currently without gameplay branching; tests explicitly expect “Stick”/“Rock” ([test_enemy_art](../../tests/test_enemy_art.gd:37)). Ordinary enemies lack stable IDs. Mount IDs **are** gameplay identifiers: `horse` is the starting/income mount ([GameState](../../scripts/autoloads/game_state.gd:63)). Keep internal IDs independent of themed names.

3. **Recommended future architecture and order**

   Use a typed `ThemeData` resource with a default fallback: stable gameplay ID → skin, localized name/description keys, textures/outlines, visual scale/animation, and sound overrides; plus tier presentation, backgrounds, carousel palette, and Godot UI `Theme`. Keep combat resources shared.

   | Step | Size |
   |---|---|
   | Establish stable enemy IDs and presentation contracts; retain existing mount/boss IDs | S |
   | Add theme lookup/application at creation, covering ordinary enemies, summons, grips, splits, and mounts | M |
   | Extend existing `Visual` into a skin interface; expose warning/armor state to presentation while retaining boss mechanics | M–L |
   | Connect menu/world/UI/audio/text presentation; initially select themes between sessions | M |
   | Produce and verify one complete theme across bosses, locales, and screen sizes | L |

   *S = hours, M = roughly 1–3 focused days, L = several days or more; asset production and Garret’s review can dominate.*

   **Habits now:** keep names out of gameplay conditions; preserve IDs and scene contracts; put new appearance tunables in exports/resources; keep visual dimensions separate from combat geometry; test behavior independently of English names. No theme framework needs building yet.

4. **Risks worth planning for**
   - **Saves:** run saves are **not implemented yet**—[SaveManager](../../scripts/autoloads/save_manager.gd:2) currently saves settings only. Runtime progression uses mount/upgrade IDs and tier ranks ([GameState](../../scripts/autoloads/game_state.gd:88)). Future saves should retain these meanings, store theme choice separately, and fall back safely when a theme disappears.
   - **Readability/tests:** orange pumpkins multiplied by tier tint may become muddy; preserve tier recognition, warning visibility, and apparent hit size. Add theme-completeness checks alongside existing [localization/glyph tests](../../tests/test_localization.gd:132). Renaming mounts also requires themed upgrade descriptions.
   - **Performance:** resolve skins once, share textures, and avoid elaborate per-enemy effects; measure any substantial animation increase.
   - **Asset policy:** use original names and Kenney CC0 or code-drawn art only; no Disney names/assets or AI-generated art/audio. Record provenance in [PROVENANCE.md](../../assets/PROVENANCE.md:8); Garret approves player-facing text.

Read-only investigation; no files changed, game launched, or checks run.