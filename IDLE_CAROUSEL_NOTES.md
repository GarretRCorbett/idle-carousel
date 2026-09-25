# 📓 Idle Carousel — Dev Notes & Thoughts
### Version 1.4

> Running notes, to-dos, design thoughts, and things to revisit.
> Keep the GDD clean — messy thinking goes here.
> This is a living document. Add freely, clean up occasionally.

---

## Changelog
- **v1.4** — Cleanup after Phase 2: removed items that are done (soft drag fixed the full-stop spiral, per-language fonts, booth/spacing issues) or now scheduled in the roadmap; kill gate moved to Phase 3; prestige is in v1.0; speedrun timer added.
- **v1.3** — Added Next Concrete Step. Phase tracker moved to IDLE_CAROUSEL_ROADMAP.md.
- **v1.2** — Removed Sparks. All upgrades Gold only. Updated to-dos and balance notes to reflect single currency. Removed Sparks drop rate from balance concerns.
- **v1.0/1.1** — Initial notes

---

## ▶️ Next Concrete Step
_Update at the end of every session._

> **Phase 3 (2026-09-25):** Steps 2–6 done: every Phase 3 mount, tier colors, bigger waves, the first boss (Leaf Storm) with the boss strip, tier pips and gating. Garret's two playtests went well (strip shifting fixed). Step 7 boss questions answered (GDD v1.15). Step 7 is built: all six tier bosses, tuned headless. Palette research ready (memo T, renders in `planning/phase3/palette/`). Garret picked palette A (Gilded Garden) and it's applied, with a theme-park look. Step 8 is built: `tools/economy_sim.tscn` plus a pricing pass that hits Garret's pace at 1 click/s (results and three open questions in `planning/phase3/step8_results.md`). Next: Garret playtests bosses, look and prices; then Step 9 (full playtest, Codex review, sign-off). Status: `planning/phase3/README.md`.

---

## 🚧 To-Do / Things To Add

### Themes, someday (Garret, 2026-09-25)
- [ ] Idea: selectable themes with the same enemy workings but new names and art (an original theme-park lineup, Halloween pumpkins, Christmas snowballs). Not now. Codex memo U (`planning/phase3/codex_memo_u_theming.md`): feasible, about M for one reskinned enemy lineup and L for a full theme. Keep these habits meanwhile: no gameplay checks on display names, stable ids, looks in exports/resources, visual size separate from hitboxes.

### Auto-clickers (Garret, 2026-09-25, after Step 8)
- [ ] Clicking speed swings run length a lot in the sims (1 click/s ≈ 2:36, 2 clicks/s ≈ 1:16). Playtest first and keep it in mind.
- [ ] Plan an **auto-clicker for enemies** and one **for Boost**. They could come after a prestige, as a very expensive shop item, or as a relic or random event. Design this with the prestige tree (GDD v1.10 already lists automation there).

### Tier colors and progression feel (Garret, 2026-09-25)
- [ ] **Tier color order feels off.** Grey is a good start, but maybe grey → green → yellow → orange → red → black reads better as "getting stronger". Claude + Codex researching color order and what players expect (studies, game conventions, Steam/Reddit); memo in `planning/phase3/`. Tier colors are also in the GDD, so a change is a GDD update.
- [ ] **Force the first boss early**, before too many more upgrades, tier colors, or tier switching. Open: how the boss challenge and tier selection look (another shop tab? buttons under the shop? a new panel on the right?). Claude + Codex drafting options (Phase 3 Step 6 builds it).

### Balance: Wolf vs Leaf tiers (Garret, 2026-09-24)
- [ ] Wolf does 1.5 per hit so a Grey Leaf takes 2 passes. Players may meet tougher Leaf tiers before buying the Wolf; revisit Wolf damage (and Wolf Fang) when tiers exist.

### Gameplay Gates
- [ ] **Enemy kill count per tier** — now **Phase 3** (Garret, 2026-09-24): any enemy kill in the tier counts; once met, a "Challenge boss" button starts a timed fight. Memo M's starting numbers: 60 / 80 / 100 / 120 / 140 / 160 kills (Clicker Heroes' ~10 per stage is too fast for our waves). Details in `planning/phase3/README.md`.

### Fail state direction (Garret, 2026-09-24)
- [ ] **Core feel: idle first, pressure when pushing.** A well-upgraded tier should run safely forever; danger comes from pushing tiers and bosses. Codex's memo (`planning/phase2/codex_memo_g_fail_state.md`) argues carousel health duplicates drag and suggests a speed floor plus automatic overload recovery instead. Both rules are playable now via `fail_rule` in run_config.tres. After playtesting, Garret kept health (HEALTH_STALL) and chose memo H's Package A ("safe farm, risky push"): a stall costs the attempt and time, never Gold or unlocks; offline has no fights and booth-only income. Tuning going in with the Wolf is listed in `planning/phase2/README.md`. Update the GDD's DECISION PENDING fail state once it's confirmed in play. Boss rule for Phase 3 playtests (timed, failure costs time only, unlimited cranks): `planning/phase3/README.md`.

