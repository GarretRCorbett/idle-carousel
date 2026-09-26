# Idle Carousel: Dev Log

Private for now (Garret decides later what to publish). Pictures go in `devlog/images/`, named by date and order; `.gdignore` keeps Godot from importing them. Newest first. Written together by Garret and Claude. The full detail lives in `planning/`, the GDD changelog and git history; this log is the story.

---

## 2026-09-25: Bosses, balance, a new look, and a plan for everything else
**How the look evolved today** (pictures in `images/`, in order):
- [Palette A on the forest park](images/2026-09-25_01_palette_a_forest_park.png) and [its title screen](images/2026-09-25_02_palette_a_title.png)
- [Grass park](images/2026-09-25_03_grass_park.png) and [its title screen](images/2026-09-25_04_title_grass_park.png): "too outside park, not enough theme park"
- [First concrete plaza](images/2026-09-25_05_first_concrete_plaza.png) and [the concrete title screen](images/2026-09-25_06_title_concrete.png)
- [Curved walkways](images/2026-09-25_07_curved_walkways.png), then [flared into plazas](images/2026-09-25_08_flared_walkways.png)
- [Beige walkways](images/2026-09-25_09_beige_walkways_rejected.png), which Garret called "a bad call"; back to brick
- [Rooftops](images/2026-09-25_11_rooftops.png), then [the big top-left roof, lamps and ring edge back](images/2026-09-25_12_big_top_left_roof.png)
- [Title shopfronts](images/2026-09-25_13_title_shopfronts.png), then [the blue title](images/2026-09-25_14_title_blue.png)
- Test themes: [Winter](images/2026-09-25_15_winter_test_theme.png), [Halloween](images/2026-09-25_16_halloween_test_theme.png), [Halloween mid-game](images/2026-09-25_17_halloween_mid_game.png)
- [Codex's palette study](images/2026-09-25_18_codex_palette_study.png), and [Purple Garden, final for now](images/2026-09-25_19_purple_garden_final.png)

**Built:**
- **All six tier bosses:**
  - Leaf Storm drifts and throws leaf packs.
  - Stick Giant zigzags in.
  - Boulder has latch points with their own health.
  - Gilded Gale trickles summons.
  - Ancient Log is armored against its first hits.
  - Obsidian Boulder has two stages.
- **Balance:** an economy simulator plays whole runs headless. It tuned prices and boss health to Garret's pace (bosses at about 15 / 35 / 60 / 90 / 125 / 160 min). Clicking was toned down so mounts carry the game.
- **The look:**
  - Grass forest → a theme-park plaza: brick walkways traced from Garret's sketch of a real park map, shop rooftops, planters and gold double lamps.
  - A matching title screen.
- **Purple Garden palette** (from a Codex style study, Garret's picks):
  - purple main buttons;
  - gold for anything that spends Gold;
  - a red Challenge button;
  - tier-shade outlines on every enemy.
- **Theming foundation:** stable enemy ids, skins and themes, plus Winter and Halloween test themes. Looks change; fights don't.
- **Debug tools:** a Debug tab in the Esc menu with Gold, tiers, waves, game speed and themes.

**Playtest 3 (Garret loved it once playing):**
- The Boost bar needs its own panel, and mounts need outlines.
- Idle feels too slow.
- The shop is cramped, and mount upgrades are confusing.

**Decided (GDD v1.17):**
- Mount **levels and stars**: 3 levels, then a ★2 star-up in the run; ★3 abilities come through prestige.
- **Auto-boost** as early automation (it also fixes touchscreens).
- Latches drain boost gently instead of breaking Overdrive.
- A compact shop with one row per mount.
- Income shown above the ticket booths.
- A Hades-style **Park Guide** almanac and a first-run tutorial.

**Art policy:**
- No generative image or audio models, ever. Kenney CC0, plus art drawn by code that Garret directs (Codex memo V).
- Codex now does style studies in its own git worktree while Claude reviews them.

**Next:**
- The small playtest-3 fixes, then the Phase 3 review and sign-off.
- Phase 4: the shop redesign, levels and stars, auto-boost, Park Guide, tutorial, music (human-made, CC0 or public domain).

## 2026-09-24: Phase 3 begins
**Built:**
- Step 2 foundations: one mount interface, shared sweep math, and big performance gains (1,000 enemies in about 3 ms a tick).
- The six color tiers, with real Kenney art for Leaf, Stick and Rock.
- New mounts: Giraffe, Sloth, Elephant and Panda.
- The first boss and the boss strip with tier pips.

**Garret's first two playtests of the boss loop:** "things are looking amazing."

**Pictures:** [tier colors](images/2026-09-24_01_tier_colors.png), [first tiers in game](images/2026-09-24_02_first_tiers_in_game.png), [the boss strip](images/2026-09-24_03_boss_strip.png), [the Leaf Storm fight](images/2026-09-24_04_leaf_storm_fight.png).
