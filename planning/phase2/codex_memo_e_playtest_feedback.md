# Topic E — First-playtest design memo

**Recommendation:** first make the existing loop readable and smooth: labeled HUD, physics interpolation, a dedicated spin control, no click Gold, and persistent shop rows. Then evaluate more booths and income upgrades. Multiple Horses would introduce a meaningful build system, but that is a substantial change to the current six-unique-mount design.

This is brainstorming for Garret’s approval. Code below describes proposed interfaces, not implementation instructions or tested patches. All UI descriptions identify information to present; Garret writes the final player-facing wording.

## 1. HUD: show relative speed, explain income

### Speed options

| Presentation | Strength | Weakness | Recommendation |
|---|---|---|---|
| Multiplier, such as `×1.35` | Makes upgrades, boosts, and slowdown easy to compare | Needs a clear reference value | **Primary speed readout** |
| Degrees per second | Precise; matches existing tuning | Technical and unfamiliar | Developer display |
| RPM | Compact, physically meaningful | Abbreviation may need explanation | Optional detail |
| Turns per minute | Understandable without technical vocabulary | Longer; less immediate than a multiplier | Optional expanded detail |
| Gauge/bar | Makes a click visibly register | Ambiguous without a number and defined scale | **Complement to the readout** |

Use **effective speed divided by the original base speed**:

```text
displayed_multiplier = actual_speed_rad_s / configured_base_speed_rad_s
turns_per_minute = actual_speed_rad_s / TAU × 60
```

Examples at the supplied base speed:

| Situation | Effective speed | Multiplier | Turns/minute |
|---|---:|---:|---:|
| Starting speed | 45°/s | 1.00× | 7.5 |
| Spin Speed 1 | 54°/s | 1.20× | 9.0 |
| Starting speed, capped boost | 67.5°/s | 1.50× | 11.25 |
| Starting speed, 50% drag | 22.5°/s | 0.50× | 3.75 |
| Fully stopped | 0°/s | 0.00× | 0 |

Do not redefine `1.00×` after every permanent upgrade: that would hide progression.

For the first revision, use:

- Gold balance with its resource name.
- Recent actual Gold/second with its unit.
- Effective speed multiplier with a speed label.
- A small **temporary boost bar**, explicitly distinct from actual speed.

The boost bar uses `current_boost / boost_cap`. It can jump immediately on a press even if actual speed is later eased. At full drag, that bar may fill while actual speed remains zero; the HUD must make the slowdown/stopped condition apparent.

A total-speed gauge is also viable, but requires a stable scale and a marker for the current unboosted speed. Avoid automatically rescaling it every frame.

### What idle games commonly communicate

