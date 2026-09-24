# Codex memo M: tiers, waves, bosses, and pacing (Phase 3)
*Codex (GPT), 2026-09-24, read-only research. Input, not decisions; see README.md for what Claude agrees with.*


**Build Phase 3 around sustainable farming and deliberate boss attempts.** Pull the minimum kill gate and a small balance simulator forward now. Use modest enemy scaling, meaningful mount upgrades, and individually priced milestones to support the three-hour run.

Everything below is input for Garret, not an approved design. New numbers are starting guesses. I read the requested files and relevant supporting scripts; I did not modify files, run the game, or run checks.

The current implementation takes precedence over historical memo D: clicks generate no Gold, Wolf deals 1.5 damage, reciprocal drag is implemented, and purchases have levels.

**1. Tier progression should separate unlocking, farming, and attempting a boss.**

Recommended loop:

1. Enter an unlocked tier voluntarily.
2. Fight ordinary waves, improve the build, and accumulate that tier’s qualifying kills.
3. Meeting the gate makes its boss available.
4. Start the boss manually when ready.
5. Victory permanently unlocks the next tier and its associated purchases.
6. Choose whether to advance immediately or continue farming.

Pull this minimal gate into Phase 3. Boss testing needs the real progression path; adding it afterward risks retuning every encounter. Leave the polished progression display and full shop visibility system in Phase 4.

Try gates of **60 / 80 / 100 / 120 / 140 / 160 kills**, Grey through Red. With the wave proposal below, these take approximately four to five minutes of successful automatic waves. The notes’ suggested 10–20 kills would take roughly one minute in Grey and less later.

These gates establish exposure to a tier; they do **not** establish combat readiness or enforce the intended tier duration. Clicking and early sending can accelerate them. Avoid making kill quotas carry the three-hour pacing target.

Count actual ordinary-enemy kills, including early-sent waves. Exclude Emergency Clear, retreat removals, boss summons, and boss split children. Credit the enemy’s original tier, not whichever tier is selected when it dies. Preserve accumulated eligibility through retreat and failed attempts.

Allow free selection of previously unlocked farming tiers. Keep separate records for:

- Highest unlocked tier.
- Currently selected tier.
- Preferred fallback farming tier.

A lower tier should remain useful because clearing it reliably preserves booth production. It should not pay better combat rewards than a sustainable higher tier.

For boss entry, pause ordinary spawning and let existing enemies finish before the attempt begins. During the attempt:

- Ordinary waves stay paused.
- Send Wave is unavailable.
- Only the boss’s own summons appear.
- The player’s Auto Wave preference remains unchanged.
- Leaving the encounter restarts a full countdown; paused time never becomes queued waves.

Treat boss victory as one encounter completion, after required children or latch targets are defeated. Award its large Gold bonus once. I would omit repeatable boss farming from the first implementation.

After Red, reveal the Rusted King encounter but retain a deliberate start. Its actual implementation remains Phase 5.

**Failure remains DECISION PENDING.** Package A gives the intended boundary: an unsuccessful push costs the attempt and earning time, never banked Gold or permanent unlocks. It does not yet settle whether the first stall ends a boss attempt, whether a successful crank preserves it, or when fallback occurs.

The existing 60-second stall safety net is not a completed boss-failure policy: waves continue, recovery is partial, and cranking resets the stall timer. Keep boss failure handling replaceable. Do not accidentally turn temporary cleanup into victory or a permanent failure rule.

**2. Scale wave pressure through recognizable combinations before increasing everything at once.**

Use authored wave recipes with controlled variation. Independent random rolls for every enemy make accidental Rock-heavy waves difficult to tune.

Here is a starting schedule. L/S/R means Leaf/Stick/Rock; percentages describe enemy counts, not recipe-selection probabilities.

