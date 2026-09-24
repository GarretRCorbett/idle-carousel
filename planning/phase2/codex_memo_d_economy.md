## Recommended starting values

**Use additive permanent spin upgrades, fixed Wolf damage per hit, and individually priced one-time purchases.** These starting prices target Wolf at roughly **2:10–2:45** and all five purchases at **4:30–5:00** during light active play.

| Setting / purchase | Starting value | Effect / rationale |
|---|---:|---|
| Base spin | **45°/s** | One revolution every 8 seconds |
| Horse payout | **5 Gold/pass** | **0.625 Gold/s** without boosts or drag |
| Spin Speed 1 | **30 Gold** | Adds 20% of base speed; permanent total **+20%** |
| Spin Speed 2 | **110 Gold** | Adds 30% of base speed; permanent total **+50%** |
| Click Damage 1 | **40 Gold** | **1 → 2 damage**; fresh Leaf takes **2 → 1 clicks** |
| Mount Slot 2 | **50 Gold** | Separate prerequisite purchase for placing Wolf |
| Wolf | **50 Gold** | Preserve existing unlock cost and **1 damage/hit** |
| Eligible play-area click | **0.25 Gold** | Fixed burst, only when no enemies are latched |
| Leaf reward | **1 Gold** | Given baseline; verify Resource default |
| Wave timing for this estimate | **3–5 Leaves every 20 seconds** | Assumed mean: 4 Leaves, yielding **0.2 Gold/s** when all are killed |

These are proposed tuning values for Garret’s approval. **Fixed Wolf hit damage requires an explicit GDD amendment** because the current text promises harder hits at higher speed.

## 1. Upgrade stacking and readability

### What the reference games actually do

Neither reference follows a universal “additive within each category” rule.

| Game | Representative stacking behavior |
|---|---|
| **Cookie Clicker** | Ordinary building-efficiency doublings compound: two ×2 upgrades produce ×4. Flavored-cookie production bonuses also generally multiply individually: five +2% upgrades give `1.02⁵`, not `1 + 0.10`. Some other systems accumulate contributions additively, including clicking upgrades that add a share of CpS. |
| **Clicker Heroes** | Hero damage combines several multiplicative factors. Global DPS upgrades can compound even within the same category: Betty Clicker’s four +20% bonuses produce `1.2⁴ = 2.0736`. Other categories accumulate additively: seven click upgrades contributing 0.5% of DPS each total 3.5% of DPS. |

