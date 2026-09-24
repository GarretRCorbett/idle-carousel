# Topic C — Phase 2 state, speed, income, and purchases

## Recommendation

Use **GameState as the sole owner of run data**, a shared **CarouselConfig `.tres` Resource for tuning**, and **UpgradeManager as the catalog and purchase entry point**.

Keep calculations independent of scene nodes. Carousel reads effective speed; HUD listens for changes; mount placement reacts to committed ownership changes. Enemy nodes remain under `EnemyLayer`.

This memo proposes implementation contracts for Garret’s approval. It does not settle either DECISION PENDING item. All numerical tuning recommendations below remain provisional.

## 1. Configuration and ownership

### Put gameplay defaults in `CarouselConfig`

A `.tres` Resource is the best fit for autoload-owned tuning:

- Garret can select it directly in the FileSystem dock and edit its Inspector.
- Tests can construct their own configuration.
- GameState and Carousel cannot accidentally acquire competing speed settings.
- Runtime damage, purchases, and boosts never modify the Resource.

Suggested files:

```text
scripts/carousel_config.gd
resources/carousel_config.tres
scripts/autoloads/game_state.gd
scripts/autoloads/upgrade_manager.gd
scripts/upgrade_data.gd
resources/upgrades/*.tres
```

`CarouselConfig` extends `Resource` and has `class_name CarouselConfig`. Neither autoload receives `class_name`.

| Configuration field | Meaning |
|---|---|
| `base_spin_speed_deg_s: float` | Designer-facing base angular speed |
| `click_boost_increment: float` | Fraction added by each eligible click |
| `click_boost_cap: float` | Maximum temporary fractional bonus |
| `click_boost_decay_seconds: float` | Time to drain the current boost after the latest click |
| `max_health: float` | Starting maximum health |
| `temporary_recovery_fraction: float` | Fraction restored after clearing a health stall |
| `base_click_damage: float` | Damage before purchases |
| `play_area_click_gold: float` | Gold awarded when no enemies are latched |
| `starting_gold: float` | Run initialization |
| `starting_slot_count: int` | One for Phase 2 |
| `income_bucket_seconds: float` | Recommend `1.0` |
| `income_bucket_count: int` | Recommend `10` |

The starting Horse is a Phase 2 rule, not a configurable selection system.

Suggested initial **boost** tuning for approval: increment `0.10`, cap `0.50`, duration `2.0` seconds. Base speed, recovery fraction, click damage, and purchase costs still need Garret’s tuning decisions.

Carousel retains exports for its own geometry and placeholder appearance. Enemy and mount statistics remain in their existing Resources.

Configuration validation must reject nonfinite values, negative rates or amounts, nonpositive maximum health or decay duration, invalid bucket settings, and recovery fractions outside `(0, 1]`. Inspector ranges help authoring but do not replace validation.

### Resource immutability

Treat loaded configuration, mount, enemy, and upgrade Resources as definitions.

GameState stores runtime values separately. For example:

```gdscript
_health = _config.max_health
```

Damage changes `_health`; it never changes `_config.max_health`.

Changes to the `.tres` take effect on the next `reset_run()`. Live tuning propagation is unnecessary for Phase 2.

## 2. GameState API

### Stored versus derived

Use private-by-convention backing fields and getters. GDScript does not provide fully private fields, so “written only through functions” remains an enforced project convention.

