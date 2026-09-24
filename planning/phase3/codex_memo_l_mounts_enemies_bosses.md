# Codex memo L: mounts, enemies, and bosses (Phase 3 architecture)
*Codex (GPT), 2026-09-24, read-only research. Input, not decisions; see README.md for what Claude agrees with.*


Phase 3 needs three foundations before the remaining content becomes straightforward: moving-target sweeps, explicit enemy removal and boss encounter state, and mount-tier ownership. Build those first, then add the mounts and bosses through small behavior scripts and data resources.

These are recommendations for Garret’s approval. Phase 2 is treated as signed off; the older “remaining” items in its README and roadmap are historical. No files were changed, and no game, checks, or tests were run.

**1. What the existing implementation establishes**

The current code is the authority where memo A describes an older proposal:

- `MountWolf._on_rotation_advanced()` uses `RotationMath.sweep_passes()`. It does **not** use ray queries.
- `_last_hit_pass` remembers a pass separately for each enemy instance. That memory survives ticks and stops.
- `MountBase.place()` is a relocation, never simulated travel. Wolf seeds enemies already overlapping its new position to prevent free placement hits.
- `Carousel.advance_rotation()` preserves unwrapped travel, including several revolutions in one tick.
- Damage and Gold per trigger are fixed. Faster spin increases trigger frequency.
- Enemies remain under `World/EnemyLayer`; they do not rotate with Carousel.

All six mount `.tres` files and all three ordinary-enemy `.tres` files already exist. Eagle, Turtle, Lion, Unicorn, Stick, and Rock primarily need runtime support, scenes, and integration—not new base resource definitions from scratch.

Several current assumptions need deliberate extension:

| Current implementation | Phase 3 pressure |
|---|---|
| Wolf checks enemies at their final position this tick | Eagle interception and Stick Giant’s sideways movement |
| `Game` knows `_wolves` and Wolf-specific damage | Four additional combat/effect mounts |
| Enemy stats are read directly from `enemy.data` | Color-tier scaling and statuses |
| One latch entry per enemy instance ID | Boulder’s three latch points |
| Every `died` signal pays Gold and removes one enemy | Splits, encounter completion, and boss bonuses |
| Mount roster stores type IDs; upgrade levels also represent purchase counts | Mount Tier 2/3 and Unicorn’s requirement |
| One `WaveManager.enemy_scene` | Mixed ordinary enemies, tiers, and boss summons |

**2. Shared mount architecture**

Recommend **composition through `MountSweep`**, owned by each relevant `MountBase` subclass.

A `SweepingMount` superclass would work for Wolf, Eagle, and Lion, but Turtle uses the same geometric encounter detection without damage, and Unicorn combines combat with independent economy triggers. Horse Tier 3 may eventually reuse rotation-triggered income. Composition keeps those policies separate without duplicating the difficult math.

Proposed responsibilities:

| File/class | Responsibility |
|---|---|
| `rotation_math.gd` / `RotationMath` | Pure crossing, angular-window, and contact calculations |
| `mount_sweep.gd` / `MountSweep extends RefCounted` | Per-mount pass memory, target filtering, placement rebasing, contact collection |
| `mount_base.gd` / `MountBase` | Placement, carousel connection, shared attack signal/interface |
| Individual mount scripts | Decide what an accepted contact does |
| `combat_resolver.gd` / `CombatResolver` | Apply damage/status/knockback, identify killing source, reject stale targets |
| `game.gd` / `Game` | Drive simulation and connect systems |

`MountSweep` should expose typed operations along these lines:

```text
collect_contacts(context: SweepContext) -> Array[SweepContact]
claim_contact(contact: SweepContact) -> bool
rebase(context: SweepContext) -> void
forget_enemy(enemy_id: int) -> void
clear() -> void
```

Contacts need target identity, attack-channel identity, pass identity, and contact time within the simulated interval. Claim a contact when resolving it, rather than while constructing speculative future contacts.

Use one helper per attack channel if that keeps the ledger simple. Pack Mentality’s offset sweep must eventually have its own channel; sharing Wolf’s original ledger would suppress its intended second hit.

Retain the existing `MountData.sweep_range`, `sweep_arc`, `base_damage`, and `base_gold_bonus`. Recommended additions:

| Field | Purpose |
|---|---|
| `mount_id: StringName` | Stable type identity independent of display name |
| `target_states` flags | Approaching, latched, or both |
| `slow_speed_multiplier: float` | Turtle’s movement multiplier |
| `slow_duration_seconds: float` | Turtle’s duration |
| `freeze_duration_seconds: float` | Later freeze effect |
| `heal_on_kill: float` | Unicorn’s healing |
| `knockback_distance: float` | Lion upgrade |
| `gold_trigger` enum | Booth crossing, full rotation, or enemy contact |
| `tier_definitions: Array[MountTierData]` | Explicit mount-tier modifiers and ability unlocks |

Avoid turning `is_stationary` into a universal behavior switch. It currently describes a design category, not enough information to execute an ability.

