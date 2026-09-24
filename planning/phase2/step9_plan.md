# Phase 2 · Step 9 Plan: Wolf + health/stall tuning
**Status:** BUILT 2026-09-24.
**Inputs:** PHASE_2_GOALS.md Step 9, `codex_memo_a_sweep_booth.md` §6 (pass ledger), `codex_memo_h_health_offline.md`, README "Decided 2026-09-24, after the Steps 6-8 playtest".

## Decisions (Garret)
| Topic | Decision |
|---|---|
| Wolf damage | **3 per swipe**. One swipe kills a Grey Leaf (2 health) and most tougher Leaves until Wolf damage upgrades exist. |
| Wolf reach | Out to **40 px past the rim** (tunable anywhere in 15–60). `sweep_range` 65 from the Wolf's slot (75 px from center). |
| Getting a Wolf | Placed by hand in **slot 2** for now. Step 10 adds a **Mounts tab** in the shop: buy a Horse or a Wolf, and mount slots. |
| Hit detection | **Angle math, not physics rays.** Same crossing math as booth passes: each tick, which enemies' angle ranges did the Wolf's line sweep across, and are they within reach. Exact at any speed. CLAUDE.md rule updated. |
| Piercing | Every enemy the line crosses is hit, each **once per pass** (memo A's enemy-relative pass ledger). |
| Stopped Wolf | No damage. Placing a Wolf on an enemy gives no free hit. |
| Fail rule | HEALTH_STALL only. **OVERLOAD_CLEAR is removed** (Garret chose health; it's in git history if needed). |
| Drag | Softer curve: speed × 1 / (1 + drag). Never reaches 0 from drag alone, so Boost always helps. |
| Regen | 2 health/s once no enemy has been latched for 2 s. |
| Leaf damage | 0.5 health/s (was 1). |
| Latch grace | A new latch deals no damage for its first 2 s; its drag applies right away. |
| Crank it back | While stalled, Boost fills a restart meter instead: 10 presses, or hold Boost 4 s. Restart at **15%** health with the Leaves still attached, plus 3 s of no latch damage so the first sweep can happen. Clearing every latch still restarts at 25%. The Boost bar shows the meter during a stall. |
| Safety net | Stalled for **60 s** → every enemy is removed (no Gold), restart at 25%. Waves keep coming. |

## Wolf
```
Slot2 (Marker2D, existing)
└── Wolf (Node2D)   mount_wolf.gd (MountWolf extends MountBase), data = wolf.tres
```
- Draws its placeholder shape plus a faint line showing its reach, so you can see what it covers.
- Each tick after the carousel turns: for each live enemy, its bearing from the center and its angular half-width (from its hitbox radius) give a window. `RotationMath.sweep_passes()` returns which passes of that window the Wolf's line crossed this tick. If the enemy is within the line's radial reach and the pass is new, the Wolf emits `enemy_swept(wolf, enemy)`. Game applies `wolf.data.base_damage`.
- Game order is unchanged: GameState → enemies move → carousel turns (Horse pays, Wolf sweeps).

## GameState changes
- `register_latch` records each latch's age, so damage starts after the grace period.
- `advance_simulation`: latch damage (after grace, and not during crank protection), regen when clear, crank hold, 60 s stall timeout.
- `add_click_boost()` cranks instead while stalled. New `set_boost_held(held)` for hold-to-crank.
- New signals: `crank_changed(fraction)`, `stall_timed_out` (replaces `overloaded`).
- RunConfig: `regen_per_second`, `regen_delay_seconds`, `latch_grace_seconds`, `crank_presses`, `crank_hold_seconds`, `crank_restart_fraction`, `crank_protection_seconds`, `stall_timeout_seconds`. The fail_rule and overload fields go away.

## Tests
- Sweep math: one pass per turn, several per long tick, window edges, the 0° wrap, no passes when stopped.
- Wolf: hits a latched Leaf once per turn; pierces two Leaves on one line; ignores Leaves out of reach; a stopped Wolf deals nothing.
- Drag curve, regen timing, grace, crank by presses and by holding, crank protection, 60 s timeout.
- Game scene: the Wolf in slot 2 kills a latched Leaf within one turn.

## Your steps
- Open Wolf.tscn and Game.tscn and save each once.
- Playtest: does the Wolf keep up with Leaves on its own? Is boosting while it fights fun? Do stalls now build up readably, and does cranking feel good?
- Tune: `wolf.tres` (damage, sweep_range), the new RunConfig fields.
- Placeholder text to replace: the Boost button's crank label.
