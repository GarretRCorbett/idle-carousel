# Codex memo N: timed boss challenges (how other idle games do it)
*Codex (GPT), 2026-09-24, read-only web research. Input, not decisions; the real fail state is DECISION PENDING.*


*2026-09-24. Recommendations for Garret, not decisions. The real fail state remains DECISION PENDING. No files changed.*

I recommend testing **timed attempts with health and crank rescue, free retries, and no mount loss**. Failure already costs fighting time, reduced booth production, and boss progress.

**1. Clicker Heroes: Garret’s recollection is right**

For ordinary progression bosses in the PC/web game:

- A boss appears every fifth zone, with a **base 30-second deadline**. Damage does not carry into another attempt. There is no Gold admission fee or loss of heroes on failure.
- **Progression Mode**, unlocked at zone 100, advances automatically after clearing zones. A failed boss switches it off and returns the player to the preceding zone.
- **Farm Mode** repeatedly kills monsters in the selected zone, earning Gold for upgrades. Players can return to earlier zones, retry the boss, or re-enable progression. The default failure response is farming, rather than endless automatic retries. [Boss rules](https://clickerheroes.fandom.com/wiki/Monsters), [progression/farming guide](https://steamcommunity.com/sharedfiles/filedetails/?id=442565210).

The timer changes substantially later. Chronos adds `30 × (1 − e^(−0.034n))` seconds at level `n`, approaching +30 seconds. Orphalas increases Chronos’s effectiveness by 75% per level; relics can add Chronos levels. Every 500 zones subtracts two seconds from the resulting allowance, with a two-second minimum. Ordinary damage upgrades help meet the deadline rather than extend it. Older descriptions of Chronos giving a flat five seconds per level are outdated for this ruleset. [Chronos](https://clickerheroes.fandom.com/wiki/Chronos,_Ancient_of_Time), [Orphalas](https://clickerheroes.fandom.com/wiki/Orphalas), [relics](https://clickerheroes.fandom.com/wiki/Relics), [zone scaling](https://clickerheroes.fandom.com/wiki/Zones).

**Player response:** this is an established system, but establishment does not prove preference. One player describes the shortening timer as frustrating because another half-second would permit further pushing; others recommend ascending instead. Reports also show confusion when automatic progression silently becomes farming. [Timer discussion](https://www.reddit.com/r/ClickerHeroes/comments/151kc8a), [mode confusion](https://www.reddit.com/r/ClickerHeroes/comments/13391nv).

**2. Three useful comparisons**

| Game | Documented mechanics and failure cost | Community response |
|---|---|---|
| **Tap Titans 2** | Timed bosses gate stages. Timeout returns players to ordinary titans for Gold; Leave Battle and Fight Boss support retreat and retry. Ordinary attempts do not destroy equipment or charge admission. Spells can consume mana during the attempt. [Guide](https://www.reddit.com/r/TapTitans2/comments/c09vpl/) | A player describes bosses appearing almost dead while the remaining timer accomplishes nothing; replies explain percentage-health damage and the actual damage wall. The complaint concerns misleading feedback as much as difficulty. [Discussion](https://www.reddit.com/r/TapTitans2/comments/1ljmxyf) |
| **Idle Slayer** | The first Victor fight offers unlimited attempts. Later special-box bosses return defeated players to their previous dimension; premium currency can buy an immediate retry. Fast completion can guarantee better loot, so a speed target need not be a hard failure deadline. [Wiki](https://idleslayer.fandom.com/wiki/Boss_Fight) | Steam responses range from learning reliable strategies to anger at mandatory action combat and repeated entry chores. Free attempts alone do not fix a fight that clashes with the expected idle experience. [Discussion](https://steamcommunity.com/app/1353300/discussions/0/3412056228819802147/) |
| **Melvor Idle** | Standard-mode death stops combat and can destroy equipment from a randomly selected equipped slot. Protect Item prayer prevents that loss; spent combat supplies remain a cost. This is a survival check rather than a Clicker Heroes deadline. [Death rules](https://steamcommunity.com/app/1267910/discussions/0/4665175132475615016/), [FAQ](https://wiki.melvoridle.com/index.php/FAQ) | One player explicitly says item loss discourages experimentation and reports restoring a backup after losing valuable equipment. Replies recommend protection and combat simulation. This directly supports concern about avoidance and reloading. [Discussion](https://www.reddit.com/r/MelvorIdle/comments/1i4v8gr) |

**3. What the evidence suggests**

There is no representative survey here establishing a genre consensus. These are selected community reports, with complaints naturally overrepresented.

Nevertheless, the recurring preference is **bounded setbacks with understandable recovery**. An r/incremental_games discussion contains both support for short failed challenges and strong objections to losing accumulated progress or repeating content without learning anything. [Discussion](https://www.reddit.com/r/incremental_games/comments/1gu4uri/).

My design interpretation:

- Timers can make upgrades visibly matter and prevent hopeless fights lasting indefinitely. They frustrate when tiny misses erase long attempts or mandatory clicking becomes the answer.
- Entry fees make experimentation expensive. Their value depends on creating a useful decision, not merely another wait.
- Item destruction threatens the engine players spent time building.
- A wall feels better when the player can identify an affordable upgrade that changes the next result.
- Auto-retry can reduce babysitting, but repeated unwinnable attempts can waste farming time. With fees, it can drain savings unattended. Evidence here supports clear fallback behavior more strongly than universal auto-retry.

**4. Garret’s three ingredients**

**(a) Kill timer: good candidate.** It gives each push an endpoint while unlocked tiers remain available for farming. However, Carousel already has two pressures: drag reduces damage *and income*, while latch damage can stall it. A strict timer adds a third. Tune all three together; otherwise every failure merely demands more damage.

Memo M’s fights take roughly 45–130 seconds before the final boss. Copying Clicker Heroes’ 30 seconds would contradict those starting budgets. Preserve health so defensive upgrades still matter, and preserve a brief crank opportunity so bosses do not unexpectedly invalidate the rescue mechanic.

**(b) Lost Gold entry cost: weak baseline, useful comparison variant.** It conflicts with Package A’s proposed boundary: lose the attempt and earning time, never banked Gold or unlocks. That is an explicit alternative for Garret to consider.

A small fixed fee becomes irrelevant when late Gold is plentiful. A large fee competes with the upgrade needed to win, producing a failure spiral. Pricing in seconds of normal booth income scales better, although a large accumulated wallet still makes it feel minor. Do not use admission fees to repair the whole late-game economy.

**(c) Losing a mount: reject for the initial test.** Losing a Horse slows recovery income; losing Wolf can make the previously sustainable farming tier unsafe. Either can lengthen a three-hour run unpredictably. Extra sellable Horses also invite sacrificial purchases or selling before challenges, depending on which mount can disappear. The first Horse requires protection to avoid destroying basic income.

My prediction is more over-preparation, boss avoidance, and reloading. Melvor provides evidence for that behavior, although it does not quantify how often Carousel players would do it. Mount destruction also sits awkwardly beside the game’s restoration theme.

**5. Concrete TEMPORARY Phase 3 proposal**

Starting deadlines, including approach and required split children:

| Boss | Seconds |
|---|---:|
| Leaf Storm | 90 |
| Stick Giant | 120 |
| Boulder | 120 |
| Gilded Gale | 150 |
| Ancient Log | 150 |
| Obsidian Boulder | 180 |

Reserve **300 seconds** as a Phase 5 starting hypothesis for the Rusted King; do not implement it now.

- **Entry:** meeting the kill gate permanently enables manual attempts. Pause ordinary spawning, finish existing enemies, and begin at full carousel health after normal regeneration. Disable Next Wave during the encounter; preserve the Auto Wave preference.
- **Combat:** health, drag, Boost, and booth earnings remain active. Aim for an appropriately upgraded unattended build to succeed; clicking supplies margin. Boss summons provide no Gold or gate credit.
- **Stall:** allow **10 seconds** to clear latches or crank to the existing 25%/15% recovery values. The boss timer continues. Failed rescue or a second stall ends the attempt. The ordinary 60-second safety net remains outside bosses; boss cleanup must never count as victory.
- **Timeout/retreat:** end the encounter, remove all encounter enemies without rewards, and reset boss health. Keep Gold, mounts, purchases, unlocks, and qualifying kills.
- **Recovery:** apply Package A’s proposed **30-second service period**, without production, restoring full health. Then return to the chosen farming tier with a fresh wave countdown and preserved toggle. Grey’s fallback pauses waves.
- **Retry:** manual and free after recovery; no repeated kill gate, extra cooldown, or automatic retry. Emergency Clear cannot remove boss bodies, latch targets, or required children.
- **Offline:** closing abandons the encounter. Remaining service time precedes booth-only offline income; no offline fights or victories. This is a future save/offline contract, not extra Phase 3 scope.

For comparison, change one ingredient at a time:

| Variant | Change from baseline |
|---|---|
| Softer | Deadlines ×1.5. |
| Harsher | Deposit **30 seconds of unboosted, drag-free booth income**, quoted and fixed at entry; refund on victory, forfeit on failure or abandonment. No mount loss. |

Put deadlines in boss Resources and shared rules in a `BossChallengeRules` Resource: timer multiplier, rescue window/count, recovery duration, and deposit-income seconds.

Measure attempts, failure reason, boss health remaining, recovery time, and time until the next useful purchase. Repeated failures should not supply the missing minutes needed to reach the run target.

**6. Questions for Garret**

1. **Penalty:** A) time and attempt only **[recommended]**; B) Gold deposit; C) mount loss.
2. **Health:** A) health plus one crank rescue **[recommended]**; B) first stall immediately fails; C) timer only, no boss health damage.
3. **Attention:** A) adequate builds win unattended, clicks help **[recommended]**; B) bosses require active input.
4. **Retries:** A) manual after recovery **[recommended]**; B) opt-in automatic retries when free; C) automatic by default.
5. **First comparison:** A) baseline versus longer deadlines **[recommended]**; B) baseline versus Gold deposit; C) all three variants immediately.