Keep purchase prices in `UpgradeData`. Existing `MountData.unlock_cost_gold` is already stale relative to the shop: Wolf’s mount resource says 50, while its upgrade costs 80. Remove or formally deprecate that second price source during the relevant implementation step.

All Resource definitions remain immutable at runtime. Effective stats and pass/status state belong to runtime objects.

**3. Eagle: moving targets are the first technical risk**

Eagle can reuse Wolf’s attack policy with greater range. Its existing resource specifies a 250-pixel outward reach. Unless Garret chooses otherwise, it should hit both approaching and latched enemies: “can hit approaching enemies” does not imply “cannot hit latched enemies.”

The present tick order in `Game._physics_process()` is:

1. `GameState.advance_simulation(delta)`.
2. Every surviving enemy calls `advance(delta)`.
3. Carousel rotates using the resulting effective speed.
4. Rotation signals synchronously run mount sweeps.

Consequently, an enemy can move to the rim, register drag, and become `AT_RIM` before Eagle examines it. Wolf then sweeps the carousel’s entire angular interval against that enemy’s **end-of-tick position**.

For radial movement, bearing stays constant, but distance and angular half-width do not:

```text
bearing = enemy offset angle
half_width = asin(hitbox_radius / distance)
```

Thus, stable bearing does not make the current calculation temporally exact.

For example, the Eagle can cross an enemy’s bearing early in a tick while the enemy is still beyond reach. The enemy enters reach late in the tick. Using its final position can award a hit that never occurred. Conversely, movement out of reach or sideways can hide a contact that did occur earlier.

There is an important qualification to “can a fast enemy tunnel through Eagle’s window?” Ordinary inward-moving enemies currently clamp to the rim. With the present Eagle reach, they cannot travel completely through its radial attack band and emerge inside it: they stop while still reachable. That does **not** guarantee correct interception timing. Sideways movement, outward knockback, narrower bands, and an approaching-only filter can produce missed contacts.

Stick Giant also breaks a second assumption: `offset.angle()` wraps at ±π. Feeding changing wrapped bearings into the existing pass ledger can change pass numbers by one without a real revolution.

Recommend:

- Capture start and end movement information for each interval.
- Represent enemy bearing continuously across the ±π seam.
- Test carousel motion and enemy motion over the **same interval**.
- Include the time when approach movement clamps at the rim.
- Retain the current stationary-target calculation as a fast path.

Define moving contact as:

```text
At some time t within the interval,
the enemy's circular hitbox intersects the mount's attack shape at t.
```

A broad angular window or the union of start/end hitboxes is useful for rejecting impossible contacts, but must not itself award damage.

For implementation, use bounded movement segments and continuous contact tests for those segments. A zigzag should expose its turning points so the sweep solver does not assume one straight path across an entire turn. If numerical subdivision is used, its termination and geometric tolerance must be explicit; endpoint-only sampling with an arbitrary substep cap does not establish a no-tunneling guarantee.

This is the part worth proving in isolation before building Eagle’s scene.

**Recommended tick evolution.** Keep `Game` as the sole driver, but replace immediate movement/attack side effects with planned motion and ordered events:

1. Advance GameState and process any resulting removals.
2. Snapshot active enemies and determine the tick’s carousel travel.
3. Plan enemy trajectories, including rim-arrival times.
4. Collect contacts and rim arrivals, then resolve them in time order.
5. Recheck target activity before every event. A slow or knockback invalidates that target’s later planned motion and contacts.
6. Add queued children/summons after the interval, so they cannot receive sweeps from before their birth.

Holding carousel speed fixed for that interval is the simpler recommendation. Latch changes affect the next interval. This changes the current treatment of newly arriving drag by up to one interval and should be documented and approved. It avoids retroactively changing travel after an attack has already used it.

**4. Lion: a sector with one hit per encounter**

Recommend a **carousel-centered annular sector**: the union of radial attack lines across Lion’s arc, from mount radius to mount radius plus reach.

That matches the existing outward sweep geometry. A cone originating at the moving Lion’s position is a different shape and needs different math.

For a stationary circular enemy, Lion can use:

```text
effective half-width =
    enemy's finite-segment contact half-width
    + half of Lion's sweep_arc
```

The current `sweep_arc = 45` should mean **45 degrees total**, not 45 degrees on each side.

There is a small geometric issue to address while extracting Wolf’s helper. `_window_of()` currently combines radial overlap with `asin(radius / distance)`. The latter describes the tangent angle of an unbounded ray. Near a finite attack’s inner or outer endpoint, it can overestimate the actual window.

For distance `d`, enemy radius `r`, and attack radii `[a, b]`, where `d > r`, an exact finite-segment half-width can be obtained using:

```text
q = clamp(sqrt(d*d - r*r), a, b)
half_width = acos(clamp((d*d + q*q - r*r) / (2*d*q), -1, 1))
```

First reject circles that do not intersect the radial band. Handle unsupported center-containing hitboxes explicitly. Add endpoint tests before using this geometry for Eagle and large bosses.

