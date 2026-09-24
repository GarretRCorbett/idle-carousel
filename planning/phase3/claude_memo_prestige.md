# Prestige research (Claude, 2026-09-24)

Garret asked: is prestige planned, is a 2.5–3.5 h first loop too long before the first
prestige, what rewards do players like, upgrade tree or challenges (Slay the Spire,
Wildfrost)? Web research by Claude (Codex was out of usage). **Input, not a decision:**
prestige scope is DECISION PENDING in the GDD ("resolve before Phase 5").

## Where it stands
- GDD: prestige is **out of v1.0** and **DECISION PENDING** ("does the game need a light
  prestige/replay loop at launch… or ship as a complete one-run experience?").
- GDD post-launch ideas: "Prestige system with permanent multipliers and new carousel skin."
- NOTES: roguelike element parked "to revisit when planning prestige."
- Garret's idea (2026-09-24): after beating every boss you can prestige, start fresh, and
  keep permanent boosts. Bosses may only be idle-winnable "after a prestige or two."

## Is a 2.5–3.5 h first loop too long?
There's no single genre answer; it depends on the kind of game.
- **Free-to-play mobile idlers** aim for a first prestige in **10–15 minutes**, and the
  next run should feel faster within 30 seconds ([dev.to](https://dev.to/aguier/i-built-7-idle-games-in-30-days-what-i-learned-about-incremental-design-5d3f)).
  That's retention design for a free game with a huge funnel.
- **Big incrementals** make the first prestige slow on purpose: players report first
  resets taking an hour, 16 hours ([Revolution Idle](https://steamcommunity.com/app/2763740/discussions/0/6955341154010347761)),
  or days in Cookie Clicker ([Steam](https://steamcommunity.com/app/1454400/discussions/0/3165461141533122780)).
  The consistent pattern: **each later run is much faster**, and that speed-up is the reward.
- **Short, paid Steam incrementals are the closest match** to Idle Carousel ($4.99, a few
  hours): Nodebuster (~3–4 h, [review](https://mancunion.com/2025/05/08/nodebuster-review-a-short-and-sweet-incremental-game/)),
  Tower Wizard ([Steam](https://store.steampowered.com/app/3372980/Tower_Wizard/)), and
  (the) Gnorp Apologue ([prestige](https://gnorp.wiki.gg/wiki/Prestige)) are the ones players
  recommend to each other as "short & incremental" games that "make you want more"
  ([Steam thread](https://steamcommunity.com/app/3372980/discussions/0/599656878323016464/)).
  Nodebuster resets every few minutes into a permanent upgrade tree; Gnorp suggests a
  first run of about an hour.

**Claude's read:** a 2.5–3.5 h first run is fine *if the run is a complete, satisfying game
on its own* (bosses, new mounts, restoration ending) and prestige is the "keep playing"
hook after it. It's risky if prestige is where the game's best part lives, because most
first-time players won't see it until hour three. Two practical points:
- Steam refunds are allowed under 2 hours of play, so hour 1–2 must already be great.
  That's a reason to protect early pacing, not to move prestige earlier.
- If playtests show players want the reset hook sooner, a **softer early taste** is an
  option: e.g. a first "prestige" at the Tier 3 boss that gives a small permanent bonus.
  That adds scope; only worth it if the full run drags.

## What rewards players like
From the examples above, roughly in order of how memorable they are:
1. **New things:** mechanics, mounts, modes that the first run didn't have. Strongest "wow."
2. **Choices:** an upgrade tree with talent points (Gnorp, Nodebuster). Players like building
   toward a plan and trying a different build next run.
3. **Automation and QoL:** e.g. auto-boost, auto-challenge, start with the Wolf. This ties
   to Garret's hold-to-boost idea and "idle-winnable after a prestige or two."
4. **Plain multipliers:** always good, never exciting alone. Fine as filler between nodes.
The rule every source agrees on: **prestige must feel like acceleration, not punishment.**
The second run should blow through Grey in minutes.

## Challenges: Slay the Spire and Wildfrost
- **Slay the Spire Ascension:** win a run to unlock Ascension 1; each win unlocks the next
  level; modifiers **stack** (more elites, less healing, a curse card…)
  ([wiki](https://slay-the-spire.fandom.com/wiki/Ascension)). Simple, clear ladder.
- **Wildfrost Storm Bells:** after your first win you unlock bells you **pick yourself**,
  each worth points (fewer enemy-wave bells, pricier shops, cursed charms…); enough points
  unlocks a true final boss ([announcement](https://www.gonintendo.com/contents/29760-wildfrost-ver-1-1-0-the-storm-bells-update-now-live),
  [wiki](https://wildfrostwiki.com/Bells)). More freedom; players build their own difficulty.
- **Antimatter Dimensions challenges** (the incremental-genre version): restricted runs
  that give a permanent reward when completed
  ([wiki](https://antimatterdimensions.wiki.gg/wiki/Eternity_Challenges)).

These fit Idle Carousel well: the modifiers are mostly **data we'll already have** after
Phase 3 (enemy tier multipliers, wave sizes, boss timers, prices, drag). Examples:
"Rusty Rims" (boss timers −25%), "Gale Season" (+1 Leaf per group), "Tight Budget" (prices
+50%), "Lone Horse" (no extra Horses). They also give **speedrun categories** for free
("Tier 5, Storm 0" vs "Tier 5, Storm 10").

## A possible shape (for discussion, not decided)
- **Prestige at victory** (Garret's idea): beat the Rusted King → "restore" the carousel →
  start a new run keeping a prestige currency (earned from bosses beaten, maybe time).
- **A small permanent tree** (~15–25 nodes): starting kits (begin with Slot 2 and the
  Wolf), automation (auto-boost, auto-challenge bosses), economy multipliers, and one or
  two **new things** (a new mount behavior, a carousel skin as the GDD suggests).
- **Optional challenge modifiers** after the first win, Wildfrost-style (pick your own,
  each worth points), multiplying prestige currency. A Slay-the-Spire ladder is the simpler
  alternative.
- Target: run 2 ≈ 60–90 min, later runs faster; the speedrun timer fits naturally.

## Cheap things to do now (Phase 3), whatever is decided
- Keep **run state** (Gold, tier, kills, mounts, upgrades) separate from future
  **permanent state** in GameState. `reset_run()` already exists; don't let permanent-ish
  data leak into it.
- Put enemy/boss/price numbers in data with multipliers (already planned), so challenge
  modifiers are just more multipliers later.
- Track run time and first-clear times (already planned for the speedrun timer).

## Questions for Garret (before Phase 5)
1. Prestige in v1.0? ★ a light version at launch (victory prestige + small tree) / post-launch update / not at all.
2. When is the first prestige? ★ at victory (end of the 2.5–3.5 h run) / also a small early one mid-run.
3. Challenges? ★ Wildfrost-style pick-your-own modifiers / Slay the Spire ladder / none at launch.
4. Reward mix? ★ tree with starting kits + automation + a couple of new things / mostly multipliers.
