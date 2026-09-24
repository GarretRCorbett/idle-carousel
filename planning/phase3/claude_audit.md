# Phase 3 prep: code and art audit (Claude, 2026-09-24)

What the Phase 2 code already gives Phase 3, what's hard-wired to Horse/Wolf/Leaf,
and what art exists. Input for the Phase 3 plan, not decisions.

## Already generic (reuse as-is)
- **Sweep math:** `RotationMath.sweep_passes()` plus the Wolf's per-enemy pass memory
  (`_last_hit_pass`). Any sweeping mount can reuse it; the Lion's arc is a wider
  window (`half_width` + half the arc). Seeding on placement (`set_enemy_layer`) already
  stops "free hits" when mounts re-space.
- **Even spacing** for any mount count (`Game._layout_mounts`), and the roster in
  GameState (`get_mount_roster`). Slots 4–6 are just more `max_level` on `mount_slot.tres`
  plus a boss gate.
- **Data fields that exist but nothing uses yet:** `MountData.sweep_arc` (Lion),
  `MountData.is_stationary` (Horse/Turtle), `MountData.base_gold_bonus` on the Unicorn.
- **Enemies:** `EnemyBase` (approach, latch, die once), separate `hitbox_radius` and
  `click_radius`, `gold_multiplier` per enemy (Send wave bonus). `stick.tres` and
  `rock.tres` exist.
- **Shop:** leveled `UpgradeData` with `prerequisite_id`, tabs, `BUY_MOUNT` with
  `mount_scene`, sell refunds.

## Hard-wired: needs generalizing early in Phase 3
| Where | What | Why it matters |
|---|---|---|
| `game.gd` `_create_mount()` | `if mount is MountHorse` / `if mount is MountWolf` to connect signals | Each new mount would add another branch. Better: every mount emits the same few signals (e.g. `enemy_hit(enemy, damage)`, `gold_earned(amount)`, `effect_applied(enemy, effect)`) that Game connects once. |
| `game.gd` `_on_enemy_swept()` | Damage = `wolf.data.base_damage + GameState.get_wolf_damage_bonus()` | Per-mount damage bonuses (Eagle Eye, Lion Roar…) need a per-mount lookup, not a Wolf-only getter. |
| `game.gd` `_horses` / `_wolves` lists | Type-specific bookkeeping (booth passes, `forget_enemy`) | `forget_enemy` should go to every sweeping mount. |
| `UpgradeData.EffectType` | `ADD_WOLF_DAMAGE` is Wolf-specific | Mount tiers and per-mount upgrades want something like `ADD_MOUNT_STAT` + `target_mount` + `stat` rather than one enum per mount. |
| `WaveManager.enemy_scene` | One enemy scene for every wave | Tiers need a wave composition (which enemies, how many, which tier). Data, probably a `WaveTable`/`TierData` `.tres`. |
| `GameState` | No tier, kill count, or boss state at all | Tier, kills this tier, bosses beaten, and slot unlocks need a home, save-friendly for Phase 4. |
| `GameState.register_latch(enemy_id, …)` | One latch per enemy instance id | The Boulder boss has "3 latch points". Either one latch with 3× drag, or keys like `(id, point)`. |
| `EnemyData` | No status effects, no tier scaling | Turtle slow, freeze, Ancient Log's slow immunity and "resists first 3 hits". |

## Data that's stale
- **Stick and Rock stats are Phase 1 placeholders** that were never tuned against the
  current Leaf. Leaf: 0.5 dmg/s, 0.05 drag. Stick: 2.0 dmg/s (4×), 0.12 drag. Rock:
  **4.0 dmg/s (8×), 0.3 drag (6×)**. With the soft drag curve one Rock is about −23%
  speed. Retune before they spawn.
- **`MountData.unlock_cost_gold`** is legacy. Prices moved to `UpgradeData` in Step 10
  (Wolf, Horse). Remove it or mark it unused so nobody tunes the wrong field.
- Eagle/Turtle/Lion/Unicorn `.tres` numbers are first guesses from Phase 1.

## Bug class to design against
Phase 2's last Codex review found a removed enemy could still latch on the same tick.
Phase 3 adds more ways to remove or create enemies mid-tick: split on death, spawners,
knockback, "must kill twice." Rule to carry forward: **anything removed is skipped
the same tick, and anything spawned mid-tick doesn't act until the next tick.**
Add a test for each new remove/spawn path.

## Art inventory (Kenney packs already downloaded in `../kenney_assets/`)
| Need | Available | Notes |
|---|---|---|
| Turtle, Eagle, Lion, Unicorn | **Not in Animal Pack Remastered** (it has bear, owl, parrot, zebra, goat, frog, crocodile, horse…) | Stand-ins like the Wolf's `dog.png`: owl or parrot for the Eagle, bear for the Lion, horse re-tinted for the Unicorn; nothing turtle-like except frog/crocodile. Or placeholder polygons until Phase 6. Garret's call. |
| Leaf | Foliage Pack: 44 `foliagePack_leaves_*.png` | Leaves use a code polygon today. |
| Stick | Foliage Pack bare branches; Tanks `treeBrown_twigs.png` | Branches are side view; twigs are top-down. |
| Rock | Foliage Pack grey rocks | Grey, so Modulate tinting works well. |
| Tier colors | — | **Modulate multiplies**, so it only reads well on light/grey sprites. Colored sprites (orange leaf, brown horse) go muddy. Options: greyscale copies of the sprites, a small tint shader, or tinting only a part (saddle, eye glow) as the GDD describes for mounts. |

Sprite orientation (heads outward, bottom mount upside down) is still parked for Phase 6.
