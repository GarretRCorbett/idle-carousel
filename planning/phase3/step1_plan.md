# Phase 3 · Step 1 Plan: decisions, contracts, and scene trees for Steps 2–3
**Status:** APPROVED 2026-09-24 (Garret), including Codex memo O's 10 changes and the draft upgrade names.
**Inputs:** `README.md` (decisions, draft steps), `claude_audit.md`, `claude_memo_performance.md`,
`codex_memo_l_mounts_enemies_bosses.md` §2, §4, §7, §8, `codex_memo_m_tiers_pacing.md` §1–3,
`codex_memo_o_step1_review.md` (review of this plan; all 10 changes folded in, marked **[O#]**).

Step 1 is mostly this document: the data and code "contracts" (names, fields, signals, who
owns what) that Steps 2 and 3 build. Mount-specific fields (Sloth slow, Panda heal, Elephant arc,
mount tiers) wait for Steps 4–5, after Garret answers README questions 6–11. Boss contracts
wait for Step 6.

## Decisions (Garret, 2026-09-24)
| Topic | Decision |
|---|---|
| Tier colors on art | **Light greyscale sprites + tint.** Kenney leaf/stick/rock sprites converted to light grey (logged in PROVENANCE), a `Sprite2D` tinted per tier, on a different node from the hit flash. |
| Stick / Rock latch damage | **0.9 and 1.5** per second (from 2.0 and 4.0), before tiers multiply them. |
| Wave make-up | **Random with caps.** Each tier has odds per enemy type plus a maximum per wave for each type (e.g. at most 1 Rock in Green). Sticks unlock after ~40 Grey kills, Rocks after ~40 Green kills. |
| Wave interval | **Per tier, in data.** Grey starts at today's 10 s; later tiers a little longer. Tuned in playtest. |
| Tier shades | **Claude drafts** six colors in the tier files and renders a frame; Garret tweaks them in the Inspector. |
| Switching tiers before Step 6 | **Dev keys in debug builds only** (e.g. F2 / F3 = previous / next tier). Removed or replaced when Step 6 adds the kill gate and picker. |
| Step 1 scope | **Steps 2–3 only.** Mount abilities and bosses get contracts at their own steps. |
| Mount animals | **Turtle → Sloth, Eagle → Giraffe, Lion → Elephant, Unicorn → Panda**, all Kenney Animal Pack art. Abilities unchanged. GDD v1.12. Upgrade names are Claude drafts pending approval: Drowsy 1/2/3, Deep Sleep (Sloth); Long Neck 1/2/3, Double Take (Giraffe); Trumpet 1/2/3, Trunk Toss (Elephant); Bamboo Feast, Lucky Bamboo (Panda). Slow icon: a sleepy "Zzz". |
| Send wave limit | **Keep 30** live enemies; revisit at the first Grey + Green playtest (end of Step 6). |
| Performance target | **Decide after content** (after Step 7). Until then, run `tools/stress_test.tscn` at the end of each step and record the numbers, same GPU (Radeon 780M), so regressions show. |

Already decided earlier and used below: tier scaling from memo M (health ×1.40 per tier,
Gold ×1.45, latch damage ×1.10, speed ×1.03, drag unchanged); free choice of any unlocked tier;
kills of any enemy in a tier count for that tier; wave randomness seeded per run.

## What Step 1 changes in the project (small, after approval)
- Rename the four unused mount data files: `turtle.tres → sloth.tres`, `eagle → giraffe`,
  `lion → elephant`, `unicorn → panda`, and their `mount_name`. Nothing loads them yet, so
  nothing else changes. (Other `MountData` changes wait for Step 2.)
- Docs already updated this session: GDD v1.12, roadmap, notes, Phase 3 README.
- Run the check; one commit.

---

## Step 2 contracts: foundations
Goal: adding a mount or an enemy type never needs another `if mount is MountX` branch, and
no enemy can act after it's removed. **All current Wolf and Horse tests keep passing**; it's
a refactor plus a few new guarantees.

### 2a. One mount interface
Today `game.gd` keeps `_horses` and `_wolves` lists and connects signals per type. Instead,
`MountBase` declares everything Game needs, with do-nothing defaults:

```
MountBase (Node2D)
  signal booth_passed(mount: MountBase, booth_index: int, pass_count: int)   # moved from MountHorse
  signal enemy_swept(mount: MountBase, enemy: EnemyBase)                      # moved from MountWolf
  func set_booth_bearings(bearings: Array[float]) -> void    # default: nothing (Horse overrides)
  func set_enemy_snapshot(snapshot: EnemySnapshot) -> void   # default: nothing (sweeping mounts use it)
  func rebase() -> void          # after placement: whatever is under the mount now gives no free hit
  func forget_enemy(id: int) -> void
  func apply_sweep(enemy: EnemyBase) -> void   # [O9] what one sweep contact does; default: nothing
```
**[O9]** Game's `_on_enemy_swept(mount, enemy)` applies the mount's damage (2b), then calls
`mount.apply_sweep(enemy)`. The Sloth's slow (Step 4) overrides that hook, so no type branches
come back into `game.gd`. `MountSweep` only finds contacts; it never decides effects.
Game connects both signals for every mount once in `_create_mount`, and calls the setters on
every mount in `_layout_mounts` / `_layout_booths`. `_horses` and `_wolves` go away.

### 2b. Per-mount damage
- `MountData` gets `mount_id: StringName` (`&"wolf"`, `&"horse"`, …), matching the shop's
  upgrade id. `unlock_cost_gold` is **removed** (the shop's `UpgradeData` owns prices).
- `UpgradeData.EffectType.ADD_WOLF_DAMAGE` becomes `ADD_MOUNT_DAMAGE` plus a new field
  `target_mount: StringName`. Wolf Fang sets `target_mount = &"wolf"`.
- `GameState.get_mount_damage(data: MountData) -> float` = `data.base_damage` + the bonus
  bought for `data.mount_id`. It replaces `get_wolf_damage_bonus()`.
- Game's `_on_enemy_swept(mount, enemy)` applies `get_mount_damage(mount.data)` when it's above 0,
  as `enemy.take_damage(amount, mount)` (kill attribution, 2f).

### 2c. `MountSweep` (extracted from the Wolf)
The hit math that lives in `MountWolf` today moves into a helper that any sweeping mount
owns (composition, not a superclass, so the Sloth can use it without dealing damage):

```
MountSweep extends RefCounted     # scripts/mount_sweep.gd
  var inner_radius: float          # the mount's distance from the center
  var reach: float                 # MountData.sweep_range
  var half_arc: float              # 0 = a line (Wolf); Elephant later
  func collect(snapshot: EnemySnapshot, start_angle: float, delta_angle: float) -> Array[EnemyBase]
      # one entry per new pass (an enemy can appear twice in a very long tick, as today)
  func rebase(snapshot: EnemySnapshot, angle: float) -> void
  func forget(id: int) -> void
```
- Same per-enemy pass memory as today (`_last_hit_pass`), same `RotationMath.sweep_passes`.
- **Line-tip fix** [O7], memo L §4's formula: reject by distance first (`d + r < inner` or
  `d − r > outer`); then for `d > r`, the touch point along the line is
  `q = clamp(sqrt(d² − r²), inner, outer)` and the half-window is the cosine-law angle at `q`
  (equal to `asin(r / d)` when `q` isn't clamped). An enemy covering the center (`d ≤ r`) is
  skipped, as today. Tests: both ends, exact tangency, and the change-over to the plain `asin` window.
- `MountWolf` becomes: own a `MountSweep`, forward rotation to it, emit `enemy_swept` per entry.
- **[O2] Recheck before every entry.** A long tick can list the same enemy twice. Before emitting
  each entry, check `is_instance_valid(enemy) and enemy.is_active()`, as the Wolf does today, so
  the hit after a kill does nothing (no second sound, Gold, or kill credit).

### 2d. Shared enemy snapshot (performance + correctness)
Each tick, after enemies move and **before** the carousel turns, Game rebuilds one list;
every sweeping mount reads it instead of scanning the enemy layer itself.

```
EnemySnapshot extends RefCounted   # scripts/enemy_snapshot.gd
  var enemies: Array[EnemyBase]
  var bearings: PackedFloat64Array   # unwrapped bearing from the carousel center (see 2g)
  var distances: PackedFloat64Array
  var radii: PackedFloat64Array      # hitbox radius
  func rebuild(layer: Node, center: Vector2) -> void   # active enemies only; updates bearings (2g)
```
`MountSweep` skips entries whose distance is outside `[inner − r, inner + reach + r]` before
any angle math. It also rechecks `enemy.is_active()` before using an entry, because an earlier
mount in the same tick may have killed it.

### 2e. Enemy removal is a state
`EnemyBase.State` gains `REMOVED`. **[O4]** `Game._remove_enemy()` calls `enemy.mark_removed()`
as its **first** line, before unregistering the latch (which sends signals) and before
`queue_free()`, and does nothing if the enemy was already removed. A kill still sets DEAD before
`died` is emitted. Code that keeps enemy references checks `is_instance_valid()` first, since a
freed enemy can't be asked anything. New `is_active() -> bool` (APPROACHING or AT_RIM) replaces the mix of
`can_receive_click()` and `is_queued_for_deletion()` checks. A removed or dead enemy can't
move, latch, be hit, be clicked, or die again. One test per removal path: kill, Emergency
Clear, stall safety net, a listener touching the enemy during cleanup, and (Step 3) switching
tier doesn't touch live enemies.

### 2f. Kill attribution and queued spawns
- `take_damage(amount: float, source: Node = null) -> bool` and
  `signal died(enemy: EnemyBase, killer: Node)` (null = a click or no source). Nothing uses
  the killer yet; the Panda's heal-on-its-own-kill (Step 5) needs it.
- **Spawns join at the next tick.** `Game._on_enemy_spawned` puts the enemy in a
  `_pending_spawns` list; `_physics_process` adds them first thing. So an enemy spawned
  in the middle of a tick (later: splits, summons) never moves, latches, or gets hit
  that tick. A wave shows up at most one tick (1/60 s) later, too short to notice.
- **[O3] Queue rules.** At the start of a tick Game swaps the list for an empty one and admits
  that batch; anything spawned while admitting goes into the next batch. The enemy's tier and
  reward are set when it's requested (Step 3's `configure`), not when admitted. Game frees any
  enemies still waiting when the run resets or the scene exits. **Tick order:** admit batch →
  GameState → enemies move → snapshot → carousel turns (mounts sweep).
- **[O1] Send limit counts the queue.** `can_send_wave()` counts active enemies on screen plus
  enemies waiting in the queue, so pressing Send several times within one tick can't get past
  the limit. Game gives WaveManager a count function instead of the enemy layer. The rule is
  unchanged: Send works at exactly 30, not at 31; auto waves are never blocked. Tests: repeated
  sends with no tick in between, the 30/31 boundary, removed-but-not-yet-freed enemies don't count.

### 2g. Unwrapped bearings
Bearings jump from +180° to −180° at the left side of the screen. A straight-flying enemy
never crosses that line, but a zigzagging one (Stick Giant, Step 7) could, and the Wolf would then
see a "new pass" and hit it twice. Each enemy keeps a running unwrapped bearing. **[O6]** It
starts from the enemy's real spawn position (set in `setup()`), and `EnemySnapshot.rebuild()`
updates it by the wrapped change, which is after *all* movement, including subclass moves like the
Leaf's. `rebase()` after placing mounts uses the enemies' current positions (not a stale
snapshot) and keeps existing pass memory. Tests: crossing the seam in both directions gives no
second hit in the same pass; zigzag and in-and-out-of-reach movement isn't hit again until the
mount comes round; buying or selling a mount between ticks gives no free hit.

### 2h. Performance check
Run `tools/stress_test.tscn` before 2a and after 2d, same GPU. Record both tables in the
README. Expected: mount cost per enemy drops (one snapshot, distance pre-check), with no other change.

### Step 2 commits (one feature each)
1. Mount interface (2a) and per-mount damage (2b), Wolf/Horse unchanged in play.
2. `MountSweep` + line-tip fix (2c).
3. Enemy snapshot (2d) + stress-test numbers.
4. Removal state, kill attribution, queued spawns (2e, 2f).
5. Unwrapped bearings (2g).

---

## Step 3 contracts: tiers, Stick and Rock, waves

### 3a. `TierData` (one per color) and `TierCatalog`
```
TierData extends Resource          # scripts/tier_data.gd; resources/tiers/grey.tres … red.tres
  @export var tier_id: StringName        # &"grey", &"green", …
  @export var rank: int                  # 0 = Grey … 5 = Red
  @export var name_key: String           # "TIER_GREY" (localization key, for Step 6 UI)
  @export var tint: Color
  @export_group("Enemy multipliers")     # stored per tier, so one tier can be tuned alone
  @export var health_multiplier: float
  @export var speed_multiplier: float
  @export var drag_multiplier: float
  @export var latch_dps_multiplier: float
  @export var gold_multiplier: float
  @export var waves: WaveProfile

TierCatalog extends Resource       # resources/tiers/tier_catalog.tres
  @export var tiers: Array[TierData]     # in rank order; a test checks ranks 0..5 match
```
Starting numbers (memo M, rounded; `t` = rank):

| Tier | Health | Gold | Latch dmg | Speed | Drag | Draft tint |
|---|---|---|---|---|---|---|
| Grey | 1.00 | 1.00 | 1.00 | 1.00 | 1 | light grey |
| Green | 1.40 | 1.45 | 1.10 | 1.03 | 1 | green (check it against the green park) |
| Blue | 1.96 | 2.10 | 1.21 | 1.06 | 1 | blue |
| Purple | 2.74 | 3.05 | 1.33 | 1.09 | 1 | purple |
| Gold | 3.84 | 4.42 | 1.46 | 1.13 | 1 | gold |
| Red | 5.38 | 6.41 | 1.61 | 1.16 | 1 | red |

### 3b. Waves: `WaveProfile` + `WaveEntry` (random with caps)
```
WaveProfile extends Resource       # a sub-resource inside each tier .tres
  @export var interval_seconds: float
  @export var min_enemies: int
  @export var max_enemies: int
  @export var directions: int = 1        # clusters per wave, each from its own direction
  @export var entries: Array[WaveEntry]

WaveEntry extends Resource
  @export var enemy_scene: PackedScene   # Leaf.tscn, Stick.tscn, Rock.tscn
  @export var weight: float              # relative odds
  @export var max_per_wave: int          # 0 = no limit
  @export var unlock_after_kills: int    # kills in THIS tier before it can appear (0 = always)
```
How a wave is rolled (pure static function, tested with a seeded RNG like `plan_wave` today):
roll a count between min and max; for each enemy, pick by weight among entries that are
unlocked, have weight above 0, and are under their cap (odds re-worked from the remaining entries
each pick). Caps count across the whole wave; enemies are split among `directions` clusters
afterward. **[O8]** Each profile must have an entry that is always unlocked, has weight > 0, and
has no cap (the Leaf), so a wave can always be filled. A data test checks every tier, and also
rejects negative or non-finite weights, `min > max`, and intervals ≤ 0. The weights aren't final
percentages once caps kick in: in Green, a Rock shows up in only about 1 wave in 5 after kill 40,
so the first Rock can take several waves. That's expected.

Starting numbers (to tune in playtest):

| Tier | Interval | Enemies | Directions | Leaf / Stick / Rock weight | Caps (Stick, Rock) | Unlocks |
|---|---|---|---|---|---|---|
| Grey | 10 s | 3–5 | 1 | 94 / 6 / 0 | 1, – | Stick after 40 kills |
| Green | 10 s | 3–6 | 1 | 76 / 19 / 5 | 2, 1 | Rock after 40 kills |
| Blue | 11 s | 4–7 | 2 | 62 / 30 / 8 | 2, 1 | – |
| Purple | 12 s | 5–8 | 2 | 62 / 25 / 13 | 2, 1 | – |
| Gold | 13 s | 6–9 | 2 | 66 / 22 / 12 | 3, 1 | – |
| Red | 14 s | 6–10 | 3 | 60 / 30 / 10 | 3, 2 | – |

`WaveManager` changes: `enemy_scene` and the group-size exports go away; it reads the selected
tier's `WaveProfile` (interval, count, mix). The early-send Gold bonus, auto toggle, and Send
limit (30) stay as they are. A new interval applies from the next countdown.

### 3c. Effective stats, fixed at spawn
Enemies stop reading tier-scaled numbers from `enemy.data` after they spawn:

```
EnemyBase
  func configure(tier: TierData, reward_multiplier: float) -> void   # before add_child
  func get_max_health() / get_move_speed() / get_latch_drag() / get_latch_dps()
       / get_kill_gold() / get_hitbox_radius() / get_click_radius() -> float
  func get_tier_rank() -> int
```
`configure` computes every stat once (base × tier multiplier; Gold also × the early-send
bonus). **[O5]** Today's `gold_multiplier` variable and the multiplication in
`Game._on_enemy_died` are removed; Game pays exactly `get_kill_gold()`. `_ready()` sets Grey
stats only if `configure` was never called, then sets health from `get_max_health()`. Readers
that switch explicitly: starting health, health-bar fraction and offset, `setup()`'s rim stop
distance, movement, latch drag/damage, kill Gold, sweep windows, clicks. An enemy that's never
configured uses Grey values, so existing tests keep working. Test: a Green early-sent enemy
through admission, damage, latching, and death pays base × 1.45 × 1.5. Everything that reads `enemy.data.*` for these today
switches to the accessors: latching, kill Gold, movement, health bar, sweep windows, clicks.
Switching tier changes **future** spawns only; enemies already alive keep their stats.

### 3d. Tier and kill state in GameState (minimal, save-ready)
```
GameState
  signal selected_tier_changed(rank: int)
  func get_selected_tier() -> int / set_selected_tier(rank: int) -> void
  func record_kill(tier_rank: int) -> void          # called from Game._on_enemy_died
  func get_tier_kills(tier_rank: int) -> int
  var run_seed: int                                 # set in reset_run; WaveManager seeds from it
```
Plain ints and arrays, reset in `reset_run`. Kills count for the enemy's own tier
(`get_tier_rank()`), not the tier selected when it dies. Removals without a kill (Emergency Clear,
safety net) don't count. Step 6 adds the highest unlocked tier, the gate, and bosses on top of this.

Dev keys (debug builds only, `OS.is_debug_build()`): **F2 / F3** select the previous / next tier.
No UI; the enemy colors show which tier you're on.

### 3e. Enemy scenes and art
Same tree for all three enemies; the tint and the flash sit on different nodes so neither
erases the other:

```
Leaf / Stick / Rock (Node2D)   enemy_leaf.gd (Leaf) or enemy_base.gd (Stick, Rock); data = leaf/stick/rock.tres
├── Visual (Node2D)            hit flash (modulate) and tumble rotation, as today
│   └── Sprite (Sprite2D)      texture from data; tier tint = self_modulate; squash = scale
└── HealthBar (Node2D)         enemy_health_bar.gd, unchanged (outside the tinted branch)
```
- Stick and Rock need no scripts of their own (no special behavior); the Leaf keeps its tumble.
- Squash moves from the drawn polygon to the Sprite's scale. The Sprite gets
  `physics_interpolation_mode = OFF` so the per-frame squash doesn't fight smoothing (its parent
  still moves smoothly).
- The code-drawn polygon stays as the fallback when `data.texture` is empty, and fixes today's
  gap where setting a texture made the enemy vanish.
- `placeholder_size` is the enemy's **visual** radius (the sprite is scaled to it); hitbox and
  click radius stay separate, as today.
- **Art:** Claude makes a contact sheet of candidates (Foliage Pack leaves, Tanks
  `treeBrown_twigs.png` for the Stick, a grey rock) and Garret picks. A small Godot tool,
  `tools/make_tier_sprites.gd`, converts the picks to light greyscale so they can be rebuilt
  later (Python has no image library installed). Each file is logged in `assets/PROVENANCE.md` as modified.
- Tier colors: Claude sets draft tints, renders one frame with all six tiers side by side
  over the park background, and Garret adjusts in the Inspector.

### 3f. Stick / Rock retune
`stick.tres` `damage_per_second` 2.0 → 0.9; `rock.tres` 4.0 → 1.5. Other stats unchanged.

### Step 3 commits
1. `TierData`, `TierCatalog`, six tiers; effective stats + `configure` (3a, 3c).
2. `WaveProfile` / `WaveEntry`, WaveManager reads the tier, seeded RNG (3b, 3d seed).
3. Tier/kill state + dev keys (3d).
4. Enemy scenes: Sprite layer, Stick.tscn, Rock.tscn, art + provenance, retune (3e, 3f).

---

## Tests to add (Steps 2–3)
- **Mounts:** Game has no per-type branches (a sweeping test mount works with no Game changes);
  Wolf damage comes from `get_mount_damage`; Wolf Fang still adds damage via `target_mount`.
- **MountSweep:** every existing Wolf sweep test, now against the helper; the line-tip cases; distance
  pre-check never drops an enemy that the full math would hit.
- **Removal:** each removal path; a dead enemy in the snapshot isn't hit by a later mount in the same tick.
- **Spawns:** an enemy spawned mid-tick doesn't move, latch, or get hit until the next tick.
- **Kill attribution:** the Wolf's kill reports the Wolf; a click kill reports null.
- **Bearings:** crossing the ±180° seam gives no extra hit.
- **Tiers:** effective stats = base × multiplier, applied once; early-send bonus applied once on
  top of the tier Gold; changing tier leaves live enemies alone; catalog ranks 0..5.
- **Waves:** caps are never exceeded (many seeded rolls); locked entries never appear before
  their kill count; same seed gives the same waves; every tier's profile can always fill a wave.
- **Kills:** a kill counts for the enemy's tier; Emergency Clear and the safety net don't count.
- **Scenes:** Stick.tscn and Rock.tscn load; tint and flash don't overwrite each other.
- **[O10] Through the real game:** test fixtures go through the real admission → snapshot → sweep
  path (existing helpers assume enemies appear immediately); keep the Wolf/Horse integration
  tests; add a long-reach test mount hitting an *approaching* enemy (ready for the Giraffe). Plus
  one rendered frame (`--write-movie`) to check squash recovery, tint surviving a flash, and
  smooth tumble.

## Risks and open items
- **Wolf vs tougher tiers** (NOTES): without Wolf Fang the Wolf (1.5 per hit) needs 2 passes for a Grey
  or Green Leaf (2 / 2.8 health) and 3 for a Blue one (3.92). Expected; watch it when testing Green with the dev keys.
- **Green tint on the green park** may be hard to read. The tier-colors frame will show it.
- **Rocks are slow** (25 px/s → ~15 s to arrive). With 10 s waves they overlap the next wave.
  Probably fine; it's what the per-tier interval is for.
- `directions > 1` is cheap to add now, but if it complicates the wave roll, Blue+ stays at 1 until Step 9.

## Your steps
- ~~Approve this plan~~ Done 2026-09-24.
- After Step 1's rename commit: nothing to do in the editor (no scenes change).
