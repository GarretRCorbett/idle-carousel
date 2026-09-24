# 🗺️ Idle Carousel — Roadmap & Phase Tracker
### Version 1.0 — AI-First Build

> Replaces the Phase Goals Tracker in IDLE_CAROUSEL_NOTES.md.
> Each phase lists the goal, who does what, and a done-when check.
> Every phase ends with an **understanding check**: explain the phase's systems back
> without looking at the code. If you can't, do a walkthrough before moving on.

---

## Standing Split

| Claude Code does | Garret does |
|---|---|
| GDScript, Resource scripts, `.tres` data | Reviewing and tweaking scene layouts in the editor |
| Tests, tooling, and first-draft scene layouts (`.tscn`) | Reviewing every plan before code |
| Save/load, math, balance sheets | Playtesting and feel |
| Refactors and bug hunts | Design decisions (all DECISION PENDING items) |
| Explaining diffs | Art, audio, and player-facing text |

---

## Phase 1 — Project Setup ✅
**Goal:** Foundation plus Claude Code working on the repo with clear rules.
**Details:** `completed_phases/PHASE_1_GOALS.md`
- [x] Repo, project settings, folders, autoloads, tooling
- [x] `.gitignore` fix, CLAUDE.md, AGENTS.md, check scripts
- [x] Autoload order, first real commit, Resource scripts + `.tres`, placeholder scenes
- [x] ~~Optional: GdUnit4 harness~~ → moved to Phase 2

**Done when:** F5 runs clean, check script passes, Phase 2 plan reviewed.

---

## Phase 2 — Core Loop
**Details:** `PHASE_2_GOALS.md`
**Goal:** The smallest version that's actually a game: carousel spins, Horse earns Gold at the booth, Leaves latch and slow it down, Wolf clears them.

- [x] GdUnit4 test harness + headless test command in `tools/check.sh` (moved from Phase 1)
- [ ] Carousel spins with click-to-boost (spin speed in GameState)
- [ ] One Horse on a slot; ticket booth detects passes and pays a fixed amount per pass (speed = more passes)
- [ ] Gold counter and Gold/sec on the HUD via signals
- [ ] Leaves spawn on a timer in world space, approach, and latch
- [ ] Latch drag slows spin; latched enemies deal damage to carousel health
- [ ] Click a Leaf (approaching or latched) to damage it; Gold drop on kill; zero health = temporary stall
- [ ] Wolf sweep kills Leaves (ray-query sweep detection)
- [ ] Five purchases to prove the shop flow: Spin Speed 1, Spin Speed 2, Click Damage 1, Mount Slot 2, Wolf

**Claude Code:** scripts for carousel, booth, mount base, Horse, Wolf, enemy base, Leaf, wave timer, HUD, plus first-draft scenes (Game, Carousel, Mount, Enemy, HUD) with proper containers and anchors.
**Garret:** reviews and approves each scene in the editor, tweaks layout and look, tunes feel in the Inspector.
**Understanding check:** Why do enemies live outside the Carousel node? How does the Wolf know it hit something?
**Done when:** You can play for 5 minutes and want to keep going.

---

## Phase 3 — Content
**Goal:** All mounts, all enemies, all color tiers.

- [ ] Turtle, Eagle, Lion, Unicorn (behavior scripts + `.tres`)
- [ ] Stick and Rock enemies
- [ ] Six color tiers via Modulate, tier data in `.tres`
- [ ] Boss base class plus the six tier bosses
- [ ] Mount slots 2–6 and equidistant spacing (test 1, 2, and 6 mounts)

**Claude Code:** most of this; it's pattern replication once Phase 2's base classes exist.
**Garret:** playtest each mount against each enemy; pick placeholder shapes/colors.
**Understanding check:** How do mount_base and enemy_base get extended? Where does a tier's difficulty come from?

---

## Phase 4 — Systems
**Goal:** Progression that holds together over a full run.

- [ ] UpgradeManager: full tree from data, can_afford/purchase/is_unlocked, signals
- [ ] Upgrade Shop UI with the visibility states (affordable / almost / locked / hidden)
- [ ] Kill-count gate before each boss, visible in the HUD
- [ ] Save system: auto, milestone, manual; `user://save_data.json`
- [ ] Offline progress with the 8-hour clamp and "Welcome back" popup
- [ ] Wave controls: auto-wave toggle, next wave, Emergency Clear

**⚠️ Resolve before starting:** DECISION PENDING — death/fail state design.
**Claude Code:** UpgradeManager, save/load serialization, offline math, tests for all three.
**Garret:** shop layout in the editor; decide fail-state design.
**Understanding check:** What happens, step by step, when you click Buy? What's in the save file?

---

## Phase 5 — Endgame
**Goal:** Beat the Rusted King and see the restoration.

- [ ] Rusted King: multi-latch, Rust Breath, summons, enrage
- [ ] Victory sequence: rust particle burst, palette brighten, Restoration Complete screen
- [ ] High score saved; return to main menu
- [ ] First full playthrough, timed (target 2.5–3.5 hours)

**⚠️ Resolve before starting:** DECISION PENDING — prestige loop scope relative to playtime.
**Claude Code:** boss behavior, victory sequence logic, a balance spreadsheet/sim of the full run.
**Garret:** full playtest; tune the curve.

---

## Phase 6 — Polish
**Goal:** Looks, sounds, and feels like a real game. **Human-made assets only.**

- [ ] Sprites: Kenney/game-icons base recolored to one palette; carousel, horses, key pieces drawn by hand
- [ ] Audio: Kenney audio + Sonniss bundles; music layers (main, tension, boss, victory)
- [ ] Juice: tweens, particles, pulsing UI, sweep effects (code-driven effects are fine)
- [ ] Settings and statistics screens
- [ ] Steam Achievements via GodotSteam (Garret picks the list; Claude Code wires the unlock hooks to GameState signals)
- [ ] Balance pass
- [ ] Asset provenance log complete (asset, source URL, license, date)

**Claude Code:** AudioManager, effects code, settings/stats screens, balance tooling.
**Garret:** all art and audio choices, feel, final balance.

---

## Phase 7 — Ship
**Goal:** On Steam with a free demo.

- [ ] Steam page live early for wishlists (capsule and screenshots from real gameplay)
- [ ] Free demo build (non-negotiable for the genre)
- [ ] Steam Next Fest entry; consider Idler Fest timing for launch
- [ ] Trailer from real gameplay footage
- [ ] Short devlog; r/incremental_games post with the real backstory
- [ ] Export, test on a clean machine, launch at $4.99

**Claude Code:** headless export pipeline, build checks, store-page checklist.
**Garret:** store copy, trailer, community posts, launch.

---

## Next Concrete Step
_Update this line at the end of every session._

> Phase 2 Step 2: GameState foundation + Game scene skeleton (see `PHASE_2_GOALS.md`).