| Tier | Starting recipes | Approximate L/S/R mix | Mean enemies | Interval |
|---|---|---:|---:|---:|
| Grey | Initially 3–5 L; later add 1 S every fourth wave | 94/6/0% after introduction | 4.25 | 20 s |
| Green | 3–5 L + 1 S; add 1 R every fourth wave | 76/19/5% | 5.25 | 20 s |
| Blue | 3–5 L + 2 S; add 1 R every other wave | 62/31/8% | 6.5 | 18 s |
| Purple | 5 L + 2 S + 1 R | 63/25/13% | 8 | 17 s |
| Gold | 6 L + 2 S + 1 R | 67/22/11% | 9 | 16 s |
| Red | 6 L + 3 S + 1 R | 60/30/10% | 10 | 15 s |

Introduce the first Stick after approximately **40 Grey kills**, ordinarily around the time Wolf automation is established. Introduce the first Rock after **40 Green kills**. These are teaching milestones, not additional boss requirements.

Keep Leaf subgroups at 3–5, Sticks alone or paired, and Rocks alone. A six-Leaf wave can contain two three-Leaf groups. Start with one arrival direction; introduce two directions in Blue, then occasionally three in Gold/Red. Preserve enough clustering for Lion’s wide arc to matter.

Do not add endless within-tier escalation. Once a player establishes sustainable farming, that tier should stay sustainable. Pressure increases through tier selection and voluntary early sends.

Existing controls remain important:

- **Auto waves:** use the listed interval even if enemies remain. Sustainability means keeping up with this indefinitely.
- **Send Wave:** preserve the existing +50% Gold on that wave’s actual kills and full countdown restart. Apply it to every ordinary enemy type.
- **Emergency Clear:** preserve the normal-booth-income price, minimum 25 Gold, and 60-second cooldown.

There is currently no meaningful limit on repeated manual sends. Wolf pierces, so many stacked waves can be killed by the same sweeps. Resetting the countdown prevents a coincident automatic wave; it does not prevent deliberate stacking.

Test rapid sending explicitly. If it dominates progression, my first proposed restriction would be **one unresolved manually sent wave at a time**, while automatic waves retain their normal behavior. That would be a change to the current control contract and needs Garret’s approval.

Emergency Clear should remove eligible ordinary latches without Gold, healing, or kill credit. Boss bodies, mandatory split children, and boss latch points should be excluded. Optional boss summons can remain clearable.

This requires changing both sides of the current clear operation: GameState currently clears **all** latch records, while Game removes latched enemy nodes. Filtering only the nodes would leave surviving bosses with no registered drag or damage.

**3. Use modest health and reward scaling, with slower growth in latch damage.**

For zero-based tier index `t`, Grey = 0 and Red = 5:

```text
health(type, t) = base_health(type) × 1.40^t
kill_gold(type, t) = base_gold(type) × 1.45^t
latch_DPS(type, t) = proposed_base_DPS(type) × 1.10^t
movement_speed(type, t) = base_speed(type) × 1.03^t
```

Keep ordinary latch drag unchanged across tiers initially.

| Enemy | Base health | Base Gold | Proposed base latch DPS | Drag | Base movement |
|---|---:|---:|---:|---:|---:|
| Leaf | 2 | 2 | 0.5 | 0.05 | 90 |
| Stick | 4 | 3 | **0.9** | 0.12 | 50 |
| Rock | 8 | 8 | **1.5** | 0.30 | 25 |

Stick and Rock currently have 2 and 4 latch DPS. I would lower these before multiplying them across tiers. Their longer survival already increases total damage and suppresses clean-rim regeneration.

The resulting health curve is:

| Tier | Leaf | Stick | Rock |
|---|---:|---:|---:|
| Grey | 2.00 | 4.00 | 8.00 |
| Green | 2.80 | 5.60 | 11.20 |
| Blue | 3.92 | 7.84 | 15.68 |
| Purple | 5.49 | 10.98 | 21.95 |
| Gold | 7.68 | 15.37 | 30.73 |
| Red | 10.76 | 21.51 | 43.03 |

This deliberately avoids ×2 health every tier. Existing flat damage upgrades cannot support that curve comfortably.

