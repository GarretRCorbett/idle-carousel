# Technical design memo: rotation crossings and Wolf sweep

## Recommendation

Use one authoritative **unwrapped rotation increment per physics tick** for both systems:

- **Horse:** count crossings mathematically. Do not use collision overlap or compare wrapped angles.
- **Wolf:** sample the entire angular interval with finite outward rays, pierce using repeated queries with RID exclusions, and deduplicate using an **enemy-relative pass index**.
- **Enemies:** use `Area2D` with circular combat hitboxes for Phase 2. Keep them under world-space `EnemyLayer`.

Two correctness details matter especially:

1. Wolf’s `sweep_range = 60` measures distance **outward from the mount**, not from the carousel center.
2. A global “new revolution” reset can hit the same enemy twice around 0°. Pass boundaries must sit away from that enemy.

This is a proposed design for Garret’s approval. No files were changed or tests executed.

## 1. Rotation bookkeeping and booth crossings

### Coordinate convention

Use radians throughout gameplay calculations:

- `0` points right.
- Positive rotation is clockwise in Godot’s usual 2D screen coordinates.
- Top is `-PI / 2`.
- Never recover travelled rotation using `angle_difference()` or subtraction of wrapped transforms: both lose complete revolutions.

Let:

- \(C\): carousel’s unwrapped angle.
- \(\alpha\): mount’s slot angle relative to the carousel.
- \(\psi\): fixed world rotation of the carousel’s parent.
- \(\theta=\psi+C+\alpha\): mount’s unwrapped world bearing.

This assumes radial slots, a stationary center, and unit scale on gameplay transforms.

The booth’s bearing is:

```gdscript
var booth_angle: float = (
    booth.global_position - carousel.global_position
).angle()
```

The booth’s distance from the center does not affect counting.

### Tick ownership

`Carousel._physics_process()` calculates and applies rotation once, then emits a synchronous signal containing the actual increment. Mounts consume that increment; they do not independently integrate speed.

Proposed interface:

```gdscript
class_name Carousel
extends Node2D

signal rotation_advanced(
    previous_angle: float,
    delta_angle: float
)

var _unwrapped_angle: float = 0.0

func _physics_process(delta: float) -> void:
    # Proposed project accessor; the speed formula belongs in one place.
    var speed: float = GameState.get_effective_spin_speed()
    var previous: float = _unwrapped_angle

    _unwrapped_angle += speed * delta
    var applied_delta: float = _unwrapped_angle - previous

    rotation = wrapf(_unwrapped_angle, -PI, PI)
    rotation_advanced.emit(previous, applied_delta)
```

Initialize `_unwrapped_angle` from the intended initial rotation when binding the scene. The sketch assumes zero initially.

For Phase 2, effective speed must remain nonnegative. Additive drag can reduce the speed multiplier to zero; drag above 100% must not reverse the carousel.

Each mount maintains its own unwrapped world-bearing cache. Initialize it from placement, then advance it only by the emitted increment. Retain the exact calculated endpoint as the next tick’s starting angle.

These are transient simulation caches; Gold, health, upgrades, and other authoritative gameplay state still use controlled GameState functions.

### Crossing contract

Count target occurrences in a half-open travel interval:

- Forward: \((previous,\ previous+delta]\)
- Reverse: \([previous+delta,\ previous)\)
- Zero movement: zero crossings.

**Arrival counts; departure does not.** This prevents payment twice when one tick ends exactly at the booth and the next begins there.

For positive motion:

\[
N=
\left\lfloor\frac{previous+delta-target}{TAU}\right\rfloor
-
\left\lfloor\frac{previous-target}{TAU}\right\rfloor
\]

A pure implementation:

```gdscript
class_name RotationMath
extends RefCounted

static func count_crossings(
    previous_angle: float,
    delta_angle: float,
    target_angle: float
) -> int:
    var start_turns: float = (previous_angle - target_angle) / TAU
    var end_turns: float = (
        previous_angle + delta_angle - target_angle
    ) / TAU

    if delta_angle > 0.0:
        return floori(end_turns) - floori(start_turns)
    if delta_angle < 0.0:
        return ceili(start_turns) - ceili(end_turns)
    return 0
```