“Once per pass” should remain once during the entire encounter with the sector, even if the enemy stays inside it for many ticks. A wider arc is not permission to damage every frame.

For stationary enemies, the existing pass-index approach remains suitable. For moving enemies, track continuous relative phase and whether the current encounter has been consumed. A zigzag that exits and re-enters a nearby edge should not manufacture extra hits. Rearm after the attack and target have passed around the opposite side of their relative cycle; test reversals explicitly. Keep supported arc widths below a full-ring attack, where this definition ceases to work naturally.

A balance implication: Wolf already pierces every enemy it crosses. Lion’s wider arc primarily changes **when** a cluster is hit, not the number of hits each stationary enemy receives over a complete turn. Width alone may provide less sustained damage advantage than the description suggests.

For King’s Wrath, introduce:

```text
EnemyBase.apply_knockback(distance: float) -> bool
```

A successful knockback of a latched ordinary enemy must:

- Unregister its latch immediately.
- Change `AT_RIM` to `APPROACHING`.
- Move it outward in world space.
- Invalidate its remaining planned movement/contact events.
- Preserve Lion’s consumed-pass memory.
- Allow a later, fresh rim arrival to register again.

Apply damage first. A killed enemy must not also be knocked back or scheduled to relatch.

Whether relatching grants a fresh grace period, and whether multi-latch bosses can be displaced, are gameplay decisions. Both materially affect Lion’s strength.

**5. Turtle: make “stationary” a trigger description**

The GDD’s category definition fits Horse but does not fully specify Turtle: Turtle has no designated fixed target point.

Recommend this concrete interpretation:

> Turtle applies its effect once per approach encounter when its forward direction sweeps across an approaching enemy within range. It has no damaging attack and no effect without carousel rotation.

Under this interpretation, “stationary” means a discrete pass-triggered ability; it does not mean stationary in world space, and it does not mean an autonomous timer.

Use `MountSweep` for detection, with `APPROACHING` eligibility and a status-effect action. Turtle’s existing 120-pixel reach is measured outward from its slot, like Wolf’s.

The proposed rule is directly testable:

- An approaching enemy crossed in range receives slow once.
- Remaining within the window does not repeatedly refresh it.
- A later genuine pass can refresh it.
- A latched enemy receives no approach slow.
- Placement and stopped rotation produce no effect.

Slow belongs to the **enemy’s status system**, not Turtle’s private dictionary and not GameState’s global spin modifiers.

A small `EnemyStatusEffects` runtime helper is sufficient. Suggested interface:

```text
apply_slow(speed_multiplier: float, duration_seconds: float) -> bool
apply_freeze(duration_seconds: float) -> bool
advance(delta: float) -> void
get_movement_multiplier() -> float
```

Put the specified `0.5` multiplier and `3.0` seconds in `turtle.tres`.

Recommend refreshing equal-strength slow rather than multiplying slows together. Freeze temporarily makes movement zero; a still-active slow can resume afterward. Track expiration even while latched, rather than returning before status updates whenever the enemy is not approaching. Integrate movement across expiration boundaries so one long tick does not apply three seconds of slow for its entire duration.

Add separate immunity flags such as `slow_immune` and `freeze_immune` to enemy/boss configuration. Ancient Log rejects slow through this shared interface. Its freeze immunity needs Garret’s decision; the GDD only explicitly names slow.

Slow and freeze should affect approach movement initially. Disabling latch damage, drag, or boss spawning would add effects the GDD has not specified.

**6. Unicorn: distinguish rotation income from enemy hits**

“Gold per sweep” has at least two plausible meanings:

- Gold for every enemy contacted.
- Gold once per complete carousel rotation.

Recommend **once per completed rotation**, independent of enemy count. That preserves its hybrid income role, works when the field is empty, and avoids making Gilded Gale’s endless adds an additional per-contact income multiplier.

Use accumulated actual carousel travel or `RotationMath.count_crossings()` against a fixed reference. Relocation must not count, zero travel pays nothing, and multiple turns in one tick pay the corresponding number of times. Unicorn does not receive Horse booth payments.

Its damaging line uses the shared sweep helper and its own pass ledger. Its existing resource has damage `0.5` and Gold `1.5`; these are existing tuning values, not a decision that their eventual balance is correct.

Healing needs kill attribution. Currently `take_damage()` returns whether the hit killed, but `died(enemy)` carries no source. A typed `AttackContext` and `DamageResult` would let the resolver distinguish:

- Accepted damaging hit.
- Resisted hit.
- Lethal hit credited to this Unicorn.
- Stale hit against an already dead/removed enemy.

Heal through a new controlled `GameState.heal_carousel(amount)` function, clamped to maximum health. Do not have Unicorn write health or pay ordinary enemy Gold. Those remain centralized.

The recommended heal rule is “this Unicorn dealt the lethal hit,” not “any enemy died while a Unicorn existed.” Simultaneous contacts need deterministic ordering so exactly one source receives credit.