Preserve frequency-only speed scaling:

```text
turns_per_second =
    base_degrees_per_second / 360
    × (1 + 0.20 × Carousel_Speed_level)
    × boost_factor × temporary_speed_modifiers
    / (1 + total_drag)

booth_Gold_per_second =
    booths × turns_per_second × sum(Horse payouts per pass)

Wolf_damage_per_hit =
    (1.5 + 0.5 × Wolf_Fang_level) × explicit_mount_tier_multiplier

click_damage = 1 + 0.5 × Click_Damage_level
```

The Wolf mount-tier multiplier is a proposal, not an existing implementation. Start by testing **×2 at Wolf Tier 2**, applying to base damage plus Fang. Define Tier 3’s damage trail separately rather than assuming another doubling.

Useful thresholds:

- Current Wolf needs two passes for a Grey Leaf.
- Fang 1 raises damage to 2, making Grey Leaves one-pass kills.
- Fang 3 reaches 3, making Green Leaves one-pass kills.
- Fang 5 reaches 4, making Blue Leaves one-pass kills.
- Maximum Fang gives 6.5; Tier 2 would make that 13, enough for a Red Leaf in one hit.

Click Damage currently tops out at 6. Against the proposed Red enemies, that means **2 / 4 / 8 clicks** before Combo. Clicking remains useful without requiring a new click-damage progression system.

Do not automatically multiply Horse payout by enemy tier. Horse Tier 2 supplies its explicit doubling. Additional booths and speed supply the rest.

The existing Eagle and Lion damage values, both 0.75, need deliberate review. At Red, they would barely damage a Leaf without further effects. Lion also cannot justify its slot simply by “hitting multiple enemies”: Wolf already pierces. Test its earlier contact, wider coverage, and knockback as measurable advantages.

**4. Use a three-hour purchase schedule as a target, then test whether the economy actually produces it.**

First, test **60°/s base speed**, up from 45°/s. That changes a starting revolution from eight to six seconds and starting booth income from 0.625 to 0.833 Gold/s.

Keep the initial 30-Gold speed upgrade, 60-Gold slot, and 80-Gold Wolf while testing this change. Aim for Wolf at **two to three minutes** and the first one-pass Leaf breakpoint shortly afterward. Do not increase starting prices immediately to cancel the improvement.

The following is a planning envelope for an intermittently attentive player, using automatic waves, one permanent Horse, no sustained Overdrive, and no random-event income. Rates are proposed tier averages, not simulation results.

| Stage | Minutes; cumulative end | Mean recurring Gold/s | Purchases and intended payoff |
|---|---:|---:|---|
| Grey | 18; 18 | ~1.5 | Speed 1–3, slots 2–3, Wolf, early Fang/Click levels, Turtle or Eagle; booth 2 potentially late |
| Green | 25; 43 | ~6 | Slot 4, remaining Turtle/Eagle, booth 2 if needed, Horse Tier 2, early health upgrade |
| Blue | 30; 73 | ~12 | Slot 5, Lion, booth 3, Wolf Tier 2, another mount Tier 2 |
| Purple | 35; 108 | ~18 | Slot 6, third distinct mount at Tier 2, Unicorn access, booth 4, first major combat ability |
| Gold | 35; 143 | ~27 | Unicorn upgrades, selected Tier 3 mounts, Pack/Dive/knockback, later health and economy upgrades |
| Red | 30; 173 | ~35 | Finish the chosen build, final damage breakpoints, remaining major upgrades |
| Rusted King | 7; 180 | Build-dependent | Preparation and approximately 3–4 minutes fighting |

All six mount types should become usable by late Purple or early Gold. Players need time to enjoy Unicorn before the ending.

With the proposed waves and reward formula, fully cleared automatic waves produce approximately **0.44 / 0.94 / 2.10 / 4.30 / 7.18 / 12.39 combat Gold/s**. The rest must come from the economic engine.

For comparison, at the proposed 60°/s base speed, maximum Carousel Speed, four booths, and one Tier 2 Horse:

```text
4 booths × 0.5 turns/s × 10 Gold/pass = 20 Gold/s
```

Red ordinary combat adds about 12.4 Gold/s before Gold bonuses. This supports a roughly 35-Gold/s late economy without making combat replace Horses.

The table implies approximately **190,000 recurring Gold earned before the final encounter**, plus boss bonuses. That is a useful budget constraint, not evidence that the game already lasts three hours. If the winning purchase path costs only 60,000 Gold, players will finish much earlier. If it requires 300,000, the table does not fund it.

Current prices have several problems:

- **Booths:** 500 + 750 + 1,125 = **2,375 Gold total**. They cannot remain meaningful purchases across six tiers at the proposed income rates.
- **Carousel Speed:** all ten levels cost about **3,400 Gold**. The last level costs about 1,153 but improves speed from ×2.8 to ×3: only 7.1%.
- **Click Damage:** all ten levels cost about **2,833 Gold**. This becomes a cheap completed track later.
- **Boost Power:** all ten levels cost about **4,533 Gold**. Cheap late maxing greatly widens the active/passive gap.
- **Wolf Fang:** its actual growth is **×1.6**, not ×1.5. All levels cost about **18,159 Gold**; the last costs about 6,872 for +0.5 damage. That purchase needs a useful breakpoint.
- **Slots:** extending the existing ×2.5 curve gives slots 4–6 prices of approximately **375 / 938 / 2,344**. These are reasonable quick post-boss purchases, but should not be expected to pace entire tiers.

Starting price experiments:

- Booths 2–4: **500 / 2,500 / 8,000**.
- Turtle: **150**; Eagle: **300**; Lion: **1,500**; Unicorn: **7,500**.
- Horse Tier 2: **1,000**; other early Tier 2 upgrades: roughly **1,500–4,000**.
- Major combat abilities: approximately **4,000–8,000**.
- Late Tier 3 upgrades: approximately **8,000–15,000**, provided their effects warrant it.

These require explicit per-level prices or separate milestone definitions; one geometric curve is insufficient. They also change the GDD’s booth-price rule and need approval.

Keep early speed levels affordable. It is acceptable for that track to finish before Red if mount abilities supply later discoveries. Do not make every track last all six tiers.

The main “wow” moments should be automation, the first one-pass clear, doubled booth output, Horse Tier 2, another combat role joining, six occupied slots, and Unicorn sustain. Avoid placing several of these in one purchase burst followed by twenty quiet minutes.

Two economy definitions need clarification before promising the late curve:

- Horse Tier 3’s “Gold on every sweep” needs a precise trigger. Replacing four booth payments with one payment per revolution would be a downgrade.
- Extra Horses trade away combat slots. The forecast above assumes one Horse; extra-Horse builds need separate simulations, including the cost of selling them later.

**5. A small simulator is worth building in Phase 3.**

Pull the first version forward from Phase 5. Its purpose is to expose impossible budgets and dominant strategies while content is still cheap to change.

Prefer a **headless GDScript model that loads the actual Resources** and shares pure calculation functions with gameplay. Python is also reasonable, but avoid maintaining a second manually copied balance table.

Model:

- Purchases, prerequisites, slots, mount tiers, refunds, and Gold.
- Discrete rotations and booth payments.
- Wave arrival, enemy approach, sweep timing, drag, grace, damage, and regeneration.
- Kill gates and boss encounter states.
- Defined player input budgets.
- Explicit provisional failure-policy variants.

Run several simple policies:

- Automation first, then economy.
- Economy first, including extra Horses and waves off.
- Combat first.
- Occasional intervention.
- Sustained boosting and aggressive early sends as a stress case.

Include a purchase decision cadence. An optimizer buying immediately every frame is not an unattended player.

Output time to every purchase, boss eligibility, tier entry, boss victory, and final victory. Also report Gold by source, idle time spent saving, stalls, minimum health, maximum latch count, and the proportion of time spent boosted.