The result is a nonnegative count, including for reverse travel. Supporting reverse travel in this utility does not introduce reverse spinning into gameplay.

Do not use `is_zero_approx(delta_angle)` here: arbitrarily slow genuine movement must eventually produce crossings.

### Placement and redistribution

Treat placement as a discontinuity, separate from physical travel:

1. Apply queued mount additions and redistribution at a tick boundary.
2. Set each affected mount’s slot transform.
3. Reinitialize its bearing cache from the new placement.
4. Emit no travel interval for that relocation.
5. Process the next actual carousel increment normally.

Do not compare the old slot position with the new slot position.

This also handles loading a run or moving a booth in an editor test: rebind the baseline without generating historical crossings.

For a Horse:

```text
actual rotation interval
    → count_crossings()
    → booth_passed(horse_id, crossing_count)
    → fixed Gold per pass × crossing_count
    → GameState controlled income function
```

Connect systems through signals, with Game wiring the connections. HUD listens to income/state signals.

With the supplied Horse resource, two passes pay `2 × 5 = 10` Gold before applicable economy upgrades. Spin speed does not multiply this payout.

**Documentation correction:** `MountData.base_gold_bonus` currently says “before spin-speed scaling.” That conflicts with the approved booth rule. Claude’s Step 4 plan should include correcting that comment.

### Floating-point boundaries

The half-open convention is mathematically exact; floating-point arithmetic still has finite precision.

Use consistent cached endpoints so adjacent intervals telescope. Avoid independently adding arbitrary epsilon values to comparisons; that can pay early or duplicate a boundary.

Use scalar unwrapped angles for bookkeeping, and bounded angles for transforms/trigonometry. If extremely long runs eventually require rebasing, rebase all relevant angle and pass state together—never silently wrap only the authoritative angle.

## 2. Proposed node structure and collision setup

The following is the relevant gameplay subtree. It is a proposal for the implementation plan, not permission to write scenes.

```text
Game (Node2D)                                  game.gd
└── World (Node2D)                             stationary; scale (1, 1)
    ├── Carousel (Node2D)                      carousel.gd
    │   ├── Visual (Node2D)                    code-drawn placeholder
    │   ├── HitZone (Area2D)                   carousel click target
    │   │   └── CollisionShape2D               CircleShape2D
    │   └── MountSlots (Node2D)
    │       ├── Slot1 (Marker2D)
    │       │   └── Horse (Node2D)             mount_horse.gd
    │       │       └── Visual (Node2D)
    │       ├── Slot2 (Marker2D)
    │       │   └── Wolf (Node2D)              mount_wolf.gd
    │       │       └── Visual (Node2D)
    │       ├── Slot3 (Marker2D)
    │       ├── Slot4 (Marker2D)
    │       ├── Slot5 (Marker2D)
    │       └── Slot6 (Marker2D)
    ├── TicketBooth (Node2D)                   ticket_booth.gd
    │   └── Visual (Node2D)
    └── EnemyLayer (Node2D)                    stationary
        └── Leaf (Area2D)                      enemy_leaf.gd
            ├── CollisionShape2D               CircleShape2D
            └── Visual (Node2D)
```

Enemy health display can remain part of Step 6’s approved enemy scene; it is unrelated to sweep detection.

For a slot at angle `alpha`:

```gdscript
slot.position = Vector2.from_angle(alpha) * mount_radius
slot.rotation = alpha
```

Mount local position and rotation are zero. Local `+X` points outward. Rotate artwork under `Visual` if its drawn orientation differs.

### Layers and masks

Proposed assignments, since no named 2D layers appear in the supplied project settings:

| Object/query | Layer | Mask | Additional settings |
|---|---:|---:|---|
| Carousel `HitZone` | Layer 1: `CarouselClick` | None | Independent of Wolf detection |
| Enemy root `Area2D` | Layer 2: `EnemyHurtbox` | None | `monitoring = false`, `monitorable = true` |
| Wolf ray query | N/A | `EnemyHurtbox` only | Areas enabled; bodies disabled |

Layer 2’s bitmask value is `2`, not `1 << 2`. Store the mask in an exported physics-layer property, not a literal repeated through scripts.