| State | Ownership / representation |
|---|---|
| Gold | Stored `float` |
| Health | Stored `float` |
| Purchased upgrade IDs | Stored `Dictionary[StringName, bool]` |
| Purchased slot count | Stored `int` |
| Owned mount IDs | Stored `Array[StringName]`; initially Horse |
| Accumulated spin bonus | Stored `float`; initially zero |
| Accumulated click damage bonus | Stored `float`; initially zero |
| Boost envelope | Stored peak and elapsed time since latest click |
| Temporary stall | Stored enum |
| Latched enemies | Stored registry keyed by enemy instance ID |
| Simulation elapsed time | Stored `float` |
| Recent earnings | Stored bucket array and running sum |
| Spin multiplier | Derived: `1.0 + accumulated_spin_bonus` |
| Current boost | Derived from boost envelope |
| Total drag / latch DPS | Derived from registry; optionally cached |
| Latched count | Derived from registry size |
| Effective speed | Derived from configuration and runtime modifiers |
| Click damage | Derived: base plus purchased bonus |
| Gold/sec | Derived from recent earnings |
| Maximum health | Configuration value in Phase 2 |

Do not copy the GDD’s entire illustrative GameState into Phase 2. Save timestamps, offline income, high scores, settings, and later progression statistics can wait for their owning features.

### Public functions

```gdscript
# Queries
func get_gold() -> float
func get_health() -> float
func get_max_health() -> float
func get_spin_upgrade_multiplier() -> float
func get_click_boost() -> float
func get_total_drag() -> float
func get_latched_count() -> int
func get_effective_spin_speed_rad_s() -> float
func get_click_damage() -> float
func get_recent_gold_per_second() -> float
func get_slot_count() -> int
func get_owned_mount_ids() -> Array[StringName]
func is_upgrade_purchased(id: StringName) -> bool
func is_stalled() -> bool

# Commands
func add_gold(amount: float) -> void
func spend_gold(amount: float) -> bool
func add_click_boost() -> void
func damage_carousel(amount: float) -> void
func register_latch(enemy_id: int, drag: float, damage_per_second: float) -> bool
func unregister_latch(enemy_id: int) -> bool
func advance_simulation(delta: float) -> void
func reset_run(config_override: CarouselConfig = null) -> void

# UpgradeManager's transaction boundary
func try_purchase_upgrade(upgrade: UpgradeData) -> bool
```

Return a copied array from `get_owned_mount_ids()`, not the internal collection.

`reset_run()` without an override reloads production defaults. An override supports deterministic tests without editing shared `.tres` files.

### Signals

```gdscript
signal gold_changed(balance: float, delta: float)
signal gold_per_second_changed(value: float)
signal spin_speed_changed(speed_rad_s: float)
signal health_changed(current: float, maximum: float)
signal stalled_changed(stalled: bool)
signal latch_state_changed(count: int, total_drag: float)
signal click_damage_changed(damage: float)
signal slot_count_changed(count: int)
signal mounts_changed()
signal run_reset()
```

Emit ordinary change signals only when their observable values change. A boost that decays while stalled does not change effective speed, so it does not need a speed signal.

On reset:

1. Initialize **all** state.
2. Clear purchases, latch records, boost, income history, and elapsed time.
3. Restore starting Gold, health, slots, and Horse ownership.
4. Emit `run_reset()`, followed by a complete initial signal snapshot.

Every reset listener therefore reads a fully initialized state.

`reset_run()` resets data; it does not free enemies or rebuild scenes. The Game controller must remove old run objects before beginning another run.

### Money rules

Use `float` Gold because the supplied data and GDD already allow fractional amounts.

- `add_gold()` accepts finite, positive earned amounts.
- `spend_gold()` rejects negative/nonfinite amounts and insufficient funds.
- Spending zero may succeed without emitting a change.
- Never use an affordability epsilon that permits a negative balance.
- Starting Gold and resets do not count as earnings.
- Spending never reduces measured income.

In Phase 2, every normal `add_gold()` call represents actual earnings: booth, kills, or eligible play-area clicks. Do not add refund, offline, or save-loading semantics prematurely.

## 3. Effective speed and click boost

### Units

**Author base speed in degrees/second; calculate and expose runtime speed in radians/second.**

Godot’s `rotation` uses radians:

