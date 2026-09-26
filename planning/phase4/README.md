# Phase 4 Planning: Start Here

## Status (2026-09-26)
- **Phase 4 started** while Phase 3 Step 9 waits for Codex (Garret). Codex review fixes for
  Phase 3 may land on top of Phase 4 work.
- **Fail state decided** (Garret, GDD v1.18): "safe farm, risky push" as played since Phase 2 is
  official. That clears the roadmap's "resolve before Phase 4".
- **Order** (Garret): save system first; Claude renders the shop mockups (Codex is out).
- **Step 1 done (2026-09-26):** save system (Continue / New run, auto-save 60 s, milestone and
  manual saves, `.tmp` + `.bak`, forgiving loads, 12 tests); `TEMPORARY` stall comments retired.
  Saving is on only for runs started from the main menu, so running `Game.tscn` directly (F6),
  tests, and the sims never touch the real save.
- **Step 2 done (2026-09-26):** offline progress (Garret: normal booth income + the Panda's Gold per
  turn at base speed, ×0.5, 1 min minimum, 8 h cap; only time with the game closed counts, so the
  main menu pays nothing) and the "Welcome back" popup on Continue. Numbers in RunConfig "Offline".
- **Step 3 done (2026-09-26):** **Auto-Boost** (Garret's name), Carousel tab after Boost Power, 4 levels
  holding 30 / 50 / 65 / 82% of the bar; 400 Gold ×3 per level, level 4 after the second boss (drafts).
  It refills at a steady 0.3 bar/s (≈3 presses/s; Garret's pick), never above its hold, never while
  stalled. One latch can't beat it at the top level; two or three drain faster and end Overdrive.
- **Step 4 mockups rendered (2026-09-26)**, waiting for Garret's pick: `mockups/` (A compact rows, B cards,
  C one line + details box; `compact_carousel_tab.png` for the other tabs). Made-up levels and stars.
  Rebuild with `tools/_mockups/ShopMockups.tscn`. Note: below ~270 px the three tab titles don't fit.

## Scope
From the roadmap: save system, offline progress + "Welcome back", the full upgrade tree with shop
visibility states, kill-gate HUD polish, hold-to-boost automation (now auto-boost), random events.
From playtest 3 (`planning/phase3/playtest3_plan.md`, GDD v1.17): shop redesign, mount levels and
stars, auto-boost, Park Guide, tutorial, music (human-made CC0/public domain only).

## Proposed steps (draft)
Sizes: S ≈ under 1 h, M ≈ 1–2 h, L ≈ 2–3 h.

| Step | Work | Size |
|---|---|---|
| 1 | **Save system** (plan below) + retire the `TEMPORARY` stall comments (the rule is official now) | L |
| 2 | **Offline progress** + "Welcome back" popup | M |
| 3 | **Auto-boost** (4 levels; needs names and prices from Garret) | M |
| 4 | **Shop mockups** (Claude renders 2–3 over the real game) → Garret picks | S |
| 5 | **Shop redesign + mount levels and stars** (built together; Tier 2 rows become per-mount tracks with ★2) | L (maybe 2 sessions) |
| 6 | **Full upgrade tree** from the GDD + shop visibility states (affordable / almost / locked / hidden) | L |
| 7 | **Random events** (pickups and surprise visitors, data-driven) | M–L |
| 8 | **Park Guide** (almanac from the pause menu) + kill-gate HUD polish, Gold more prominent | M–L |
| 9 | **Tutorial** (Claude drafts the script, Garret approves, then build) | M |
| 10 | **Music** (sources in `playtest3_plan.md`; logged in PROVENANCE) | S–M |
| 11 | Playtest, Codex review, understanding check, sign-off | M |

Controller/touch readiness (Garret, 2026-09-26): build new UI with Input Map actions (not
hard-coded keys) and working focus, so a controller pass later is cheap.

## Step 1 plan: save system
**Goal:** closing the game never loses progress; the file is safe against crashes and future
changes; prestige can be added later without breaking old saves.

**What's saved** (`user://save_data.json`, human-readable):
```json
{
  "version": 1,
  "saved_at": 1790000000,
  "permanent": {},
  "run": {
    "gold": 1234.0,
    "upgrade_levels": {"carousel_speed": 3, "wolf": 2},
    "mount_roster": ["horse", "wolf", "wolf"],
    "selected_tier": 1,
    "tier_kills": {"0": 60, "1": 12},
    "bosses_beaten": 1,
    "boss_clear_times": {"0": 1060.5},
    "run_seconds": 2400.0,
    "run_seed": 123456
  }
}
```
- **Only the facts are saved; everything else is rebuilt.** Spin bonus, boost cap, click damage,
  booths, slots and mount tiers all follow from the upgrade levels, so loading re-derives them
  from the upgrade catalog. One source of truth; a changed upgrade value applies to old saves.
- **Not saved (on purpose):** enemies on the field, latches, health, boost and Overdrive, a boss
  fight in progress. Loading starts a clean field at full health (the fail-state rule: returning
  finds a healthy carousel). Quitting mid-fight forfeits that attempt, which only costs time.
- `permanent` stays empty until prestige (Phase 5). Settings stay in `settings.cfg`.

**When it saves** (GDD's three layers):
- Auto: every 60 s (a Timer), with a small save icon flashing in the corner.
- Milestone: right after any purchase, sale, boss win, or tier change.
- Manual: a Save button in the Esc menu. Also on quit and on returning to the main menu.

**Safety:**
- Write to `save_data.json.tmp`, then swap it in; the previous file becomes `save_data.json.bak`.
  A crash mid-write never leaves a broken save.
- Loading: a bad or unreadable file falls back to the `.bak`. Unknown upgrade ids are skipped;
  levels are clamped to each upgrade's max; a roster that doesn't match the levels is rebuilt.
- `version` lets a later build upgrade old files instead of breaking them.

**Main menu:** **Continue** (shown when a save exists) and **New Run**. New Run over an existing
save uses the two-step "Confirm?" button (GDD v1.14: confirmations for losing things).

**Code shape:**
- `GameState.to_save_data() -> Dictionary` and `GameState.load_save_data(data) -> bool`. GameState
  stays the only writer of its own state; `load_save_data` re-derives through the same code a
  purchase uses, so loading can't disagree with buying.
- `SaveManager`: file I/O only (`save_run()`, `load_run()`, `has_run_save()`, `delete_run_save()`),
  plus the auto-save timer and milestone hooks. Tests point it at a test path, like settings.
- Tests: save → load round trip (every field), derived stats match a run that bought the same
  things, corrupt file → `.bak`, missing file → fresh run, unknown ids and over-max levels,
  a mid-fight save loads with no fight.

**New strings** (drafts for Garret): `MENU_CONTINUE` "Continue", `MENU_NEW_RUN` "New Run",
`OPTIONS_SAVE` "Save", `OPTIONS_SAVED` "Saved".

## Step 5 plan: shop redesign (A) + mount levels and stars
Garret picked **A, compact rows** for Mounts and the compact style for the other tabs (2026-09-26).

**One track per mount** (GDD v1.17), a single upgrade `<mount>_level` in place of `<mount>_tier2`
(and Wolf Fang, which becomes the Wolf's levels):
- Buys 1–3 are **levels** (pips). Buy 4 is the **★2 star-up** (its own big price; glowing button).
  Buys 5–7 are levels 4–6 (the pips reset and turn gold). ★3 waits for prestige (Phase 5).
- Shared by every copy of the mount; selling one never loses progress (as tiers today).
- The Panda unlocks at **3 mount types at ★2** (was 3 at Tier 2).

| Mount | Each level (draft) | ★2 (today's Tier 2 value) |
|---|---|---|
| Horse | +15% Gold per booth pass | ×2 Gold per pass |
| Wolf ("Wolf Fang") | +0.5 damage per hit | ×1.5 damage |
| Giraffe ("Long Neck") | +10% reach | ×1.5 damage (GDD "hits harder"; today's Tier 2 gives reach) |
| Sloth ("Drowsy") | +15% slow time | ×2 slow time |
| Elephant ("Trumpet") | +10% wedge width | ×2 wedge width |
| Panda | +15% Gold per turn and healing | ×1.5 Gold, healing and damage |

Prices (drafts, then re-simmed): levels start near today's Wolf Fang/Tier 2 scale (×1.6 per level);
the star-up costs about today's Tier 2 price. The economy sim's build order is updated to buy levels.

**Shop (A):** a Mounts row = icon (greyed when locked), name, ×count, ★ badge, pips (gold after ★2),
the lock reason if locked, then **Buy** (gold) · **Sell** (blue, two-step) · **Up** / **Star up**
(gold; glowing for the star-up). What the next level does goes in the Up button's tooltip. Other tabs:
one line per upgrade (name, short description, pips, gold price button). Shop about 270 px wide.

**Code:** `UpgradeData` gets `star_cost` (the price of buy 4) and a `MOUNT_LEVEL` effect; `MountData`'s
`tier2_*` become `star2_*` plus per-level bonuses; `GameState.get_mount_star()` / `get_mount_level()`
replace `get_mount_tier()`; the shop's Mounts tab becomes one row per animal. **Save v2:** old saves
convert (a Tier 2 becomes ★2; Wolf Fang levels become Wolf levels, up to 3). Tests for all of it.

**Step 5 done (2026-09-26).** Built as planned, with Garret's picks (Golden Saddle, Bamboo Snack,
Giraffe ★2 hits harder). Changes from the plan after the sims:
- Wolf levels give **+0.75** damage (not +0.5): with only 6 levels (Wolf Fang had 10) the late Wolf
  was too weak and Ancient Log couldn't be beaten.
- Track prices (level / star-up): Horse 480 / 2,500, Wolf 420 / 2,500, Giraffe 640 / 3,250,
  Sloth 640 / 3,900, Elephant 2,100 / 9,750, Panda 3,200 / 14,600; levels ×1.6 (Wolf ×1.75).
- Boss health: Stick Giant 330, Boulder 590, Gilded Gale 580 (Leaf Storm 120, Ancient Log 460,
  Obsidian 440 unchanged). The fights sit near a pass/fail line, so small changes swing a lot.
- Economy sim, 1 click/s, seeds 1-3: bosses at **0:20, 0:37, 0:54, 1:45, 2:06, 2:27**
  (targets 0:15, 0:35, 1:00, 1:30, 2:05, 2:40). Gilded Gale is the longest wall (~50 min): watch it.
- Save version 2: old saves convert (a Tier 2 becomes ★2 with levels 1-3; Wolf Fang levels become
  Wolf levels, up to 3 before the star and 3 after).

## Step 6 plan: the rest of the upgrade tree + shop visibility (Garret's answers, 2026-09-26)
**New upgrades** (Upgrades tab; every number is a draft, re-simmed before commit):

| Upgrade | Levels | Effect per level | Price (growth) | Available |
|---|---|---|---|---|
| Carousel Health | 3 | +25 max health (100 → 175) | 600 (×2.5) | one level per boss beaten (0 / 1 / 2) |
| Gilded Rims (merges Polish and Shine) | 3 | +10% to all Gold earned; the rim turns more golden | 1,500 (×2.5) | after Leaf Storm |
| Offline Efficiency | 5 | +5% offline rate (50% → 75%) | 800 (×1.8) | after Leaf Storm |
| Click Range | 3 | +25% click radius | 150 (×2) | from the start |

- "All Gold earned" = booth passes, kills, the Panda, offline Gold and boss rewards (not sale refunds).
- **Click Combo: skipped for now** (Garret); noted with the auto-clicker ideas.
- ★3 abilities (Trunk Toss, Double Take, Pack Mentality) stay in Phase 5 (prestige).

**Visibility** (GDD "Upgrade Visibility System"):
- **Hidden** until you're **one boss away** from unlocking it (e.g. Elephant and Mount Slot 5 appear once
  Leaf Storm is beaten); then **locked** (dimmed, with its requirement), then buyable. Same rule on both tabs.
- **Affordable:** the gold button pulses gently.
- **Fill bar:** a thin (3 px) bar under each price button, Gold toward the price.
- **Bought / maxed:** stays in place, dimmed, "Max".

**Upgrades tab sections** (small headers): Carousel (Speed, Ticket Booth, Carousel Health) · Boost (Boost
Power, Auto-Boost) · Clicks (Click Damage, Click Range) · Gold (Gilded Rims, Offline Efficiency).
`UpgradeData.section` sets it; headers hide when all their rows are hidden.

**Also:** the economy sim buys the new rows; tests for each effect, the visibility rule, and saves
(new upgrades load through `_apply_effect` like the rest). GDD updated (merged Gilded Rims, booth
prices, Combat tab gone).