### Why `Area2D`

Phase 2 enemies move toward a point and latch at a geometric radius. They do not need sliding, wall response, or mutual physical blocking.

Use:

- Scripted movement through `global_position`.
- Distance-based latch detection, clamping movement to the latch position.
- An `Area2D` for combat/click queries.

Use `CharacterBody2D` only if later approved behavior requires physical movement response. Making enemies bodies now adds behavior and configuration that this phase does not need.

Add an explicit exported **combat hitbox radius** to `EnemyData`. `placeholder_size` describes drawing, not collision geometry. A Leaf visual radius of 10 px does not establish a 10 px minimum combat radius.

## 3. Ray geometry: start at the mount

Let:

- \(O\): carousel center.
- \(a\): mount radius.
- \(L\): `MountData.sweep_range`.
- \(b=a+L\): outer endpoint radius.
- \(u(\theta)=(\cos\theta,\sin\theta)\).

At each sampled angle:

\[
from=O+a\,u(\theta)
\]

\[
to=O+b\,u(\theta)
\]

```gdscript
var direction: Vector2 = Vector2.from_angle(
    wrapf(sample_angle, -PI, PI)
)
var ray_from: Vector2 = center + direction * mount_radius
var ray_to: Vector2 = ray_from + direction * mount_data.sweep_range
```

**Reconstruct both endpoints for every sample.** Reusing the mount’s final position as the origin of all rays produces a fan from one point, not the swept motion of a rotating mount.

With an illustrative mount radius of 100 px and the supplied Wolf range of 60 px, each ray occupies radial distances **100–160 px**.

A center-origin ray of length 60 cannot reach the rim. A center-origin ray of length 160 also changes the attack by including the carousel interior.

For reliable latch clearing, validate the actual placement:

- Enemy centers at the rim should lie within the ray’s radial span.
- If enemy centers sit outside the rim by their hitbox radius, include that in the check.
- If a latched hitbox contains the ray origin, enable `hit_from_inside`.

Godot’s ray parameters provide area/body switches, RID exclusions, global endpoints, and `hit_from_inside`. [Godot ray query reference](https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters2d.html)

## 4. Deriving the angular sample count

### Familiar infinite-ray bound

A circular enemy with radius \(r\), centered distance \(\rho\) from the carousel center, subtends half-angle:

\[
\alpha=\arcsin(r/\rho)
\]

If adjacent rays differ by \(h\), the nearest ray is at most \(h/2\) away. For \(\rho\le R\), a sufficient infinite-ray condition is:

\[
h\le2\arcsin(r/R)
\]

Here, **\(R\) is distance from the carousel center**, not Wolf’s 60 px range.

However, Wolf uses finite segments. The perpendicular intersection may fall behind the mount’s origin. Use the following slightly more conservative bound.

### Recommended finite-segment bound

Assume the enemy center lies at radial distance:

\[
a\le\rho\le b=R
\]

At the nearest sampled angle, the segment contains a point at the same radius \(\rho\). If the angular error is \(\epsilon\), its distance from the enemy center is:

\[
d=2\rho\sin(|\epsilon|/2)
\]

Since \(|\epsilon|\le h/2\):

\[
d\le2R\sin(h/4)
\]

Therefore:

\[
\boxed{h\le4\arcsin\left(\frac{r}{2R}\right)}
\]

This also covers the finite segment’s inner and outer endpoints.

Use a sampling safety factor \(0<s<1\), exported as a technical setting:

\[
h_{\max}=
\min\left(\pi,\,
4\arcsin\left(\frac{sr}{2R}\right)\right)
\]

For angular travel \(\Delta\ne0\):

\[
\boxed{M=\left\lceil\frac{|\Delta|}{h_{\max}}\right\rceil}
\]

\[
\boxed{Q=M+1}
\]

`M` is the number of gaps; `Q` is the number of rays, including both interval endpoints.

Sample:

\[
\theta_i=\theta_{previous}+\Delta\frac{i}{M},
\quad i=0,\ldots,M
\]

Do not reduce \(\Delta\) modulo `TAU`. Multiple revolutions require multiple pass opportunities.

Proposed additions to `RotationMath`:

```gdscript
static func max_sample_gap(
    minimum_radius: float,
    outer_radius: float,
    safety_factor: float
) -> float:
    assert(minimum_radius > 0.0)
    assert(outer_radius > 0.0)
    assert(safety_factor > 0.0 and safety_factor < 1.0)

    var ratio: float = minf(
        1.0,
        minimum_radius * safety_factor / (2.0 * outer_radius)
    )
    return minf(PI, 4.0 * asin(ratio))

static func sample_count(
    delta_angle: float,
    minimum_radius: float,
    outer_radius: float,
    safety_factor: float
) -> int:
    if delta_angle == 0.0:
        return 0

    var gap: float = max_sample_gap(
        minimum_radius, outer_radius, safety_factor
    )
    return ceili(absf(delta_angle) / gap) + 1
```

The integers in these formulas are geometric constants, not balance tunables.

### Limits of the guarantee

The guarantee assumes:

- Actual colliders contain a centered disk of radius at least \(r\).
- Enemy centers remain stationary during the tested sweep.
- Guaranteed enemy centers lie between radii \(a\) and \(b\).
- Shapes and gameplay transforms have the expected scale.

**No finite uniform spacing guarantees every arbitrarily shallow grazing contact outside that radial center range.** For example, an enemy centered just beyond `b + r`’s tangent limit can intersect the endpoint over an arbitrarily narrow angular interval.

For circular Phase 2 hitboxes, close that fringe gap with a small supplement:

1. Consider enemies whose circles overlap the radial span but whose centers lie outside `[a, b]`.
2. Add a ray at each occurrence of their center bearing within the swept interval.
3. Merge these angles with the uniform sample list in travel order.
4. Interval endpoints are already sampled.

For a circle, the segment closest to its center occurs at its center bearing, or at an interval endpoint if that bearing is outside the interval. This supplement therefore catches fringe contacts without extending the attack’s range. Use the same physics ray query to confirm hits.

The active enemy registry needed for this can be maintained from spawn/removal signals. This is a narrow addition for circular hitboxes, not a general polygon sweep solver.

## 5. Piercing and query cost

### Recommended: repeat the same ray with exclusions

`intersect_ray()` returns one collision result. Pierce by excluding that collision object’s RID and querying the **same complete segment** again.

Do not advance the origin past the first hit. That can skip overlapping enemies and introduces an arbitrary offset.

```gdscript
class_name WolfRayQuery
extends RefCounted

static func collect_hits(
    space: PhysicsDirectSpaceState2D,
    ray_from: Vector2,
    ray_to: Vector2,
    enemy_mask: int
) -> Array[CollisionObject2D]:
    var hits: Array[CollisionObject2D] = []
    var excluded: Array[RID] = []

    var query: PhysicsRayQueryParameters2D = (
        PhysicsRayQueryParameters2D.create(
            ray_from, ray_to, enemy_mask
        )
    )
    query.collide_with_areas = true
    query.collide_with_bodies = false
    query.hit_from_inside = true

    while true:
        var result: Dictionary = space.intersect_ray(query)
        if result.is_empty():
            break

        var hit_rid: RID = result["rid"]
        excluded.append(hit_rid)
        query.exclude = excluded

        var collider: CollisionObject2D = (
            result["collider"] as CollisionObject2D
        )
        if is_instance_valid(collider):
            hits.append(collider)

    return hits
```

Reassign `query.exclude` after modifying the list; the API documents that retrieving its array yields a copy. [Godot exclusion semantics](https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters2d.html)

Exclude even an already-damaged or dying enemy so it cannot block enemies farther out. Filter its eligibility separately.

Collect results before damage callbacks can remove objects. Process accepted hit events in angular order, check that targets remain alive, and use the existing controlled damage entry point. Death and Gold-drop logic must remain idempotent.

### Alternatives

| Approach | Benefit | Problem for this phase |
|---|---|---|
| Repeated rays with RID exclusions | Matches required architecture; exact finite line; straightforward debugging | One query per hit plus one empty query |
| `intersect_shape()` with a thin rectangle | Returns multiple hits in one call | Gives the line thickness; still needs angular sampling |
| Polygon approximation of swept sector | Can cover a whole interval | Finite outward sweep is an annular sector; requires decomposition and careful approximation |
| Analytical circle intersections | Potentially inexpensive and precise | Duplicates collision logic and departs from the required ray-query architecture |

