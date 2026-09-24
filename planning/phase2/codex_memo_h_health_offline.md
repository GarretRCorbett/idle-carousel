# Codex memo H: keeping health: stall tuning, drag curves, crank, offline (2026-09-24)

> Input, not a decision. Follow-up to memo G after Garret playtested both fail rules and chose HEALTH_STALL. Codex saw his playtest words, his answers (regen when clear, crank it back, all stall costs considered, offline worry), GDD v1.7 excerpts, and memo G.

**Keep health. Make it measure whether your defense can sustain the current pressure; let drag show the immediate strain.** Garret’s playtest gives health a clear purpose: it creates a rescue moment and makes him want the Wolf.

The missing piece is a bounded consequence. My recommendation is: **a stall offers a brief rescue opportunity, then automatically ends an unsuccessful push and restores safe earning.** Offline time uses a separate, predictable income rule, with no simulated deaths.

Everything below is a proposal, not a resolution of the GDD’s pending decision. It changes some existing rules, especially drag, recovery, and offline income.

## 1. Why the current stall feels sudden

Assume full health, clustered Leaves latch together, no kills, and no upgrades or Boost. First contact occurs around **13 seconds after starting**, with further contacts every 20 seconds.

If only one wave arrives:

| Leaves latched | Time from first latch to zero health | Speed immediately before health stops it |
|---|---:|---:|
| 3 | 33.3 s | 85% / 38.25°/s |
| 4 | 25 s | 80% / 36°/s |
| 5 | 20 s | 75% / 33.75°/s |

With the actual repeating countdown:

| Leaves per wave | Health when second wave arrives, at +20 s | Time from first latch to stall | Latches at stall | Speed just before stall |
|---|---:|---:|---:|---:|
| 3 | 40 | 26.7 s | 6 | 70% |
| 4 | 20 | 22.5 s | 8 | 60% |
| 5 | 0 | 20 s | 5–10, depending on update order | 75–50% |

**A third unanswered wave cannot arrive before the first stall:** it would latch at +40 seconds. For perspective, if one, two, or three four-Leaf waves were already attached to a *fresh* 100-health carousel, survival would be 25, 12.5, or 8.3 seconds, with 80%, 60%, or 40% speed remaining.

That is the abruptness: the carousel can still look reasonably healthy mechanically, then health overrides its speed to zero.

The restart is harsher. At 25 health, four new Leaves need only **6.25 seconds** to stop it; eight need **3.125 seconds**. Because approaching enemies and the countdown survive a latch clear, restarting can immediately lead into another crisis.

### Starting tuning

| Setting | Starting proposal |
|---|---|
| Maximum health | Keep 100 |
| Leaf damage | Reduce from 1 to **0.5 health/s** |
| Latch grace | **2 s before damage**, drag applies immediately |
| Clean-rim regeneration | **2 health/s**, beginning after 2 s without latches |
| Warning | Health below **40%**, plus stronger feedback below 20% |
| Damage ramp | Initially none |
| Optional ramp experiment | 0.25 DPS for first 4 damaging seconds, then 0.5 |

Use grace once per enemy; Lion knockback should not repeatedly reset it.

With 0.5 DPS and two-second grace on each wave, unanswered four-Leaf waves stall at roughly **37 seconds after first contact**, versus 22.5 today. A single isolated four-Leaf wave takes 52 seconds. That gives a rescue more room without making accumulation harmless.

Do not increase health, halve damage, and add a long ramp simultaneously. You would lose track of what improved the feel.

The critical balance test is:

> **Health recovered between waves must exceed health lost during each wave on a sustainable build.**

Four Leaves damaging for six seconds cost 12 health at the proposed rate. Six seconds of actual regeneration replaces that. Test worst-case Wolf alignment, not just average damage: a wave arriving just after its sweep waits almost a full revolution.

## 2. Drag curves where Boost still helps

Let `D = 0.05 × latched Leaves`, and `B` be Boost, from 0 to 0.5. Speeds below are multiples of upgraded, unboosted speed, with no Overdrive.

Each cell shows **no Boost / maximum Boost**.

