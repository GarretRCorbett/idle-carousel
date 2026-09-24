# 📓 Idle Carousel — Dev Notes & Thoughts
### Version 1.3

> Running notes, to-dos, design thoughts, and things to revisit.
> Keep the GDD clean — messy thinking goes here.
> This is a living document. Add freely, clean up occasionally.

---

## Changelog
- **v1.3** — Added Next Concrete Step. Phase tracker moved to IDLE_CAROUSEL_ROADMAP.md.
- **v1.2** — Removed Sparks. All upgrades Gold only. Updated to-dos and balance notes to reflect single currency. Removed Sparks drop rate from balance concerns.
- **v1.0/1.1** — Initial notes

---

## ▶️ Next Concrete Step
_Update at the end of every session._

> Phase 2 Step 6: One Leaf (approach, click damage, death) + Click Damage 1. Steps 2–5 done; plans and design memos in `planning/phase2/`.

---

## 🚧 To-Do / Things To Add

### Gameplay Gates
- [ ] **Enemy kill count per tier** — need a minimum kills before boss spawns
  - Prevents players from auto-waving straight to The Rusted King underpowered
  - Clicker Heroes uses ~10 kills per stage as the model
  - Simple implementation: `kills_this_tier: int` counter in GameState (already in v1.2 GameState structure)
  - Boss spawn condition: `kills_this_tier >= required_kills[current_tier]`
  - Can tune required kills per tier separately (early = 10, later = 20?)
  - Add during tier system build (Phase 4) — it's a number + condition, not a system

### Balance (tune during playtesting — don't set in stone early)
- [ ] Gold per second at each tier
- [ ] Enemy Gold drop rates — if too low, Combat tree feels inaccessible; if too high, Carousel tree gets maxed too fast
- [ ] Ticket Booth 2 timing — should feel like mid-game "wow", not too early
- [ ] Boss Gold bonus — should feel meaningfully larger than regular enemy drops
- [ ] The Rusted King health pool — long but not frustrating
- [ ] Offline Gold cap (currently 8 hours) — adjust based on playtesting
- [ ] **Full-stop spiral (watch in Phase 2 playtest)** — drag has no floor (GDD v1.4), so enough latches stop the carousel. A stopped carousel earns no booth Gold and mounts don't sweep, so only clicks can recover. Check it feels tense, not hopeless. If hopeless, options: a drag floor, or stronger clicks while stopped.
- [ ] **Offline rate source (decide in Phase 4)** — the HUD's Gold/sec is recent *actual* income (includes kills and clicks). Offline progress probably should use booth income only, shown separately. Decide when building offline progress.

### QoL Ideas (post v1.0 unless easy)
- [ ] Tooltip on each mount showing current stats
- [ ] Speed up button (2× game speed toggle)
- [ ] Statistics screen (total gold, enemies killed, time played)
- [ ] Settings panel (volume sliders, save/load buttons)
- [ ] "Welcome back" notification showing offline Gold earned

### Post v1.0 Only (don't touch until shipped)
- [ ] Prestige/ascension system
- [ ] Mount placement customization mode
- [ ] Spell/mana mount type
- [ ] Multiple carousel skins
- [ ] Steam Trading Cards

---

## 💭 Design Thoughts

### On going Gold-only
Single currency was the right call. The latch mechanic already forces combat engagement — a latched enemy slows the carousel which slows Gold income. That's a more elegant constraint than a separate currency. If playtesting reveals players ignore combat upgrades anyway, consider making combat upgrade costs scale higher than carousel upgrades to create natural prioritization pressure — but try the simple version first.

### On the kill count gate
Make the kill counter VISIBLE in the HUD so players always know where they stand.
"Kill 10 more enemies to face the boss" is clear. A vague "not strong enough yet" is not.
Clicker Heroes is good at this — always tells you exactly what's needed.

### On difficulty curve
The gap between Turtle (3rd mount) and Eagle (4th mount) is probably the hardest
stretch of early game. Watch this in playtesting. If it feels punishing, either
tune Eagle unlock cost down or make Spin Speed upgrades available at lower Gold cost.

### On Unicorn unlock requirement
"Requires 3 other mounts at Tier 2+" may be too gating if Gold is tight.
Fallback: change to "3 other mounts unlocked" (not Tier 2) if playtesting
shows Unicorn arrives too late. Tune cost before changing requirement.

### On single-currency balance
With Gold doing everything, the main balance risk is one tree getting maxed while the other feels neglected. Watch for:
- Players maxing Carousel Tree and having an overpowered economy but weak combat
- Players maxing Combat Tree and having powerful mounts but slow Gold generation
Both are fine if the player recovers — neither should feel like a dead end. The latch mechanic naturally punishes over-indexing on economy (enemies slow Gold) and under-indexing on economy (can't afford upgrades). Trust the system before tuning.

### On offline progress
Standard is 50% of online rate. Add a "welcome back" notification showing
exactly how much was earned while away — players love this number, it's
a real retention hook.

---

## 🐛 Known Issues / Things To Revisit

- Mount equidistant spacing — test edge cases (1 mount, 2, full 6)
- Ticket Booth 2 trigger — Horse needs to detect BOTH booths, not just Booth 1.
  Make trigger data-driven, not hardcoded to one position.
- Emergency Clear cooldown — 60 seconds might be too long for returning players.
  Consider: free but limited uses per session instead of cooldown.

---

## 📚 Godot Lessons From Carousel Defender (apply here)

- **Autoloads for persistence** — GameState, SaveManager, AudioManager
- **`call_deferred()` for scene transitions inside physics callbacks**
- **`global_position` when crossing scene boundaries** — mounts on carousel
  (local space) need to hit enemies in world space
- **Signals for loose coupling** — carousel emits events, game.gd listens
- **Resources for data** — MountData/EnemyData = one scene, many .tres files
- **Timer nodes for recurring events** — spawning, auto-save, offline calc
- **Max Polyphony on AudioStreamPlayer** — set 4+ for overlapping sounds
- **No class_name on Autoload scripts** — causes name collision error

---

## 🎯 Phase Goals Tracker

Moved to `IDLE_CAROUSEL_ROADMAP.md`.

---

## 🔗 Reference Links

- GDD: `IDLE_CAROUSEL_GDD.md`
- Roadmap: `IDLE_CAROUSEL_ROADMAP.md`
- Carousel Defender repo: https://github.com/GarretRCorbett/carousel-defender
- Godot 4.7 docs: https://docs.godotengine.org
- Kenney assets: https://kenney.nl/assets
- OpenGameArt CC0: https://opengameart.org
- Lospec palettes: https://lospec.com/palette-list
- r/incremental_games: https://reddit.com/r/incremental_games