Sources: Cookie Clicker’s [upgrades](https://cookieclicker.wiki.gg/wiki/Upgrades), [production formula](https://cookieclicker.fandom.com/wiki/Cookies_per_Second), and [click formula](https://cookieclicker.wiki.gg/wiki/Cookies_per_Click); Clicker Heroes’ [formulas](https://clickerheroes.fandom.com/wiki/Formulas) and [upgrade categories](https://clickerheroes.fandom.com/wiki/Upgrades).

**Recommendation: keep the proposed additive spin system.** Four clearly defined upgrades are easy to understand, and their increasing increments avoid negligible later gains:

| Purchased through | Permanent bonus | Speed multiplier | Speed without boost/drag | Gain over previous speed |
|---|---:|---:|---:|---:|
| Spin 1 | +20% | 1.20× | 54°/s | 20% |
| Spin 2 | +50% | 1.50× | 67.5°/s | 25% |
| Spin 3 | +100% | 2.00× | 90°/s | 33.3% |
| Spin 4 | +175% | 2.75× | 123.75°/s | 37.5% |

Multiplying all four upgrades instead would give **4.095×** base speed.

### Display the result, not just the increment

Player discussion supports clear notation and previews, rather than establishing that everyone prefers additive math. Some players expect `+%` to add and `×` to multiply; others dislike additive bonuses when their actual benefit is hidden. [Notation discussion](https://www.reddit.com/r/incremental_games/comments/qbdcuo), [additive-bonus complaints](https://www.reddit.com/r/incremental_games/comments/16snoif).

For Garret’s UI wording, expose these **numeric fields**:

- Permanent bonus: **+50%** after Spin 2.
- Spin 2 preview: **+20% → +50%**, with **54 → 67.5°/s** available in details.
- Clarification: the added 30% is measured against **base speed**; the improvement over current speed is **25%**.
- Current effective speed: separate from the permanent bonus, since boost and drag change it.

Keep the approved calculation:

```text
effective_speed =
    base_speed
    × (1 + sum_of_permanent_spin_bonuses)
    × (1 + temporary_boost)
    × max(0, 1 − total_latch_drag)
```

The zero clamp prevents reverse rotation; it introduces **no positive minimum speed**.

## 2. Wolf damage versus spin speed

**Recommend frequency-only scaling for Phase 2, preserving `wolf.tres.base_damage = 1.0`.**

Let `s` be effective speed divided by the original 45°/s. For one continuously reachable enemy, ideal sustained damage scales as follows:

| Damage rule | Damage/hit | DPS scaling | DPS at 1.5× speed | DPS at half speed |
|---|---|---|---:|---:|
| Fixed | `D` | `s` | 1.50× | 0.50× |
| Square root | `D × sqrt(s)` | `s^1.5` | 1.84× | 0.35× |
| Linear | `D × s` | `s²` | 2.25× | 0.25× |

These are damage-throughput comparisons, not guaranteed kill-rate or Gold-rate multipliers.

Fixed damage has three advantages:

1. **Readable combat thresholds.** A fresh 2-health Leaf always needs two Wolf hits; one base click plus one Wolf hit also kills it.
2. **Less severe slowdown feedback.** Drag already delays the next attack. Reducing hit damage too can increase the required number of passes, causing further drag accumulation.
3. **Useful future damage upgrades.** Wolf Fang can change hits-to-kill directly, while spin upgrades improve attack frequency and booth income.

Square-root scaling adds fractional damage without necessarily changing Leaf kills: at 1.5× speed, a 1-damage Wolf deals approximately 1.225 damage and still needs two passes.

With Spin 1, the no-drag revolution takes **6.67 seconds**. A fresh Leaf requiring two Wolf contacts dies roughly **6.67–13.33 seconds** after entering continuous sweep coverage, depending on angular phase. Drag increases that delay.

Also, faster killing only increases combat Gold while enemies remain available. With four Leaves arriving every 20 seconds, sustained kill income eventually caps at **0.2 Gold/s**.

**Planning change:** amend the GDD’s speed-dependent damage statements explicitly. If Garret retains “faster sweep = harder hit,” square-root scaling is the gentler alternative, but it needs separate approval and testing of slowdown thresholds.

## 3. Cost curves and the first five minutes

### Use milestone prices for this shop

The familiar exponential purchase formula is:

```text
next_cost = starting_cost × growth_factor^number_already_owned
```

Cookie Clicker buildings use approximately **1.15×** per additional building, before discounts and rounding. Most ordinary Clicker Heroes hero levels use **1.07×**, with exceptions. These describe repeat purchases of the same producer or hero—not prices across unrelated one-time upgrades. [Cookie Clicker building prices](https://cookieclicker.wiki.gg/wiki/Buildings), [Clicker Heroes cost formulas](https://clickerheroes.fandom.com/wiki/Formulas).

For these five purchases, use independent `.tres` costs. Balance their wait times and benefits directly. Exponential costs paired with slower production growth eventually create longer waits; the growth factor alone does not establish good pacing. [Kongregate’s idle-economy analysis](https://www.kongregate.com/en/pages/the-math-of-idle-games-part-i).

There is no reliable universal “first purchase at 30–60 seconds” convention. Treat that as **Idle Carousel’s onboarding target**: early visible progress, then automation, then another meaningful upgrade before minute five.

### Income model

```text
booth_gold_per_second = 5 × effective_speed_degrees / 360
combat_gold_per_second = actual_kills_per_second × 1
click_gold_per_second = eligible_play_area_clicks_per_second × 0.25
```

An eligible click is a play-area click made with zero latched enemies. Enemy clicks do not also receive the burst.

| Permanent upgrades | Booth Gold/s, without boost/drag |
|---|---:|
| None | `5 × 45 / 360 = 0.625` |
| Spin 1 | `5 × 54 / 360 = 0.750` |
| Spin 1 + 2 | `5 × 67.5 / 360 = 0.9375` |

For the light-active estimate, assume:

- All spawned Leaves eventually die: **0.2 Gold/s**.
- One eligible play-area click per 2.5 seconds on average: **0.1 Gold/s**.
- Average combined boost-and-drag factor of **1.0** for this calculation. This is a modeling assumption, not a proposed mechanic.

Thus:

```text
Before Spin 1: 0.625 + 0.2 + 0.1 = 0.925 Gold/s
After Spin 1:  0.750 + 0.2 + 0.1 = 1.050 Gold/s
After Spin 2:  0.9375 + 0.2 + 0.1 = 1.2375 Gold/s
```

### Suggested purchase path

| Purchase | Cost | Approximate time since start |
|---|---:|---:|
| Spin 1 | 30 | **0:32** |
| Slot 2 | 50 | **1:20** |
| Wolf | 50 | **2:08** |
| Click Damage 1 | 40 | **2:46** |
| Spin 2 | 110 | **4:31** |

For example:

```text
Wolf time = 30 / 0.925 + (50 + 50) / 1.05
          ≈ 128 seconds

All-five time = 30 / 0.925 + (50 + 50 + 40 + 110) / 1.05
              ≈ 271 seconds
```

The total spend is **280 Gold**.

These are continuous-rate estimates. Actual earnings arrive in 5-Gold booth payments and discrete kills, so measured purchase times will differ.

### Sensitivity and purchase choices

| Scenario, same purchase order | First purchase | Wolf | All five |
|---|---:|---:|---:|
| Light active model above | 0:32 | 2:08 | 4:31 |
| Same kills, no Gold-generating clicks | 0:36 | 2:22 | 5:00 |
| Booth only, no drag | 0:48 | 3:01 | 6:21 |

The second row still requires enemy clicking before Wolf. The third is an income baseline, **not a prediction of hands-off survival**.

Buying Click Damage immediately after Spin 1 moves Wolf to approximately **2:46** in the light-active model. Buying Spin 2 before the slot/Wolf pair moves Wolf to approximately **3:38**, although all five still finish around **4:11**.

Therefore, the Wolf timing target depends on purchase order. Make the **100-Gold slot-plus-Wolf commitment** visible before buying the slot; do not add new prerequisite locks merely to enforce the benchmark.

At four eligible clicks per second, click bursts alone generate **1 Gold/s**, exceeding starting booth income. The proposed value supports light clicking, but rapid clicking will accelerate progression. Measure that separately.

Spin 2’s booth-only marginal gain is **0.1875 Gold/s**, so its **110-Gold** cost takes approximately **587 seconds** to repay through booth income alone. Its Phase 2 purpose also includes faster combat and visible progression; do not describe it as a quick financial payback.

## 4. Click Damage 1

Use **1 base damage**, with a **flat +1 damage** upgrade:

```text
clicks_to_kill = ceil(remaining_health / click_damage)
```

For a fresh Leaf:

- Before: `ceil(2 / 1) = 2 clicks`.
- After: `ceil(2 / 2) = 1 click`.

The upgrade halves the required click count, while each Leaf still drops **1 Gold**. It raises realized income only when faster clearing prevents missed kills or reduces latch drag.

Keep click damage independent of spin speed. This preserves a dependable way to clear enemies when the carousel stops.

## 5. Implementation sketches and tests

These are proposed interfaces, not claims about existing scripts. Keep tuning values in the existing mount/enemy/upgrade Resources and exported click/spin settings. Give Wolf’s purchase cost one authoritative source.

A small pure calculation helper is sufficient; no new scene tree is needed:

```gdscript
class_name Phase2EconomyMath
extends RefCounted


static func effective_speed(
        base_degrees: float,
        purchased_bonuses: Array[float],
        boost_bonus: float,
        total_drag: float
) -> float:
    var permanent_bonus: float = 0.0
    for bonus: float in purchased_bonuses:
        permanent_bonus += bonus

    return (
        base_degrees
        * (1.0 + permanent_bonus)
        * (1.0 + boost_bonus)
        * maxf(0.0, 1.0 - total_drag)
    )


static func booth_rate(
        gold_per_pass: float, speed_degrees: float
) -> float:
    return gold_per_pass * deg_to_rad(speed_degrees) / TAU


static func play_area_gold(
        gold_per_click: float, latched_count: int
) -> float:
    return gold_per_click if latched_count == 0 else 0.0
```

Here `0`, `1`, and `TAU` are mathematical constants, not balance tunables. Godot supplies [`deg_to_rad`, `maxf`, and `TAU`](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html).

The booth-rate function is for forecasts and tests. **Actual booth income still comes from pass events**, and the HUD retains its rolling average of actual earnings.

Representative GdUnit4 cases:

```gdscript
class_name Phase2EconomyMathTest
extends GdUnitTestSuite


func test_spin_bonuses_add_and_predict_booth_rate() -> void:
    var bonuses: Array[float] = [0.20, 0.30]
    var speed: float = Phase2EconomyMath.effective_speed(
        45.0, bonuses, 0.0, 0.0
    )

    assert_float(speed).is_equal_approx(67.5, 0.000001)
    assert_float(
        Phase2EconomyMath.booth_rate(5.0, speed)
    ).is_equal_approx(0.9375, 0.000001)


func test_drag_can_stop_without_reversing() -> void:
    var bonuses: Array[float] = [0.20, 0.30]
    var speed: float = Phase2EconomyMath.effective_speed(
        45.0, bonuses, 0.0, 1.20
    )

    assert_float(speed).is_equal(0.0)
    assert_bool(speed < 0.0).is_false()


func test_click_upgrade_crosses_leaf_health_threshold() -> void:
    var leaf_health: float = 2.0
    var base_damage: float = 1.0
    var upgrade_damage: float = 1.0

    assert_int(ceili(leaf_health / base_damage)).is_equal(2)
    assert_int(
        ceili(leaf_health / (base_damage + upgrade_damage))
    ).is_equal(1)


func test_latch_blocks_play_area_gold() -> void:
    assert_float(
        Phase2EconomyMath.play_area_gold(0.25, 0)
    ).is_equal(0.25)
    assert_float(
        Phase2EconomyMath.play_area_gold(0.25, 1)
    ).is_equal(0.0)
```

Claude’s implementation plan should additionally include integration tests for:

- Purchasing/reloading Spin 1 and 2 produces **1.5×**, without applying either twice.
- Wolf deals **1 damage per contact** at different speeds; a fresh Leaf needs two contacts.
- Enemy clicks and UI clicks never award the play-area burst.
- Slot purchase alone neither places Wolf nor awards Gold.
- HUD income counts earnings, excluding purchase spending.
- A deterministic pacing fixture records purchase times using actual pass and kill events.

Use signals for purchase and income notifications. Preserve world-space enemies under `EnemyLayer`. Run `tools\check.bat` after implementation changes.

## Open questions / uncertain

- **Wolf scaling:** fixed hit damage is a recommendation requiring a GDD change, not an already approved decision.
- **Pacing assumptions:** starting Gold is zero; waves average four Leaves every 20 seconds; kills keep pace with spawning. Actual boost, drag, approach timing, and stalls remain unmeasured.
- **Purchase order:** the proposed prices meet the Wolf target when players prioritize automation or buy Click Damage first; rushing Spin 2 delays Wolf.
- **Fractional Gold:** 0.25-Gold clicks need a display that reveals quarter-Gold progress. Garret should choose the presentation and write all final UI text.
- **Resource defaults:** the supplied Leaf file omits `gold_drop`; confirm its inherited value is 1.0.
- **Validation limits:** these are calculated estimates and unexecuted sketches. CLAUDE.md was not included, and the environment blocked reading it; Claude must check its full rules before planning.
- **DECISION PENDING:** death/fail-state and prestige decisions remain untouched.