Run different wave seeds and initial sweep alignments. Report median and slow cases.

A first financial model can estimate combat clearance. Before trusting “safe forever,” it needs discrete sweep timing: average DPS misses the nearly full-revolution wait when an enemy arrives just after Wolf passes.

It cannot judge visual excitement, target-selection frustration, readable zigzags, or whether boosting feels like work. It also cannot settle the pending fail state. Compare its first ten minutes against play before trusting its three-hour forecast.

**6. Boss health should follow measured effective damage, while abilities provide the distinction.**

Use:

```text
boss health budget ≈ measured effective damage/second × target combat duration
```

Measure with the expected build, drag, resistance, target accessibility, and realistic player input. For multi-target bosses, aggregate health must be compared with aggregate damage across targets; Wolf can damage several targets during one revolution.

These are initial test fixtures:

| Encounter | Starting health budget | Target time | First-clear Gold |
|---|---:|---:|---:|
| Leaf Storm | 40 body + four 2-HP Grey Leaves | 45–60 s | 200 |
| Stick Giant | 100 | 60–75 s | 600 |
| Boulder | Three 180-HP targets; no extra body pool initially | 75–90 s | 1,200 |
| Gilded Gale | 360, plus summons | 75–100 s | 2,000 |
| Ancient Log | 600, plus opening resistance | 90–120 s | 3,000 |
| Obsidian Boulder | 900 body + two ~22-HP Purple Rocks | 100–130 s | 4,500 |
| Rusted King | 1,800 body + three 40-HP latch targets | 180–240 s | Victory; reward amount can wait |

These health values require validation. For example, Leaf Storm’s combined 48 HP implies approximately 0.8–1.1 effective DPS at the target duration. A highly active player can exceed that substantially.

The Gold bonuses are roughly one to two minutes of the proposed recurring income, enough to contribute toward the next milestone without buying the entire next tier.

Ability-specific guidance:

- **Leaf Storm:** completion waits for all four children. Their purpose is a cleanup burst, so do not inflate their health beyond the specified Grey Leaves.
- **Stick Giant:** zigzag should reduce interception reliability, not create repeated hits from crossing a sweep boundary. Once latched, it becomes a dependable Wolf target.
- **Boulder:** define total drag and total latch DPS, then distribute them across three points. Start near **0.36 total drag and 1 total DPS**, rather than accidentally applying three full Rock stat blocks.
- **Gilded Gale:** the GDD’s **two Gold Leaves every second** is the largest tuning concern. At this curve that adds 15.4 enemy HP every second, compared with ordinary Purple waves averaging about 0.47 enemies per second. It also creates profitable endless farming if summons pay normal Gold. I recommend testing **two Gold Leaves every four seconds**, with no summon Gold or gate credit. That is an explicit proposed GDD change. Keep the specified two-per-second version as a stress test.
- **Ancient Log:** retain Turtle immunity. Try **50% resistance on the first three damaging hits**, not complete immunity or permanent resistance. Test whether cheap clicks make the mechanic negligible. It should not require selling Turtle.
- **Obsidian Boulder:** victory waits for both Purple Rocks. Their inherited tier matters: under this curve they have about 22 HP each, not Red Rock health. Prevent recursive splitting and duplicate payouts.
- **Rusted King:** budget the three latch targets separately from body health. Reciprocal drag requires total drag around 9 to produce 10% speed; copying ordinary Rock drag will not create near-stop. Keep point health low enough that removing them is a rescue objective, not several minutes of immobility. Rust Breath and enrage need explicit cooldowns; try 20 seconds becoming 10 below 25% health, preserving the specified five-second damage reduction.

Do not scale boss latch damage using ordinary-enemy rules without checking fight length. At 100 carousel health, 2 sustained DPS consumes the entire health bar in 50 seconds, regardless of boss health.

Use a starting damage budget of roughly **40–60% of expected carousel maximum health over a successful attempt**, before avoidable adds. Existing clean-rim regeneration usually cannot help while the boss remains attached.

