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