```gdscript
func get_effective_spin_speed_rad_s() -> float:
    if is_stalled():
        return 0.0

    var base_rad_s: float = deg_to_rad(_config.base_spin_speed_deg_s)
    var drag_factor: float = maxf(0.0, 1.0 - get_total_drag())

    return (
        base_rad_s
        * get_spin_upgrade_multiplier()
        * (1.0 + get_click_boost())
        * drag_factor
    )
```

The `0.0` and `1.0` here are mathematical boundaries and identities, not hidden balance settings.

Preserve total drag above `1.0`. Clamp only the resulting speed factor. For example, removing `0.05` drag from a total of `1.10` must still leave the carousel stopped.

Do not maintain another writable `carousel_spin_speed` field.

### Recommend additive spin tiers

Interpret each tier as adding a fraction of **base** speed:

| Purchases | Multiplier |
|---|---:|
| None | `1.00` |
| Spin Speed 1 | `1.20` |
| Spin Speed 1 + 2 | `1.50` |
| All four listed GDD tiers, later | `2.75` |

Multiplication would produce `1.56` after the first two and `4.095` after all four. Additive tiers are easier to explain and tune, particularly because speed also affects combat.

This is a recommendation requiring approval: the GDD does not explicitly define how those percentages combine.

### Recommend a linear envelope after the latest click

Exponential decay is frame-rate independent when implemented with `exp()`, but it approaches zero asymptotically and needs a cutoff or different duration terminology.

Recommend this explicit rule:

> Each eligible click adds to the remaining boost, clamps it to the cap, and starts a linear decay of that resulting boost over the configured duration.

Thus both a small boost and a capped boost reach zero approximately two seconds after the last click. Clicking while capped refreshes its duration.

```gdscript
# GameState excerpt.
var _boost_peak: float = 0.0
var _boost_elapsed: float = 0.0

func get_click_boost() -> float:
    var remaining_fraction: float = maxf(
        0.0,
        1.0 - _boost_elapsed / _config.click_boost_decay_seconds
    )
    return _boost_peak * remaining_fraction

func add_click_boost() -> void:
    var previous_speed: float = get_effective_spin_speed_rad_s()

    _boost_peak = minf(
        _config.click_boost_cap,
        get_click_boost() + _config.click_boost_increment
    )
    _boost_elapsed = 0.0

    _emit_speed_if_changed(previous_speed)

func _advance_boost(delta: float) -> void:
    _boost_elapsed = minf(
        _config.click_boost_decay_seconds,
        _boost_elapsed + delta
    )
```

`advance_simulation()` validates `delta`, advances the envelope, and publishes changes once the tick’s state is complete.

This avoids a fixed drain rate such as `cap / duration`, which would drain small boosts much sooner than capped boosts.

The envelope is independent of timestep subdivision within floating-point tolerance. Ordinary rotation integration still has the normal small timestep error from applying a sampled speed over each physics tick.

### Click routing

The click controller chooses exactly one path:

| Click target | Effect |
|---|---|
| UI | UI action only |
| Enemy | Enemy damage only |
| Other play-area position | Boost; also Gold if latch count is zero |

Enemy clicks do not also boost or award play-area Gold.

Boost can continue updating during a health stall, but effective speed remains zero. Continue decaying it while stalled. This avoids adding another boost state machine.

## 4. Physics ownership and scene boundary

Use one explicit update order. GameState should not run an independent `_physics_process()` that competes with Carousel.

```gdscript
class_name Game
extends Node2D

@onready var _carousel: Carousel = $World/Carousel

func _physics_process(delta: float) -> void:
    GameState.advance_simulation(delta)
    _carousel.advance_rotation(
        delta,
        GameState.get_effective_spin_speed_rad_s()
    )
```

```gdscript
class_name Carousel
extends Node2D

var _travelled_angle_rad: float = 0.0

func advance_rotation(delta: float, speed_rad_s: float) -> void:
    var angular_step: float = speed_rad_s * delta
    _travelled_angle_rad += angular_step
    rotation += angular_step
```

