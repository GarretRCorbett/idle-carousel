# Codex memo G: health, latch, and fail state (2026-09-24)

> Input, not a decision. Asked while building Steps 6-8: does health + latch drag + a fail state make sense for an idle game, and what should zero health do? Codex saw GDD v1.7 excerpts (core loop, health, latch, enemies, progression, wave controls) and the NOTES balance items.

**My recommendation: keep latch drag, remove carousel health for v1.0, and make overload cause a brief, automatic recovery that leaves the player’s purchases and saved Gold intact.** Keep meaningful failure for deliberately attempted bosses.

The carousel being both engine and weapon is a strong idea. Its natural weakness—slowing down makes defending yourself harder—already creates substantial pressure. Health needs to add a different decision to justify its complexity.

These are proposals for Garret to choose from, not resolutions of the GDD’s pending decision.

**1. Does health add anything?**

Drag already delivers three consequences:

- Less booth income.
- Fewer mount attacks.
- Slower removal of enemies, allowing more drag to accumulate.

That third consequence creates a reinforcing feedback loop. Health then adds another clock driven by exactly the same enemies, usually demanding exactly the same response: clear the latches.

The current numbers make health particularly dominant. Four latched Leaves cause only 20% drag, but drain 100 health in 25 seconds. Ignoring travel time, a second four-Leaf wave arriving 20 seconds later would finish the remaining 20 health in 2.5 seconds. Health can stop a carousel that still has 60% of its undragged speed available.

At 45 degrees/second, one rotation takes eight seconds. Four Leaves extend that to ten seconds. Your visual mechanic says “the machine is struggling”; the health rule can abruptly say “the machine is dead.”

There is also a missing recovery rule. If health does not regenerate between waves, even a build that reliably clears every wave can eventually die from accumulated chip damage. More health merely delays that outcome.

| Approach | What it adds | Main concern |
|---|---|---|
| **No health** | One visible problem: enemies slow the engine. | Needs an overload/recovery rule to prevent permanent stoppage. |
| **Current health plus drag** | Both immediate slowdown and accumulated damage. | Two punishments with the same solution; eventual attrition without healing. |
| **Separate pressure meter** | Measures sustained overload rather than every latch. | Useful only if it communicates a recovery threshold clearly. |
| **Health affects booth income only** | Combat can continue while earnings suffer. | Drag already reduces income; another economic multiplier may feel opaque. |
| **Health for boss attempts only** | Gives deliberate challenges a clear loss condition. | Adds an exception, but one players can understand. |

A pressure meter could fill only below a speed threshold and drain when the carousel recovers. That measures “how long have I been overwhelmed?” rather than duplicating enemy count. It can also be an internal timer with a warning, avoiding another permanent HUD bar.

**2. Six possible fail states**

For offline consequences below, assume failure is simulated. You can instead choose a separate offline-income rule, discussed later.

| Option | Active-player experience | Idle/AFK experience | Offline, capped at eight hours | Death-spiral risk |
|---|---|---|---|---|
| **Hard Game Over; restart current tier** | Clear stakes, but replaying solved content interrupts saving for upgrades. | Often ends in a restart screen awaiting input. | Earnings may stop minutes into an eight-hour absence. Automatic retries can repeatedly fail. | Medium if restart clears enemies and restores health; high if it also removes upgrade money. |
| **Current TEMPORARY stall until every latch clears** | A clickable rescue challenge, followed by a fragile 25-health restart. | Indefinite stoppage without intervention. | First stall can erase most earning time. | Very high: neither booth income nor mount sweeps can restart the engine. |
| **Purchase a repair** | Makes spending versus saving a decision. Can feel like a maintenance tax. | Stops until purchase unless repairs are automated. | Automatic repairs can consume the entire absence’s earnings. | High unless a free recovery route exists and repairs remove the underlying overload. |
| **Fall back one tier; clear enemies** | Communicates that the attempted tier was too hard. | Returns to easier farming automatically. | Can keep earning at a lower tier; stop further fallback once safe. | Low if the previous tier is sustainable. Requires a Grey-tier fallback and never revoking unlocks. |
| **Lose Gold; immediately clear and restart** | Understandable but punishes saving for expensive upgrades. | Repeated failures can quietly drain savings. | Needs a strict cumulative penalty cap; otherwise returning is disappointing. | Medium–high: penalties delay the upgrades needed to prevent another failure. |
| **Temporary slowdown with automatic recovery** | Brief lost efficiency and a failed push; active intervention can avoid it. | Recovers without attention. | Predictable, bounded lost earnings rather than indefinite shutdown. | Low if recovery removes enemies and suppresses arrivals; high if it merely restores health. |

My preference is the last option, without a separate health bar. Tier fallback is the strongest alternative if Garret wants combat progression to be more central.

