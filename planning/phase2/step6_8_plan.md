# Phase 2 · Steps 6–8 Plan: Leaves, Latch, Waves
**Status:** DRAFT, waiting on Garret's approval.
**Why merged:** Garret (2026-09-24) asked to build Steps 6, 7, and 8 together. A Leaf that just walks in has nothing to do without latching, and hand-spawning is throwaway work once waves exist.
**Inputs:** PHASE_2_GOALS.md Steps 6–8, GDD v1.7 (Clicking, Health, Latch, Leaf, Wave Controls), `codex_memo_b_input_layout.md` §1 and §3, `codex_memo_c_state_speed.md` §6.

---

## Goal
Waves of 3–5 Leaves arrive on a visible countdown. Each Leaf flies at the carousel, and if it reaches the rim it latches on: it slows the carousel and chips its health. Clicking a Leaf damages it; a dead Leaf pays 2 Gold, exactly once. At zero health the carousel stalls until every latch is cleared (TEMPORARY). Click Damage is a new 10-level shop row.

## Decisions (Garret, 2026-09-24)
| Topic | Decision |
|---|---|
| Build order | Steps 6, 7, 8 as one plan, three commits |
| Click Damage | Base 1. **+0.5 per level, 10 levels**, first level **25 Gold**, ×1.5 per level. The Leaf (2 health) dies in one click at level 2. |
| Leaf health bar | Hidden until the first hit |
| Leaf Gold | **2** per kill |
| Leaf latch damage | **1** health per second each (carousel has 100) |
| Waves | First wave at **10 s**, then every **20 s**. 3–5 Leaves, **clustered** from one random direction. |
| TEMPORARY stall | At 0 health the carousel stops until all latches are cleared, then refills to **25%** |
| Already decided | Nearest enemy to the click takes it. Empty space does nothing. 0 health with nothing latched refills right away. |

---

## 1. The Leaf (Step 6)

### Scene: `scenes/enemies/Leaf.tscn` (new)
```
Leaf (Area2D)                 enemy_leaf.gd; data = leaf.tres
│                             collision_layer = 2 ("EnemyHurtbox"), collision_mask = 0,
│                             monitoring = false, input_pickable = false
├── CollisionShape2D          CircleShape2D, radius set from data.hitbox_radius in setup()
├── Visual (Node2D)           placeholder polygon drawn from data; tumbles (rotates)
└── HealthBar (ProgressBar)   24×4 px, centered above the Leaf, visible = false,
                              mouse_filter = IGNORE, show_percentage = false
```
- The root never rotates, so the health bar stays upright while `Visual` tumbles.
- `Area2D` isn't used for clicks (the router handles those). It's there for Step 9: the Wolf's ray queries hit the collision shape on the `EnemyHurtbox` layer. `project.godot` gets that layer name.
- Each Leaf makes its own `CircleShape2D`, so resizing one never resizes all of them.

### Scripts
- **`enemy_base.gd`** (`EnemyBase`, extends `Area2D`): everything shared by Leaf, Stick, Rock.
  - `setup(center: Vector2, latch_radius: float)`: where to fly and where the rim is.
  - `advance(delta)`: called by Game each tick. Moves straight toward the center at `move_speed`. When it reaches `latch_radius + hitbox_radius` it stops exactly there (no overshoot) and emits `latched(self)` once.
  - `take_damage(amount) -> bool`: lowers **runtime** health (a variable on the Leaf; `leaf.tres` is never changed). Shows the health bar and flashes. Returns true only on the hit that kills it. At zero it sets its state to DEAD **before** emitting `died(self)`, so a second hit in the same frame does nothing.
  - `can_receive_click() -> bool`: false once dead.
  - State: `APPROACHING → LATCHED → DEAD` (or straight to DEAD if killed on the way in).
- **`enemy_leaf.gd`** (`EnemyLeaf`, extends `EnemyBase`): only the tumble (`@export tumble_speed_deg_s`). Stick and Rock get their own small scripts later.
- **Hit feedback:** a short white flash on `Visual` (`@export` color and duration). No death animation yet; the Leaf disappears on death. Easy to add later if it feels abrupt.