Unicorn’s unlock cannot be implemented honestly without mount-tier ownership. `_upgrade_levels[&"horse"]` currently counts purchased extra Horses; it is not Horse’s tier.

Recommend counting **three distinct other mount types upgraded to Tier 2 or higher**, with the unlock retained for the run after earned. That prevents three extra Horses from satisfying the requirement. Garret must choose whether upgrades are type-wide or per placed mount.

**7. Stick, Rock, statuses, and targeting**

Stick and Rock have no special ordinary-enemy behavior in the GDD. Use `EnemyBase` with their existing `.tres` files and separate visual scene configurations. Do not copy approach, damage, and latch code into empty behavior subclasses.

If keeping `enemy_stick.gd` and `enemy_rock.gd` helps project navigation, they can be thin classes, but they should not contain duplicated simulation logic. Leaf legitimately has a subclass for its tumble.

`WaveManager` needs data describing enemy composition. A small `WaveProfile`/`WaveEntry` model can hold enemy definition, count range, weight, and spatial spread. Preserve Leaf groups, Stick singles/pairs, and Rock singles rather than applying the current 3–5 count to every type.

Status and resistance responsibilities should stay distinct:

| Mechanic | Owner |
|---|---|
| Slow/freeze duration and movement multiplier | `EnemyStatusEffects` |
| Slow/freeze immunity | Enemy definition |
| First-N-hit resistance counter | Boss runtime ability |
| Current health | Enemy runtime state |
| Effective tier-scaled stats | Per-enemy runtime stats |
| Carousel drag/damage contribution | GameState latch registry |

Do not mutate `EnemyData.move_speed` to slow one enemy: loaded resources are shared.

Keep three separate size concepts:

- **Visual size:** texture/placeholder presentation.
- **Combat radius:** sweep intersection and rim stopping distance.
- **Click radius:** input forgiveness.

A bigger sprite alone must not silently alter the other two. Conversely, tier scaling should not enlarge enemies unless that is an explicitly chosen mechanic.

`ClickRouter.choose_target()` already supports different click radii and selects the nearest eligible center. A large Rock does not require a physics query. Test overlap with smaller enemies: nearest-center selection can let a Leaf take the click over part of a Rock, but this is the existing approved rule.

Add an accessor such as `get_click_radius()` so Phase 4’s Click Range upgrade need not mutate shared data. Multi-latch targeting requires a richer target result, discussed below.

There is also a concrete rendering gap: `EnemyBase._draw_placeholder()` returns when `data.texture` exists, but the current Leaf scene has no `Sprite2D` that displays that texture. Assigning a texture alone would make the enemy’s visual disappear. Phase 3’s approved scene plan should provide the sprite path.

**8. Color tiers and effective enemy stats**

Recommend one `TierData` resource per color under `resources/tiers/`:

```text
id: StringName
rank: int
tint: Color
health_multiplier: float
speed_multiplier: float
drag_multiplier: float
gold_multiplier: float
latch_dps_multiplier: float
```

Keep independent multipliers. One universal power multiplier would accidentally couple enemy travel time, durability, drag, income, and damage.

At spawn, produce an immutable effective-stat snapshot:

```text
max_health = enemy.base_health × tier.health_multiplier
move_speed = enemy.move_speed × tier.speed_multiplier
latch_drag = enemy.latch_drag × tier.drag_multiplier
latch_dps = enemy.damage_per_second × tier.latch_dps_multiplier
kill_gold = enemy.gold_drop × tier.gold_multiplier × spawn_reward_multiplier
```

The existing early-send multiplier becomes `spawn_reward_multiplier`, distinct from color-tier scaling. Apply each once.

Add accessors such as `get_latch_drag()`, `get_latch_dps()`, `get_kill_gold()`, and `get_hitbox_radius()`. Update `Game._on_enemy_reached_rim()`, `_on_enemy_died()`, movement, health-bar initialization, and sweep code together. Changing only initial health would leave most tier behavior reading Grey stats.

Recommend shared tier multipliers across the three ordinary enemy types initially. Their base data already establishes their relative roles. Add per-type overrides only if balance testing demonstrates a need.

Boss definitions should explicitly choose whether their stats are Grey-relative and tier-scaled or already final. Recommend the same base-plus-tier pipeline, applied once. Summoned Gold Leaves must use Gold tier regardless of the current wave tier.

Changing the selected tier should affect future spawns, not rescale enemies already alive. Boss victory unlocks the next tier; manual escalation remains the player’s choice.

**Tinting requires an art choice.** Modulate multiplies existing pixel colors. A brown or orange Kenney sprite multiplied by blue will generally become dark, rather than becoming a clean blue version. Godot’s documented CanvasItem color pipeline confirms this multiplication. [Godot CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html)

Recommend a **light neutral/greyscale enemy base plus Modulate**. It matches the roadmap and requires little runtime machinery. Garret chooses and approves the source conversion, brightness, and six colors; log modified asset provenance.

Alternatives are a luminance-remapping shader or a separately tinted accent. A shader preserves the source file but adds material handling; an accent preserves natural colors but makes tier identification less dominant.

