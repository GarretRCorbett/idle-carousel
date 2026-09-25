# Phase 3 · Step 7 Plan: the other five tier bosses
**Status:** Garret: "go ahead and get started" (2026-09-25). Built on Step 6's framework
(`EnemyBoss`, `BossEncounter`, roles, strip). Numbers are drafts; tuned with `tools/boss_sim.tscn`.
**Inputs:** GDD v1.15 boss table, README Decided (Q16–Q20), memo M (kill gates, boss health),
memo N (timers).

## Shared additions (7.1)
- **Latching bosses** (Stick Giant, Ancient Log, Obsidian Boulder) fly in and latch like big
  enemies. A latched boss or required piece is a **protected** latch (Emergency Clear can't remove
  it; the stall safety net is already off in fights). Its drag and latch damage are the pressure.
- `EnemyBase._speed_multiplier() -> float` hook (1.0 by default) for the Boulder's roll.
- `EnemyData.immune_to_slow` (Ancient Log; freeze later reads it too).
- `EnemyBoss.split_tier: TierData`: children of a split can be a different tier (Obsidian's Red
  Rocks). Default: the fight's tier.
- A `BossData` per tier, linked from each tier file. Starting numbers:

| Tier | Boss | Kill gate | Timer | First / repeat Gold |
|---|---|---|---|---|
| Green | Stick Giant | 80 | 120 s | 300 / 75 |
| Yellow | Boulder | 100 | 120 s | 450 / 110 |
| Orange | Gilded Gale | 120 | 150 s | 650 / 160 |
| Red | Ancient Log | 140 | 150 s | 900 / 225 |
| Charcoal | Obsidian Boulder | 160 | 180 s | 1,300 / 325 |

## The bosses
- **7.2 Stick Giant** (Green): a big Stick that **zigzags** on its way in (its bearing swings side
  to side, which the unwrapped bearings from Step 2 handle), then latches with heavy drag.
- **7.3 Boulder** (Yellow): a big Rock that **rolls faster as it nears** the carousel. When it
  reaches the rim it breaks into **3 grips**: three ordinary enemies latched side by side, each
  with a third of the health it has left (hits on the way in count) and a third of its drag, so
  the drag drops as each grip breaks. All three must die (REQUIRED). Simpler than one enemy
  latched at three points: every latch, sweep and click rule already works.
- **7.4 Gilded Gale** (Orange): Leaf Storm's drifting script with a different rhythm: a **steady
  trickle** of about 2 Orange Leaves every 4 s (short warning, no packs), gold wind. Summons pay
  nothing. No death split: killing it wins.
- **7.5 Ancient Log** (Red): a huge, slow Stick. **Immune to slow**; its **first 3 hits do 25%
  damage** (three bark rings drawn on it show the hits left). Latches.
- **7.6 Obsidian Boulder** (Charcoal): a big dark Rock with the outline. Latches. **Two stages**:
  on death it splits into **2 Red Rocks** (REQUIRED); the win comes when both are dead.

Art: the existing leaf/stick/rock sprites, scaled up, tinted by tier, plus code-drawn details.

## Tuning (7.7)
`tools/boss_sim.tscn` learns every tier: for each boss, a plausible build for that point in the
run (e.g. Green: Horse, 2 Wolves, Giraffe; more slots and Tier 2s later) at 1.5 clicks/s. Target:
a win in roughly 60–80% of the timer with some pressure; no clicking and a thin build lose.

## Tests
Each boss: its behavior (zigzag bearing swing, faster roll near the rim, trickle timing, the 25%
armor for 3 hits and slow immunity, the split into 2 Red Rocks), its win rule (all REQUIRED pieces
dead), protected latches, and a data test that every tier has a valid boss.