A nonzero speed floor alone is insufficient. At 25% speed, mounts attack one-quarter as often while waves still arrive every 20 seconds. Enemies can accumulate forever unless the system eventually clears them, pauses arrivals, or retreats.

Similarly, restoring health while leaving all latches attached just schedules another failure.

**3. Recommended v1.0 rules**

I would start with this concrete model:

1. **Drag reduces speed to a minimum of 25% of the current unboosted, upgraded speed.** Boost can still help above that minimum.
2. **Ten continuous seconds at that minimum triggers automatic recovery.** Recovering above the threshold resets the timer.
3. **Recovery removes all current enemies without kill rewards**, including approaching enemies, and suppresses new spawns.
4. **The carousel runs at 50% of normal speed for 15 seconds**, then returns to normal.
5. **After an ordinary-wave overload, Auto Wave pauses until the player resumes it.** Booth income continues automatically.
6. **All Gold, upgrades, slots, and tier unlocks remain.** A boss overload ends that boss attempt without awarding victory.

The consequence is lost combat rewards, interrupted advancement, and a short production loss. The player returns to a functioning carousel and money to spend.

This deliberately changes both “drag has no floor” and “Auto Wave always sends waves while enabled.” Garret would need to approve those design changes. The interrupted wave countdown must be obvious; it should not silently look enabled.

It also chooses a side in the GDD’s tension: **a mastered tier should eventually support indefinite unattended play.** Threat comes from pushing, weak builds, bursts, and bosses. Requiring recurring rescue even after a player has built effective automation would undermine the Wolf’s promised transformation.

For bosses, a failed attempt can reset boss health and remove its summons while keeping earned progression. Manual retry makes the loss intentional and bounded. Whether bosses need a dedicated health/timer condition can wait until their combat exists.

**4. Interactions that matter**

**Offline progress.** For a solo-dev v1.0, avoid simulating eight hours of latch positions, attacks, deaths, repairs, and retries.

A simple starting rule is:

**Offline Gold = 50% × unboosted, drag-free booth Gold/sec × elapsed time, capped at eight hours.**

Exclude kill Gold, manual clicks, Boost, Overdrive, and boss rewards. Show this rate separately from recent actual income. Treat 50% as a tuning proposal, not a genre standard.

One starting Horse and one booth produce 5 Gold every eight seconds: **0.625 Gold/sec**. This proposal awards **9,000 Gold over eight hours**; four booths yield 36,000 before other upgrades. Check those figures against the whole upgrade curve. An eight-hour cap may still be extremely generous for a short game.

On return, remove ordinary threats without rewards and restore safe operation; an unfinished boss attempt is abandoned. That makes closing the game a possible escape, so compare it against the short online recovery. Do not accidentally make repeatedly closing the application the best economic strategy.

This offline simplification weakens combat’s influence on offline income. That is a real tradeoff. If unacceptable, later base offline earnings on demonstrated unattended performance—but that needs rules for changing builds and avoiding click-assisted records.

**Emergency Clear.** Make it an optional way to preserve momentum, never the only affordable escape from zero income. Start its price around **20 seconds of normal booth income**, independent of current drag or Gold balance. Keep the 60-second cooldown initially.

It should remove latches without kill rewards. Otherwise its cost may pay for itself. Approaching enemies remain a meaningful limitation, but automatic recovery must still handle a player who spends their last Gold and gets overwhelmed again.

If players need Emergency Clear every minute on their farming tier, the baseline combat balance is wrong.

**Manual escalation.** This already supplies consent to risk. Let players retreat to any unlocked lower tier freely; distinguish the selected farming tier from permanent unlocks. Trying Green should not threaten the mount slot earned in Grey.

**Auto Wave.** Turning it off pauses new arrivals, not existing threats. Automatic recovery needs to suspend manual wave sends too.

Also test the underlying economy: if enemies only reduce booth income, turning waves off could be optimal. Combat rewards and unlocks must make sustainable fighting worthwhile. Conversely, early-send Gold must not make “spam waves, collect bonuses, trigger recovery” profitable; consider paying that bonus upon clearing the wave.

**Combat mounts.** The excerpts do not specify every ability, especially Lion’s, so these are role-level implications:

- **Wolf:** Must establish reliable unattended clearing on an appropriate tier. Test its worst wait before reaching a newly latched enemy, not only average damage.
- **Eagle:** Interception prevents drag before it starts. Health removal preserves that value. Avoid making Eagle mandatory for every sustainable build.
- **Turtle:** Slowing approaches buys time for interception and distributes arrivals. Unless its actual ability affects latches, it cannot rescue an already overloaded rim.
- **Lion:** If its intended role is burst or area clearing, test whether it restores speed during overload. Do not assume it solves stoppage if its attack still requires rotation.