### Balance (tune during playtesting — don't set in stone early)
- [ ] Gold per second at each tier
- [ ] Enemy Gold drop rates — if too low, Combat tree feels inaccessible; if too high, Carousel tree gets maxed too fast
- [ ] Ticket Booth 2 timing — should feel like mid-game "wow", not too early
- [ ] Boss Gold bonus — should feel meaningfully larger than regular enemy drops
- [ ] The Rusted King health pool — long but not frustrating
- [ ] Offline Gold cap (currently 8 hours) — adjust based on playtesting
- [ ] **Offline rate source (decide in Phase 4)** — the HUD's Gold/sec is recent *actual* income (includes kills and clicks). Offline progress probably should use booth income only, shown separately. Decide when building offline progress.

### Localization (2026-09-24)
- [ ] **Plurals:** use `tr_n()` + CSV plural rows the first time text depends on a count. Never `if n == 1`.
- [ ] **Review translation drafts** (added 2026-09-24, Claude drafts per the text policy): es, fr, de, pt_BR, ru, zh_CN, ja, ko columns in `localization/strings.csv`. Garret approves (or has native speakers check) before shipping.
- [ ] **Adding a language:** add a CSV column, register its `.translation` in Project Settings (a test fails if you forget), and if it needs a new script, add a font in `LocaleFonts` + `tools/subset_fonts.py`. Re-run `python tools/subset_fonts.py` whenever CJK text changes (a test fails if a character is missing).

### Scope ideas to revisit later
- [ ] **Roguelike element** (Garret, 2026-09-24): the itch came from wanting more mounts. Parked to protect v1.0 scope; revisit while designing prestige (Phase 5).

### Prestige is in v1.0 (Garret, 2026-09-24)
- [ ] Design the details before Phase 5: tree nodes, prestige currency, which challenge modifiers. Direction is in the GDD (Prestige, v1.10); research in `planning/phase3/claude_memo_prestige.md`.
- [ ] Revisit the parked **roguelike element** (above) as part of that design: challenge modifiers and new prestige unlocks may scratch the same itch.

### Speedrun timer (Garret, 2026-09-24)
- [ ] An optional run timer so players can speedrun, e.g. "fresh start to Tier 5." Garret wants to plan for it. Scope (v1.0 or later) not decided yet.
- **Plan for it now (cheap):** GameState tracks active play time from the start of the run (memo M already suggests this for saves/stats) and records the time each boss is first beaten, so splits come for free. Keep wave randomness seeded per run so runs are comparable, and keep offline progress out of speedrun time (or disable it for a speedrun). Later: an in-game timer display with splits per tier, and maybe a "speedrun mode" toggle on New Game.

### QoL Ideas (post v1.0 unless easy)
- [ ] **Auto-boost option** (Garret, 2026-09-24): now in the roadmap (Phase 4, hold-to-boost) and a candidate prestige automation node.
- [ ] **Idle base speed feels slow** (Garret, 2026-09-24): Phase 3 pricing pass tests 60°/s (Phase 3 README, question 22).
- [ ] Tooltip on each mount showing current stats
- [ ] Speed up button (2× game speed toggle) — careful: it conflicts with speedrun timing and the balance model
- [ ] Statistics screen (total gold, enemies killed, time played) — roadmap Phase 6
- [ ] Save/load buttons in Settings (volume sliders and language are done)
- [ ] **Display options (Phase 6):** Fullscreen is exclusive now; also offer Borderless, and maybe a VSync/frame-limit option. Laptop + external monitor players can get jitter when the monitor hangs off the other GPU (Garret's MSI did; see `planning/phase2/README.md`), so consider a short tip.
- [ ] **Sound taste + music (Garret, 2026-09-24):** current SFX feel off (not a bug); simple carousel-style background music may fix a lot. Phase 6.
- [ ] "Welcome back" notification showing offline Gold earned — part of Phase 4 offline progress

### Post v1.0 Only (don't touch until shipped)
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
The gap between the Sloth (3rd mount) and Giraffe (4th mount) is probably the hardest
stretch of early game. Watch this in playtesting. If it feels punishing, either
tune the Giraffe's unlock cost down or make Spin Speed upgrades available at lower Gold cost.

### On Panda unlock requirement
"Requires 3 other mounts at Tier 2+" may be too gating if Gold is tight.
Fallback: change to "3 other mounts unlocked" (not Tier 2) if playtesting
shows the Panda arrives too late. Tune cost before changing requirement.

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

- Mount spacing at 6 mounts — spacing works for any count (tested up to 3 in Phase 2);
  re-test at 4–6 when slots 4–6 arrive in Phase 3.
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