### `EnemyData` gets two new fields
| Field | Leaf | Stick | Rock | Meaning |
|---|---|---|---|---|
| `click_radius` | 20 | 22 | 26 | How close a click must be. Bigger than the shape so fast Leaves are fair to click. |
| `hitbox_radius` | 10 | 14 | 16 | Physical size: latch distance and (Step 9) Wolf hits |

`leaf.tres` also gets `gold_drop = 2` and `damage_per_second = 1` written out explicitly (it relies on defaults today).

### Clicks: `scripts/click_router.gd` (`ClickRouter`, new node `World/ClickRouter`)
Memo B §1's router, minus the play-area branch, because empty space does nothing now:
- `_unhandled_input()`: left-button presses only. The HUD gets every click first, so clicks on panels or the Boost button never arrive here.
- Converts the click to world coordinates, then `choose_target()` picks the **nearest** live enemy whose `click_radius` covers the click. If there is one, it emits `enemy_clicked(enemy)` and marks the click handled. If there isn't, nothing happens.
- Keeps a list of live enemies (`register_enemy` / `unregister_enemy`). Scans only when a click arrives, never every frame.

### Click Damage upgrade
- New `resources/upgrades/click_damage.tres`: `ADD_CLICK_DAMAGE`, value 0.5, cost 25, growth 1.5, max 10. Listed after Boost Power in the shop.
- `RunConfig.base_click_damage = 1.0`. GameState adds `get_click_damage()` (base plus levels) and supports the `ADD_CLICK_DAMAGE` effect.
- Name and description are placeholders marked `# TODO(Garret): text`.

## 2. Latch, drag, health, stall (Step 7)

### Latch registry in GameState (memo C §6)
```gdscript
signal latch_count_changed(count: int)
signal stall_changed(stalled: bool)

func register_latch(enemy_id: int, drag: float, damage_per_second: float) -> bool  # false if already there
func unregister_latch(enemy_id: int) -> bool                                      # safe to call twice
func get_latched_count() -> int
func get_total_drag() -> float        # already exists; now the sum of latches, still unclamped
func get_total_latch_dps() -> float
func is_stalled() -> bool
```
- Each latched enemy records its own drag and damage, keyed by its instance ID. Totals are recomputed from the registry, so killing one Leaf removes exactly its share.
- **Drag** already sits in the speed formula (`× max(0, 1 − total_drag)`), so latching slows the carousel with no formula changes. Three Leaves = 15% slower.
- **Latched Leaves hold their world position.** They stay in `EnemyLayer`, and the carousel turns underneath them.