Carousel does not also advance itself in a second physics callback. Its unwrapped travelled angle supports later booth and sweep detection.

Proposed Step 2 tree, preserving the supplied phase structure:

```text
Game (Node2D; game.gd)
├── World (Node2D; positioned at play-area center)
│   ├── Carousel (Node2D; carousel.gd)
│   │   └── MountSlots (Node2D)
│   │       ├── Slot1 (Marker2D)
│   │       ├── Slot2 (Marker2D)
│   │       ├── Slot3 (Marker2D)
│   │       ├── Slot4 (Marker2D)
│   │       ├── Slot5 (Marker2D)
│   │       └── Slot6 (Marker2D)
│   ├── TicketBooth (Node2D; fixed relative to World)
│   └── EnemyLayer (Node2D)
└── HUD (CanvasLayer)
    └── MarginContainer (full-rect anchors; theme margins 16)
        └── HBoxContainer (expand/fill)
            ├── VBoxContainer
            │   ├── GoldLabel (Label)
            │   ├── GoldPerSecLabel (Label)
            │   ├── HealthBar (ProgressBar)
            │   └── WaveCountdownLabel (Label)
            ├── Spacer (Control; horizontal expand/fill)
            └── ShopPanel (PanelContainer)
                └── UpgradeRows (VBoxContainer)
```

The margins are scene-authorable properties. Decorative HUD layout controls should ignore mouse input; the shop and its interactive controls should consume it.

Do not add wave timers or projectile layers before their owning steps require them. Wave spawning and other recurring gameplay events use Timer nodes as required by the project rules.

## 5. Gold/sec: actual recent earnings

### Bucket representation

Use:

```gdscript
var _income_buckets: PackedFloat64Array
var _income_bucket_epoch: int = 0
var _recent_gold_sum: float = 0.0
var _simulation_elapsed: float = 0.0
```

For ten one-second buckets:

- Each bucket stores Gold earned during one simulation-second interval.
- The active index is `epoch % bucket_count`.
- `epoch = floori(simulation_elapsed / bucket_seconds)`.
- Every earning updates the active bucket and running sum.
- Advancing to a new epoch subtracts and clears each expired bucket.
- A jump of at least `bucket_count` epochs clears the whole buffer directly.

```gdscript
func get_recent_gold_per_second() -> float:
    var window_seconds: float = (
        float(_config.income_bucket_count)
        * _config.income_bucket_seconds
    )
    return _recent_gold_sum / window_seconds
```

`advance_simulation()` advances the clock and expires buckets even when nothing is earned. Otherwise the displayed rate could remain positive forever after the carousel stops.

This is time-dependent state calculation, like boost decay; it does not require a repeating sampling event or another timer.

### Define the approximation

Ten buckets containing the current partial second and nine previous seconds approximate a trailing ten-second window. An individual earning expires between nine and ten seconds after it occurred.

That boundary approximation fits the GDD’s “roughly ten seconds.” State it in tests instead of pretending this is an exact timestamped window.

Recommend a fixed ten-second denominator from run start. The display ramps up during the initial window rather than amplifying the first payout.

Examples:

- Earn `20` Gold: displayed rate becomes `2` Gold/sec.
- Spend `8`: displayed income remains `2`.
- Earn nothing until the buckets expire: displayed income becomes zero.

Use simulation time so game pauses freeze the window consistently with gameplay. Do not use wall-clock time or reuse this metric for future offline rewards.

The lag is intentional: a ten-second average falls over time after a stop; it does not instantly become zero.

## 6. TEMPORARY zero-health stall

### Separate health stall from drag stopping

```text
RUNNING
  ├── total_drag >= 1
  │     Remain RUNNING; effective speed is zero from drag.
  │
  └── health reaches 0
        Enter TEMPORARY_STALLED.
        Effective speed is forced to zero.

TEMPORARY_STALLED
  ├── latched_count > 0
  │     Remain stalled.
  │
  └── latched_count == 0
        Restore max_health × temporary_recovery_fraction.
        Return to RUNNING.
```