| Curve | 0 Leaves | 4 | 8 | 12 | 20 |
|---|---:|---:|---:|---:|---:|
| Current: `(1+B) × max(0,1−D)` | 1 / 1.50 | .80 / 1.20 | .60 / .90 | .40 / .60 | 0 / 0 |
| Reciprocal: `(1+B)/(1+D)` | 1 / 1.50 | .83 / 1.25 | .71 / 1.07 | .63 / .94 | .50 / .75 |
| Exponential: `(1+B) × exp(−D)` | 1 / 1.50 | .82 / 1.23 | .67 / 1.01 | .55 / .82 | .37 / .55 |
| Boost bypass: `max(0,1−D)+B` | 1 / 1.50 | .80 / 1.30 | .60 / 1.10 | .40 / .90 | 0 / .50 |
| 25% floor: `(1+B) × max(.25,1−D)` | 1 / 1.50 | .80 / 1.20 | .60 / .90 | .40 / .60 | .25 / .38 |

The current curve creates two independent shutdowns: drag can prevent movement even before health fails. That complicates teaching and recovery.

**Reciprocal drag is my starting choice.** It softens stacking, always gives Boost a proportional benefit, and preserves mount activity until health reaches zero. Health makes large infestations dangerous even when drag is gentler.

Exponential drag feels heavier at high latch counts, but eventually approaches an effectively motionless state. A floor guarantees meaningful movement, but additional drag stops mattering once the floor is reached.

Boost bypass most literally delivers “I can force it around.” Its drawback is that passive defense can become completely motionless while manual input remains essential. At extreme loads, it encourages constant button work.

Under the reciprocal proposal, eight Leaves give:

- Unboosted: about **32.1°/s**, one revolution per 11.2 seconds.
- Maximum Boost: about **48.2°/s**, one revolution per 7.47 seconds.

That is a tangible rescue benefit. Overdrive multiplies the result normally. **At zero health, however, Boost changes function to cranking**; make that transition unmistakable.

## 3. “Crank it back” without mandatory mashing

Give every stall three exits: clear the latches, crank a risky restart, or accept automatic recovery.

| Exit | Starting rule |
|---|---|
| Clear every latch | Immediate restart at **25% health** |
| Crank restart | Restart at **15% health**, remaining enemies stay |
| Automatic recovery | After **30 s from the original stall**, abandon the encounter, clear all enemies without rewards, restore full health |

On entering a stall, freeze the wave countdown and disable early sends. Existing approaching enemies can still arrive. Automatic recovery removes those too.

For cranking:

- Meter runs from 0 to 100.
- Each press adds 10, with at most five credited presses per second.
- Holding Boost adds 25 per second: a four-second accessible alternative.
- Meter does not decay.
- Restart grants **three seconds without latch damage**, allowing the first movement to matter.
- Cranking does not build Overdrive. Reset its charge; normal charging resumes after restart.

The 15% versus 25% distinction is useful: cranking buys movement while preserving the problem; clearing solves the current latch problem. Boost can then carry the Wolf into a sweep.

Do not let repeated cranks postpone automatic recovery indefinitely. After the first stall, keep the original 30-second deadline until the carousel has spent five continuous seconds latch-free and above 25% health.

That preserves Garret’s preferred fragile recovery while bounding the chore. If cranking routinely causes another stall before even one Wolf sweep, improve its protection window or starting health.

## 4. Four coherent online/offline packages

These packages share a few accounting rules:

- Offline time produces Gold, never fights, kills, boss victories, or early-send bonuses.
- No accumulated waves arrive on return.
- Boost, Overdrive, random events, and boss payouts never enter the offline rate.
- Save encounter/recovery transitions immediately. The normal 60-second autosave is insufficient for enforcing consequences consistently.
- Provide the same retreat/rest option online that closing the game invokes.

### A. Safe farming, risky pushes — recommended

**Online:** Health operates everywhere. A sustainable farming tier naturally survives indefinitely. Stalls allow the rescue window above; failed rescue ends the current attempt and returns to a player-selected lower farming tier. For Grey, fallback is waves paused with booth production running.

**Cost:** Time, missed production, abandoned enemies, and current boss progress. Lose no banked Gold or permanent unlocks. A small optional streak can reset, but is unnecessary initially.

**Offline:** Leaving abandons an unfinished encounter. Remove threats without rewards, reset the countdown, and apply a **30-second service period** before offline production begins. Health restores when service completes. Returning sooner resumes the remaining service time; reopening does not instantly heal.

Use unboosted, drag-free **recurring economic income** for the offline rate, initially booth income. Later explicitly include deterministic Unicorn income, excluding combat rewards.

**Bosses/tiers:** Boss health resets on abandonment. Earned unlocks and previously completed progression remain. A failed new tier returns to the selected farming tier; that tier is a preference, not a guarantee of safety.