### Health and the TEMPORARY stall
- `advance_simulation()` gains one line: `damage_carousel(get_total_latch_dps() * delta)`. Enemies never damage the carousel themselves.
- In one clearly marked function (`# TEMPORARY Phase 2 policy`):
  - Health reaches 0 → **stalled**: effective speed is forced to 0 (the Boost button can't help).
  - Stalled and the last latch is removed → health = 25% of max (`RunConfig.stall_recovery_fraction`), running again.
  - Health 0 with nothing latched → refill right away.
- A drag stop (total drag ≥ 1) isn't a stall and gives no refill.

## 3. Waves (Step 8)

### `scripts/wave_manager.gd` (`WaveManager`, new node `Game/WaveManager` with a `WaveTimer` child)
- Exports (tune in the Inspector on the node): `enemy_scene` (Leaf.tscn), `first_wave_delay` 10 s, `wave_interval` 20 s, `min_group` 3, `max_group` 5, `spawn_radius` 380 px (just off-screen above and below the carousel; from the sides they come out from behind the panels), `cluster_spread_deg` 20°, `cluster_depth_px` 60.
- `WaveTimer` (a Timer node) runs the countdown and **always runs**, whether or not the last wave is cleared (GDD).
- `spawn_wave()`: picks one random direction, then places each Leaf within ±`cluster_spread_deg` of it, staggered up to `cluster_depth_px` further out so they arrive one after another instead of stacked. Emits `enemy_spawned(enemy)` for each.
- `countdown_changed(seconds_left)` → HUD's existing `WaveCountdownLabel` (`"Next wave: %d"`, TODO(Garret): text).
- **Debug key** (debug builds only): `N` sends a wave now, for testing. It never ships.
- The Auto Wave toggle and Next Wave button stay in Phase 4.

## 4. Wiring (Game)
Game stays the single driver, and the order is explicit:
```gdscript
func _physics_process(delta: float) -> void:
	GameState.advance_simulation(delta)   # boost, latch damage, stall, income
	_advance_enemies(delta)               # approach and latch
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())
	...
```
| Signal | Game does |
|---|---|
| `WaveManager.enemy_spawned(e)` | add to `EnemyLayer`, `e.setup(center, carousel.radius)`, register with the router, connect `latched` and `died` |
| `ClickRouter.enemy_clicked(e)` | `e.take_damage(GameState.get_click_damage())` |
| `enemy.latched(e)` | `GameState.register_latch(id, drag, dps)` |
| `enemy.died(e)` | `GameState.add_gold(gold_drop)` (counts toward Gold/sec), `unregister_latch`, router unregister, `queue_free` |
| `WaveManager.countdown_changed(s)` | `hud.set_wave_countdown(s)` |

## 5. Tests
- **Enemy:** takes damage without changing `leaf.tres`; two kill-shots in one frame → `died` once and one `true`; health bar hidden until hit; can't be clicked once dead; moves `move_speed × delta` toward the center; latches exactly at the rim distance, once, then stops.
- **Kill pays once** (integration): kill a Leaf in the Game scene → Gold +2 exactly once, even if it's hit twice that frame.
- **Router:** nearest enemy within radius wins; outside every radius → nothing; dead enemies are skipped; right-clicks and releases are ignored.
- **Latch:** two Leaves stack drag (0.10) and speed drops to match; removing one leaves exactly 0.05; registering twice fails; removing twice is safe; latched damage per second lowers health by `dps × time`.
- **Stall:** 0 health → speed 0 even with boost; stays stalled while anything is latched; clearing the last latch → 25% health and moving again; 0 health with nothing latched → immediate refill; a drag stop isn't a stall.
- **Click Damage:** base 1; each level +0.5; the shop row reaches level 10 and stops.
- **Waves:** group size stays within 3–5 (seeded RNG); every spawn lies within the cluster spread and depth; `spawn_wave()` emits one `enemy_spawned` per Leaf.

Test fixtures use their own numbers; real values stay in the `.tres` files and exports.

## 6. Build order (three commits, check passes after each)
1. **Leaf + clicks + Click Damage** (Step 6). No waves yet: `N` spawns a wave, and Leaves stop at the rim without latching.
2. **Latch + drag + health + stall** (Step 7).
3. **Wave timer + HUD countdown** (Step 8).

After each commit I render frames with `--write-movie` and check the PNG before calling it done.

## 7. Your steps (after the build)
- Open `Leaf.tscn` and `Game.tscn`, save each once (Godot assigns IDs).
- F6 on Game: the first wave comes at 10 s. Can you read and click Leaves at Boost and Overdrive speeds?
- Let a wave latch: does the slowdown show? Let health hit 0: is the stall tense or hopeless? (NOTES: full-stop spiral.)
- Tune: `leaf.tres` (speed, health, Gold, drag, damage, click radius), `WaveManager` exports, `click_damage.tres`, `RunConfig.stall_recovery_fraction`.
- Replace the placeholder text (Click Damage name and description, "Next wave").

## Done when
Waves arrive on a visible countdown. Leaves latch and visibly slow the carousel, clicking kills them for Gold, clearing latches brings the speed back, and a zero-health stall recovers once every latch is cleared. Tests pass.

## Not in this step
Wolf and sweeps (Step 9), Stick and Rock in waves (they get click and hitbox radii now), Auto Wave toggle / Next Wave / Emergency Clear (Phase 4), tiers and kill counts (Phase 4), the real fail state (DECISION PENDING).