`intersect_shape()` has a result limit—32 by default—so switching to it does not automatically guarantee unlimited piercing. Any result cap needs explicit handling. [Godot direct-space query reference](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html)

Recommend repeated rays for Phase 2.

### Cost at 60 physics ticks/second

If ray \(i\) intersects \(k_i\) collision objects:

\[
queries\ per\ tick=\sum_i(k_i+1)
\]

Illustration only: \(a=100\), \(L=60\), \(r=10\), \(s=0.9\).

This gives a maximum gap of approximately **6.45°**.

| Spin | Travel/tick | Uniform rays/tick | Empty-space queries/second |
|---|---:|---:|---:|
| 1 revolution/second | 6° | 2 | 120 |
| 5 revolutions/second | 30° | 6 | 360 |
| 60 revolutions/second | 360° | 57 | 3,420 |
| 120 revolutions/second | 720° | 113 | 6,780 |

Fringe rays add to these counts. If every ray hits two enemies, query count triples.

These are operation counts, not measured frame times. Profile query count, hit count, and physics time with representative enemy density.

Do not silently cap the number of rays: doing so breaks the high-speed guarantee. An approved maximum supported spin speed or a later optimization must preserve the same hit semantics.

## 6. “Each enemy once per pass”

### Avoid a global revolution reset

This is unsafe:

```text
if floor(carousel_angle / TAU) changed:
    clear_hit_enemies()
```

An enemy straddling the zero-angle line could be hit at 359° and again at 1°, during one continuous encounter.

### Define the pass relative to the enemy

For Phase 2’s radial approach and stationary latch, give each enemy a stable center bearing \(\beta\).

For a sampled unwrapped Wolf angle \(\theta\):

\[
\boxed{
pass(\theta,\beta)=
\left\lfloor\frac{\theta-\beta+\pi}{TAU}\right\rfloor
}
\]

Its boundary lies **opposite the enemy**, where Wolf’s outward ray cannot intersect an ordinary rim enemy.

For an enemy at bearing zero:

- Wolf at −1°: pass 0.
- Wolf at +1°: pass 0.
- Wolf at 359°: pass 1.

This groups rays from the same physical encounter, including across ticks and the display wrap.

Add to `RotationMath`:

```gdscript
static func enemy_pass_index(
    sample_angle: float,
    enemy_bearing: float
) -> int:
    return floori((sample_angle - enemy_bearing + PI) / TAU)
```

Each Wolf maintains a ledger:

```gdscript
class_name WolfPassLedger
extends RefCounted

var _last_hit_pass: Dictionary[int, int] = {}

func claim_hit(enemy_id: int, pass_index: int) -> bool:
    if _last_hit_pass.has(enemy_id):
        if _last_hit_pass[enemy_id] == pass_index:
            return false

    _last_hit_pass[enemy_id] = pass_index
    return true

func forget_enemy(enemy_id: int) -> void:
    _last_hit_pass.erase(enemy_id)

func clear() -> void:
    _last_hit_pass.clear()
```

Processing order:

1. Traverse sample angles in travel order.
2. Query all enemies on that ray.
3. Map collision objects to enemy identities.
4. Compute that sample’s enemy-relative pass index.
5. Claim the hit in the Wolf’s ledger.
6. Emit a damage request only if claimed and the enemy is alive.

Use `get_instance_id()` for the enemy identity, not a collision-shape index. Remove entries on enemy removal and reset them for a new run. If pooling is introduced, explicitly clear an entry on respawn.

**Keep the ledger across ticks.** A per-tick set is insufficient at slow speeds.

Multiple revolutions in one tick naturally produce different pass indices. Do not keep one exclusion list for the whole tick: that would suppress later revolutions.

### Placement and stalls

Proposed placement behavior:

- Relocation emits no sweep interval.
- Rebase the Wolf’s bearing.
- Before its first moving sweep, seed currently intersected enemies as already consumed for that current pass, without dealing damage.
- Clear old placement-dependent ledger state as part of that rebase.