Any mount whose attack requires a sweep loses that recovery ability at zero speed. Stronger damage does not solve an attack that never happens.

**5. What comparable games suggest**

**Cookie Clicker** makes its closest visual analogue surprisingly forgiving: wrinklers reduce current production but return more cookies than they consumed when popped. Apparent infestation can become a deferred reward. That is useful inspiration for satisfying cleanup, though copying the payout would risk making deliberate overloading optimal. [Cookie Clicker Wiki: Wrinklers](https://cookieclicker.wiki.gg/wiki/Wrinkler)

**Clicker Heroes** uses failed boss attempts to return players to the preceding zone and farming mode. The valuable pattern is that failure blocks advancement while leaving a way to earn toward the solution. [Steam community beginner’s guide](https://steamcommunity.com/sharedfiles/filedetails/?id=442565210)

**The Perfect Tower II** explicitly expects towers to break. A run loses its temporary progression while earned town resources support permanent improvements. It also offers an idle mode based on demonstrated resource production. Death fits because the game establishes repeatable runs and persistent growth around it. Idle Carousel currently promises continuous operation instead. [The Perfect Tower II: Tower Testing](https://www.perfecttower2.com/wiki/New_Round)

**Rusty’s Retirement** explicitly positions itself as a relaxing game that operates while the player does other things. Borrowing that expectation makes frequent emergency clicking a poor fit. This is a lesson about attention, not evidence that Idle Carousel needs identical mechanics. [Official Steam page](https://store.steampowered.com/app/2666510/Rustys_Retirement/?l=english)

**A Game About Feeding a Black Hole’s demo** used short rounds that banked money for permanent upgrades. Coverage described the appeal as improving each round without a conventional loss. That supports bounded attempts with retained earnings; it does not establish how every current mode behaves. [GamesRadar demo coverage](https://www.gamesradar.com/games/roguelike/help-i-fed-the-black-hole-in-a-game-about-feeding-a-black-hole-and-now-i-cant-stop-the-approaching-galactic-entropy-of-its-steam-next-fest-demo/)

My design inference—not a universal player survey—is that incremental players tend to enjoy **visible improvement after failure, reliable farming, and upgrades that genuinely remove chores**. Common friction points are lost savings, unexplained offline shortfalls, mandatory rescue clicking, and buying automation that still needs constant supervision.

Failure can work. Its promise should be clear: what was risked, what was retained, and what purchase helps next.

**6. Smallest Phase 2 playtest**

Wait for Wolf before judging whether the system supports idle play. Horse-only combat tests the clicking tutorial.

Compare the existing TEMPORARY behavior with one alternative: **health disabled, 25% speed floor, ten-second overload timer, automatic enemy removal, and Auto Wave paused afterward.** Skip the 15-second repair slowdown initially. No new art, elaborate UI, repair shop, or offline simulation is needed for the comparison.

Use these starting points:

| Variable | Initial value or target |
|---|---|
| Leaf drag | Keep 5% to isolate the failure-rule change |
| Minimum speed | 25% of upgraded unboosted speed |
| Overload duration | 10 continuous seconds |
| Recovery cost | No Gold; removed enemies give no rewards |
| Later repair slowdown | 50% speed for 15 seconds |
| Sustainable Grey build | Ten minutes unattended without accumulating latches |
| Pre-Wolf clicking introduction | Aim for roughly 1–3 minutes; test affordability |

Observe active play, hands-off farming, deliberate over-pushing, and recovery with zero Gold.

Watch for:

- Can players explain why income slowed and how it recovered?
- Does Wolf create an obvious reduction in required attention?
- Do latch counts stabilize, or slowly climb despite apparently successful waves?
- Is the first stalled sweep tense, or simply frustrating waiting?
- Does recovery leave players wanting an upgrade or wanting to stop?
- Are waves-off farming, Emergency Clear, or intentional overload economically dominant?
- Do mouse movement and repeated clicking become tiring before strategic decisions emerge?

Measure minimum speed, time under heavy drag, required clicks per minute, recovery frequency, and income with waves on versus off. Average damage alone will miss the spatial timing that makes this game distinctive.

**7. Decisions only Garret can make**

- Is the intended experience primarily a relaxing idle machine or an active defense game with idle earnings?
- Should a correctly upgraded current tier remain safe indefinitely?
- Should failure cost future earning time, saved wealth, or completed progress?
- Is health serving a desired fantasy or decision that drag cannot provide?
- May automatic recovery pause Auto Wave?
- How much of the complete game should one eight-hour absence buy?
- Should offline income reward combat strength, or primarily economic investment?
- What distinguishes Lion, and which mount combinations should sustain idle play?
- Should ordinary waves and bosses share a failure rule?

I would settle the first two before tuning health. They determine whether a fail state supports the intended experience at all.