**Player feeling:** “I tried too high, but my machine is still earning.”

**Offline story:** “The encounter ended, the carousel recovered, and I earned maintenance income.”

**Exploit/cost:** Closing escapes combat, but the identical online retreat has the same delay and better earning efficiency. Combat investment contributes little to offline income—a deliberate tradeoff. Implementation cost: **low–medium**.

### B. Production streak, forgiving stalls

**Online:** Use the same recovery exits, but stay on the selected tier. Automatic recovery pauses waves until resumed. Successful wave clears build a bonus from 0% to **20%**, reaching maximum after ten clears. A stall resets it.

**Cost:** Time and future bonus earnings, never saved Gold. Boss attempts reset; ordinary tier progress remains.

**Offline:** Clear threats, apply the service period, heal, and earn at the base economic rate. Preserve the streak value through ordinary departures, but never grow or pay it offline; a saved stall has already reset it.

**Player feeling:** “I lost momentum, not my savings.”

**Offline story:** “I earned steady Gold while away; active combat earns the extra bonus.”

**Exploit/cost:** Easy-wave farming becomes the safest streak builder. Keep the bonus modest and prevent weak-tier farming from subsidizing an oversized multiplier on a harder tier. Award early-send bonuses only after a legitimate clear. Implementation cost: **medium**, with additional tracking and explanation.

This is the best choice if tier retreat feels too punitive.

### C. Repair invoice with a free recovery route

**Online:** A stall permits latch clearing or cranking. Alternatively, pay a repair invoice worth **20 seconds of normal unboosted economic income** for an immediate full recovery and encounter abandonment. Waiting 30 seconds provides the same recovery free.

**Cost:** Either Gold or time. Never deduct money automatically, never create debt, and never charge repeatedly while unattended.

**Offline:** Treat departure as choosing free service. Deduct its remaining time from eligible offline earning time, clear threats, and restore health afterward.

**Bosses/tiers:** Full repair abandons the boss; clearing/cranking can preserve the attempt. Recovery returns to farming or pauses waves in Grey.

**Player feeling:** “I can spend to get moving immediately.”

**Offline story:** “Repairs finished while I was away, then production resumed.”

**Exploit/cost:** Price from the clean economic rate, so deliberately dragging income down cannot discount repairs. It overlaps heavily with Emergency Clear and risks making health feel like upkeep. Implementation cost: **medium**.

### D. Offline income based on proven automation

**Online:** Health and rescue work as in A. A three-minute unattended test records actual recurring income on a farming tier, including ordinary combat earnings but excluding temporary bonuses. Clicks, Boost, and Emergency Clear invalidate the test.

**Cost:** Failed pushes lose time and attempt progress. No saved Gold penalty.

**Offline:** Abandon encounters, service the carousel, then pay 50–75% of the certified rate. Clear threats and restart the wave countdown on return.

**Bosses/tiers:** No offline advancement. Higher farming tiers can improve certification.

**Player feeling:** “My defensive build earned better offline production.”

**Offline story:** “My proven setup kept producing.”

**Exploit/cost:** A short test can overestimate long-term sustainability. Build changes require recertification or a conservative fallback rate; economic upgrades need defined handling too. Implementation cost: **highest**. Strong concept, poor Phase 2 priority.

### Why not charge all four penalties?

Garret can get all four *kinds of consequence* without four deductions: a stall interrupts boss progress, loses earning time, reduces Gold earned, and breaks momentum.

**Start there.** Adding a wallet deduction and streak reset on top may make the same mistake feel charged several times.

## 5. Connecting later content to health

| Content | Connection and balancing concern |
|---|---|
| **Wolf** | Establish sustainable ordinary-wave clearing. Test a starting sweep that kills a Grey Leaf in one pass; otherwise a second revolution can dominate incoming damage. |
| **Eagle** | Prevents both damage and drag. Its three-second interception window needs phase testing: longer range alone does not guarantee a sweep before contact. |
| **Turtle** | Buys interception time. It delays incoming pressure but cannot rescue existing latches. Pairing with Eagle should noticeably improve prevention. |
| **Lion** | Restores speed during concentrated overload. Wolf already pierces every enemy in its line; Lion’s wider arc must offer a measurable timing advantage. |
| **Unicorn** | Sustain under pressure. Start around **2 health per kill credited to Unicorn**, capped at maximum health; no healing from despawns or Emergency Clear. |
| **Health 1/2/3** | Try maximum health **150/225/325**. These buy burst tolerance, not permanent safety if average damage still exceeds healing. |