This prevents placement from granting an immediate hit or a duplicate hit during an already-overlapping encounter. It is a proposed gameplay edge rule for approval.

When `delta_angle == 0`, perform no sweep damage. A stopped Wolf is not a recurring damage turret.

Do not clear the ledger on stopping or resuming; otherwise a stall while overlapping an enemy can grant another hit.

### Why latched enemies are passed once per rotation

For a latched enemy:

\[
E=O+\rho u(\beta)
\]

Its world position and bearing remain fixed. Wolf’s segment rotates through angle \(\theta\). The segment crosses that enemy’s angular footprint once each revolution.

Thus:

- The carousel turns underneath the enemy.
- The mount’s world position moves around the ring.
- The ray repeatedly reaches the same fixed enemy position.
- The enemy-relative pass index increments once between encounters.

This works only if the enemy remains under stationary `EnemyLayer`; parenting it under Carousel would make its bearing rotate with the Wolf.

The “once per rotation” statement assumes the enemy is within radial reach and the carousel actually completes a rotation.

## 7. Physics timing and movement scope

Run direct-space queries from `_physics_process()` or synchronously from signals emitted within that callback. Godot documents physics callbacks as the safe place to access physics space. [Godot ray-casting guidance](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)

A useful tick contract is:

1. Apply queued structural changes and placement rebases.
2. Calculate effective spin for this tick.
3. Advance carousel angle.
4. Count booth crossings and collect Wolf sweep hits.
5. Apply hit requests; resulting deaths and drag changes affect subsequent rotation.
6. Complete other scheduled simulation work in a documented order.

Do not rely on incidental scene-tree callback ordering between independently processing scripts. Establish ordering explicitly in the approved implementation.

**Angular sampling is not full moving-target continuous collision detection.** Queries inspect the physics snapshot available at query time; they do not reconstruct an approaching enemy’s historical trajectory through the tick.

For latched enemies, this is exact because their position is fixed. For approaching Leaves:

- Their supplied speed is 90 px/s, or 1.5 px per tick at 60 Hz.
- Radial movement preserves their center bearing.
- That small displacement is useful context, but is not a mathematical CCD guarantee.

Test physics synchronization explicitly. If later enemies can cross the entire attack band in one tick or move sideways, extend the design with synchronized substeps or relative-motion detection. Merely increasing angular samples does not solve that problem.

## 8. GdUnit4 tests

### Pure crossing tests

```gdscript
class_name TestRotationMath
extends GdUnitTestSuite

func test_wrap_crosses_once() -> void:
    assert_int(RotationMath.count_crossings(
        deg_to_rad(359.0),
        deg_to_rad(2.0),
        0.0
    )).is_equal(1)

func test_arrival_counts_and_departure_does_not() -> void:
    assert_int(RotationMath.count_crossings(
        -PI / 2.0, PI / 2.0, 0.0
    )).is_equal(1)

    assert_int(RotationMath.count_crossings(
        0.0, PI / 2.0, 0.0
    )).is_equal(0)

func test_two_complete_turns() -> void:
    assert_int(RotationMath.count_crossings(
        PI / 4.0, 2.0 * TAU, 0.0
    )).is_equal(2)

func test_stationary_at_booth() -> void:
    assert_int(RotationMath.count_crossings(
        0.0, 0.0, 0.0
    )).is_equal(0)

func test_near_booth_without_crossing() -> void:
    assert_int(RotationMath.count_crossings(
        -0.2, 0.1, 0.0
    )).is_equal(0)

func test_reverse_arrival_and_departure() -> void:
    assert_int(RotationMath.count_crossings(
        PI / 2.0, -PI / 2.0, 0.0
    )).is_equal(1)

    assert_int(RotationMath.count_crossings(
        0.0, -PI / 2.0, 0.0
    )).is_equal(0)

func test_tick_partition_preserves_crossing_count() -> void:
    var first: int = RotationMath.count_crossings(
        -PI / 2.0, PI / 2.0, 0.0
    )
    var second: int = RotationMath.count_crossings(
        0.0, TAU, 0.0
    )
    var whole: int = RotationMath.count_crossings(
        -PI / 2.0, PI / 2.0 + TAU, 0.0
    )
    assert_int(first + second).is_equal(whole)

func test_fixed_gold_for_two_passes() -> void:
    var passes: int = RotationMath.count_crossings(
        PI / 4.0, 2.0 * TAU, 0.0
    )
    var gold_per_pass: float = 5.0
    assert_float(float(passes) * gold_per_pass).is_equal(10.0)
```

