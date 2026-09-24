# 🎯 Idle Carousel — Phase 2 Goals (Core Loop)
### Version 1.0 — Approved

> The smallest version that's actually a game: the carousel spins, the Horse earns Gold
> at the booth, Leaves latch on and slow it down, and the Wolf clears them.
> Estimated time: 10–16 hours over several sessions. The Wolf sweep is the biggest unknown.

---

## Changelog
- **v1.1** — First-playtest changes (GDD v1.5): new Step 5b (smooth spin, Spin button, HUD labels, no click Gold, shop redesign). Step 10 now also covers extra Horses and Ticket Booths 2–4.
- **v1.0** — Approved by Garret. First draft. Built from the roadmap, Codex's Phase 2 brainstorm, and Garret's design decisions (GDD v1.4).

---

## The Working Model (updated for Phase 2)

**Garret = director, reviewer, and tweaker.** Approves every plan, reviews each scene in the editor and adjusts layout and feel, playtests, and makes every design call. Writes all player-facing text (button labels, upgrade names).

**Claude Code = implementer.** Writes scripts, tests, `.tres` data, **and first-draft scenes**. UI uses containers (MarginContainer, VBox/HBox, anchors) so Garret's tweaks don't break the layout. See CLAUDE.md → Workflow → Scenes.

**Codex = second opinion.** Brainstorms before big steps and reviews the diff before commits, when Garret asks.

**Every step follows the same loop:**
1. Claude Code plans in plan mode, including the node tree for any new scene. Garret approves.
2. Claude Code builds it, runs `tools/check.sh`, and lists what to check in the editor.
3. Garret opens the scene, saves it once so Godot assigns its IDs, tweaks, and playtests (F6 runs the current scene).
4. Short walkthrough, then one commit per step.

Placeholder UI text is fine while building. Mark it `# TODO(Garret): text`. Garret replaces it before anything ships.

---

## Design Decisions This Phase Uses (GDD v1.4)

| Topic | Decision |
|---|---|
| Booth income | Fixed amount per Horse pass. Speed means more passes, not bigger payouts. |
| Clicks | **Spin button** boosts spin (v1.5). Clicking an enemy damages it. Empty space does nothing. Clicks never pay Gold. |
| Spin boost | Each click adds a small bonus. Bonuses stack up to a cap and decay back to base. |
| Latch | Latched enemies hold their world position; the carousel grinds past underneath. |
| Drag | Adds up with **no floor**. Enough latches stop the carousel. |
| Zero health | **TEMPORARY** stall until latches are cleared, then a small refill. The real fail state is still DECISION PENDING. |
| Wolf | Pierces: hits every enemy in its line, each one once per pass. |
| Waves | The countdown always runs; auto-wave OFF pauses it (the toggle arrives in Phase 4). |
| Gold/sec | Rolling average of actual Gold earned over roughly the last 10 seconds. |
| Phase 2 shop | Spin Speed 1, Spin Speed 2, Click Damage 1, Mount Slot 2, Wolf, plus extra Horses and Ticket Booths 2–4 (v1.5). |
| Income | Horse booth passes + enemy kills. Horses × booths multiply; each extra Horse/booth costs more. |

---

## ✅ Step 1 — Test harness (GdUnit4) (45–75 min, Claude Code)

Moved here from Phase 1.