The Rusted King’s three Grey summons every 30 seconds will be trivial to a Red build. Preserve the specified mechanic initially, but do not count it as significant difficulty.

**7. Phase 3 needs stable state and event boundaries for Phase 4.**

The current GameState has Gold, upgrade levels, a roster of mount IDs, health, and transient combat state. It does **not** yet contain the GDD’s tier counters or durable progression records.

Add state when the corresponding Phase 3 feature arrives, with controlled mutation methods:

| State | Purpose |
|---|---|
| `current_tier`, `highest_unlocked_tier`, `preferred_farm_tier` | Separate selection, permanent progress, and fallback preference |
| `kills_by_tier` | Preserve gates when revisiting tiers |
| Completed boss IDs | Derive progression and prevent duplicate first-clear rewards |
| Upgrade ID → integer level | Retain the existing leveled model; do not serialize it as booleans |
| Ordered mount records with stable IDs, type, and tier | Distinguish multiple Horses and preserve progression |
| Permanent unlocked mount/upgrade milestones | Separate ownership, discovery, and placement where needed |
| Encounter kind, boss ID, and attempt identity | Coordinate entry, completion, abandonment, and later saving |
| Gold, health, active playtime, total earned Gold, kill totals | Save and future statistics/achievement support |

Derive slot capacity and boss eligibility from authoritative records where possible, rather than maintaining conflicting duplicate flags.

Reserve serialization fields for schema version, save timestamp, and eventual recovery state. Do not choose a service duration or load-time recovery behavior before the fail-state decision. Auto Wave already persists in settings; avoid creating a second conflicting copy.

Do not save Node references, instance IDs, latch dictionaries, or rolling HUD income as permanent progression. If Package A is confirmed, loading need not reconstruct a battlefield. It must still remember that an encounter was unfinished so reload cannot invent a victory or bypass the selected recovery rule.

Provide explicit events for enemy kills, removals, boss completion, purchases, and tier changes. An enemy death should identify its source tier, spawn origin, reward eligibility, and encounter membership. One generic “enemy disappeared” event cannot safely drive all these systems.

For the full UpgradeManager:

- Add data-driven boss requirements, prerequisite levels, and the three-distinct-mounts-at-Tier-2 condition.
- Make purchase validation enforce these requirements independently of the shop UI.
- Let visibility states derive from the same definitions.
- Preserve current atomic purchases and stable upgrade IDs.

For offline income, extend the normal-income calculation to account for Horse tiers and permanent economy modifiers. It currently reads the starting Horse payout directly. Do not use recent HUD Gold/s, which can contain kills and boss rewards.

For random events, keep temporary Horses and booths distinct from purchased ownership and six-slot capacity. Their expiry must not remove permanent objects. Extend the existing modifier-source approach to Gold effects; keep events out of the baseline pacing model and offline calculations.

The GDD also duplicates several effects between mount Tier 3 and named upgrades—Eagle double attacks, Turtle freeze, Lion knockback—and gives conflicting Prismatic Horn descriptions. These need explicit definitions before pricing the complete tree.

**8. The most likely failures are measurable early.**

- **Farming slowly drains health.** A build survives five minutes but eventually stalls. Run at least 20–30 unattended minutes per benchmark build and inspect health across successive waves. More maximum health delays a deficit; it does not fix it.
- **Waves off becomes the best economy.** Compare booth-only income with waves-on income after drag and clear costs. Ordinary combat should justify its pressure once mastered.
- **Repeated early sends exploit piercing.** Compare manual-send strategies against automatic waves before setting kill gates or late prices.
- **Clicking and Overdrive erase the pacing curve.** Maximum Boost plus Overdrive can reach ×5 unboosted speed. Test a finite shared input budget; do not assume continuous boosting and simultaneous rapid enemy clicking.
- **Turtle and Lion fail to justify slots.** Measure prevented latches, damage taken, and actual income against an extra Horse or another available combat role.
- **Unicorn arrives after the game is effectively won.** Track the third distinct Tier 2 purchase and the six-slot roster. Aim for at least 30–45 useful minutes afterward.
- **Bosses become health-bar waits or instant defeats.** Log effective DPS and incoming damage separately. Raising boss HP cannot repair an excessive latch-DPS budget.
- **Offline progression overwhelms the short campaign.** At 20 normal booth Gold/s, eight hours at 50% pays **288,000 Gold**, exceeding this proposed run’s economic budget. The existing cap and efficiency therefore need a deliberate pacing review in Phase 4.
- **Mount choices become permanent traps.** Currently only bought Horses can be sold. Test obtaining all six unique mounts after temporary extra-Horse purchases; do not assume combat mounts can be freely exchanged.