Also test equivalent target angles such as `target` and `target + TAU`, and negative unwrapped starting angles.

Placement needs a component test: call the mount’s proposed rebase API, verify no travel/pass signal, then apply a real crossing and verify exactly one payment. Passing zero into the math function alone does not test correct relocation wiring.

### Sampling and pass tests

```gdscript
class_name TestWolfSweepMath
extends GdUnitTestSuite

func test_full_turn_sample_count() -> void:
    assert_int(RotationMath.sample_count(
        TAU, 10.0, 160.0, 0.9
    )).is_equal(57)

func test_no_samples_when_stopped() -> void:
    assert_int(RotationMath.sample_count(
        0.0, 10.0, 160.0, 0.9
    )).is_equal(0)

func test_worst_gap_has_radial_point_inside_enemy() -> void:
    var gap: float = RotationMath.max_sample_gap(
        10.0, 160.0, 0.9
    )
    var enemy_center: Vector2 = (
        Vector2.from_angle(gap / 2.0) * 160.0
    )
    var sampled_endpoint: Vector2 = Vector2(160.0, 0.0)
    var distance: float = enemy_center.distance_to(sampled_endpoint)

    assert_bool(distance < 10.0).is_true()
    assert_float(distance).is_equal_approx(9.0, 0.0001)

func test_same_encounter_across_zero() -> void:
    var before: int = RotationMath.enemy_pass_index(
        deg_to_rad(-1.0), 0.0
    )
    var after: int = RotationMath.enemy_pass_index(
        deg_to_rad(1.0), 0.0
    )
    assert_int(before).is_equal(after)

func test_next_rotation_is_next_pass() -> void:
    var first: int = RotationMath.enemy_pass_index(0.0, 0.0)
    var next: int = RotationMath.enemy_pass_index(TAU, 0.0)
    assert_int(next).is_equal(first + 1)

func test_ledger_rejects_repeated_rays() -> void:
    var ledger: WolfPassLedger = WolfPassLedger.new()

    assert_bool(ledger.claim_hit(101, 0)).is_true()
    assert_bool(ledger.claim_hit(101, 0)).is_false()
    assert_bool(ledger.claim_hit(102, 0)).is_true()
    assert_bool(ledger.claim_hit(101, 1)).is_true()
```