- [x] Review `Randroids-Dojo/Godot-Claude-Skills` and GdUnit4 before installing anything. Confirm they support Godot 4.7. *(GdUnit4 6.2.1 works on 4.7.2. The skills plugin was skipped: it's mostly CI and deploy tooling; revisit in Phase 7.)*
- [x] Install GdUnit4 into `addons/`; the check script already skips that folder.
- [x] One smoke test: `leaf.tres` loads and `gold_drop == 1.0`.
- [x] Add a headless test run to **both** `check.sh` and `check.bat`.
- [x] Extend `tools/check_scripts.gd` to also load every `.tscn`, so a broken scene fails the check. Claude Code will be writing scene files from now on.

- [ ] **Garret:** enable the plugin in Godot: Project → Project Settings → Plugins → gdUnit4 → Enable. This adds the GdUnit test panel to the editor.

**Done when:** the check runs the tests. Break the assertion on purpose and confirm the check fails, then restore it.

---

## ✅ Step 2 — GameState foundation + Game scene skeleton (45–60 min)

**Claude Code:** GameState functions and signals for Gold, spin speed, and carousel health, plus `reset_run()` so every test and playthrough starts clean. It also drafts `Game.tscn`:

```
Game (Node2D)                      game.gd
├── World (Node2D)                 centered on screen
│   ├── Carousel (Node2D)          placeholder circle drawn in code; rotates
│   │   └── MountSlots (Node2D)    Slot1..Slot6 (Marker2D)
│   ├── TicketBooth (Node2D)       fixed, top of the carousel
│   └── EnemyLayer (Node2D)        world space; enemies go here, never under Carousel
└── HUD (CanvasLayer)
    └── MarginContainer            full rect, 16px margins
        └── HBoxContainer
            ├── VBoxContainer      Gold, Gold/sec, health bar, wave countdown
            ├── Control            spacer (expand)
            └── ShopPanel          right side (filled in Step 5)
```

**Garret:** open it, save once, and adjust margins and positions to taste.
**Done when:** F6 on Game shows the carousel and an empty HUD with no errors, and GameState resets cleanly.

---

## ✅ Step 3 — Spin + click boost (45–75 min)

**Claude Code:** rotation in `_physics_process`, using an effective speed of base × upgrades × boost × (1 − drag), calculated in one place. The stacking, decaying click boost and click routing (enemy / play area / UI) come in this step too. Every tunable is `@export`.
**Garret:** tune the base speed, boost size, cap, and decay in the Inspector until it feels good.
**Tests:** boost stacks to the cap and decays to base; effective speed matches the formula.
**Done when:** clicking visibly speeds it up and it settles back smoothly.

---

## ✅ Step 4 — Horse, ticket booth, Gold HUD (60–90 min)

**Claude Code:** `mount_base.gd` and `mount_horse.gd`, booth pass detection that tracks angle travelled rather than the wrapped angle, a fixed payout per pass, the Gold burst on play-area clicks, the Gold and Gold/sec labels, and a coin pop placeholder.
**Garret:** position the booth, check that the pop reads, and tune the payout.
**Tests:** a 359°→1° wrap pays exactly once; sitting near the booth doesn't pay repeatedly; one tick spanning two turns pays twice; placing a mount pays nothing.
**Done when:** Gold climbs at a steady rhythm and Gold/sec looks right.

---

## ✅ Step 5 — Upgrade shop: Spin Speed 1 and 2 (45–60 min)

**Claude Code:** `upgrade_data.gd` Resource plus `.tres` files, a minimal UpgradeManager (`can_afford`, `purchase`, `is_purchased`, `upgrade_purchased` signal), and a ShopPanel draft (VBox of upgrade rows; affordable rows highlighted).
**Garret:** upgrade names and descriptions, button text, shop look.
**Tests:** 10 Gold minus a cost of 8 leaves 2; 7 Gold can't buy it; a one-time upgrade can't be bought twice; Spin Speed 2 needs Spin Speed 1.
**Done when:** you save up, buy, and see the carousel speed up.

---

## ✅ Step 5b — First-playtest fixes (Claude Code + Garret)

From Garret's first playtest (see `planning/phase2/codex_memo_e_playtest_feedback.md`).

- [x] **Smooth spin:** turn on physics interpolation, so the carousel draws smoothly on 60 Hz and 120 Hz screens without changing any gameplay math. *(Garret flips one project setting; code handles the rest.)*
- [x] **Boost button** below the carousel with a boost bar. Empty-space clicks do nothing. The Space key also presses it.
- [x] **No click Gold.** Gold comes from Horse passes (and kills from Step 6).
- [x] **HUD labels:** "Gold", "Gold per sec", "Speed ×1.35" (the multiplier of base speed).
- [x] **Shop:** every row stays listed with a fill bar toward its cost. Locked rows show what they need; bought rows stay in place, marked as bought.

**Done when:** the spin looks smooth, the Spin button clearly speeds it up, and the shop always shows what you're saving toward.

---

## Step 6 — One Leaf: approach, click damage, death (45–75 min)

**Claude Code:** `enemy_base.gd` and `enemy_leaf.gd` reading `leaf.tres`, a placeholder polygon plus health bar in an `Enemy.tscn` draft, approach movement, clicking to damage, dying exactly once, and a Gold drop. The **Click Damage 1** upgrade also goes in here.
**Garret:** check that the Leaf is readable and clickable at speed.
**Tests:** one death pays Gold once, even if it's hit twice in the same frame. Damage never changes `leaf.tres` itself (runtime health is separate).
**Done when:** a Leaf spawned by hand walks in and dies to clicks.

---

## Step 7 — Latch, drag, health, temporary stall (60–90 min)

**Claude Code:** the Leaf latches at the rim and holds its world position, drag adds up (no floor), latched enemies deal damage per second, and the TEMPORARY zero-health stall.
**Garret:** tune drag and damage. Watch the full-stop spiral: tense or hopeless? (See NOTES.)
**Tests:** two latched Leaves stack drag; killing one removes exactly its share; the stall ends when latches clear.
**Done when:** latches visibly slow the carousel, and clearing them brings it back.

---

## Step 8 — Wave countdown (45–75 min)

**Claude Code:** `wave_manager.gd` with a Timer and a countdown that always runs, spawning Leaves in groups of 3–5 around the edge. The countdown shows on the HUD.
**Garret:** tune the wave gap and group size.
**Done when:** waves arrive on a visible countdown and pressure builds.

---

## Step 9 — Wolf sweep (90–150 min)

**Claude Code:** `mount_wolf.gd` with ray queries that cover the whole angle swept each physics tick (so it doesn't miss at high spin). It pierces and hits each enemy once per pass. A dev-only way to place a Wolf without buying it is included for testing.
**Garret:** watch it at slow and fast spin; check the hit flash reads.
**Tests:** a Leaf between last tick's and this tick's angle still gets hit; several rays touching one Leaf count as one hit; two Leaves in line both get hit.
**Done when:** the Wolf reliably clears latched Leaves at every speed.

---

## Step 10 — Slots, Wolf, extra Horses, Ticket Booths (2–3 hours)

**Claude Code:** Mount Slot 2 (and 3) and Wolf as shop items, plus **extra Horses** (bought into empty slots, rising price, sell back for a partial refund) and **Ticket Booths 2–4** (rising price, re-spaced evenly). Mounts space themselves evenly by count. Moving a Horse or a booth never pays Gold. The dev-only Wolf shortcut is removed.
**Done when:** buying Slot 2 then Wolf works; buying a second Horse and Booth 2 roughly quadruples booth income; selling a Horse frees its slot; nothing pays from being moved.

---

## Step 11 — Five-minute playtest + walkthrough (90–120 min)

- [ ] Play 5 minutes actively and 5 minutes hands-off.
- [ ] Note three things: when the loop first felt satisfying, when clicking felt required, and what you wanted to buy next.
- [ ] Claude Code fixes bugs you find and turns any hard-coded numbers you'd want to tune into settings.
- [ ] Codex review of the full Phase 2 diff.
- [ ] Understanding check (below).

---

## ✅ Phase 2 Complete When:

- [ ] Check script passes, including tests
- [ ] The carousel spins; clicks boost; the Horse earns at the booth; Gold/sec is shown
- [ ] Leaves arrive on a countdown, latch, drag, and deal damage; the TEMPORARY stall works
- [ ] Clicking and the Wolf both kill Leaves, and each kill pays once
- [ ] All five purchases work
- [ ] **Understanding check:** Why do enemies live outside the Carousel node? How does the Wolf know it hit something? Why can't a booth pass be counted twice?
- [ ] You play for 5 minutes and want to keep going

**Then move to Phase 3: Content.**