A drag stop does not cause a health refill. A health stall ends only after **all** latches clear, including zero-drag latches.

### Latch registry

Register each enemy once using its `get_instance_id()`.

Each record contains immutable runtime copies of that enemy’s drag and damage-per-second contribution. A small `LatchContribution` class extending `RefCounted`, with `class_name LatchContribution`, is sufficient.

- Duplicate registration returns `false`.
- Unknown or duplicate removal returns `false`.
- Count, drag, and DPS all come from the same registry.
- Recompute sums after mutations; Phase 2 enemy counts do not warrant a more complicated accumulator.
- Removal is idempotent because death and cleanup paths may both attempt it.

GameState aggregates latch damage once per simulation tick:

```gdscript
damage_carousel(get_total_latch_dps() * delta)
```

Enemies must not also apply their own per-frame carousel damage.

Keep enemies stationary in world space under `EnemyLayer`. Latching records a contribution; it never reparents an enemy under Carousel.

### Isolate the replacement point

```gdscript
enum RunCondition {
    RUNNING,
    TEMPORARY_STALLED,
}

# TEMPORARY Phase 2 policy.
# Replace only after Garret resolves the GDD fail-state decision.
func _evaluate_temporary_stall() -> void:
    if _health <= 0.0:
        _run_condition = RunCondition.TEMPORARY_STALLED

    if (
        _run_condition == RunCondition.TEMPORARY_STALLED
        and get_latched_count() == 0
    ):
        _health = (
            get_max_health()
            * _config.temporary_recovery_fraction
        )
        _run_condition = RunCondition.RUNNING
```

Call this policy after damage and latch removal. Capture old values before the operation, settle the complete new state, then emit health, stall, latch, and speed changes.

If health reaches zero with no latches, this policy immediately refills it. That is a proposed edge-case interpretation, flagged below.

No Gold penalty, respawn, repair purchase, scene change, or permanent fail state belongs here.

## 7. Upgrade definitions and purchase API

### `UpgradeData`

```gdscript
class_name UpgradeData
extends Resource

enum EffectType {
    ADD_SPIN_BONUS,
    ADD_CLICK_DAMAGE,
    ADD_MOUNT_SLOT,
    UNLOCK_MOUNT,
}

@export var id: StringName = &""

# TODO(Garret): text
@export var display_name: String = ""

@export var cost_gold: float = 0.0
@export var prerequisite_id: StringName = &""
@export var effect_type: EffectType = EffectType.ADD_SPIN_BONUS
@export var effect_value: float = 0.0
@export var mount_id: StringName = &""
@export var one_time: bool = true
```

Leave player-facing text empty for Garret, or use only names he has already supplied. Do not generate descriptions.

For Phase 2, validate that `one_time` is `true`. A repeatable-upgrade implementation would need purchase levels and repeat pricing; do not imply that changing this boolean already provides them.

| Internal ID | Prerequisite | Effect |
|---|---|---|
| `spin_speed_1` | None | Add `0.20` spin bonus |
| `spin_speed_2` | `spin_speed_1` | Add `0.30` spin bonus |
| `click_damage_1` | None | Add Garret-approved damage amount |
| `mount_slot_2` | None | Add one slot |
| `wolf` | `mount_slot_2` | Add Wolf ownership |

For `UNLOCK_MOUNT`, use `mount_id`; `effect_value` is unused and must be zero. Validate slot effects as positive integral values before converting to `int`.

Wolf also requires a free purchased slot and must not already be owned.

### One authoritative purchase price

`wolf.tres` already contains `unlock_cost_gold = 50`.

Recommend migrating purchase prices to `UpgradeData.cost_gold`, carrying that existing `50` into Wolf’s upgrade Resource. Remove the obsolete `MountData.unlock_cost_gold` field and its `.tres` entries as part of the approved Step 10 plan.