The useful convention is **resource balance plus an earning/output rate**, with costs and production improvements nearby. There is no universal idle-game speed unit. Cookie Clicker foregrounds cookie production; Clicker Heroes foregrounds damage output. Their official game interfaces are useful references for hierarchy, rather than evidence that Idle Carousel needs the same metrics. [Cookie Clicker](https://orteil.dashnet.org/cookieclicker/), [Clicker Heroes](https://www.clickerheroes.com/).

**Recommendation:** multiplier for the primary display; turns/minute in details if Garret wants a physical interpretation.

### Keep actual income distinct from predicted income

Retain the GDD’s rolling average of actual earnings. With one 5-Gold payment every eight seconds, a ten-second window will fluctuate—often between approximately 0.5 and 1.0 Gold/s after startup—even though the long-run average is 0.625.

That is expected sampling behavior, not an economy bug. Startup also deliberately underreports while the window fills.

If added later, a theoretical booth rate belongs in details and must be identified separately. It should not silently replace the approved actual-income metric.

**GDD status:** labeling and adding speed information are compatible additions. Final wording remains Garret’s work.

## 2. Random jolts: diagnose presentation before changing the simulation

### What the supplied code establishes

The simulation correctly separates:

- `_unwrapped_angle`: accumulated travel for gameplay.
- `rotation`: wrapped orientation for display.

It also integrates travel incrementally:

```gdscript
_unwrapped_angle += speed_rad_s * delta
```

Consequently, changing speed does **not** reset orientation. A click changes angular velocity; it does not directly create an angle jump.

### Likely causes, ranked

| Candidate | Expected symptom | Assessment |
|---|---|---|
| Physics/render mismatch without interpolation | Uneven movement visible during constant-speed rotation, particularly at high refresh rates | **First suspect** |
| Render stalls or uneven frame presentation | Occasional freeze followed by a catch-up jump | Plausible; profile separately |
| Instantaneous boost increments | A noticeable acceleration step exactly when clicking | Real behavior, but cannot explain sustained no-input jolts |
| Linear boost decay ending | Small change in acceleration when the fade reaches zero | Possible feel issue; not an orientation discontinuity |
| Incorrect interpolation across wrapped angles elsewhere | Dramatic wrong-way movement near ±180° | Audit other writers; not demonstrated by supplied code |
| Multiple rotation writers or reset/reposition events | Discrete, event-linked jumps | Check during implementation review |

At a default 60 physics ticks/second, the base rotation advances **0.75° per tick**. Rendering at 144 Hz without interpolation repeats some poses more often than others. Godot identifies this timing mismatch as a common jitter cause. VSync can improve presentation timing, but does not create the missing intermediate poses. [Godot jitter and stutter guide](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html).

The supplied project file does not enable interpolation. Godot’s documented default for `physics/common/physics_interpolation` is `false`; confirm the effective setting in Garret’s build. [ProjectSettings reference](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-physics-common-physics-interpolation).

### Does interpolation handle wrapping at ±PI?

**Normal small-step rotation should cross that boundary smoothly.**

The orientations immediately before and after the wrap are adjacent. Godot’s current 2D interpolation implementation interpolates transforms, with angle-aware rotation interpolation; it does not simply average the exposed wrapped scalar. Thus, ±PI wrapping alone is not sufficient evidence of an engine bug. The source inspected here is upstream `master`, not a verified 4.7.2 build. [Transform interpolation source](https://github.com/godotengine/godot/blob/master/core/math/transform_interpolator.cpp), [Transform2D source](https://github.com/godotengine/godot/blob/master/core/math/transform_2d.cpp).

Two caveats matter:

- Ordinary scalar `lerpf(previous_wrapped, current_wrapped, alpha)` would take the wrong route across the boundary.
- Endpoint transforms cannot preserve full-turn history. If a physics tick travels more than half a turn, shortest-path rendering can disagree with actual travel. Exact gameplay counting must still use the unwrapped interval.

Current speeds are far below that second limit.

### Recommended first fix: built-in physics interpolation

Enable **Physics → Common → Physics Interpolation** through the editor. Keep `Game._physics_process()` as the only simulation driver.

Godot’s relevant rules are to update interpolated transforms in physics ticks and call `reset_physics_interpolation()` after discontinuous placement. Temporarily testing at 10 physics ticks/second makes defects easier to see; restore the normal rate afterward. [Using physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html).

For this project:

- Keep Carousel and its mount hierarchy interpolated consistently.
- Keep HUD controls outside world interpolation.
- Reset interpolation after initial placement, a run reset that repositions objects, or mount redistribution.
- Handle `_center_world()` resizing as a deliberate reposition: update the position, then reset interpolation for the affected hierarchy, or apply the reposition during the next physics tick.
- Do not call the reset function every rotation tick.

**Booth counting remains unchanged.** Rendering can lag simulation slightly; pass events still come from the authoritative physics interval. A booth pop may precede the interpolated visual contact by roughly a tick. Address that only if visible in playtesting, without delaying or duplicating the actual payment.

### Alternative: render-only interpolation in `_process`

This is a fallback if built-in interpolation proves unsuitable.

Maintain previous/current **unwrapped** simulation angles and interpolate only a separate visual representation:

```gdscript
# Methods on a proposed CarouselPresentation component.
# The component must not contain gameplay hitboxes or pass detectors.
func sample_angle(
        previous_angle: float,
        current_angle: float,
        fraction: float
) -> float:
    return lerpf(previous_angle, current_angle, fraction)
```

The render caller uses `Engine.get_physics_interpolation_fraction()` and wraps the sampled result only when assigning visual rotation. Godot exposes that fraction for custom interpolation. [Engine reference](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-physics-interpolation-fraction).

Important implementation constraints:

- Refresh previous/current snapshots on **every** physics tick, including stopped ticks.
- Disable built-in interpolation on that manually driven visual subtree.
- Mirror the platform and all mount visuals consistently.
- Preserve authoritative mount transforms or analytic angles for gameplay.
- Never feed interpolated display angles back into pass counting.
- Avoid an independent `visual_rotation += speed * render_delta` clock, which can drift from simulation.

**Recommendation:** do not introduce this extra representation unless the simpler built-in approach fails a reproducible test.

### Optional feel change: ease propulsion toward its target

Interpolation smooths presentation between ticks. It does not remove an abrupt change in angular velocity.

If presses still feel harsh after interpolation, try exponential smoothing with a proposed time constant of **0.08–0.15 seconds**, stored in `RunConfig`. Around three time constants reaches 95% of a fixed target change.

```gdscript
class_name SpinResponseMath
extends RefCounted


static func approach_speed(
        current: float,
        target: float,
        delta: float,
        response_seconds: float
) -> float:
    if delta <= 0.0:
        return current
    if response_seconds <= 0.0:
        return target
    var weight: float = 1.0 - exp(-delta / response_seconds)
    return lerpf(current, target, weight)
```

Prefer smoothing the **propulsion component**, then applying drag and the existing temporary stall:

```text
target_drive = base × permanent_multiplier × (1 + boost)
actual_drive = exponential_approach(actual_drive, target_drive)
actual_speed = actual_drive × max(0, 1 − total_drag)
actual_speed = 0 when the existing temporary stall applies
```

This preserves immediate full-stop behavior at sufficient drag. Smoothing the final effective speed without a stop override would allow residual rotation and payments after a commanded stop.

If adopted:

- Store actual drive/speed in the authoritative runtime state.
- Reset it explicitly at run start.
- Integrate **actual** speed into unwrapped travel.
- Report actual speed through `spin_speed_changed`.
- Keep target boost separately available for input feedback.

**GDD change:** physical speed would no longer match the current instantaneous formula during transitions. It would also retain a small smoothing tail after the two-second target fade. That needs explicit approval and revised tests.

The current linear decay is continuous in speed, but its slope changes at the endpoint. A smoothstep-shaped decay is another option that still ends exactly at two seconds; that also changes the approved linear behavior. Change one variable at a time.

### Verification before blaming a Godot regression

Record physics angle, angular step, effective speed, and render frame duration during:

1. At least 30 seconds without input.
2. Repeated ±PI crossings.
3. One press and its complete fade.
4. Rapid presses to the cap.
5. Window resizing and a purchase.

If unwrapped travel stays continuous while presentation jolts, investigate rendering. If the simulation angle jumps, inspect its writers and reset paths.

Compare interpolation off/on at 60 Hz and an available high refresh rate, then compare VSync settings. Test a standalone run as well as the editor. Headless tests cannot establish visual smoothness.

## 3. Input: a dedicated spin control is the clearest first experiment

Cookie Clicker gives clicking an obvious object—the cookie. Clicker Heroes similarly directs attacks at monsters. The transferable lesson is that the target and consequence should be recognizable. [Cookie Clicker](https://orteil.dashnet.org/cookieclicker/), [Clicker Heroes](https://www.clickerheroes.com/).

### Options

| Control | Advantages | Costs and conflicts |
|---|---|---|
| Large dedicated Spin/Push button | Discoverable; clear separation from attacking; easy feedback and keyboard support | Pulls attention away from the carousel |
| Click the carousel itself | Strong connection between action and object; keeps focus central | Overlaps enemies and future mount-info interactions |
| Hold-to-crank | Less repetitive clicking; clear sustained action | Needs a defined repeat cadence and release/focus behavior; changes active-play balance |
| Lever/pump | Strong playground identity and tactile rhythm | More interaction design, artwork, and testing |

**Recommendation:** start with a large dedicated button near the carousel, with the boost bar beside it. Keep hold behavior and a decorative lever for a later comparison.

A lever could eventually use the same action signal as the button, avoiding a second boost implementation.

### Keep attack and boost distinct

For the recommended button design:

| Input target | Result |
|---|---|
| Spin control | One boost request |
| Enemy | Damage request only |
| Mount interaction target | Mount information, when implemented |
| Other UI | Its own UI action only |
| Empty play area | No action |

The Spin button is an explicit gameplay control. Its GUI event remains consumed; its own signal requests a boost. This is different from allowing UI events to fall through into world input.

For a carousel-click alternative, priority should be enemy → mount interaction → eligible carousel surface → nothing. Define the eligible area deliberately; do not preserve the current viewport-wide fallback.

Use a signal such as `spin_requested`, connected centrally by `Game` to `GameState.add_click_boost()`. Both pointer and keyboard activation should reach that same route exactly once.

**GDD change:** replacing “click anywhere else in the play area” requires updating the click rules and Phase 2 expectations. The high-level promise of boosting and attacking still holds; the detailed GDD already treats those as separate click outcomes.

### Feedback: communicate acceptance and consequence

Recommended minimum:

1. **Immediate control response:** pressed appearance or a brief squash of a decorative child.
2. **Immediate boost-bar jump:** identifies what the press added.
3. **Visible carousel response:** a short procedural rim arc or restrained spoke emphasis.
4. **Effective-speed readout:** shows the resulting speed.
5. **Optional sound:** an approved sourced or human-created push sound.

Avoid scaling a container-managed button itself if that destabilizes layout; animate a visual child.

Number popups are optional. Without click Gold, a coin popup would misrepresent the action. A boost-number popup adds clutter and can become misleading near the cap, where a press may add less than the nominal increment.

At the cap, feedback should still acknowledge the press because it restarts the decay. It must not claim another full increment.

The GDD forbids floating **damage** numbers, not all procedural feedback. Keep enemy feedback to health changes and a hit flash. Procedural effects are permitted; final art, sound, and wording remain Garret’s responsibility.

## 4. Remove click Gold: support the change, then measure the opening

**Recommendation: remove it.** Direct click Gold competes with the carousel as the economic centerpiece. Boost-only presses make the relationship clearer: pushing increases travel, and travel creates booth payments.

At four eligible clicks/second, the current 0.25-Gold burst produces **1 Gold/s**, already exceeding the starting Horse’s **0.625 Gold/s**, before boosted booth income.

### Opening purchase timing

With zero starting Gold, no drag, one Horse, one booth, and 5 Gold/pass:

```text
turn duration = 360 / 45 = 8 seconds
income = 5 / 8 = 0.625 Gold/s
Spin Speed 1 needs six payments
continuous-rate estimate = 30 / 0.625 = 48 seconds
```

Actual timing depends on the Horse’s initial phase:

```text
purchase_time = first_pass_delay + five additional turn durations
```

That gives approximately **40–48 seconds** at base speed, with no payment merely for initial placement.

At a continuously maintained 50% boost, the ideal income is **0.9375 Gold/s**, and the continuous estimate is **32 seconds**. Real play includes ramp-up, decay, and discrete payments.

One isolated +10% boost fading linearly over two seconds adds only:

```text
extra travel ≈ 45°/s × 0.10 × 2 s / 2 = 4.5°
```

That advances the next pass by roughly **0.1 seconds** at base speed. A single press therefore needs immediate feedback even when the economy is working correctly.

### Recommended tuning approach

Keep 45°/s, 5 Gold/pass, and the 30-Gold first purchase for the first comparison. Establish whether clear feedback and a visible savings target make the wait acceptable.

If it remains slow, try one change:

- Lower Spin Speed 1’s cost.
- Increase base speed, which also affects future combat frequency.
- Increase Horse payout, which affects the economy without changing motion.

My preference is a modest first-purchase cost adjustment before changing the global speed balance. A proposed 25-Gold trial removes one required pass while preserving the underlying motion.

If all non-booth income is also removed, the earlier economy memo’s kill-income estimates no longer apply. With the same purchase order and no boost/drag:

| Milestone | Continuous estimate |
|---|---:|
| Spin Speed 1 | 48 s |
| Slot 2 + Wolf, after Spin Speed 1 | About 181 s total |
| All five Phase 2 purchases, Spin Speed 2 last | About 381 s total |

These are economy baselines, not predictions of survival once Leaves arrive.

**GDD change:** remove click bursts from Currency, Clicking and Spin Boost, Phase 2 decisions/tests, and the HUD income-source description. Remove the earning call itself; setting the reward to zero is useful for an experiment but leaves the old rule embedded in the design.

## 5. More booths and Horses: distinguish income progression from mount builds

### The economy equation

For identical Horses and booths:

```text
Gold/s = Horse count × booth count × turns/second × Gold/pass
```

At the current base values:

| Horses | Booths | Gold/s | Relative income |
|---:|---:|---:|---:|
| 1 | 1 | 0.625 | 1× |
| 1 | 2 | 1.250 | 2× |
| 2 | 2 | 2.500 | 4× |
| 3 | 4 | 7.500 | 12× |

This is multiplicative across independent factors. Each extra Horse becomes more valuable after buying booths, and each booth becomes more valuable after buying Horses.

For one added identical producer:

```text
marginal Horse income = booths × turns/sec × payout
marginal booth income = horses × turns/sec × payout
```

Speed should continue affecting frequency only. Do not also multiply payout by speed.

### Placement changes rhythm, not long-run yield

Evenly spaced booths make one Horse’s payments more regular:

- One booth: every eight seconds.
- Two booths: every four seconds.
- Four booths: every two seconds.

Multiple evenly spaced Horses can synchronize:

- Two opposite Horses and two opposite booths produce **two payments simultaneously every four seconds**.
- Two opposite Horses and three evenly spaced booths produce six distinct payment moments per turn.

For `H` Horses evenly distributed around the entire ring and `B` evenly spaced booths:

```text
distinct payment moments per turn = lcm(H, B)
simultaneous payments per moment = gcd(H, B)
total Horse–booth crossings per turn = H × B
```

Mixed combat/economy layouts do not generally satisfy that simple evenly-spaced-Horses assumption. The GDD spaces **all occupied mounts**, so actual Horse slot offsets determine payment clustering.

Aggregate simultaneous visual/audio feedback when necessary, but award every valid crossing.

### Multiple Horses would create a different strategic game

The tradeoff is appealing: an economic slot generates Gold; a Wolf slot protects that income by removing drag.

However, current scope explicitly excludes mount doubling/stacking. Staying within six slots avoids the “more than six mounts” limit, but **does not avoid the duplicate-mount conflict**.

It also raises new design requirements:

- Can players sell, replace, or bench a Horse?
- Can a mistaken early purchase permanently occupy a needed combat slot?
- How do duplicate mounts coexist with the promised six unique mounts?
- Does completing v1.0 require owning each type or fielding all six simultaneously?
- How are per-instance tiers, saves, costs, and upgrades represented?
- How does automatic redistribution affect existing pass baselines?

**Recommendation:** keep unique mounts for this version unless Garret deliberately wants slot allocation to become a central build mechanic. Duplicate Horses should be evaluated as a separate prototype with replacement rules, not slipped in as another shop row.

### Options that better fit the current GDD

| Option | Benefits | Costs |
|---|---|---|
| Existing Booth 2 | Already specified; strong visual milestone; doubles frequency | Only one additional purchase |
| Booths 3 and 4 | More visible income infrastructure; no combat-slot displacement | New content, layout, and economy scope |
| Horse payout tiers | Already part of progression; smallest implementation burden | Less visible than buying another object |
| Duplicate Horses | Strong economic/combat tradeoff | Explicit scope conflict; requires mount-build rules |

**Recommended direction:** one unique Horse, existing Booth 2, and Horse payout progression. If Garret still wants more visible economic purchases, expand to a maximum of four booths before introducing duplicate Horses.

Booths 3 and 4 remain a GDD amendment. They should arrive after the initial Wolf automation milestone rather than competing with it during the first-playtest repair.

For placement, Garret should choose between:

- Redistributing booths evenly at each count: 180° apart, then 120°, then 90°.
- Keeping existing booths fixed: easier continuity, but three booths cannot remain evenly spaced while preserving the original opposite pair.

Repositioning or constructing booths must never award retroactive crossings.

### “Gold only from Horse passing a booth” is a broader revision

Taken literally, this removes or changes:

- Enemy death Gold.
- Boss Gold bonuses.
- Early-wave Gold rewards.
- Unicorn sweep Gold.
- Horse Tier 3’s Gold outside booth passes.
- Offline earning semantics.

It also changes the motivation for combat: killing enemies preserves production rather than paying immediately. Bosses would rely more heavily on unlocks and progression as rewards.

**Recommendation:** the strict Horse–booth economy is coherent and reinforces the game’s identity, but approve it explicitly before Step 6 introduces enemy death payouts. If that is Garret’s intended direction, honor it consistently rather than quietly preserving several exceptions.

Offline Gold would need an explicit allowance for calculated Horse–booth production while absent. This memo does not choose offline combat or fail-state behavior.

### Multiple-booth implementation shape

The supplied `MountHorse.set_booth_bearing()` and `_on_booth_passed()` represent one booth. Multiple booths need:

- Stable booth identifiers and bearings.
- Crossing counts for each Horse–booth pair.
- Events identifying both Horse and booth.
- One authoritative earning handler.
- Per-pair baseline resets after construction or mount redistribution.

Keep booths under `World`, outside Carousel. Combat mounts must not earn simply because they pass a booth.

The GDD sentence saying Booth 2 makes “every mount pass” collect Gold conflicts with the Horse-specific currency rule. Clarify it as a Horse pass during the document update.

## 6. Shop: persistent rows and explicit states

**Recommendation: keep every Phase 2 catalog row visible, including purchased rows.** Five entries are small enough to show the entire immediate progression without overwhelming the player.

The current shop hides unavailable and purchased rows. That obscures both the next goal and purchase history.

### Relationship to the GDD

| Existing GDD rule | Recommendation |
|---|---|
| Affordable highlighted/pulsing | Retain restrained emphasis |
| Within 20% of affordability | Retain as optional secondary emphasis |
| Locked silhouette with requirement | Keep requirement information; avoid making the whole row unreadable |
| Far-future hidden | Override for the small Phase 2 catalog |
| No early-game scrolling | Preserve with compact rows |
| Next goal always visible | Strengthen |

Showing the entire eventual game catalog is a separate choice. For the complete game, tabs or tier sections can preserve visibility without presenting dozens of disabled entries at once.

A resource-backed affordability bar fits idle-game progression well because it communicates distance to a purchase. It must represent money available now, not elapsed time or guaranteed progress.

### Recommended row states

| State | Appearance | Action | Fill |
|---|---|---|---|
| Prerequisite locked | Readable, subdued; explicit requirement | Disabled | May show funds coverage, but lock remains unmistakable |
| Available, insufficient Gold | Normal identity; subdued action | Disabled | `clamp(Gold / cost, 0, 1)` |
| Almost affordable | Same state, slightly stronger emphasis | Disabled | Same calculation |
| Affordable | Clear enabled action; optional gentle pulse | Enabled | Full |
| Purchased | Compact completion treatment; retained effect summary | No buy action | Hidden |

“Within 20%” means a balance of at least `0.8 × cost`, excluding already affordable rows. Store that threshold in presentation configuration.

Important behavior:

- Spending elsewhere reduces all relevant bars.
- A fully funded locked row stays locked.
- Purchased rows stop pulsing and stop tracking affordability.
- Stable row positions avoid shifting a different action under the cursor.
- Ownership and eligibility come from the manager; the bar never authorizes a purchase.
- Avoid dimming the entire row to the current 45% alpha if that makes text hard to read.

### Proposed node trees

These are drafts for Claude’s approval plan, not permission to edit scenes.

```text
HUD (CanvasLayer)
└── RootMargin (MarginContainer; full rect)
    └── MainRow (HBoxContainer)
        ├── StatusColumn (VBoxContainer)
        │   ├── GoldRow (HBoxContainer)
        │   │   ├── GoldCaption (Label)
        │   │   └── GoldValue (Label)
        │   ├── IncomeRow (HBoxContainer)
        │   │   ├── IncomeCaption (Label)
        │   │   └── IncomeValue (Label)
        │   ├── SpeedRow (HBoxContainer)
        │   │   ├── SpeedCaption (Label)
        │   │   └── SpeedValue (Label)
        │   ├── HealthBar (ProgressBar)
        │   └── WaveTimer (Label)
        ├── PlayColumn (VBoxContainer; expand horizontally)
        │   ├── PlaySpace (Control; expand vertically)
        │   └── SpinCenter (CenterContainer)
        │       └── SpinColumn (VBoxContainer)
        │           ├── BoostBar (ProgressBar)
        │           └── SpinButton (Button)
        └── ShopPanel (PanelContainer)
            └── ShopMargin (MarginContainer)
                └── UpgradeRows (VBoxContainer)
```

Transparent structural controls and the play-space spacer should ignore mouse input. Interactive controls and the shop panel must consume it. Otherwise a full-screen HUD wrapper can accidentally swallow world clicks.

```text
UpgradeRow (PanelContainer; UpgradeRow script)
└── RowMargin (MarginContainer)
    └── RowColumn (VBoxContainer)
        ├── MainLine (HBoxContainer)
        │   ├── DescriptionColumn (VBoxContainer; expand horizontally)
        │   │   ├── UpgradeName (Label)
        │   │   ├── UpgradeEffect (Label)
        │   │   └── RequirementOrOwnership (Label)
        │   └── PurchaseButton (Button)
        └── AffordabilityBar (ProgressBar)
```

Keep tunable spacing, sizes, colors, pulse periods, and formatting in exports, Themes, or Resources.

## 7. Short calculation sketches and GdUnit4 cases

The following helper expresses proposed contracts. Production balancing values come from configuration; test numbers are deliberate fixtures.

```gdscript
class_name CarouselFeedbackMath
extends RefCounted


static func speed_multiplier(
        actual_speed: float,
        base_speed: float
) -> float:
    return actual_speed / base_speed if base_speed > 0.0 else 0.0


static func affordability_fraction(gold: float, cost: float) -> float:
    if cost <= 0.0:
        return 1.0
    return clampf(gold / cost, 0.0, 1.0)


static func booth_rate(
        horses: int,
        booths: int,
        speed_rad_s: float,
        payout: float
) -> float:
    return float(horses * booths) * speed_rad_s / TAU * payout


# Forward-only motion. Count crossings in (previous, current].
# phase is a fixed crossing angle in the same unwrapped coordinate system.
static func count_forward_passes(
        previous: float,
        current: float,
        phase: float
) -> int:
    if current <= previous:
        return 0
    return (
        floori((current - phase) / TAU)
        - floori((previous - phase) / TAU)
    )
```

For a Horse offset `h` and booth bearing `b`, the corresponding carousel phase is `b - h`. Do not use this calculation across an interval where placement changes; reset the baseline instead.

Representative tests use GdUnit4’s typed assertion families. [GdUnit4 assertions](https://godot-gdunit-labs.github.io/gdUnit4/latest/testing/assert/).

```gdscript
class_name CarouselFeedbackMathTest
extends GdUnitTestSuite

const EPSILON: float = 0.000001


func test_speed_uses_original_base_as_reference() -> void:
    assert_float(CarouselFeedbackMath.speed_multiplier(
        deg_to_rad(54.0), deg_to_rad(45.0)
    )).is_equal_approx(1.2, EPSILON)


func test_wrapped_boundary_is_one_forward_crossing() -> void:
    assert_int(CarouselFeedbackMath.count_forward_passes(
        deg_to_rad(179.0), deg_to_rad(181.0), PI
    )).is_equal(1)


func test_exact_endpoint_is_not_paid_again() -> void:
    assert_int(CarouselFeedbackMath.count_forward_passes(
        -0.1, 0.0, 0.0
    )).is_equal(1)
    assert_int(CarouselFeedbackMath.count_forward_passes(
        0.0, 0.1, 0.0
    )).is_equal(0)


func test_two_full_turns_pay_twice() -> void:
    assert_int(CarouselFeedbackMath.count_forward_passes(
        0.25, 0.25 + 2.0 * TAU, 0.0
    )).is_equal(2)


func test_no_travel_pays_nothing() -> void:
    assert_int(CarouselFeedbackMath.count_forward_passes(
        PI, PI, PI
    )).is_equal(0)


func test_booths_and_horses_multiply_income() -> void:
    assert_float(CarouselFeedbackMath.booth_rate(
        2, 2, deg_to_rad(45.0), 5.0
    )).is_equal_approx(2.5, EPSILON)


func test_affordability_tracks_spending() -> void:
    assert_float(CarouselFeedbackMath.affordability_fraction(
        24.0, 30.0
    )).is_equal_approx(0.8, EPSILON)
    assert_float(CarouselFeedbackMath.affordability_fraction(
        9.0, 30.0
    )).is_equal_approx(0.3, EPSILON)


func test_smoothing_is_consistent_for_a_constant_target() -> void:
    var one_step: float = SpinResponseMath.approach_speed(
        1.0, 1.5, 0.1, 0.1
    )
    var two_steps: float = SpinResponseMath.approach_speed(
        1.0, 1.5, 0.05, 0.1
    )
    two_steps = SpinResponseMath.approach_speed(
        two_steps, 1.5, 0.05, 0.1
    )

    assert_float(one_step).is_equal_approx(two_steps, EPSILON)
    assert_bool(one_step > 1.0 and one_step < 1.5).is_true()
```

The smoothing test applies to a constant target. It does not establish tick-rate-independent integration for a decaying target.

Claude’s plan should additionally specify integration cases:

| Case | Required assertion |
|---|---|
| Spin activation | Boost increases; Gold balance and earned-income total do not |
| Enemy activation | One damage request; no boost request |
| Empty-space click with button design | No gameplay action |
| Spin button GUI event | Exactly one boost, with no world-input fallthrough |
| Fully funded prerequisite lock | Row visible, purchase disabled, ownership unchanged |
| Purchase | Row remains visible in purchased state; duplicate purchase rejected |
| Mount/booth reposition | No payment caused by placement |
| Two booths crossed in one tick | Both valid passes paid exactly once |
| Drag ≥ 1 | Actual speed and new pass income are zero, including with smoothing |
| Different render frame counts | Same physics history produces identical Gold and pass totals |
| Actual income window | Spending does not reduce earned Gold/sec |

If strict Horse-only income is approved, replace the planned enemy-death payout expectation with **death occurs once and awards no Gold**. Death cleanup still needs exactly-once behavior.

## 8. Suggested order of work

1. **Diagnose and fix rotation presentation.** Try built-in interpolation first. Establish a smooth no-input baseline.
2. **Add HUD labels, effective-speed multiplier, and boost bar.** This makes subsequent playtests interpretable.
3. **Add the dedicated spin control and remove click Gold.** Test routing before Leaves introduce overlapping targets.
4. **Keep shop rows visible with affordability progress and purchased states.**
5. **Repeat the opening playtest using actual pass events.** Record first purchase time, press frequency, and time spent without an understandable goal.
6. **Settle whether Horse–booth passes are the exclusive Gold source before Step 6.** Update the planned enemy reward behavior accordingly.
7. **Continue Leaves, latch, waves, and Wolf.** Judge economic pacing with the actual pressure loop.
8. **Evaluate additional booths/Horse tiers afterward.** Treat duplicate Horses as a separate scope decision.

Each implementation step still needs Claude’s plan, Garret’s scene approval, and `tools\check.bat` after changes.

## Open questions / uncertain

- **Control choice:** recommendation is a dedicated button. Garret should choose button-only or carousel-surface activation; hold-to-crank changes the boost cadence and needs separate tuning.
- **Income scope:** does “Gold only from Horse passing a booth” literally remove kills, bosses, early-wave rewards, Unicorn income, and off-booth Horse Tier 3 income? The memo recommends making that scope explicit before Step 6.
- **Mount scope:** recommendation is unique mounts plus booth/payout progression. Duplicate Horses require approved replacement and six-slot progression rules.
- **Booth layout:** evenly redistributing three booths moves the existing opposite pair. Fixed placement preserves continuity but gives uneven spacing at three.
- **Smoothing:** recommendation is interpolation first. Exponential speed response is an optional mechanic change with a decay tail, not a confirmed bug fix.
- **Diagnosis limits:** no live frame trace or running build was inspected. Stable documentation and upstream source support the proposed investigation, but do not prove a 4.7.2-specific cause.
- **Pacing assumptions:** zero starting Gold, constant payout, no drag in baseline estimates, and no placement payment. Initial Horse phase affects the first purchase time.
- **Document precedence:** the older economy memo calls fixed hit damage unapproved; GDD v1.4 and the approved Phase 2 goals already specify it. Those newer documents should govern.
- **CLAUDE.md:** its contents were not included in the supplied material, and no file-reading tool was available without running a command. The memo follows the supplied rules; Claude must read the full file before planning implementation.
- **Validation:** sketches and tests are unexecuted; no project files were changed.
- **DECISION PENDING:** death/fail-state and prestige remain unresolved and untouched.