The fixture IDs, radii, and safety values above are test data, not production defaults. GdUnit4 supports the illustrated float assertions and explicit comparison tolerance. [GdUnit4 float assertions](https://godot-gdunit-labs.github.io/gdUnit4/latest/testing/assert-float/)

### Small physics integration fixture

Proposed scene:

```text
WolfSweepFixture (Node2D)                    wolf_sweep_fixture.gd
├── Carousel (Node2D)
│   └── MountSlots (Node2D)
│       └── WolfSlot (Marker2D)
│           └── Wolf (Node2D)               production Wolf script
└── EnemyLayer (Node2D)
    ├── NearEnemy (Area2D)                  production enemy damage path
    │   └── CollisionShape2D               CircleShape2D
    └── FarEnemy (Area2D)
        └── CollisionShape2D               CircleShape2D
```

Use high-health stationary enemies so one hit does not remove them. Disable waves, random behavior, and ordinary spin advancement.

The fixture exposes proposed test helpers:

- `request_sweep(previous, delta)`: queues an interval.
- `sweep_completed`: emitted after the fixture processes that interval from `_physics_process()`.
- `hit_count(enemy)` and `health_of(enemy)`: inspect observed outcomes.

These are project fixture APIs, not GdUnit4 methods.

A representative test:

```gdscript
class_name TestWolfSweepPhysics
extends GdUnitTestSuite

func test_pierces_two_enemies_once(timeout: int = 3000) -> void:
    var runner: GdUnitSceneRunner = scene_runner(
        "res://tests/fixtures/WolfSweepFixture.tscn"
    )
    var fixture: WolfSweepFixture = (
        runner.scene() as WolfSweepFixture
    )

    # Allow newly added collision objects to enter physics space.
    await get_tree().physics_frame
    await get_tree().physics_frame

    # Fixture: radius 100, reach 60; enemies at radii 115 and 145,
    # bearing 0, radius 10, health 20; damage fixed to 1 for this test.
    fixture.request_sweep(deg_to_rad(-20.0), deg_to_rad(40.0))
    await fixture.sweep_completed

    assert_int(fixture.hit_count(fixture.near_enemy)).is_equal(1)
    assert_int(fixture.hit_count(fixture.far_enemy)).is_equal(1)
    assert_float(fixture.health_of(fixture.near_enemy)).is_equal(19.0)
    assert_float(fixture.health_of(fixture.far_enemy)).is_equal(19.0)
```

`scene_runner()` supplies scene lifecycle management. Do not equate a count of rendered/simulated frames with an exact count of physics ticks; queue the operation and await explicit fixture completion. Also remember `SceneTree.physics_frame` occurs before physics callbacks, so it is not itself proof that a requested sweep has finished. [GdUnit4 scene runner](https://godot-gdunit-labs.github.io/gdUnit4/latest/advanced_testing/sceneRunner/), [Godot SceneTree signals](https://docs.godotengine.org/en/stable/classes/class_scenetree.html)

### Required integration cases

| Case | Expected result |
|---|---|
| Enemy between tick’s start/end directions; endpoint rays miss | Intermediate ray hits |
| Several samples intersect one enemy | One hit |
| Slow encounter spans several ticks | One hit across those ticks |
| Enemy overlaps zero-angle seam | One hit across 359°→1° |
| Two collinear enemies | Both hit |
| Two overlapping enemies | Both hit |
| Ray begins inside a hitbox | Hit detected and piercing continues |
| Two rotations from a clear starting direction | Two hits per surviving in-range enemy |
| Zero movement over many ticks | No additional damage |
| Stop/resume while still overlapping | No duplicate current-pass hit |
| Enemy behind mount or wholly beyond reach | No hit |
| Fringe contact between uniform rays | Supplementary bearing ray detects it |
| Horse redistribution across booth | No payout from relocation |
| Wolf placement overlapping enemy | No placement hit under proposed rule |
| Carousel rotates while enemy is latched | Enemy’s `global_position` unchanged |
| Enemy dies during multi-ray/multi-pass processing | One death and one Gold drop |
| Target on wrong layer | Ignored |

After implementation changes, Claude must run `tools\check.bat`, including the headless GdUnit4 suite. Any scene creation follows the approved-plan and editor-review workflow.

## Open questions / uncertain

- **Actual geometry:** The supplied docs do not specify mount radius, latch-center radius, or combat collider radius. The 100 px mount radius and 10 px enemy radius above are illustrative. Validate these together before claiming reliable latch clearing.
- **Placement edge behavior:** Seeding an overlapping Wolf encounter as consumed avoids free placement damage. Garret should approve that specific behavior.
- **Stopped Wolf:** This memo proposes no attack without rotation, including when an approaching enemy enters the stationary line. Confirm that interpretation.
- **Moving enemies:** The strong guarantee applies to stationary latched enemies. Approaching enemies use a physics snapshot; full relative-motion CCD is not included.
- **Pass identity scope:** The enemy-relative index assumes monotonic spin, fixed carousel center, radial approach, and ordinary hitboxes that do not surround the center. Sideways movement, reversal, or future boss geometry needs an explicit extension.
- **Sampling settings:** Choose the collision-radius minimum and safety factor from real colliders. Changing hitbox size must update or validate the sampling bound.
- **Damage scaling:** The supplied docs require speed-scaled combat damage but do not provide its formula. Reuse an approved formula; do not invent one in Step 9.
- **API/version validation:** The sketches use documented Godot 4 APIs and GdUnit4 interfaces. They were not compiled against this project’s Godot 4.7.2 and vendored GdUnit4 6.2.1.
- **DECISION PENDING:** This design makes no decision about the final death/fail state or prestige scope.