Avoid keeping two independently editable prices.

Also correct `MountData.base_gold_bonus`’s existing comment: Horse payout is fixed per pass and is **not** multiplied by spin speed.

### UpgradeManager API

```gdscript
signal upgrade_purchased(id: StringName)

func can_afford(id: StringName) -> bool
func can_purchase(id: StringName) -> bool
func purchase(id: StringName) -> bool
func is_purchased(id: StringName) -> bool
func get_definition(id: StringName) -> UpgradeData
func get_definitions() -> Array[UpgradeData]
```

Define the distinction:

- `can_afford()` checks a known, valid item’s price against Gold.
- `can_purchase()` additionally checks prerequisites, ownership, capacity, and transaction availability.
- `purchase()` rechecks everything; earlier UI checks are advisory.
- `is_purchased()` delegates to GameState.
- Unknown IDs return `false`, or `null` for definition queries.

UpgradeManager owns definitions and catalog lookup. GameState owns purchased IDs and resulting runtime values. Do not maintain a second ownership dictionary inside UpgradeManager.

Catalog validation should catch duplicate/empty IDs, invalid values, missing prerequisites, prerequisite cycles, and unsupported effects.

## 8. Atomic purchase and scene application

### Commit all state before notifying observers

Do **not** implement this sequence:

```text
spend_gold → emit gold_changed → mark purchased → apply effect
```

Godot signals can invoke listeners synchronously. A listener could attempt another purchase while the first appears incomplete.

Instead:

1. Resolve and validate the definition.
2. Acquire a purchase guard.
3. Recheck funds, prerequisite, ownership, and effect preconditions.
4. Calculate the complete result.
5. Write Gold, ownership, and effect state without emitting signals.
6. Publish GameState changes.
7. Emit `UpgradeManager.upgrade_purchased(id)`.
8. Release the guard.

The commit contains no `await`, scene instantiation, arbitrary effect callbacks, or other fallible operation after charging.

```gdscript
# UpgradeManager excerpt; no class_name on an autoload.
var _purchase_in_progress: bool = false

func purchase(id: StringName) -> bool:
    if _purchase_in_progress:
        return false

    var upgrade: UpgradeData = get_definition(id)
    if upgrade == null:
        return false

    _purchase_in_progress = true
    var purchased: bool = GameState.try_purchase_upgrade(upgrade)

    if purchased:
        upgrade_purchased.emit(id)

    _purchase_in_progress = false
    return purchased
```

GameState’s transaction function needs its own guard because it is also a callable API:

```gdscript
func try_purchase_upgrade(upgrade: UpgradeData) -> bool:
    if _purchase_commit_active:
        return false
    if not _validate_purchase(upgrade):
        return false

    _purchase_commit_active = true

    # Capture values needed for change notifications.
    var previous_gold: float = _gold
    var previous_speed: float = get_effective_spin_speed_rad_s()

    # Validation already proved the complete effect can be applied.
    _gold -= upgrade.cost_gold
    _upgrades_purchased[upgrade.id] = true
    _apply_validated_effect_without_signals(upgrade)

    _emit_purchase_changes(previous_gold, previous_speed)

    _purchase_commit_active = false
    return true
```

The named validation/application/notification helpers are project functions to implement, not engine APIs. The notification helper also publishes click damage, slots, or mounts when relevant.

Keep synchronous notification listeners observational. A listener that needs to reset the run or initiate another gameplay mutation should schedule that work after notification completes. Nested purchases during notification return `false`.

### Effects do not require Carousel references

Spin and click effects update GameState’s modifiers.

Slot and Wolf purchases update GameState’s slot count and owned mount IDs. A Game-side controller listens to `slot_count_changed` and `mounts_changed`, then synchronizes Carousel’s mounted objects.

That synchronization must be idempotent:

- One owned Wolf produces one Wolf node.
- Repeated notifications cannot duplicate mounts.
- Connecting late still works by reading current state.
- Moving the Horse resets its booth-crossing baseline and grants no payout.

Load and validate required mount scenes during scene setup. A paid purchase must not depend on discovering a missing Wolf scene after charging.

## 9. GdUnit4 verification

### Isolation contract

Each suite uses `extends GdUnitTestSuite` and has a `class_name`.

Every `before_test()` calls `GameState.reset_run(test_config)`. Because Game is the simulation driver, the autoload does not advance itself while a unit test is running.

For manager tests, provide a catalog configuration function used by initialization and test fixtures:

```gdscript
func configure_catalog(definitions: Array[UpgradeData]) -> bool
```

Allow replacement only with no purchases and no active transaction. Validate the new catalog completely before replacing the old one.

Suites should preserve the production catalog, restore it after testing, reset GameState to production configuration, and disconnect test listeners. Scene fixtures must be freed before the next reset.

### Required tests

| Area | Cases |
|---|---|
| Reset | Starting values restored; purchases, latches, boost, income, and elapsed time cleared; reset listeners see complete state |
| Gold | Add earnings; exact spend; insufficient funds; zero amount; negative/nonfinite rejection; no signal on failed spend |
| Speed | Base conversion; each formula factor; additive tiers; total drag `1.0` and above yield zero |
| Boost | Increment; cap; half-duration decay; expiration; timestep subdivision; click during decay; cap click refresh |
| Income | All three earning sources; spending excluded; startup denominator; bucket expiration; multi-bucket jumps; idle decay; reset |
| Latches | Two contributions stack; removing one preserves the other; duplicate add/remove; zero-drag latch still counts |
| Damage | Aggregated DPS × elapsed time; health clamps to zero; repeated damage at zero does not repeat stall entry |
| Stall | Forced zero speed; partial removal does not recover; final removal refills once; later damage can stall again |
| Purchases | `10 − 8 = 2`; seven cannot buy eight; prerequisites; duplicate purchase; unsupported effect rejected without charge |
| Atomicity | Signal listener sees committed ownership/effect; reentrant purchase rejected; purchase signal emitted once |
| Mounts | Slot and Wolf are separate; Wolf requires capacity; exactly one Wolf; Horse relocation grants no Gold |
| Definitions | Duplicate IDs, missing/cyclic prerequisites, invalid costs/effects, and repeatable definitions rejected |

### Representative executable-style sketches

These assume the APIs above. Test values are fixtures, not production tuning.

