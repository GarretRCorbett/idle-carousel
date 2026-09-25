# 🗺️ Idle Carousel — Roadmap & Phase Tracker
### Version 1.1 — AI-First Build
*v1.1 (2026-09-24): Phase 2 items ticked; Phase 3 gains minimal tier progression, timed bosses, and the simulator; prestige added to Phase 5 (GDD v1.10).*

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
| Explaining diffs; drafting player-facing text and translations | Art and audio; approving all player-facing text; store page, trailer text, credits |

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

## Phase 2 — Core Loop ✅
**Details:** `completed_phases/PHASE_2_GOALS.md` (signed off 2026-09-24)
**Goal:** The smallest version that's actually a game: carousel spins, Horse earns Gold at the booth, Leaves latch and slow it down, Wolf clears them.

- [x] GdUnit4 test harness + headless test command in `tools/check.sh` (moved from Phase 1)
- [x] Carousel spins with a Boost button (spin speed in GameState)
- [x] One Horse on a slot; ticket booth detects passes and pays a fixed amount per pass (speed = more passes)
- [x] Gold counter and Gold/sec on the HUD via signals
- [x] Leaves spawn on a timer in world space, approach, and latch
- [x] Latch drag slows spin; latched enemies deal damage to carousel health
- [x] Click a Leaf (approaching or latched) to damage it; Gold drop on kill; zero health = temporary stall (crank + safety net)
- [x] Wolf sweep kills Leaves (angle-math sweep detection, same idea as booth passes)
- [x] Leveled shop in three tabs (replaces the original "five purchases"): Carousel Speed, Boost Power, Ticket Booths 2–4, Click Damage, Wolf Fang, Mount Slots, Wolf, extra Horses (sell for 50%)
- [x] Extras built early: sprites (Horse, Wolf), UI theme, sound effects, main menu, backgrounds, Settings/Controls, wave controls (Send wave, Auto waves, Emergency Clear), 9 draft languages

**Claude Code:** scripts for carousel, booth, mount base, Horse, Wolf, enemy base, Leaf, wave timer, HUD, plus first-draft scenes (Game, Carousel, Mount, Enemy, HUD) with proper containers and anchors.
**Garret:** reviews and approves each scene in the editor, tweaks layout and look, tunes feel in the Inspector.
**Understanding check:** Why do enemies live outside the Carousel node? How does the Wolf know it hit something? Why can't a booth pass be counted twice? *(Passed 2026-09-24.)*
**Done when:** You can play for 5 minutes and want to keep going.

---

## Phase 3 — Content
**Goal:** All mounts, all enemies, all color tiers.

- [ ] Turtle, Eagle, Lion, Unicorn (behavior scripts + `.tres`)
- [ ] Stick and Rock enemies
- [ ] Six color tiers via Modulate, tier data in `.tres`
- [ ] Boss base class plus the six tier bosses
- [ ] Mount slots 4–6 (slots 2–3 and equidistant spacing were built in Phase 2)
- [ ] Minimal tier progression (pulled from Phase 4, Garret 2026-09-24): per-tier kill gate, "Challenge boss" button, timed boss fights (TEMPORARY rule), pick any unlocked tier to farm
- [ ] Mount Tier 2 upgrades, enough to unlock the Unicorn
- [ ] Run time and first-clear times tracked in GameState (speedrun timer and prestige later)
- [ ] Balance simulator v1 (economy only) and a pricing pass

**Plan:** `planning/phase3/README.md` (decisions, draft steps, open questions).

**Claude Code:** most of this; it's pattern replication once Phase 2's base classes exist.
**Garret:** playtest each mount against each enemy; pick placeholder shapes/colors.
**Understanding check:** How do mount_base and enemy_base get extended? Where does a tier's difficulty come from?

---

## Phase 4 — Systems
**Goal:** Progression that holds together over a full run.

- [ ] UpgradeManager: full tree from data, can_afford/purchase/is_unlocked, signals
- [ ] Upgrade Shop UI with the visibility states (affordable / almost / locked / hidden)
- [ ] Kill-count gate HUD polish (the gate itself is built in Phase 3)
- [ ] Save system: auto, milestone, manual; `user://save_data.json`; keeps permanent (prestige) state separate from the current run
- [ ] Offline progress with the 8-hour clamp and "Welcome back" popup
- [x] Wave controls: auto-wave toggle, next wave, Emergency Clear *(built in Phase 2, Step 10b)*
- [ ] Hold-to-boost automation (from Garret's playtest idea; see NOTES)
- [ ] Random Events (GDD): clickable pickups (speed/Gold surges, Lucky Ticket) and surprise visitors (Wandering Horse, Pop-up Booth), data-driven

**⚠️ Resolve before starting:** DECISION PENDING — death/fail state design.
**Claude Code:** UpgradeManager, save/load serialization, offline math, tests for all three.
**Garret:** shop layout in the editor; decide fail-state design.
**Understanding check:** What happens, step by step, when you click Buy? What's in the save file?

---

## Phase 5 — Endgame
**Goal:** Beat the Rusted King, see the restoration, then prestige into a faster run.

- [ ] Rusted King: multi-latch, Rust Breath, summons, enrage
- [ ] Victory sequence: rust particle burst, palette brighten, Restoration Complete screen
- [ ] High score saved; return to main menu
- [ ] First full playthrough, timed (target 2.5–3.5 hours)
- [ ] Prestige (in v1.0, GDD v1.10): reset after the Rusted King, prestige currency, small permanent upgrade tree (starting kits, automation, multipliers, a couple of new things)
- [ ] Challenge modifiers after the first win (Wildfrost Storm Bells / Slay the Spire Ascension style) that raise prestige rewards
- [ ] Second-run playtest: run 2 should feel much faster (target ~60–90 min)

**Before starting:** Garret designs the prestige details (tree nodes, currency, which modifiers). Research: `planning/phase3/claude_memo_prestige.md`.
**Claude Code:** boss behavior, victory sequence logic, prestige reset and tree, extending the Phase 3 balance simulator to the full run and run 2.
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

## Target Timeline (Steam Next Fest June 2027)
A game gets only one Next Fest, so this is the one.
- **Jan 2027:** Steam store page live as "Coming Soon" (capsule art, screenshots, one strong GIF). Start collecting wishlists and share the first build on r/incremental_games.
- **Apr 25, 2027:** Next Fest registration deadline.
- **May 17, 2027:** Demo and store page ready for the press preview.
- **June 14–21, 2027:** Steam Next Fest.
- **After Next Fest:** Launch at $4.99 while the wishlists are fresh.
- **Stretch:** Localize the store page first, then the game (common idle-game markets: Simplified Chinese, Japanese, Korean, German, Brazilian Portuguese, Russian).

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

> Phase 2 Step 11 wrap-up in a fresh session: follow `planning/phase2/step11_plan.md` (playtest, doc tidy, walkthrough, sign-off). Then plan Phase 3 (more mounts).