The earliest useful content slice is Grey and Green with Stick, Rock, Turtle/Eagle, two bosses, one mount-tier upgrade, and lower-tier selection. Validate that slice before multiplying its assumptions across all six tiers.

**9. Questions for Garret**

1. **What does the 2.5–3.5-hour target measure?**  
   Options: intermittently attentive online play; sustained active play; elapsed time including offline progress.  
   **Recommendation:** intermittently attentive online play, with faster expert runs acceptable.

2. **Should satisfying the kill gate summon the boss automatically?**  
   Options: automatic summon; manual challenge after eligibility.  
   **Recommendation:** manual challenge, with the minimal gate pulled into Phase 3.

3. **What should count toward boss eligibility?**  
   Options: ordinary tier kills only; all kills including summons; completed waves.  
   **Recommendation:** ordinary tier kills, retained through failure and retreat.

4. **When does a stall end a boss attempt? — DECISION PENDING**  
   Options: immediately; after a bounded rescue opportunity; only on retreat or automatic recovery.  
   **Recommendation:** bounded rescue, preserving Gold and unlocks. The exact rule remains Garret’s decision.

5. **Where should an abandoned push leave the player? — Part of the pending fail state**  
   Options: selected lower farming tier; current tier with waves paused; automatic previous tier.  
   **Recommendation:** player-selected farming tier, with waves-paused Grey as the fallback.

6. **How should idle speed improve?**  
   Options: raise base speed to 60°/s; retain 45°/s and cheapen early upgrades; rely on later hold-to-boost.  
   **Recommendation:** test 60°/s first.

7. **Where should extra-booth milestones land?**  
   Options: keep 500/750/1,125; use approximately 500/2,500/8,000; impose tier locks.  
   **Recommendation:** individual milestone prices, accepting booth 2 in late Grey or early Green.

8. **How much manual wave stacking should be allowed?**  
   Options: unrestricted current behavior; one unresolved manual wave; a short send cooldown.  
   **Recommendation:** test unrestricted behavior, then use one unresolved manual wave if stacking dominates.

9. **Should Gilded Gale retain two Gold Leaves per second?**  
   Options: keep it exactly; reduce to two every four seconds; use short two-per-second bursts.  
   **Recommendation:** two every four seconds initially, with summons paying no Gold or gate credit.

10. **How should Horse Tier 3 generate Gold?**  
    Options: retain booth payments plus one fixed extra payment per revolution; increase fixed booth payout; pay on combat interactions.  
    **Recommendation:** retain booth payments plus a clearly defined per-revolution payment. Avoid enemy-count-dependent Horse income.

11. **How should mount tiers and named capstones overlap?**  
    Options: distinct effects; two routes to the same non-stacking effect; intentionally stacking effects.  
    **Recommendation:** distinct effects, defined before their prices. Separately choose whether extra Horses share a species upgrade or upgrade individually; shared upgrades are simpler, individual upgrades offer more purchase depth.

12. **How much progress should an overnight absence buy?**  
    Options: most economic upgrades; roughly one tier’s purchases; a modest return bonus.  
    **Recommendation:** roughly one tier’s purchases, then review the offline formula against that target in Phase 4.

Prestige remains outside this proposal and **DECISION PENDING**. No additional currencies, enemy types, slots, or replay systems are needed to test this run.