# Codex Memo S: How the first boss (Leaf Storm) should work
**Asked:** 2026-09-25. Garret's idea: Leaf Storm "occasionally summons a lot of leaves, then blows
around the screen, then summons a lot more... you mostly have to click the Leaf Storm and rely on
your Wolf to protect the carousel." The GDD only says "On death splits into 4 Grey Leaves" (a burst
test). Codex read the repo (read-only, snapshot unchanged) and searched the web; answer verbatim,
then Claude's read. **Input, not a decision**; Step 6's plan builds on Garret's pick.

---

**I recommend Garret’s idea: a large, slowly moving Leaf Storm that alternates summoning and resting, while Wolf clears the rim.** Keep the four death-split Leaves as the final burst test. The lesson should be “trust your mounts, intervene where needed, keep spinning.”

These are proposals for Garret. The September 25 decisions supersede older memo suggestions; the permanent fail state remains **DECISION PENDING**. No files changed; no game or checks run.

The comparisons below distinguish documented behavior from my interpretation. Community reports are anecdotes, not evidence of a consensus.

| Comparison | Sourced behavior and design implication |
|---|---|
| **Clicker Heroes / Tap Titans 2** | Timed bosses test accumulated damage; TT2 explicitly returns failed attempts to ordinary enemies and supports retreat/retry. **Judgment:** preserve the familiar combat interface and make the next useful upgrade apparent. [CH mechanics](https://clickerheroes.fandom.com/wiki/Monsters), [TT2 guide](https://www.reddit.com/r/TapTitans2/comments/c09vpl/) |
| **Idle Slayer** | Victor discussions expose both unclear tactics and resistance to mandatory action combat. One player tried only arrows; the developer describes adding guidance about approaching for damage. **Judgment:** explain the intended division of labor before asking players to execute it. [Developer/player discussion](https://steamcommunity.com/app/1353300/discussions/0/3412056228819802147/) |
| **Cookie Clicker** | Golden Cookies offer temporary clicking opportunities; duration upgrades improve the opportunity to notice and activate them. **Judgment:** borrow generous target availability, not sustained precision tracking. This is an interaction comparison, not a boss analogue. [Golden Cookies](https://cookieclicker.wiki.gg/wiki/Golden_Cookie) |
| **Kingdom Rush / Bloons TD 6** | Juggernaut, Kingdom Rush’s first boss, summons Golem Heads. Bloonarius releases larger bursts at visible skull thresholds. **Judgment:** distinguish boss damage from crowd control and announce bursts visibly. Bloonarius is a specialist challenge, not an onboarding difficulty target. [Juggernaut](https://kingdomrushtd.fandom.com/wiki/The_Juggernaut), [Bloonarius](https://bloons.fandom.com/wiki/Bloonarius_the_Inflator_%28BTD6%29) |
| **Nuclear Throne / Enter the Gungeon** | Big Bandit has two principal attacks, including a barrage that does not continuously retarget. Gatling Gull marks missile impacts with crosshairs. **Judgment:** committed directions and advance markers make danger learnable. [Big Bandit](https://nuclear-throne.fandom.com/wiki/Big_Bandit), [Gatling Gull](https://enterthegungeon.wiki.gg/wiki/Gatling_Gull) |
| **Vampire Survivors / Brotato** | Mad Forest embeds bosses within timed enemy waves. Brotato’s Mother combines retreating with summons; players specifically complain about chasing her while adds accumulate. **Judgment:** automatic attacks do not make simultaneous pursuit and crowd pressure automatically fair. [Mad Forest](https://vampire-survivors.fandom.com/wiki/Mad_Forest), [Mother](https://brotato.wiki.spellsandguns.com/Mother), [player discussion](https://www.reddit.com/r/brotato/comments/1vktois/is_it_just_me_or_is_mother_the_hardest_elite_by/) |

Mike Stout describes bosses as tests of learned skills with tension and release; Itay Keren’s GDC overview similarly emphasizes acquired skills. **My synthesis:** teach one recognizable cycle, provide recovery windows, and let preparation visibly improve results. Avoid unpredictable movement, overlapping telegraphs, perpetual add growth, and an unclear victory condition. [Stout’s article](https://www.gamedeveloper.com/design/boss-battle-design-and-structure), [GDC session overview](https://www.gdcvault.com/play/1024921/Boss-Up-)

For Carousel, the important constraint is **Wolf handles cleanup, not guaranteed interception**. A Leaf crosses roughly 65 pixels between Wolf’s line tip and its latch position in under one second, versus approximately 5.14 seconds per revolution. Its 2 HP requires two base Wolf hits. Piercing handles groups efficiently, but some latching is expected; six latched Leaves reduce speed to approximately 77% before Boost.

A permanently distant boss also establishes a deliberate limitation: pre-boss Wolf upgrades improve defense but cannot damage the body. That fits the decided active-first boss direction, provided clicking is comfortable. Later Giraffes can reach it, making repeat victories visibly easier; Sloth can slow its movement and approaching summons. Neither may be required for the first win.

I would start with these **unvalidated tuning values**, all stored in exports or Resources:

| Element | Starting proposal |
|---|---|
| Body | **50 HP**; no contact damage, drag, or latching; always damageable |
| Appearance | Approximately **88 px diameter** swirling silhouette; existing Leaf sprites plus code-drawn wind arcs |
| Targeting | **52 px click radius**, **36 px combat radius**; neither shrinks with hit animation |
| Path | Predictable lower arc, **220 px from carousel center**, from −20° to 200°, reversing smoothly at endpoints |
| Movement | Maximum **45 px/s**, with eased starts/stops; four seconds moving per cycle |
| Cycle | **1.5 s stationary gust telegraph → summon → 4 s drift → 6.5 s stationary recovery** |
| Summons | First burst **4 Grey Leaves**, subsequent bursts **6**, every **12 s** |
| Limit | **12 optional summons alive or queued**; reserve another four places for the final split |
| Deadline | Existing **90 seconds**, including required split cleanup |

Begin with three quiet seconds to identify and click the boss. During the telegraph, wind arcs gather and two outlined spawn fans appear beside its bearing. Spawn Leaves around **300–330 px out**, in separated fans flanking the boss; this provides roughly two seconds before latching and avoids spawning directly underneath the cursor. Keep their existing 2 HP, 90 px/s, drag, and latch grace. The gust initially communicates spawning only; pushing or accelerating existing Leaves adds unnecessary complexity.

The player clicks the body, briefly Boosts when Leaves approach or accumulate, and clicks troublesome survivors when necessary. Wolf automatically sweeps the whole group. A second Wolf, Speed upgrades, or the Fang breakpoint to 2 damage should visibly reduce intervention. Test ordinary clicking around 1–2 clicks/second, with time diverted to defense; aim for **55–75 seconds total**, accepting faster upgraded clears.

At 1280×720, that path’s entire click disk occupies approximately **x=368–912, y=233–632**. It provisionally fits between the current side panels and above Boost. Validate against the actual Step 6 strip and localized layouts; derive usable bounds through layout coordination rather than having enemy code inspect HUD nodes. Never teleport or dodge away from the cursor.

The current router chooses the nearest enemy center, so summons can steal overlapping clicks. Prefer the boss inside its clearly visible central core; retain ordinary nearest-target selection elsewhere. Show a hover outline.

The **30-enemy Send limit is not a global cap**: automatic waves currently bypass it. Suspend ordinary spawning and manual/N-key sending during attempts, preserving Auto Wave preference. Independently cap summons using admitted **plus queued** counts; discard excess requests without accumulating a future burst. Six actual Leaves can look plentiful with decorative wind. Existing stress results suggest this count is modest, but are not a universal performance guarantee.

Summons and split children should grant **no Gold or progression kill credit**. Keep Horse income. On body death, stop summoning and queue exactly **four required Grey Leaves**. Continue the same timer; replace body HP with a clearly distinguished remaining-child count. Existing optional adds can remain until victory, then disappear without rewards.

Stalls retain unlimited free cranks while the deadline runs. Timeout/give-up removes encounter members without death effects, preserves progress, and permits free manual retry. Do not import memo N’s superseded rescue limit or service delay.

Step 6 needs:

- A small encounter state machine separating body death, required-child cleanup, victory, and cancellation; reserve pending children before evaluating victory.
- An `EnemyBoss` movement override, recurring spawn Timer, encounter ownership, and queued-spawn cancellation. Enemies remain in world-space `EnemyLayer`.
- Separate reward/kill eligibility: today `_on_enemy_died()` unconditionally records kills.
- Protection in **both GameState and Game**: the stall safety net must not erase encounter latches or members. Emergency Clear may affect optional adds, never required children.
- Strip signals, boss eligibility, first/repeat reward handling, and purchase validation for Green, Giraffe/Sloth, Slot 4 availability, and the agreed upgrade gates.
- Tests for timeout during spawning, duplicate completion, required-child removal protection, and HUD-safe targeting; playtests with one Wolf, two Wolves, and two Horses plus Wolf.

This adds summoning to the GDD’s split-only description. Garret should explicitly adopt that extension in Step 6’s plan; keep Leaf Storm’s sparse, stationary casting windows distinct from Gilded Gale’s later sustained summoning pressure.
---

## Claude's read
**Sources spot-checked:** Mike Stout's boss article (Game Developer) says what Codex says: a boss is
"a test" of learned skills, built with tension and release. **Kingdom Rush's first boss, the
Juggernaut, is close to Garret's idea:** it summons packs of 7 weak Golem Heads about every 6 s
while your towers handle them ([Fandom wiki](https://kingdomrushtd.fandom.com/wiki/The_Juggernaut),
confirmed by search). Brotato's Mother shows the failure mode: chasing a retreating boss while adds
pile up feels bad, which is why the path should be slow and predictable.

**Agree with Codex's design.** In one line: *a big, slow Leaf Storm drifts along a fixed arc beyond
the Wolf's reach; every ~12 s it stops, gathers wind (a visible 1.5 s warning), and throws a pack of
Leaves at the carousel; you click the Storm; the Wolf and Boost handle the pack; when the Storm dies
it bursts into the GDD's 4 Leaves, and clearing those wins.* It keeps the GDD's split as the finale
and adds Garret's summoning, and it teaches the game's split: clicks for the boss, mounts for
defense.

Points I'd keep an eye on:
- **Some Leaves will latch, and that's fine.** Summons appear ~300 px out and reach the rim in ~2 s,
  while the Wolf passes each spot about every 5 s. So the fight is "stay spinning while you click":
  Boost when the pack lands, click a stubborn latcher if you must. Failure costs only time.
- **Clicks must hit the Storm, not a Leaf in front of it**: a click inside the Storm's core goes to
  the Storm. Its path stays clear of the side panels and the Boost button.
- **During the fight:** normal waves (auto, Send, N key) pause; summoned and split Leaves pay no Gold
  or kill credit; the stall safety net never removes the Storm; a summon cap (12) stops pile-ups.
- **Later animals make repeat fights easier** (Giraffe reaches the Storm's path, Sloth slows the
  packs), but the first win must work with Horse + Wolf + clicks.
- **Starting numbers** (Codex's table): 50 health, ~88 px wide, 52 px click radius, drifts at up to
  45 px/s, packs of 4 then 6, a 90 s timer, aiming for a 55–75 s first clear. All in data for tuning.

**For Garret to decide (Step 6 plan):** adopt the summon-and-drift version (a GDD update: it adds
summoning to "splits into 4 Leaves"); keep the 4-Leaf burst finale (★ yes); start from these numbers.
