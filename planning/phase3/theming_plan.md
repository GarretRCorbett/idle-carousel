# Theming: foundation and proof of concept (2026-09-25)

Garret: "I am pretty sure theming is something we will want to do." Examples he gave: an original theme-park enemy lineup, Halloween (pumpkins) and Christmas (snowballs). Every theme keeps the same enemy workings with new names and art. He chose to build the foundation plus a test theme now, before Step 9. Background: Codex memo U (`codex_memo_u_theming.md`).

## What was built
- **Stable ids.** Every `EnemyData` has an `id` (`leaf`, `stick`, `rock`, `storm_leaf`, `boulder_grip`, and the six bosses). Code and themes use ids, never `enemy_name`.
- **`EnemySkin`** (`scripts/enemy_skin.gd`): how one enemy looks, either a sprite or a shape drawn in code (polygon, snowball, snowflake star, icicle/bone shard, pumpkin). It holds looks only. Stats, hitbox and click radius stay in `EnemyData`, so a reskin can't change a fight.
- **`ParkTheme`** (`scripts/park_theme.gd`, one `.tres` per theme in `resources/themes/`):
  - enemy skins by id;
  - boss name keys by `boss_id`;
  - scenery color overrides by role (`park_background` for the play field, `park_scenery` for the title screen).
- **`ThemeManager`** autoload: holds the current theme and provides `skin_for(data)`, `boss_name_key(boss)`, `apply_scenery(node, role)` and a `theme_changed` signal.
  - The first theme is the normal park, with no overrides.
  - Enemies pick up their look when they spawn. Enemies already on screen, the play field, the title screen and the boss strip all update when the theme changes.
- **Two test themes**, built by `tools/make_test_themes.gd`, with all shapes drawn in code (no new art files):
  - **Winter (test):** snowflakes, icicles and snowballs, with snowy pavement and lawns.
  - **Halloween (test):** pumpkins, bones and candy balls, with dusk pavement, purple and orange roofs, and orange lamp glow.
- **Dev key:** F4 cycles Park → Winter → Halloween, in the game and on the title screen (debug builds only).
- **Tests** (`tests/test_themes.gd`):
  - ids are unique;
  - every theme's data is valid, and the park theme comes first;
  - the test themes skin every enemy;
  - a skin leaves health, speed, hitbox, click radius and Gold unchanged;
  - enemies on screen change look and change back;
  - a theme can rename a boss;
  - scenery recolors and gets its own colors back.

## What the test showed
- **The swap works end to end,** including boss summons and death splits, because those are ordinary enemies with ids.
- **Tier tints multiply the theme's colors.** On the Grey tier, white snowflakes turn grey and orange pumpkins turn brown. A real theme needs either light art that tints well (like today's grey sprites) or per-theme tier colors. Decide when a real theme is designed.
- **The test themes have no new boss names.** Player-facing names need Garret's approval and translations. The renaming hook is tested with an existing key.

## Not done yet (for a real theme)
| Step | Size |
|---|---|
| Mount skins (same pattern as enemies, by mount id) | S |
| Carousel colors, UI theme colors, and tier colors per theme | M |
| Sounds per theme (a second SoundBank) | S–M |
| Saved theme choice, plus a player-facing picker (needs approved strings) | S–M |
| Real art for a theme: Kenney CC0 sprites or shapes drawn in code, logged in PROVENANCE | L (mostly art) |

## Habits (also in CLAUDE.md → Architecture rules)
- No gameplay checks on display names.
- Ids never change.
- Looks go in data and exports.
- Visual size stays separate from hitboxes.
- Effect drawing stays apart from fight logic.
- Every new enemy gets an id and a skin in each theme.