```gdscript
class_name TestPhase2State
extends GdUnitTestSuite

func before_test() -> void:
    var config: CarouselConfig = CarouselConfig.new()
    config.base_spin_speed_deg_s = 90.0
    config.click_boost_increment = 0.25
    config.click_boost_cap = 0.5
    config.click_boost_decay_seconds = 2.0
    config.max_health = 100.0
    config.temporary_recovery_fraction = 0.25
    config.base_click_damage = 1.0
    config.play_area_click_gold = 1.0
    config.starting_gold = 0.0
    config.starting_slot_count = 1
    config.income_bucket_seconds = 1.0
    config.income_bucket_count = 10
    GameState.reset_run(config)

func after_test() -> void:
    GameState.reset_run()

func test_spend_gold() -> void:
    GameState.add_gold(10.0)

    assert_bool(GameState.spend_gold(8.0)).is_true()
    assert_float(GameState.get_gold()).is_equal(2.0)

    assert_bool(GameState.spend_gold(3.0)).is_false()
    assert_float(GameState.get_gold()).is_equal(2.0)

func test_boost_caps_and_expires() -> void:
    GameState.add_click_boost()
    GameState.add_click_boost()
    GameState.add_click_boost()
    assert_float(GameState.get_click_boost()).is_equal(0.5)

    GameState.advance_simulation(1.0)
    assert_float(GameState.get_click_boost()).is_equal(0.25)

    GameState.advance_simulation(1.0)
    assert_float(GameState.get_click_boost()).is_equal(0.0)

func test_speed_uses_boost_and_additive_drag() -> void:
    GameState.register_latch(101, 0.25, 0.0)
    GameState.add_click_boost()
    GameState.add_click_boost()

    var expected: float = deg_to_rad(90.0) * 1.5 * 0.75
    assert_bool(is_equal_approx(
        GameState.get_effective_spin_speed_rad_s(),
        expected
    )).is_true()

func test_drag_can_exceed_one() -> void:
    GameState.register_latch(101, 0.75, 0.0)
    GameState.register_latch(102, 0.5, 0.0)

    assert_float(GameState.get_total_drag()).is_equal(1.25)
    assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal(0.0)
    assert_bool(GameState.is_stalled()).is_false()

    GameState.unregister_latch(102)
    assert_float(GameState.get_total_drag()).is_equal(0.75)
    assert_int(GameState.get_latched_count()).is_equal(1)

func test_income_tracks_earnings_not_spending() -> void:
    GameState.add_gold(20.0)
    GameState.spend_gold(8.0)

    assert_float(GameState.get_recent_gold_per_second()).is_equal(2.0)

    GameState.advance_simulation(10.0)
    assert_float(GameState.get_recent_gold_per_second()).is_equal(0.0)

func test_stall_recovers_only_after_last_latch() -> void:
    GameState.register_latch(101, 0.25, 0.0)
    GameState.register_latch(102, 0.0, 0.0)
    GameState.damage_carousel(100.0)

    assert_bool(GameState.is_stalled()).is_true()
    assert_float(GameState.get_effective_spin_speed_rad_s()).is_equal(0.0)

    GameState.unregister_latch(101)
    assert_bool(GameState.is_stalled()).is_true()

    GameState.unregister_latch(102)
    assert_bool(GameState.is_stalled()).is_false()
    assert_float(GameState.get_health()).is_equal(25.0)

    assert_bool(GameState.unregister_latch(102)).is_false()
    assert_float(GameState.get_health()).is_equal(25.0)
```

For timestep independence, compare one `advance_simulation(1.0)` with sixty calls of `1.0 / 60.0` after resetting and applying the same clicks. Use `is_equal_approx()` for accumulated floating-point results.

The critical reentrancy test connects a one-shot `gold_changed` listener after funding the purchase. Inside that listener:

1. Assert the upgrade is already purchased.
2. Assert its effect is already visible.
3. Attempt the same purchase again.
4. Verify the nested result is `false`.

After the outer purchase, assert one charge, one effect, and one `upgrade_purchased` emission.

These sketches have not been executed. Claude Code must run `tools\check.bat` after each implementation change.

## Open questions / uncertain

- **Spin percentages:** Additive tiers are recommended, but the GDD does not explicitly choose additive versus multiplicative.
- **Boost timing:** The proposal restarts a two-second linear envelope on every play-area click, including clicks at cap. Confirm that feel before implementation.
- **Click Damage 1:** Its amount and additive-versus-multiplicative interpretation are unspecified. Additive damage is proposed.
- **Tuning:** Base speed, most prices, click Gold, and temporary recovery percentage need Garret’s values. Wolf’s existing price is `50`.
- **Zero health without latches:** Immediate recovery follows the proposed temporary policy; confirm this edge case.
- **Income window:** Fixed startup denominator, simulation-time aging, and up-to-one-second bucket approximation are recommendations.
- **Scope boundary:** Mount Slot 2 and Wolf belong in the catalog design now, but their effects and scene synchronization should arrive with Step 10.
- **Combat speed scaling:** This memo defines the effective speed API, not the still-unspecified mount damage scaling formula.
- **Missing documents:** The roadmap and notes were referenced but not supplied. Full-stop balance concerns and any additional decisions there remain unverified.
- **DECISION PENDING:** Permanent death/fail behavior and prestige remain untouched.