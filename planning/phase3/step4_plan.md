# Phase 3 · Step 4 Plan: Giraffe and Sloth
**Status:** APPROVED and built 2026-09-25 (commits 4.1–4.4 + stress tool).
**Inputs:** GDD (Giraffe, Sloth), README decisions (Q6: the Sloth slows each approaching enemy it
sweeps past, once per pass), `step1_plan.md` (mount interface, `MountSweep`), Step 2 code.

Goal: two new mounts you can buy in the Mounts tab. The **Giraffe** is a Wolf with a much longer
line, so it hits enemies while they're still flying in. The **Sloth** sweeps like the Wolf but
deals no damage: every approaching enemy it passes is slowed to 50% for 3 s, with a "Zzz" over
its head. Both follow Step 2's rule: no `if mount is X` in `game.gd`.

## 4a. One sweeping-mount script (rename, no behavior change)
The Wolf's script has nothing Wolf-specific left after Step 2. It becomes the shared script for
every line/wedge mount:

- `mount_wolf.gd` → `mount_sweeper.gd`, `class_name MountWolf` → `MountSweeper`. Wolf.tscn and
  Giraffe.tscn both use it; the Sloth and later the Elephant/Panda extend it.
- The sweep's `half_arc` comes from `MountData.sweep_arc / 2` (0 for a line), ready for Step 5's
  Elephant wedge.
- `MountData.hit_sfx: StringName = &"wolf_hit"`: the sound Game plays on a damaging hit, so
  `_on_enemy_swept` stops hard-coding `&"wolf_hit"`. Giraffe uses the same sound until Phase 6 audio.

## 4b. Giraffe
- `giraffe.tres` (exists): `sweep_range` 250, `base_damage` 0.75, add `mount_id`, texture.
  Its line reaches 75 + 250 = 325 px from the center; waves appear at 380–440 px, so it meets
  them early in their approach.
- `Giraffe.tscn`: same tree as Wolf.tscn (below). Art: Kenney Animal Pack `giraffe.png`.
- Shop row `resources/upgrades/giraffe.tres`: BUY_MOUNT, Mounts tab, sells back for 50%,
  up to 5, **draft price 150** (×1.5 each). Step 8's pricing pass revisits it.

## 4c. Enemy status effects (slow now, freeze later)
```
EnemyStatus extends RefCounted     # scripts/enemy_status.gd, one per enemy
  func apply_slow(multiplier: float, seconds: float) -> void
      # refreshes: the longer time left wins, the stronger slow wins; never stacks
  func advance(delta: float) -> void          # counts down; called from EnemyBase.advance
  func get_speed_factor() -> float            # 1.0, or the slow multiplier while active
  func is_slowed() -> bool
```
- `EnemyBase` owns one and moves at `get_move_speed() × status.get_speed_factor()`.
  `get_move_speed()` stays the tier speed (fixed at spawn). The timer runs on game ticks, so it
  pauses with the game and is exact in tests.
- Freeze (Deep Sleep, Phase 4) will be a slow with multiplier 0; immunity (Ancient Log, Step 7)
  a flag on `EnemyData`. Neither is built now.
- **"Zzz" icon:** a `SlowIcon` node drawn in code (three small Z strokes, no art needed), shown
  only while slowed, placed above the health bar and outside the tinted branch, so it stays white.

## 4d. Sloth
```
MountSloth extends MountSweeper    # scripts/mount_sloth.gd
  func apply_sweep(enemy: EnemyBase) -> void
      # only approaching enemies: enemy.apply_slow(data.slow_multiplier, data.slow_seconds)
```
- `MountData` gets a "Status" group: `slow_multiplier` (0.5) and `slow_seconds` (3.0). Drowsy
  (Phase 4) will add seconds through GameState, like Wolf Fang adds damage.
- `sloth.tres` (exists): `sweep_range` 120, `base_damage` 0 (so Game plays no hit sound and deals
  nothing; it only calls `apply_sweep`), add `mount_id`, texture, slow numbers.
- Once per pass comes free from `MountSweep`'s pass memory. Passing it again after it wears off
  slows it again.
- `Sloth.tscn`: same tree. Art: Kenney Animal Pack `sloth.png`. Shop row `sloth.tres`,
  **draft price 150**, same rules as the Giraffe.

## Scene trees
```
Giraffe (Node2D)   mount_sweeper.gd, data = giraffe.tres     (same as Wolf.tscn)
Sloth (Node2D)     mount_sloth.gd,   data = sloth.tres

Leaf / Stick / Rock (Node2D)
├── Visual (Node2D)
│   └── Sprite (Sprite2D)
├── HealthBar (Node2D)
└── SlowIcon (Node2D)   enemy_slow_icon.gd   NEW, hidden unless slowed
```

## Text (Claude drafts, Garret approves)
New keys in `localization/strings.csv`, all 9 languages as machine-translation drafts:
- `UPG_GIRAFFE_NAME` "Giraffe", `UPG_GIRAFFE_DESC` "Long neck: hits enemies before they reach you"
- `UPG_SLOTH_NAME` "Sloth", `UPG_SLOTH_DESC` "Slows enemies it passes (no damage)"
Then re-run `python tools/subset_fonts.py` for the CJK glyphs.

## Commits
1. `MountSweeper` rename, `sweep_arc` → `half_arc`, `hit_sfx` (4a). No change in play.
2. Giraffe: data, scene, art + provenance, shop row, strings (4b).
3. `EnemyStatus` slow + "Zzz" icon (4c).
4. Sloth: `MountSloth`, data, scene, art + provenance, shop row, strings (4d).
5. One stress-test run (silent) with Wolf + Giraffe, to see the shared snapshot pay off with
   two sweeping mounts. Numbers go in the README.

## Tests
- Giraffe hits an **approaching** enemy far outside the Wolf's reach, through the real Game tick
  (memo O10's long-reach test); its damage comes from `get_mount_damage`.
- Sloth: slows an approaching enemy to 50% of its tier speed, once per pass; doesn't slow a
  latched one; deals no damage; the slow refreshes rather than stacks and wears off after 3 s of
  ticks; the icon shows only while slowed.
- Every shop mount's `mount_id` matches its upgrade (existing test covers the new rows).
- Game still has no mount-type branches (existing test).

## Open numbers (defaults above unless Garret says otherwise)
- **Prices:** Giraffe 150, Sloth 150 (Wolf is 80). The GDD's early game has "Slot 3: Sloth or
  Giraffe" as the first real choice, so they cost more than the Wolf but not much more.
- **Giraffe damage 0.75** (GDD data): a Grey Leaf (2 health) needs three Giraffe passes, and at
  70°/s it may get only one pass before the Leaf latches. It softens enemies for the Wolf rather
  than killing them. Try it; raise to 1.0 if it feels useless.
- **Sloth reach 120 px** past its slot (to 195 px from the center): it slows enemies in their
  last ~2 seconds. Longer reach = slowed earlier.
