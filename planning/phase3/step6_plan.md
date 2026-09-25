# Phase 3 · Step 6 Plan: first boss (Leaf Storm), boss framework, strip UI, gating
**Status:** Garret approved the direction 2026-09-25 ("run with it"): memo S's Leaf Storm with
**~20 Leaves per pack**, and **bigger waves** in the main game. This plan records the contracts;
Claude builds it in one go. Numbers are drafts in data.
**Inputs:** README Decided sections (timed bosses, failure costs only time, unlimited cranks, free
tier choice, strip UI = option A, gate Giraffe/Sloth/more behind Leaf Storm, two-step confirms for
Sell and Give up, beaten bosses re-fightable with a smaller repeat reward), memos Q, R, S.

## 6a. Bigger waves (all tiers)
Roughly double each tier's `min_enemies`/`max_enemies` (Grey 6–10 … Charcoal 12–20), widen each
cluster (spread 20° → 30°, depth 60 → 120 px) so bigger packs don't arrive as one blob. The Send
limit stays 30 for now (it's a Garret call to revisit at the first playtest).

## 6b. Progression state (GameState, save-ready plain values)
- `get_bosses_beaten() -> int`: tiers whose boss is beaten, in order. Tier `rank` is unlocked
  when `rank <= bosses_beaten`. `set_selected_tier` refuses locked tiers and refuses to switch
  during a fight.
- `get_boss_clear_time(rank)`: run time of each first clear (speedrun-friendly, README).
- `tier_kills_changed(rank, kills)` signal for the strip; `boss_state_changed` for fight start/end.
- `set_boss_active(bool)`: while a fight runs the stall **safety net is suspended** (cranking is the
  rescue; the fight's own timer ends the attempt) and `record_kill` isn't called for encounter
  enemies.

## 6c. Boss data and the encounter
```
BossData extends Resource          # scripts/boss_data.gd; resources/bosses/leaf_storm.tres
  name_key, scene (the boss body), time_limit_seconds (90), kills_required (60),
  first_clear_gold, repeat_clear_gold
TierData.boss: BossData            # each tier's boss (Grey = Leaf Storm; others null until Step 7)

BossEncounter extends Node         # scripts/boss_encounter.gd, child of Game
  signal started(tier_rank) / time_changed(seconds_left) / boss_health_changed(fraction)
  signal ended(victory: bool)
  start(tier, boss) / give_up() / advance(delta)   # Game ticks it; no Timer node, so it's exact
```
- **States:** FIGHTING (body alive) → CLEANUP (body dead, required children alive) → ended.
- Encounter enemies carry `EnemyBase.encounter_role`: NONE (normal), SUMMON (optional),
  REQUIRED (the 4 split Leaves), BOSS. Non-NONE enemies **pay no Gold and give no kill credit**.
- **During a fight:** auto waves, Send and N are paused (auto preference kept); tier switching is
  off; summons are capped (live + queued); normal enemies already on screen stay.
- **Victory** (body and every REQUIRED child dead): first clear pays `first_clear_gold`, unlocks the
  next tier (and with it Slot 4 etc. via gating), records the clear time; a repeat pays
  `repeat_clear_gold`. **Timeout / Give up:** every encounter enemy is removed with no rewards;
  kill-gate progress, Gold and unlocks are kept; retry is free.
- **Protected latches:** REQUIRED children and the boss are never removed by Emergency Clear
  (GameState keeps a protected flag per latch).

## 6d. Leaf Storm
`EnemyLeafStorm extends EnemyBase` (`scenes/enemies/LeafStorm.tscn`, data `leaf_storm.tres`):
- Never latches. Drifts along a fixed lower arc 220 px from the center (from -20° to 200°,
  easing, reversing at the ends), max 45 px/s, so it stays clear of the strip, side panels and Boost.
- Cycle (ticks, deterministic): 3 s quiet start → **1.5 s gust warning** (stops; wind arcs gather,
  two fans marked beside it) → **summon a pack** → 4 s drift → 6.5 s rest → repeat (12 s cycle).
- **Packs of ~20 storm leaves** (Garret), in two fans flanking the Storm ~300–330 px out. Storm
  leaves are their own `storm_leaf.tres`: **1 health** (one Wolf pass or one click), low latch
  damage (0.25/s) and drag (0.02), no Gold. 20 normal Leaves latched would stall the carousel every
  pack. Summon cap 45 live + queued.
- 50 health, ~88 px across (Leaf art, large, plus code-drawn wind arcs), click radius 52. A click
  inside its core always hits the Storm, even with a Leaf in front.
- On death: queues exactly **4 Grey Leaves** (REQUIRED) around it; clearing them wins (GDD split).

## 6e. Gating (UpgradeData)
- `required_bosses`: can't buy at all before N bosses are beaten. Giraffe, Sloth, Elephant, Panda,
  every Tier 2 row, and extra Ticket Booths: 1.
- `level_cap_by_bosses: PackedInt32Array`: highest level buyable after 0, 1, 2… bosses. Mount slots
  `[2, 3, 4, 5]` (slot 4 after boss 1, 5 after boss 2, 6 after boss 3; `max_level` 2 → 5); Carousel
  Speed and Boost Power `[3, 10]`.
- Shop rows show "Beat {boss}" when a boss gate is what's blocking them.

## 6f. Strip UI and confirmations
`scenes/ui/BossStrip.tscn` (+ `boss_strip.gd`) instanced at the top of the HUD's PlayColumn:
```
BossStrip (PanelContainer)
└── Margin (MarginContainer)
    └── Row (HBoxContainer)
        ├── BossName (Label)            "LEAF STORM"
        ├── Progress (Label)            "42/60" kills, or the fight timer "1:12"
        ├── Bar (ProgressBar)           kill gate, or boss health (HealthBar variation) in a fight
        ├── ActionButton (TwoStepButton) Challenge (one click) / Give up (two-step)
        ├── Spacer (Control, expand)
        └── Pips (HBoxContainer)        six numbered tier pips, built in code; locked = dim
```
- `TwoStepButton extends Button` (`scripts/two_step_button.gd`): first press shows "Confirm?" for
  `confirm_seconds` (3), second press emits `confirmed`. Used by Give up and the shop's Sell.
- Pips: click an unlocked tier to farm it; disabled in a fight; tooltip = tier name.
- Strings (Claude drafts, 9 languages): tier names, "Leaf Storm", Challenge, Give up, Confirm?,
  "Beat {0}", kills "{0}/{1}", reward line. `python tools/subset_fonts.py` after.

## 6g. Dev keys
F2/F3 stay (debug builds): step through tiers and, in debug only, unlock a tier to reach it.

## Commits
1. Bigger waves. 2. TwoStepButton + Sell. 3. Progression state + BossData/TierData.boss.
4. Gating. 5. BossEncounter + encounter roles + protected latches + paused waves. 6. Leaf Storm.
7. Strip UI. 8. GDD + docs. Then a headless balance run of the fight (Horse + Wolf + clicks) and a
cleanup/optimization pass.