Separate tier tint from hit flash. `_flash()` currently resets `_visual.modulate` to white, which would erase a tier color stored there. Use separate visual layers—for example, a tier-tinted sprite under a flash-modulated parent—or compose both factors in one function. Keep health bars and status icons outside the tinted branch.

Mount tiers also need a visual decision: six enemy colors and only three described mount upgrade tiers are not automatically a one-to-one system.

**9. Bosses: small abilities plus an encounter owner**

Recommend `EnemyBoss extends EnemyBase`, composed with a few concrete abilities. Avoid six large subclasses that each implement their own death, spawn, reward, and latch handling.

A modest interface is enough:

```text
setup(owner: EnemyBoss) -> void
advance(delta: float) -> void
modify_hit(context: AttackContext) -> void
on_lethal_hit(context: AttackContext) -> void
stop() -> void
```

Only implement hooks each ability actually needs. Use runtime component instances with `.tres` configuration; do not store counters or timer state on shared Resources.

Boss motion should come from one movement policy per boss. Do not run base radial movement and then independently add zigzag movement.

| Boss | Proposed implementation | Important contract |
|---|---|---|
| **Leaf Storm** | Split-on-death ability | Queue four Grey Leaves exactly once |
| **Stick Giant** | Zigzag approach policy | Export amplitude/period; expose trajectory segments and unwrapped bearing |
| **Boulder** | Multi-latch ability plus near-rim acceleration | Three distinct latch identities; threshold and speed multiplier in data |
| **Gilded Gale** | Periodic-spawn component with Timer | Two Gold Leaves per second while active; stop immediately on removal |
| **Ancient Log** | Slow immunity plus first-N-hit resistance | Three-hit counter per instance; damage pipeline shared with clicks and mounts |
| **Obsidian Boulder** | One-time split into two Purple Rocks | Parent death begins another encounter stage; children do not inherit splitting |

