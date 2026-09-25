# Phase 3 · Step 5 Plan: Elephant, mount tiers, Panda
**Status:** APPROVED 2026-09-25 (Garret: make sure Elephant, Wolf and Giraffe feel different).
**Inputs:** GDD (Elephant, Panda, mount tier table), README decisions (Q7 Panda Gold once per full
turn, Q8 heal only on its own kills, Q9 tiers per type, Q10 Panda needs 3 *different* types at
Tier 2, Q11 Elephant = wedge that hits harder but mustn't make the Wolf pointless, Q21 knockback
waits for Phase 4), Step 4 code (`MountSweeper`).

Gating mounts and tier upgrades behind bosses is Step 6; everything here is buyable when built.

## 5a. Elephant: the heavy, close-in hitter
The wedge only makes it hit enemies *sooner* (each enemy is still hit once per pass). To give it
a job the Wolf doesn't have, it's **short-range and hard-hitting**: it pounds the rim, where
enemies latch, and can't reach enemies still flying in. The Wolf keeps the band just outside the
rim and the Giraffe the far field.

| | Wolf | Elephant (draft) |
|---|---|---|
| Reach past its slot | 65 px (to 140) | **45 px (to 120)**: latched enemies and the last few px only |
| Shape | line | **45° wedge** centered on the carousel (`sweep_arc`) |
| Damage per hit | 1.5 | **3.0**: one pass kills a Grey Leaf (2 health), two a Grey Stick (4) |
| Price | 80 | **400** (draft) |

- A `MountSweeper` with data only: no new script. The reach drawing becomes a faint wedge
  (an annular sector) when `sweep_arc` > 0, a line otherwise.
- Kenney Animal Pack `elephant.png`; shop row on the Mounts tab (sell 50%, up to 5).
- Hit sound: `wolf_hit` for now (`hit_sfx`), a heavier one in Phase 6.

## 5b. Mount tiers (per type)
Each mount type has a tier (1 by default); buying "Wolf Tier 2" upgrades **every** Wolf, including
ones bought later (decided: per type). Tier 3 effects (damage trail, freeze, double fire,
knockback, Gold on every sweep) are Phase 4 with the named upgrades.

- `UpgradeData.EffectType.MOUNT_TIER` + the existing `target_mount`: each level raises that type's
  tier by one. One row per type ("Horse Tier 2"), `max_level` 1 for now, needs one of that mount
  owned (`prerequisite_id` = the mount's id), not sellable.
- `GameState.get_mount_tier(id) -> int`. Tier bonuses live in `MountData` as "Tier 2"
  multipliers (default 1.0), so each is tuned in the Inspector:
  `tier2_damage_multiplier`, `tier2_reach_multiplier`, `tier2_arc_multiplier`,
  `tier2_gold_multiplier`, `tier2_slow_seconds_multiplier`, `tier2_heal_multiplier`.
- GameState gains one getter per stat, which all mounts and Game read instead of raw data:
  `get_mount_damage` (already there; now × tier), `get_mount_reach`, `get_mount_arc`,
  `get_mount_gold`, `get_mount_slow_seconds`, `get_mount_heal`. Buying a tier re-shapes live
  mounts on the next tick (they read the getters each tick) with no free hit (their pass memory
  is kept).

Draft Tier 2 effects (GDD table), prices for Step 8 to revisit:

| Row | Effect (GDD) | Multiplier (draft) | Price (draft) |
|---|---|---|---|
| Horse Tier 2 | Gold per pass doubled | gold ×2 | 300 |
| Wolf Tier 2 | "speed and damage increase" | damage ×1.5 (no "speed" yet: the Wolf has none) | 400 |
| Sloth Tier 2 | slow duration doubled | slow seconds ×2 | 400 |
| Giraffe Tier 2 | range extended significantly | reach ×1.5 | 500 |
| Elephant Tier 2 | arc doubled | arc ×2 (45° → 90°) | 800 |
| Panda Tier 2 | all effects +50% | damage, gold, heal ×1.5 | 1,500 |

## 5c. Panda: the all-rounder
```
MountPanda extends MountSweeper    # scripts/mount_panda.gd
  # sweeps and damages like the Wolf (weaker), plus Gold once per full turn
```
- **Gold once per full turn** (Q7): counts full turns of its own travel with
  `RotationMath.count_crossings` (exact at any speed, like booth passes) and emits a new generic
  `MountBase.gold_earned(mount, amount)`; Game adds the Gold. `MountData.gold_per_turn`
  (draft 3 Gold per turn: a Horse pays 5 per booth pass).
- **Heal on its own kills** (Q8): `MountData.heal_per_kill`, draft **2 health** per kill (max
  health is 100; regen is 2/s while nothing is latched, so this matters mid-fight). Game's `_on_enemy_died(enemy, killer)` heals when the killer is a mount
  whose `get_mount_heal` is above 0, which uses Step 2's kill attribution. Data-driven, so no type
  branch in Game. New `GameState.heal_carousel(amount)` (capped at max; does nothing while stalled,
  so it never replaces the crank).
- **Damage 0.5, reach 60** (GDD data): weaker than the Wolf, as the GDD says.
- **Unlock** (Q10): `UpgradeData.required_tier2_types: int` (Panda: 3). GameState counts mount
  types at Tier 2 or higher, *excluding the Panda itself*; the shop row shows as locked with the
  count ("2/3 mount types at Tier 2") until met. Duplicates can't unlock it (tiers are per type).
- Kenney Animal Pack `panda.png`; price draft 1,500; sparkle trail is Phase 6.

## Text (Claude drafts, Garret approves)
`UPG_ELEPHANT_NAME/DESC`, `UPG_PANDA_NAME/DESC`, `UPG_<TYPE>_TIER2_NAME/DESC` for the six tier
rows, and the Panda lock reason with a `{0}/{1}` count. All 9 languages as machine drafts, then
`python tools/subset_fonts.py`.

## Commits
1. Elephant: data, wedge drawing, scene, art, shop row, strings (5a).
2. Mount tiers: `MOUNT_TIER`, GameState tiers + stat getters, MountData Tier 2 fields, mounts and
   Game read the getters, five tier rows (Horse, Wolf, Sloth, Giraffe, Elephant) (5b).
3. Panda: `MountPanda`, `gold_earned`, heal on own kills, `required_tier2_types`, shop rows
   (Panda + Panda Tier 2) (5c).

## Tests
- Elephant: hits a latched enemy for 3.0, can't reach one 140 px out; a wedge window is wider than
  the line window by exactly the half-arc.
- Tiers: buying Wolf Tier 2 raises damage for existing *and* later Wolves; the multiplier applies
  once; Giraffe Tier 2 lengthens reach with no free hit; Horse Tier 2 doubles booth Gold; tiers
  reset with the run.
- Panda: Gold exactly once per full turn at any speed (one huge tick = several payments); heals
  only on its own kill (a Wolf kill heals nothing); no heal while stalled or above max; unlock
  needs 3 *different* types at Tier 2 (3 Wolves' worth doesn't count, the Panda doesn't count
  itself).
- Game still has no mount-type branches.

## Open for Garret
- **Elephant as the short-range heavy** (table above): OK, or would you rather it reach like the
  Wolf and hit less hard?
- The draft numbers (damage 3.0, Tier 2 multipliers, prices) are starting points to feel out.