Keep clean-rim regeneration available without Unicorn. Otherwise indefinite farming depends on a late unlock. Unicorn’s kill healing works while latches remain; any separate regeneration upgrade should be explicit. Its upgrade descriptions also conflict between +50% and doubling—Garret must settle that separately.

**Emergency Clear:** Retain Gold cost and 60-second cooldown. Start at 20 seconds of clean economic income. Clear latched ordinary enemies without kill Gold, healing, kill-gate credit, or early-send rewards. It can trigger the normal 25% clear restart. Exclude boss bodies and boss latch points; otherwise it buys boss removal. Make that restriction visible.

**Next Wave and auto-wave:** Pay early-send bonuses upon defeating the wave, not spawning it. Despawned waves forfeit bonuses. Permit only one outstanding bonus-bearing early wave initially. Auto-wave off pauses arrivals but leaves existing threats active. Resume a full countdown after recovery, respecting the saved toggle preference.

**Kill gates:** Count actual kills, not removals. Preserve completed boss eligibility through failure initially; the boss itself is enough to repeat.

**Bosses should test different failure patterns:**

- **Leaf Storm:** Its four children create a cleanup burst. Award completion after the children die.
- **Stick Giant:** Zigzag challenges interception; Wolf provides the fallback once it latches.
- **Boulder:** Three points create target priority. Specify total DPS and drag explicitly; do not accidentally triple every stat.
- **Gilded Gale:** Two Leaves per second is enormous pressure—40 arrivals per normal 20-second wave interval. Test sustainable add removal and distinguish summons for gate/streak accounting.
- **Ancient Log:** Turtle immunity tests alternate defense; make the first three resisted hits readable.
- **Obsidian Boulder:** Preserve health across the split phase. Completion waits for both resulting Rocks.
- **Rusted King:** Give its three points separate target health and defined drag contributions. Reciprocal drag may need large boss-specific values to achieve near-stop. Cranking must enable a useful sweep; Emergency Clear must not delete its central mechanic.

Keep bosses manually retryable. Stalls should never silently launch another attempt.

**Random Events:** Preserve their purely beneficial nature. Missing one never affects safety certification, regeneration, or a streak. Events should help a marginal build, not be necessary for sustainable farming.

**Achievements:** Reward first successful rescue, unattended stability, and boss victories. Avoid repeated-stall or mandatory rapid-mashing achievements. These are achievement criteria, not proposed player-facing names or text.

## 6. Recommendation and smallest Phase 2 test

Choose **Package A**, initially without a streak or Gold deduction. Its punishment is concrete: **you lose the attempt and some earning time; your permanent engine survives.**

For Phase 2, test only:

1. Wolf, with reliable Grey-wave cleanup.
2. 0.5 Leaf DPS, two-second latch grace, and clean-rim regeneration.
3. Reciprocal drag.
4. 25% clear restart and 15% crank restart, with hold support.
5. Thirty-second automatic recovery, clearing threats and pausing waves.

Keep this explicitly temporary until Garret chooses the final failure rule. Defer tier fallback, repair invoices, and certification.

For eventual offline income:

**Gold = safe recurring Gold/sec × eligible offline seconds × efficiency**, capped at eight hours, with remaining service time removed first.

One starting Horse and booth produce **0.625 Gold/s**. Eight hours at 50% yields **9,000 Gold before service deductions**; four booths yield 36,000. Check this against the intended game length before polishing offline health behavior.

In the next playtest, watch:

- Does health return to the same level between waves, or slowly ratchet downward?
- Does boosting visibly help Wolf reach the dangerous cluster?
- Can a crank restart produce a meaningful sweep before another stall?
- Does automatic recovery make failure bounded without making deliberate failure profitable?
- Does Wolf meaningfully reduce required attention?
- Are waves-on earnings worth the drag compared with waves-off farming?
- After failure, can Garret identify the upgrade that would help?

The remaining questions only Garret can answer:

- Is losing the current boss attempt and earning time enough, or must saved Gold decrease?
- Should a successful crank preserve a boss attempt?
- Should offline income primarily reward economic investment, or require demonstrated combat strength?
- How much progression should one eight-hour absence purchase?
- Should automatic recovery resume easier combat, or pause waves until the player returns?