For Gilded Gale, a Timer should request spawns through `Game`, not add children directly. Timer callbacks can enqueue requests; the simulation validates and commits them at a safe boundary. Timer supports physics processing, but ordering should remain explicit rather than depending on node callback order. [Godot Timer reference](https://docs.godotengine.org/en/stable/classes/class_timer.html)

“Two per second” could mean two together every second or one every half-second. That cadence is a small but real design choice.

For Ancient Log, “resists” needs definition. Model it with `resisted_hit_count` and `resisted_damage_multiplier`; do not hard-code invulnerability. Recommend each accepted positive-damage attack consumes one charge, including clicks and distinct second strikes. Turtle’s zero-damage slow attempt should not consume a charge.

**Multi-latch cannot be three calls with the same ID.** `GameState.register_latch()` rejects a duplicate enemy instance ID.

Extend latch identity to `(owner_enemy_id, point_id)`. Preserve ordinary-enemy compatibility:

```text
register_latch(enemy_id, drag, dps, point_id = 0)
unregister_latch_point(enemy_id, point_id)
unregister_latch(enemy_id)  # removes every point for that enemy
```

Each point owns its grace age and contribution. Avoid encoding composite IDs with arithmetic. An owner record containing a typed point dictionary is clearer.

Keep `get_latched_count()` explicitly defined as latched **enemies**, and add `get_latch_point_count()` where useful. Otherwise Boulder silently changes HUD and Emergency Clear semantics.

Three entries alone do not make three playable latch points. Recommend three damageable target points with separate health pools, whose total feeds the boss health bar. This needs Garret’s approval because the GDD does not define their health or targeting.

Introduce an `EnemyTarget` result containing owner and point ID. Click routing selects a point, sweep memory keys by point, and ordinary enemies expose a single default target. Clearing a point removes only that contribution; removing the boss clears all points.

Decide how points are exposed while approaching, whether one Lion pass may hit several points, and whether drag decreases per cleared point. Do not prematurely import the Rusted King’s “all three must be cleared” drag rule into Boulder; that stronger wording belongs to the final boss.

**Encounter completion must be separate from body death.** Add a `BossEncounter` runtime owner with:

```text
encounter_id
boss_definition_id
required_member_ids
pending_required_spawns
completion_awarded
```

A killed body and a completed boss encounter are different events. Recommendation:

- Ordinary body Gold is paid once through the enemy-death path.
- The large boss bonus is paid once through encounter completion.
- Boss-body ordinary Gold can be zero in its data when the encounter bonus is the intended reward.
- Tier and slot unlocks occur only on successful encounter completion.
- Required split children are registered as pending before checking completion.

Recommend requiring Leaf Storm’s four split Leaves and Obsidian Boulder’s two split Rocks to die before awarding victory. Gilded Gale’s continuously summoned Leaves should ordinarily be optional encounter adds. These completion rules need approval.

“Splits into two Rocks” and “must kill twice” are ambiguous: the former suggests parent plus two children; the latter could mean two stages. Do not implement a resurrection in addition to the split without Garret choosing it.

**Removal needs an explicit terminal state.** The Phase 2 stale-latch fix skips queued enemies in `Game._physics_process()`. Preserve that regression test, and extend the invariant:

> Once removal begins, an enemy cannot move, latch, receive an attack, spawn children, or complete an encounter successfully.

Add `REMOVED` or an equivalent `_active` flag and a controlled `deactivate(reason)` method. Removal reasons should distinguish combat death, Emergency Clear, timeout, and reset.

`Game._remove_enemy()` should synchronously deactivate first, stop abilities/timers, unregister all latches and targets, clear every mount’s ledger entry, and only then call `queue_free()`.

Every delayed spawn or latch event must recheck activity and encounter identity. A queued Timer request from a dead Gale must not spawn after removal. Resetting a run must invalidate old requests.

Emergency Clear and timeout are not kills: no Gold, healing, split-on-death effects, or victory unlocks. How a removed boss attempt can be retried belongs to the pending fail-state/progression decision.

**10. Slots 4–6 and mount-tier progression**

Even spacing already works for any roster length:

```text
-PI / 2 + TAU * index / mount_count
```

The main work is availability and purchase validation.

Recommend separate `UpgradeData` entries for slots 4, 5, and 6, each with its required boss ID and previous-slot requirement. Leave the existing two-level `mount_slot` purchase for slots 2–3. This avoids inventing per-level boss prerequisites for one row.

Boss defeat unlocks availability; it does not grant capacity. Gold purchase grants capacity. Enforce the six-slot limit in GameState, as well as in the catalog.

At six mounts:

- Replace `_wolves`-only cleanup and reseeding with shared combat-mount/helper handling.
- Preserve existing mount objects during roster synchronization.
- Keep independent ledgers per mount and attack channel.
- Rebase every affected helper after respacing; no free hits, statuses, or rotation income.
- Process overlapping attacks deterministically; dead targets reject later contacts.
- Never let one mount’s ledger suppress another mount.
- Consider one active-enemy snapshot per interval rather than rebuilding it in every helper.

Six mounts alone do not justify a spatial index. Gilded Gale’s potentially unbounded adds are the more meaningful performance case. Measure that before adding an unapproved spawn cap.

For mount upgrades, recommend type-wide tier ownership initially:

```text
_mount_tiers: Dictionary[StringName, int]
get_mount_tier(type_id: StringName) -> int
mount_tier_changed(type_id: StringName, tier: int)
```

Keep this distinct from `_upgrade_levels`. Three Horse purchases are three mounts, not Horse Tier 3.

Type-wide tiers also make Horse resale straightforward: selling a Horse removes an instance without undoing the purchased Horse tier. If Garret wants individual tiers, the roster needs stable mount-instance IDs and per-instance tier records; `_sync_mounts()` cannot continue identifying equivalent Horses solely by type.

**11. What belongs in Phase 3 versus Phase 4**

The existing UpgradeManager already loads a catalog and performs purchases. Phase 4 expands it; it does not start from nothing.

| Needed in Phase 3 | Can remain in Phase 4 |
|---|---|
| Mount-tier ownership and effective-stat calculation | Complete branching upgrade catalog |
| Enough real Tier 2 purchases to satisfy Unicorn’s rule | Remaining Tier 3 and advanced ability purchases |
| New mount purchases and availability requirements | Full affordable/almost/locked/hidden presentation |
| Boss-defeated state and slots 4–6 gates | Kill-count gate and its HUD |
| Controlled tier selection/unlock API | Full progression pacing and boss challenge flow |
| Basic requirement reasons in existing shop | Save serialization, offline income, random events |
| Status and knockback interfaces needed by content/tests | Broader combat upgrades and final presentation |

Recommend implementing Tier 2 support for all five pre-Unicorn mount types, rather than hard-wiring exactly three qualifying choices. Actual values still need approval.

Extend `UpgradeData` with a small typed requirement list: owned mount, required mount tier, defeated boss, and count of distinct upgraded mount types. Use one requirement evaluator for purchasing and displayed lock reasons. The current shop independently checks only `prerequisite_id` and free slots; leaving that duplicated would show incorrect reasons for new gates.

The GDD needs reconciliation before the full tree:

- Eagle Tier 3 and Dive Bomb both describe firing twice.
- Lion Tier 3 and King’s Wrath both describe knockback.
- Turtle Tier 3 and Permafrost both describe freeze.
- Prismatic Horn is described as both +50% and doubling effects.
- Wolf Tier 2’s “speed increase” does not define an independent attack rate compatible with shared carousel rotation.
- Horse Tier 3’s “every sweep” is undefined.
- Damage trails are additional runtime behavior, not a numeric multiplier.

Recommend advanced named upgrades unlock the same capability as their corresponding tier upgrade, unless Garret explicitly wants stacking. Do not accidentally grant four Eagle strikes by purchasing the same described feature twice.

Phase 3 can expose boss/content selection through a development fixture while Phase 4 owns the kill gate. If Phase 3 must provide a normal playable progression route through all six bosses, that route is additional agreed scope.

The **death/fail state remains DECISION PENDING**. Phase 3 may isolate encounter removal and cancellation, but must not choose retry costs, penalties, or permanent boss-attempt behavior. **Prestige remains DECISION PENDING and outside current v1.0 scope**; no reset currency or prestige persistence belongs here.

**12. Test plan**

Keep fixture values inside tests. Production damage, durations, costs, multipliers, and ability counts belong in exports or `.tres` files.

| Area | Key tests |
|---|---|
| Existing Wolf behavior | Preserve piercing, multi-turn hits, slow overlapping encounters, stopped behavior, dead-target skipping, and placement suppression |
| Finite sweep geometry | Inner/outer endpoint contact; just-outside misses; enlarged boss circles; consistent whole-interval versus partitioned results |
| Moving Eagle targets | Radial entry before/after bearing crossing; movement to rim; tangential crossing with both endpoint snapshots missing; ±π movement seam |
| Relative pass memory | Zigzag re-entry gives no duplicate; opposite-side rearm works; slow spin and temporary relative reversal |
| Lion | Total arc width; leading/trailing edges; clustered hits; one hit through prolonged overlap; independent latch-point targets |
| Turtle | Approaching-only effect; exact expiry; refresh without multiplicative stacking; no placement/stopped application |
| Freeze and immunity | Freeze/slow precedence; expiry while latched; independent slow/freeze immunity |
| Knockback | Drag/DPS removed immediately; dead target unaffected; relatch exactly once; same-pass re-entry does not re-hit |
| Unicorn | Rotation payout with zero/many enemies; multi-turn payout; no booth payment; one attributed heal; clamp at max health |
| Tier stats | Every multiplier applied once; early-send bonus applied once; two tiers sharing one base resource do not affect each other |
| Click targeting | Larger radii, overlapping sizes, nearest-center compatibility, queued/removed target rejection |
| First-hit resistance | First three accepted damaging hits; fourth normal; clicks and second strikes; zero-damage status attempts excluded |
| Boss splits | Exact child count/type/tier; no recursive inheritance; pending children prevent premature completion |
| Gale spawning | Chosen cadence; no spawn after death, clear, timeout, or reset; correct Gold tier |
| Multi-latch | Independent grace/contributions; duplicate registration rejected; one-point removal preserves others; owner removal clears all |
| Rewards and cleanup | One body reward, one encounter bonus; no reward/heal/unlock on noncombat removal; stale latch/spawn event rejected |
| Slots and tiers | Boss unlock does not grant a slot; payment still required; cap six; Unicorn counts tiers, not Horse purchases |
| Six-mount integration | Respacing preserves identities; all helpers cleaned up; overlapping lethal attacks award once |
| Content validation | Six tiers, six mount types, three ordinary enemy types, six tier bosses; valid references, finite values, no prerequisite cycles |

Use the existing stale-latch test in `tests/test_combat.gd` as the starting point for removal regressions.

Put boss resources in a separate directory such as `resources/bosses/`; `tests/test_data_resources.gd` currently expects exactly three ordinary enemy resources in `resources/enemies/`.

For visual acceptance, Garret should inspect all six tints, flash recovery, status icons, large-enemy targeting, and six-mount readability. Logic tests cannot establish those.

During implementation, run `tools\check.bat` after every change as required. Scene changes need the approved node tree and the existing editor-review workflow.

**13. Proposed Phase 3 steps**

Sizes are relative: **S** is a contained change, **M** several connected changes, **L** a substantial integration task.

| Step | Work | Size / completion criterion |
|---|---|---|
| **1** | Resolve foundational mechanics and define Resource contracts | **M:** Garret approves trigger, tier, reward, and boss-target rules; scene trees planned |
| **2** | Extract `MountSweep`; prove moving-target contact and pass identity with Eagle/zigzag fixtures | **L:** Existing Wolf behavior preserved; moving-target and endpoint tests pass |
| **3** | Establish ordered combat events, kill attribution, explicit removal, and queued spawning | **L:** No ghost latches, stale spawns, duplicate rewards, or pre-birth hits |
| **4** | Prototype three-point Boulder targeting and GameState latch ownership | **L:** Independent points, cleanup, click routing, and sweep identity demonstrated |
| **5** | Add TierData/effective stats, Stick/Rock configurations, mixed wave definitions, and tint support | **M:** All ordinary types work at all six tiers |
| **6** | Build statuses, Turtle, and Ancient Log’s immunity/resistance behavior | **M:** Slow/freeze timing and hit resistance verified |
| **7** | Finish Eagle and Stick Giant using the proven movement path | **M:** Interception and zigzag work in the actual Game scene |
| **8** | Finish Lion and reusable knockback; complete Boulder acceleration | **M:** Sector behavior and latch transitions verified |
| **9** | Add mount-tier ownership, Tier 2 purchases, and Unicorn | **M–L:** Unicorn unlocks through real purchases; Gold and healing are attributed correctly |
| **10** | Complete split/spawner bosses, encounter rewards, and slots 4–6 | **L:** All six bosses complete correctly; boss unlocks remain separate from purchases |
| **11** | Integrated content matrix, tuning, regression checks, and understanding check | **M:** Garret can explain sweep ownership, tier scaling, statuses, and boss completion |

Steps 2–4 are intentionally early. They expose the failures most likely to force later content rewrites. The roadmap’s “pattern replication” description becomes accurate after those contracts are established.

**14. Questions for Garret**

1. **What is Turtle’s stationary trigger?**  
   A: Once when it rotates past each approaching enemy in range. B: One pulse at a fixed bearing each revolution.  
   **Recommendation: A**, matching its individual description and existing sweep machinery.

2. **What does Unicorn’s “Gold per sweep” mean?**  
   A: Once per completed rotation. B: Once per enemy contacted. C: Once per rotation that contacts at least one enemy.  
   **Recommendation: A**, giving it predictable income independent of enemy density.

3. **Which deaths heal Unicorn?**  
   A: Only its own lethal hits. B: Any death while it is equipped.  
   **Recommendation: A**, matching a combat/heal hybrid and giving attribution a clear purpose.

4. **Are mount tiers purchased per type or per individual mount?**  
   A: Type-wide, including all Horses. B: Individually for each placed mount.  
   **Recommendation: A**, keeping ownership, resale, and the shop simpler.

5. **What qualifies for Unicorn’s three Tier 2 mounts?**  
   A: Three distinct mount types upgraded during the run. B: Three qualifying mounts currently placed, including duplicate Horses. C: Three distinct types currently placed.  
   **Recommendation: A**, with eligibility retained once earned.

6. **What shape should Lion cover?**  
   A: An annular sector around the carousel. B: A cone originating at Lion’s position.  
   **Recommendation: A**, extending the current attack geometry directly. Confirm that width is intended mainly to improve cluster coverage and timing.

7. **What happens when Lion knocks an enemy loose?**  
   A: Relatching gets a fresh grace period. B: The original grace allowance is preserved across relatches.  
   **Recommendation: A** initially because it follows “new latch,” but playtest whether repeated knockback prevents too much damage.

8. **Can King’s Wrath displace multi-latch bosses?**  
   A: No; ordinary enemies only. B: Detach and move the contacted point. C: Move the whole boss.  
   **Recommendation: A** for the first implementation; the others substantially change Boulder targeting.

9. **How do Boulder’s three points take damage and reduce drag?**  
   A: Separate health pools and independently removed drag. B: Separate health pools but full drag until all clear. C: Shared health with three drag contributions.  
   **Recommendation: A**, making each cleared point visibly useful. Confirm whether Lion may damage multiple points in one pass.

10. **What does Ancient Log’s first-three-hit resistance mean?**  
    A: Block those hits completely. B: Reduce their damage by a configured fraction.  
    **Recommendation: B**, preserving the value of strong attacks. Every actual damaging strike, including a second strike, should consume one charge.

11. **Does Ancient Log also resist freeze?**  
    A: Immune to both slow and freeze. B: Immune only to slow.  
    **Recommendation: A**, preserving its Turtle-counter role; the GDD currently specifies only slow.

12. **When do split bosses count as defeated?**  
    A: After all mandatory split children die. B: When the parent dies; children are aftermath.  
    **Recommendation: A** for Leaf Storm and Obsidian Boulder. Interpret Obsidian’s “twice” as two stages unless you intend a different mechanic.

13. **How should Gilded Gale spawn its two Leaves per second?**  
    A: Two together every second. B: One every half-second.  
    **Recommendation: A**, preserving the stated small-group pressure and a readable rhythm.

14. **Do boss-generated children inherit early-send bonus Gold?**  
    A: No; bonus belongs only to the wave’s original enemies. B: Yes, inherited once from the parent encounter.  
    **Recommendation: A**, particularly for Gale’s unlimited summons.

15. **How should tier colors be applied to existing colored art?**  
    A: Approved neutral/greyscale enemy bases with Modulate. B: Luminance-remapping shader. C: Tier-colored accents only.  
    **Recommendation: A** for enemies; mount accent colors can remain a separate art choice.

16. **Are duplicated tier and named abilities the same unlock?**  
    A: They grant the same capability and do not stack. B: They are separate upgrades with explicitly stronger combined behavior.  
    **Recommendation: A**. Also choose whether Prismatic Horn is +50% or ×2; both currently appear in the GDD.

17. **How far should Phase 3 progression go?**  
    A: All content playable through development fixtures, with real mount/slot purchases; full boss challenge flow in Phase 4. B: A normal playable path through every tier and boss now.  
    **Recommendation: A**, keeping the kill gate and complete progression flow in their scheduled phase. Choice B is reasonable, but expands Phase 3.

18. **How should the three mount upgrade tiers use the six-color language?**  
    A: Use the first three colors for mount tiers. B: Choose three distinct colors from the six. C: Separate upgrade-tier markers from enemy color tiers.  
    **Recommendation: C** until the visual mapping is explicitly settled, so enemy progression does not imply nonexistent mount Tier 4–6 upgrades.