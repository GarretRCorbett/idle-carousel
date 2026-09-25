# 🎠 Idle Carousel — Game Design Document
### Version 1.15 | Working Title: Idle Carousel
> Solo dev project. Built in Godot 4.7 stable. Target: Steam release, anonymous, $4.99 (sale target ~$3.49–$3.75), with a free demo.
> Personal motivation: daughters love carousels.
> Influences: Cookie Clicker, Clicker Heroes, A Game About Feeding a Black Hole, Rusty's Retirement.

---

## Changelog
- **v1.15** — Boss details for Phase 3 Step 7 (Garret): Gilded Gale trickles summons, Ancient Log blunts its first 3 hits, Boulder's latch points have their own health, Obsidian Boulder is two stages; every split piece must die for a win.
- **v1.14** — First boss and gating (Garret, Phase 3 Step 6): Leaf Storm drifts, warns, and throws packs of ~20 storm leaves (then splits into 4); boss strip above the carousel with numbered tier pips; beaten bosses can be re-fought for a smaller reward; Horse and Wolf are the only mounts before it; waves are about twice as big. Details: `planning/phase3/step6_plan.md`.
- **v1.13** — Tier colors reordered (Garret): Grey → Green → Yellow → Orange → Red → Charcoal (light outline), a danger ramp. Boss summon/split colors to re-pair.
- **v1.12** — Mounts repicked to match the Kenney Animal Pack art (Garret, Phase 3 start): **Turtle → Sloth**, **Eagle → Giraffe**, **Lion → Elephant**, **Unicorn → Panda**. Abilities are unchanged; animal-specific upgrade names drafted by Claude, approved by Garret (Drowsy, Deep Sleep, Long Neck, Double Take, Trumpet, Trunk Toss, Bamboo Feast, Lucky Bamboo). The slow icon becomes a sleepy "Zzz".
- **v1.11** — After the Phase 2 wrap-up playtest (Garret): **mounts can be doubled and sold** (not just Horses), so players can swap builds, e.g. an extra Horse for income, then sell it for a second Wolf before a boss. Wolves now (up to the slot count, 50% refund); the Phase 3 mounts follow the same rule. Tuning: base speed 70°/s (was 45), max boost +40% (was +50%), waves every 10 s (was 20). Send wave is blocked while more than 30 enemies are alive (revisit with Sticks and Rocks). Enemy clicks get a sound and a small pop.
- **v1.10** — Prestige is **in v1.0** (Garret): after beating the Rusted King you can prestige, start a fresh run, and keep permanent boosts. Direction: a small permanent upgrade tree (starting kits, automation, multipliers, a couple of new things) and optional challenge modifiers after the first win (Wildfrost Storm Bells / Slay the Spire Ascension style) that raise prestige rewards. Details are designed before Phase 5. Resolves the prestige-scope DECISION PENDING. Also: bosses are timed challenges reached through a per-tier kill gate (TEMPORARY rule for Phase 3 playtests; see `planning/phase3/README.md`).
- **v1.9** — Wave controls pulled into Phase 2 (Garret): Next Wave button + N key with a +50% kill-Gold early-send bonus and a full countdown restart; Auto Wave toggle; Emergency Clear priced from normal booth income (20 s, min 25, 60 s cooldown). Settings and Controls screen; backgrounds (top-down park for play, fall landscape for the menu).
- **v1.8** — After the first Leaf playtest (Garret): drag softens as it stacks (speed ÷ (1 + total drag)), so Boost always helps and only the stall stops the carousel. Latched enemies deal no damage for their first 2 s. Health regenerates slowly while nothing is latched. TEMPORARY stall additions: Boost cranks a stalled carousel back (restart at 15% health, enemies stay), and a 60 s safety net clears enemies. Fail-state direction: "safe farm, risky push" (a stall costs the attempt and time, never Gold or unlocks); still DECISION PENDING until confirmed in play.
- **v1.7** — Overdrive: hold the Boost bar at max for 5 s for ×2 speed until it drops (gold glow). New Random Events section (Golden-Cookie-style pickups and surprise visitors), planned for Phase 4. Speed bonuses from any source multiply together.
- **v1.6** — Shop pacing (Garret): upgrades have levels. Spin Speed 1–4 become **Carousel Speed** (+20% base speed per level, 10 levels); new **Boost Power** (+10% max boost per level, 10 levels); **Ticket Booth** starts at 500 Gold. Each level costs ×1.5 the last. Boost bar takes 10 presses to fill and fades over 4 s; the carousel glows while boost is maxed.
- **v1.5** — First-playtest changes (Garret): a dedicated Spin button replaces click-anywhere boosting; clicks never pay Gold (Gold comes from Horse booth passes and enemy kills); extra Horses can be bought into empty slots (rising price) and sold back for a partial refund; up to 4 ticket booths, re-spaced evenly, rising price; only Horse passes pay at booths; HUD labels plus a Speed ×multiplier; shop keeps every row listed with a progress fill, bought rows stay marked.
- **v1.4** — Phase 2 design decisions: booth pays a fixed amount per pass (spin speed scales frequency only, not payout); click rules and stacking spin boost defined; latched enemies hold their world position; latch drag adds up and can stop the carousel; Wolf pierces, hitting each enemy once per pass; slots 2–3 buyable from the start, slots 4–6 unlocked by bosses then bought with Gold; wave countdown always runs; shop may use tabs, Gold stays the only currency; HUD Gold/sec is recent actual income; temporary zero-health stall for Phase 2 (fail state still pending).
- **v1.3** — Steam Achievements moved into v1.0 scope. Price set to $4.99. Added Asset & AI Policy section. Marked the two open design questions (fail state, prestige scope) as DECISION PENDING. Fixed Godot version note.
- **v1.2** — Removed Sparks currency. All upgrades now cost Gold only. Simplified to single-currency economy. Removed Combat Tree as a separate tab — combat upgrades merged into a unified Upgrade Shop. GameState updated to remove sparks variable.
- **v1.1** — Internal notes version
- **v1.0** — Initial design

---

## Table of Contents
1. Vision Statement
2. Core Loop
3. Game Phases
4. Currency
5. The Carousel
6. Mounts
7. Enemies
8. Upgrade Trees
9. Random Events
10. Progression & Tier System
11. Final Boss
12. Prestige
13. UI & HUD
14. Save System
15. Audio
16. Art Direction
17. Technical Architecture
18. Scope Definition
19. Post-Launch Ideas

---

## Vision Statement

A spinning playground carousel defends itself against waves of encroaching debris and enemies. Animal mounts placed on the carousel generate resources and fight back as they sweep past threats. The faster the carousel spins, the more powerful everything becomes — but enemies latch on and slow it down if not dealt with.

The player's job: keep the carousel spinning, upgrade the mounts, collect Gold from the ticket booth, and push through enemy tiers until the Rusted King is defeated and the carousel is restored to its former glory.

**One sentence pitch:** "An idle game where a spinning carousel is both your engine and your weapon."

**What makes it unique:**
- Spin speed is a single stat that affects EVERYTHING — resource generation, mount attack rate, combat damage, and ticket booth income all scale with carousel speed
- Physical latch mechanic — enemies grab the carousel and visibly slow it down, making combat feel tactile and urgent
- Two modes coexist naturally — active players click enemies and boost spin, idle players let mounts handle everything
- The carousel is a visual centerpiece that is always doing something interesting to watch

---

## Core Loop

```
Carousel spins → Ticket booth generates Gold each pass
      ↓
Player clicks to boost spin speed + damage approaching enemies
      ↓
Mounts sweep past enemies as carousel rotates → auto-attack + Gold
      ↓
Spend Gold on upgrades (faster spin, more mounts, better combat)
      ↓
Enemies approach automatically on a timer, latch on, slow spin
      ↓
Mounts + clicking clear latched enemies
      ↓
Defeated enemies drop bonus Gold
      ↓
Push to next enemy tier when ready for harder enemies + better rewards
      ↓
Defeat tier boss → unlock next color tier, new mount slot, new upgrade
      ↓
Repeat, scaling up until the Rusted King
```

**The five more minutes engine:**
The upgrade shop always shows the next affordable upgrade highlighted and pulsing. The next tier is always visible but just out of reach. Players can always see exactly what they are saving toward. This is the most important design principle in the game — never leave the player without a visible goal.

---

## Game Phases

The game does NOT have distinct build phase and combat phase that the player switches between. Everything happens simultaneously and continuously:

- Enemies spawn automatically on a visible countdown timer
- The carousel always spins (speed varies based on upgrades and latch drag)
- Mounts always sweep and trigger on each rotation
- The ticket booth always collects on each Horse pass
- The player can always click at any time for any purpose

**What the player controls:**
- When to push to the next enemy tier (manual escalation)
- What to spend Gold on
- Active clicking (enemies, spin boost, or both)
- Auto-wave toggle (on = the countdown runs and sends waves; off = the countdown pauses and the player sends waves manually)
- Emergency Clear button (costs Gold, removes all latched enemies — for returning after being away)

**The natural tension:**
Enemies always pressure the carousel — you cannot just idle forever without consequence. But you choose when to escalate. Grinding the current tier is always an option if the next tier feels too hard.

---

## Currency

### Gold — The Only Currency
- **Primary source:** Ticket booth generates a fixed amount of Gold each time the Horse mount passes it. Spin speed scales how *often* that happens, not the amount per pass: spin faster = booth passed more often = more Gold per minute. Horse upgrades raise the per-pass amount. (Scaling payout with speed too would make income grow with speed², which is hard to balance.)
- **No click Gold:** clicking never pays Gold directly. The Spin button speeds the carousel up, which makes the Horses pass booths sooner.
- **Combat source:** Defeated enemies drop bonus Gold. Stronger enemies in higher tiers drop more. Tier bosses give a large Gold bonus.
- **Spent on:** Everything — spin speed, mount slots, ticket booth upgrades, carousel health, click damage, mount ability upgrades, mount tier upgrades.
- **Feel:** Constant, steady flow with exciting spikes from combat. The heartbeat of the game.

**Design note:** Single currency keeps the loop clean and readable. The latch mechanic naturally forces combat engagement without needing a separate currency to gate combat upgrades — a latched enemy slows your Gold income directly, so ignoring combat always has an immediate economic consequence.

---

## The Carousel

### Visual
Top-down view. A circular rotating platform. The center has a decorative hub. Six mount positions evenly distributed around the ring. As mounts are added they space themselves equidistantly (1 mount = top, 2 = opposite sides, 3 = triangle, etc.).

A **Ticket Booth** sits fixed in the world just outside the carousel edge at the top of the screen. It does not rotate. Each time the Horse passes it, a coin animation pops and Gold is added.

### Spin Speed
The single most important stat in the game. Affects:
- How often each mount triggers (sweeps past enemies or ticket booth). Like booth Gold, mount damage per hit is fixed; faster spin means more hits per minute, not harder hits (upgrades like Wolf Fang raise damage per hit)
- How quickly the carousel recovers from latch slowdown

### Spin Button and Clicking
- **Spin button** (below the carousel, with a boost bar): each press adds a small temporary speed bonus. Bonuses stack up to a cap and decay back to base speed over a couple of seconds (cap and decay are tunable). Rapid pressing is rewarded but never required.
- **Click an enemy:** damages it (approaching or latched). Clicking an enemy never boosts spin.
- **Clicking empty space** does nothing. **UI buttons and panels** never count as game clicks.
- **Overdrive:** keep the Boost bar at max for 5 seconds and speed doubles (×2) until the bar drops back below 80%. The carousel and Boost bar glow gold while it lasts. It rewards active play without being required. Hold time and multiplier are tunable.

### Health
The carousel has a health bar. Enemies that successfully latch deal damage over time until removed.

> **⚠️ DECISION PENDING — Death / fail state.** Current draft: at zero health the carousel stops (Game Over), and the player respawns at the start of the current tier with a Gold penalty. Open questions: Is a hard Game Over right for an idle game, especially while offline? Should zero health instead stall the carousel until repaired? How big is the penalty? **Resolve before Phase 4.** Agents: do not implement or change this without Garret's decision.
>
> **Temporary Phase 2 behavior (Garret's call, placeholder only):** at zero health the carousel stalls (stops spinning) until the latched enemies are cleared, then health refills a little (25%). While stalled, the Boost button cranks it back instead (restart at 15%, enemies stay). After 60 s stalled, enemies are cleared and it restarts at 25%. Mark it TEMPORARY in code; it is replaced once the real fail state is decided.
>
> **Direction so far (v1.8, Garret):** "safe farm, risky push." A stall costs the current attempt (a boss or pushed tier) and earning time, never saved Gold or unlocks. Offline: no fights, booth-only income, and you return to a healthy carousel. See `planning/phase2/codex_memo_h_health_offline.md`.

### Latch Mechanic
When an enemy reaches the carousel edge it latches on. Visually the enemy grabs the rim and a drag effect slows the carousel. The slowdown is immediately visible and tactile.

- **Latched enemies hold their world position.** The carousel grinds past underneath them, so every mount sweeps past each latched enemy once per rotation.
- **Drag adds up and softens as it stacks (v1.8).** Speed is divided by (1 + total drag); Leaf `latch_drag` is 0.05, so four Leaves = about 17% slower and twenty = half speed. Drag alone never stops the carousel, so Boost always helps; only the zero-health stall stops it.
- **Latch grace and regen (v1.8).** A new latch deals no damage for its first 2 seconds. Health slowly regenerates while nothing is latched.

To remove a latched enemy: click it directly, OR wait for a combat mount to sweep past it, OR use Emergency Clear.

### Ticket Booths (up to 4)
The game starts with one booth at the top. More booths are bought in the shop, up to 4, each costing more than the last. Booths re-space evenly as they're added (2 = opposite sides, 3 = 120° apart, 4 = 90° apart); moving a booth never pays Gold. Only **Horse** passes pay at booths. Booth 2 is a major Gold generation upgrade and one of the most satisfying visual moments in the game.

### Income Formula
Gold/sec from booths = Horses × booths × turns per second × Gold per pass. Horses and booths multiply each other, which is why both get more expensive with each purchase.

---

## Mounts

Six total mounts. Unlocked progressively. Each occupies one carousel slot. Each has a fixed role and sweep behavior.

### Mount Behavior Types

**Stationary Mounts** — positioned at a fixed point on the carousel. Their trigger fires each time they complete a full rotation past their designated target point.

**Sweeping Mounts** — fire in a straight line outward at whatever is in their path as the carousel rotates. Their line of sight sweeps 360 degrees continuously.

---

### Horse — The Generator
- **Type:** Stationary
- **Role:** Primary Gold generation
- **Behavior:** Positioned near the ticket booth pass point. Generates a fixed amount of Gold each time it passes the booth. Faster spin means more passes per minute; upgrades raise the amount per pass.
- **Does NOT attack enemies**
- **Starting mount** — player begins with one Horse
- **Extra Horses (v1.5):** more Horses can be bought into empty mount slots, each costing more than the last. A Horse can be sold back for a partial refund to free its slot. Every slot is a choice: another Horse for income, or a combat mount for defense. (v1.11: every mount type works this way, see Mount Slot Progression.)
- **Art:** Classic carousel horse. Brown/chestnut. Simple side silhouette from top-down. Coin icon appears on booth pass.
- **Color tier:** Saddle color changes per tier (grey → green → yellow → orange → red → charcoal)
- **Upgrades:** Tier 2 doubles Gold per pass. Tier 3 generates Gold on every sweep not just booth passes. Lucky Horseshoe adds a small triple-Gold chance.

---

### Wolf — The Cleaner
- **Type:** Sweeping
- **Role:** Primary combat — clears latched enemies
- **Behavior:** Fires outward in a line as it rotates. The line pierces: it damages every enemy in its path, each enemy at most once per pass. Particularly effective against latched enemies since it passes them on every rotation.
- **Art:** Wolf silhouette top-down. Dark grey. Jaws open in attack position. Slash visual on enemy hit.
- **Color tier:** Eye glow color changes per tier
- **Upgrades:** Wolf Fang 1/2/3 increases damage. Pack Mentality adds an offset second sweep.

---

### Sloth — The Defender
- **Type:** Stationary
- **Role:** Crowd control — slows approaching enemies
- **Behavior:** As it rotates past approaching enemies (before they latch), it applies a Slow debuff. Slowed enemies move at 50% speed and have a visible slow icon above their head (a sleepy "Zzz"). Slow lasts 3 seconds.
- **Art:** Kenney Animal Pack sloth. "Zzz" icon appears above affected enemies.
- **Color tier:** An accent (saddle/collar) color changes per tier
- **Upgrades:** Drowsy 1/2/3 increases slow duration. Deep Sleep converts slow to a brief freeze (the enemy dozes off).

---

### Giraffe — The Scout
- **Type:** Sweeping, extended range
- **Role:** Long-range — hits enemies before they reach the carousel
- **Behavior:** Fires outward at significantly longer range than Wolf. Can hit enemies still approaching from a distance before they latch. Counter to fast Leaf swarms — the Giraffe's long neck reaches them mid-approach.
- **Art:** Kenney Animal Pack giraffe. Headbutt/strike visual on distant hit.
- **Color tier:** An accent (saddle/collar) color changes per tier
- **Upgrades:** Long Neck 1/2/3 extends range further. Double Take makes it fire twice per sweep.

---

### Elephant — The Heavy
- **Type:** Sweeping, wide arc
- **Role:** AoE — hits multiple latched enemies simultaneously
- **Behavior:** Instead of a single line, the Elephant sweep covers a wider arc. Hits all enemies within that arc. Particularly effective when multiple enemies are latched at the same section of the rim.
- **Art:** Kenney Animal Pack elephant. Trumpet/shockwave arc visual on sweep.
- **Color tier:** An accent (saddle/headdress) color changes per tier
- **Upgrades:** Trumpet 1/2/3 increases arc width. Trunk Toss adds knockback that flings latched enemies outward.

---

### Panda — The All-Rounder
- **Type:** Sweeping
- **Role:** Hybrid — Gold generation plus combat plus heal
- **Behavior:** Generates a small Gold amount on each sweep (less than Horse). Deals damage to enemies in sweep path (less than Wolf). On enemy kill, restores a small amount of carousel health.
- **Unlock requirement:** Must have upgraded at least 3 other mounts to Tier 2.
- **Art:** Kenney Animal Pack panda. Sparkle trail follows sweep path.
- **Color tier:** An accent (saddle/collar) color shifts through tier colors
- **Upgrades:** Bamboo Feast increases all three effects by 50%. Lucky Bamboo adds a chance to double Gold on sweep.

### Mount Slot Progression
Start with 1 slot (Horse only). Slots are always bought with Gold in the Upgrade Shop:
- **Slots 2 and 3:** in the shop from the start.
- **Slots 4, 5, and 6:** appear in the shop after beating the first, second, and third tier bosses.

A slot and its mount are separate purchases (e.g., buy Mount Slot 2, then buy Wolf to fill it).

**Doubling and selling (v1.11):** any mount type can be bought more than once (each costs more than the last) and sold back for a partial refund (50%) to free its slot, so players can reshape the carousel: Horses for income while farming, extra Wolves for a boss push. The starting Horse can't be sold. Built for the Horse and Wolf in Phase 2; the Phase 3 mounts follow the same rule. Mount-tier upgrades apply **per type** (every Wolf shares Wolf Tier 2), so selling one never loses an upgrade (Garret, v1.11).

Mount placement is automatic — they distribute equidistantly as added. No manual placement in v1.0.

---

## Enemies

Three base enemy types. Each appears in six color tiers. Tier bosses have special abilities.

### Color Tier System
Same color language applies to both enemies and mount upgrades so players learn it once:

| Tier | Color | Power Level |
|---|---|---|
| 1 | Grey | Starter |
| 2 | Green | Moderate |
| 3 | Yellow | Challenging |
| 4 | Orange | Hard |
| 5 | Red | Very Hard |
| 6 | Charcoal (light outline) | Pre-boss / Elite |

v1.13 (Garret, 2026-09-25): a danger ramp like WoW's enemy-difficulty colors (grey, green, yellow,
orange, red), darker as tiers rise, ending in charcoal with a light outline so it stays visible.
Research and a colorblind check: `planning/phase3/codex_memo_p_tier_colors.md`. Colorblind players
tell Green through Red apart mostly by brightness, so tier UI also shows the tier number.

Implementation: enemy art is light grey; the tier color multiplies it (Sprite2D self_modulate).
Same sprite, different tint = different tier. One sprite per enemy type supports all tiers.

---

### Leaf — The Swarmer
- **Speed:** Fast
- **Health:** Low (1-2 hits)
- **Latch drag:** Small
- **Behavior:** Spawns in groups of 3-5. Approaches quickly. Easy to kill individually but overwhelming in numbers if ignored.
- **Threat type:** Quantity. Tests whether the Giraffe can intercept fast movers before mass-latching.
- **Art:** Autumn leaf shape top-down. Orange/gold. Tumbles as it moves. Small and readable.
- **Gold on kill:** Low (but kills happen frequently)

---

### Stick — The Steady
- **Speed:** Medium
- **Health:** Medium (3-5 hits)
- **Latch drag:** Medium
- **Behavior:** Approaches alone or in pairs. Consistent steady threat. No special abilities.
- **Threat type:** Sustained pressure. Tests whether Wolf can keep up with continuous arrivals.
- **Art:** Stick/branch shape. Brown. Slightly elongated oval from top-down. Distinctive silhouette from Leaf and Rock.
- **Gold on kill:** Medium

---

### Rock — The Tank
- **Speed:** Slow
- **Health:** High (6-10 hits)
- **Latch drag:** Large — a latched Rock significantly slows the carousel
- **Behavior:** Approaches alone. Very tough to kill. Once latched drags hard. Forces the player to focus clicks on highest priority target.
- **Threat type:** Single high-priority target.
- **Art:** Round rock shape. Grey. Slightly irregular circle. Larger than Leaf and Stick.
- **Gold on kill:** High

---

### Tier Bosses

| Boss | Based On | Special Ability |
|---|---|---|
| Leaf Storm | Leaf | Drifts along an arc beyond the Wolf's reach; every ~12 s it stops, gathers wind (a warning), and throws a pack of ~20 weak storm leaves. Click it; your mounts defend. On death splits into 4 Grey Leaves that must die too (v1.14) |
| Stick Giant | Stick | Moves in zigzag — harder to intercept with the Giraffe |
| Boulder | Rock | Has 3 separate latch points, each with its own health (drag drops as each breaks); rolls faster near carousel |
| Gilded Gale | Leaf | A steady trickle of its tier's Leaves (about 2 every 4 s) while alive; summons pay nothing (v1.15) |
| Ancient Log | Stick | Immune to Sloth slow (and freeze); its first 3 hits do reduced damage |
| Obsidian Boulder | Rock | Two stages: on first kill splits into 2 Red Rocks; every piece must die for the win (v1.15) |
| The Rusted King | Final Boss | See Final Boss section |

Killing a boss awards a large Gold bonus, unlocks the next color tier, makes the next mount slot available to buy (first three bosses), and may unlock a new upgrade node.

---

## Upgrade Trees

Two trees. Both cost Gold. Upgrades always show the next tier even if locked so the player can always see what they are working toward.

### Upgrade Visibility System
- **Affordable now:** Highlighted, pulsing gently, buy button active
- **Almost affordable (within 20% of cost):** Visible, greyed out, shows cost and current amount
- **Locked (requires previous upgrade):** Visible as silhouette, shows requirement text
- **Hidden (far future):** Completely hidden until prerequisites met — surprise unlocks feel like discoveries
- **Progress fill (v1.5):** every visible row shows a fill bar of current Gold toward its cost
- **Bought:** the row stays in place, compact and marked as bought, so rows never shift under the cursor

---

### Carousel Tree (Gold)

| Upgrade | Effect |
|---|---|
| Carousel Speed (levels 1–10) | +20% base spin speed per level — immediate visual feedback |
| Boost Power (levels 1–10) | +10% max Boost per level |
| Mount Slot 2-6 | Unlocks additional mount positions (4–6 require a boss first) |
| Ticket Booths 2–4 | Extra booths, re-spaced evenly; first costs 500, each ×1.5 the last |
| Carousel Health 1/2/3 | Max health increased |
| Polish and Shine | +10% to all Gold generation |
| Gilded Rims | Cosmetic glow plus +5% Gold |
| Offline Efficiency | Increases offline Gold rate from 50% toward 75% |

---

### Combat Tree (Gold)

| Upgrade | Effect |
|---|---|
| Click Damage 1/2/3 | Clicks deal significantly more damage |
| Click Range | Click hitbox larger — easier to hit fast Leaves |
| Click Combo | Rapid clicks within 1 second build a 2x damage multiplier |
| Wolf Fang 1/2/3 | Wolf sweep damage increased |
| Long Neck 1/2/3 | Giraffe range extended |
| Trumpet 1/2/3 | Elephant arc width increased |
| Drowsy 1/2/3 | Sloth slow duration extended |
| Trunk Toss | Elephant knockback added |
| Double Take | Giraffe fires twice per sweep |
| Pack Mentality | Wolf fires offset second sweep |

---

### Mount Upgrades (Gold)

| Upgrade | Effect |
|---|---|
| Wolf Tier 2/3 | Speed and damage increase, then damage trail |
| Sloth Tier 2/3 | Slow duration doubled, then freeze added |
| Giraffe Tier 2/3 | Range extended significantly, then fires twice |
| Elephant Tier 2/3 | Arc doubled, then knockback added |
| Horse Tier 2/3 | Gold per pass doubled, then Gold on every sweep |
| Panda Unlock | Requires 3 other mounts at Tier 2 |
| Panda Tier 2 | All Panda effects plus 50% |
| Bamboo Feast | Panda effects doubled |

---

## Random Events

Short, surprising bonuses that break up the idle rhythm, in the spirit of Cookie Clicker's golden cookies. Planned for **Phase 4 (Systems)**; the speed-modifier plumbing already exists (Overdrive uses it).

### Two kinds
- **Clickable pickups:** a glowing token drifts in or appears somewhere on screen for a few seconds. Click it before it fades to get its effect. Missing it costs nothing.
- **Surprise visitors:** something just happens, with no click needed, and the screen says so.

### Effect ideas (tune in playtesting)
| Event | Kind | Effect |
|---|---|---|
| Speed Surge | Pickup | ×2 to ×4 speed for 10–20 s |
| Golden Hour | Pickup | ×2 or ×3 Gold from booth passes for 15–30 s |
| Lucky Ticket | Pickup | Flat Gold bonus (a few minutes of current income) |
| Wandering Horse | Visitor | A temporary extra Horse rides the carousel for 30–60 s (takes no slot) |
| Pop-up Booth | Visitor | A temporary extra ticket booth appears for 30–60 s |

### Rules
- Bonuses from different sources **multiply** (Overdrive ×2 during a ×3 Speed Surge = ×6). Two of the same event don't stack; the second refreshes the timer.
- Events are purely good. They never punish the player for not clicking.
- Timing is random within a window (e.g. every 2–5 minutes), tunable, and never during a boss intro.
- Offline: events don't happen while away.
- Each event is a `.tres` (effect, strength, duration, weight) so new events are data, not code.

---

## Progression and Tier System

### Early Game (Grey Tier — first 15-20 minutes)
- Start: Horse only, Grey Leaves approaching
- First goal: Survive first wave by clicking
- First purchase: Carousel Speed level 1 (immediate satisfaction)
- Second purchase: Mount Slot 2 + Wolf (game transforms — now have auto-combat)
- Third purchase: Slot 3: a second Wolf or a second Horse (v1.14: Horse and Wolf are the only mounts before the first boss)
- Boss: Leaf Storm (after 60 Grey kills, a manual Challenge): a timed fight (90 s) that teaches the split between clicking (the boss) and mounts (defense). Failure costs only time.
- Reward: Green Tier unlocked, Slot 4 available to buy, Giraffe/Sloth/Elephant/Panda, Tier 2 upgrades, extra booths, and Speed/Boost past level 3 (v1.14)

### Mid Game (Green through Purple)
- Enemies get tougher, spawn faster
- Extra ticket booths come online (major Gold surge moments)
- Giraffe and Elephant come online
- Click Combo upgrade changes active play feel
- Boss types introduce new behaviors

### Late Game (Gold through Red)
- All mounts in play
- Both ticket booths active
- Upgrade trees largely maxed
- Enemy combinations intense — Rocks plus Leaf swarms simultaneously
- Charcoal tier enemies are pre-boss difficulty

### Endgame
After defeating the Charcoal tier boss, the Rusted King appears.

---

## Final Boss — The Rusted King

An enormous ancient carousel horse, long neglected and consumed by rust. It moves slowly but with terrible weight. Its arrival is telegraphed — the music shifts, the screen edges darken slightly, and the enemy counter shows a skull icon.

**Visual:** A massive deteriorated carousel horse silhouette. Rust texture with broken jagged edges. Eyes glow dull red. Chains trail behind it. Dramatically larger than all other enemies — roughly 3x the size of a Rock.

**Health:** Enormous — the longest fight in the game.

**Special mechanics:**
1. **Multi-latch:** Three separate latch points. All three must be cleared to remove its drag. While all three are latched the carousel slows to near-stop.
2. **Rust Breath:** Periodically exhales a rust cloud that temporarily reduces all mount damage by 50% for 5 seconds. Shown as a brown tint over the carousel.
3. **Summon:** Every 30 seconds summons 3 Grey Leaves — tests whether the player can manage boss plus adds simultaneously.
4. **Enrage:** Below 25% health, speed increases significantly and Rust Breath cooldown halves.

**Victory sequence:**
The Rusted King defeated. All rust flakes away in a particle burst. The carousel color palette brightens — dull greens become vibrant, the rim gleams. Music swells from tense to triumphant. A "Restoration Complete" screen shows the carousel now gleaming and beautiful with a final score display. Credits roll.

**The emotional note:** The ending is a restoration. For a dad whose daughters love carousels, this is the payoff — something beautiful that was forgotten is brought back to life.

After the victory screen the player can **prestige** (see Prestige) and start a new, faster run.

---

## Prestige

**Decided (v1.10, Garret):** prestige ships in v1.0. **Details are designed before Phase 5**; research and a first shape are in `planning/phase3/claude_memo_prestige.md`.

- **When:** after beating the Rusted King. The first run stays a complete game on its own (2.5–3.5 h); prestige is the reason to keep playing, not where the best part is hidden.
- **What carries over:** a prestige currency earned from the run (e.g. from bosses beaten), spent in a small **permanent upgrade tree** (roughly 15–25 nodes). Direction for the tree: starting kits (e.g. begin with Slot 2 and the Wolf), automation (e.g. auto-boost, auto-challenge bosses), Gold/damage multipliers, and one or two new things the first run didn't have.
- **What resets:** the run: Gold, tiers, kills, mounts, and run upgrades.
- **Feel:** prestige must feel like acceleration, never punishment. Run 2 should clear Grey in minutes; target roughly 60–90 min for run 2, faster after.
- **Challenge modifiers (direction):** after the first win, optional modifiers that make a run harder and raise its prestige reward, in the style of Wildfrost's Storm Bells (pick your own, each worth points) or Slay the Spire's Ascension (a stacking ladder). Mostly built from data that already exists: enemy tier multipliers, wave sizes, boss timers, prices.
- **Bosses:** near-idle boss wins are meant to come only after a prestige or two, or a truly maxed build.
- **Speedruns:** run time and first-clear times are tracked from Phase 3, so prestige runs and challenge modifiers double as speedrun categories later.

---

## UI and HUD

### Always visible
- Speed shown as a multiplier of base speed (e.g. Speed ×1.35), so upgrades, the Spin button, and drag are visible at a glance
- Gold counter (top left) with Gold per second shown below it: a rolling average of all Gold actually earned over the last ~10 seconds (booth passes and kills), so it visibly drops when enemies latch. The offline earning rate is shown separately (e.g., shop footer or tooltip) once offline progress exists.
- Carousel health bar
- Current enemy tier indicator
- Wave countdown timer showing when next wave arrives

### Upgrade Shop
- Panel on right side of screen
- May be split into 2–3 tabs (e.g., Carousel / Combat / Mounts) for readability. Every cost is in Gold; tabs organize, they never introduce a second currency.
- Affordable upgrades highlighted, next-tier upgrades visible but locked
- No scrolling required in early game

### Wave Controls
Built in Phase 2 (v1.9), in the stats panel:
- Auto Wave toggle button — when ON, the wave countdown always runs and sends the next wave when it hits zero, whether or not the last wave is cleared. When OFF, the countdown pauses. Remembered between sessions (default ON).
- Next Wave manual button (also the N key) — shows the countdown and sends the next wave immediately. **Early-send bonus (v1.9):** that wave's enemies drop +50% Gold, paid only on kills, so sending waves can't be farmed. The countdown then restarts at a full interval, so waves never pile up by accident. **Send limit (v1.11):** Send wave is blocked while more than 30 enemies are alive (tunable); Auto waves still arrive on their timer. Revisit once Sticks and Rocks exist (one early wave at a time is the alternative).
- Emergency Clear button — removes all latched enemies (no kill Gold) and ends a stall. **Price (v1.9):** 20 seconds of normal booth income (unboosted, no drag, so latches can't discount it), minimum 25 Gold; 60 second cooldown; usable only while something is latched.

### Mount Info
- Clicking a mount slot shows a small popup with mount name, current tier, stats, and upgrade button
- Mount tier shown as a small colored gem on the carousel slot

### Simplicity principle
No floating damage numbers in v1.0. Enemy health shown as a simple health bar above each enemy. Slow debuff shown as a sleepy "Zzz" icon. Latch shown as a chain visual on the carousel rim.

---

## Save System

### Three-layer saving via SaveManager Autoload

**Auto-save:** Every 60 seconds silently in the background. A small save icon flashes briefly in the corner.

**Milestone save:** Triggered instantly on every purchase, upgrade, or tier progression. No purchase is ever lost.

**Manual save:** Available in the pause/settings menu.

### Offline Progress
On game load, SaveManager checks the timestamp of the last save against current time and calculates:

```
offline_gold = gold_per_second x offline_seconds x offline_efficiency_rate
```

The offline efficiency rate defaults to 0.5 (half rate while offline). This makes returning feel rewarding without being game-breaking and incentivizes active play. The rate can be upgraded in the Carousel Tree.

A "Welcome back" popup on load shows how much Gold was earned offline and for how long.

### What is saved
- Gold amount
- All upgrades purchased (dictionary of upgrade IDs to bool)
- All mounts placed and their tiers
- Current enemy tier
- Carousel health
- Timestamp of save (for offline progress calculation)
- Total playtime
- Settings (volume, auto-wave preference)

### Save file
Godot user:// directory. save_data.json — human readable for debugging during development.

### GameState Autoload structure
```gdscript
extends Node
# Single source of truth for all runtime game data

var gold: float = 0.0
var gold_per_second: float = 0.0
var carousel_health: float = 100.0
var carousel_max_health: float = 100.0
var carousel_spin_speed: float = 1.0
var current_tier: int = 1
var kills_this_tier: int = 0
var mounts_placed: Array = []
var upgrades_purchased: Dictionary = {}
var last_save_timestamp: int = 0
var total_playtime: float = 0.0
var total_gold_earned: float = 0.0
var total_enemies_killed: int = 0
var high_score: int = 0
var settings: Dictionary = {
    "music_volume": -5.0,
    "sfx_volume": 0.0,
    "auto_wave": false
}
```

---

## Audio

### Music
- **Main theme:** Upbeat, whimsical, looping. Feels like a real carousel. Chiptune or light orchestral.
- **Tension layer:** Adds subtle minor key shift or extra percussion when enemies are actively latched and carousel is slowing.
- **Boss theme:** Distinct heavier track for Rusted King fight.
- **Victory theme:** Triumphant swell on Rusted King defeat. Non-looping, plays once.

### Priority SFX
- Ticket booth coin collect — satisfying ding, plays very often, must not get annoying
- Mount sweep hit — distinct sound per mount type
- Enemy latch — grabbing/scraping sound
- Enemy defeat — light pop for Leaf, thud for Stick, crack for Rock
- Carousel slowdown — pitch shift on ambient spin sound
- Purchase — classic upgrade chime
- Upgrade unlock — bigger chime, slightly different tone
- Emergency Clear — whoosh plus pop

### AudioManager Autoload
Persistent AudioStreamPlayer nodes. Music persists across scene changes. Max Polyphony set to 4 or higher on all SFX players to allow rapid overlapping sounds.

---

## Art Direction

### Style
Top-down 2D. Simple readable silhouettes. Autumn park color palette. Charming not realistic. Every asset must be readable at a glance — if you cannot identify what something is within half a second, redesign it.

### Color Palette
- Background: Deep warm grey #3D3530
- Carousel base: Forest green #4A7A3D
- Carousel rim: Darker green #2D5A25
- Ticket booth: Warm red #C4553A with cream details
- Gold coins: Warm yellow #F2C94C
- Leaf enemy: Autumn orange #E07B39
- Stick enemy: Warm brown #8B5E3C
- Rock enemy: Slate grey #7A7A8C

### Sprite Sizes (Aseprite)
- Carousel base: 200x200px
- Mounts: 32x32px
- Leaf enemy: 24x24px
- Stick enemy: 24x24px
- Rock enemy: 32x32px
- Rusted King: 96x96px
- Ticket booth: 48x48px
- UI icons: 16x16px

### Per-Asset Notes

**Carousel:** Circle with subtle spoke details. Green base, darker rim ring, small center hub.

**Ticket Booth:** Small rectangular structure. Red roof, cream window, small flag on top. Does not rotate.

**Horse:** Side profile from top-down (like looking down at a carousel horse from above). Chestnut brown. Simple saddle. Reads as horse immediately.

**Wolf:** Predatory silhouette top-down. Dark grey. Open jaws facing outward. Reads as dangerous.

**Sloth:** Kenney Animal Pack sloth. Calm, sleepy face; reads as "slow" at a glance.

**Giraffe:** Kenney Animal Pack giraffe. Yellow with spots; the long neck communicates long range.

**Elephant:** Kenney Animal Pack elephant. Big ears and trunk; reads as heavy, wide area effect.

**Panda:** Kenney Animal Pack panda. Black and white, gentle; a special late unlock (sparkle effects make it feel rare).

**Leaf:** Autumn leaf shape. Orange/gold. Slightly asymmetric. Tumbles as it moves.

**Stick:** Elongated oval/branch shape. Brown. Slightly irregular edges. Clearly different silhouette from Leaf and Rock.

**Rock:** Round irregular circle. Grey. Slightly bumpy edge. Larger than Leaf.

**Rusted King:** Enormous carousel horse silhouette. Rust texture with broken edges. Red glowing eyes. Chains trailing. Dramatically larger than all other enemies.

### Color Tier Implementation
Use Godot Modulate property on Sprite2D to tint the base sprite with the tier color. Same sprite, different modulate = different tier. This keeps art to ONE sprite per enemy type while supporting all six tiers with no extra art work.

### Asset & AI Policy
- AI tools are used for code, and (since 2026-09-24) for drafting in-game text (UI labels, tooltips, upgrade names and descriptions) and machine-translation drafts, which Garret reviews and approves before anything ships. No AI-generated images, audio, or voice anywhere, including the Steam capsule, screenshots, and trailer. Store page copy, trailer text, and credits are Garret's.
- Art base: Kenney.nl (CC0) and game-icons.net (CC BY 3.0, credit line required), recolored to one custom palette. Centerpiece sprites (carousel, horses, key upgrades) drawn by hand in Aseprite/LibreSprite.
- Fonts: Google Fonts (OFL). SFX: Kenney audio and Sonniss GDC bundles.
- Other itch.io/OpenGameArt assets only from long-standing creators, marked non-AI, CC0/CC-BY only (no GPL or ShareAlike).
- Keep a provenance log (asset, source URL, license, date) and the original zips.
- Procedural effects in code (shaders, particles, tweens) are fine for polish, not as the main art style.

---

## Technical Architecture

### Scene Structure
```
Main (Node)
└── Game (Node2D)
    ├── Carousel (Node2D)
    │   ├── CarouselBase (Sprite2D)
    │   ├── CarouselRim (Sprite2D)
    │   ├── CenterHub (Sprite2D)
    │   ├── HitZone (Area2D)
    │   │   └── CollisionShape2D
    │   └── MountSlots (Node2D)
    │       ├── Slot1 through Slot6 (Node2D)
    ├── TicketBooth (Node2D — fixed, not on carousel)
    ├── TicketBooth2 (Node2D — unlocked via upgrade)
    ├── EnemyLayer (Node2D — enemies in world space)
    ├── ProjectileLayer (Node2D — mount projectiles in world space)
    ├── ClickLayer (Node2D — handles click detection)
    └── HUD (CanvasLayer)
        ├── GoldLabel
        ├── GoldPerSecLabel
        ├── HealthBar
        ├── TierLabel
        ├── WaveTimer
        ├── UpgradeShop (Panel)
        └── WaveControls
            ├── AutoWaveToggle
            ├── NextWaveButton
            └── EmergencyClearButton
```

### Four Autoloads
**GameState** — all runtime data. Single source of truth. Read by all systems, written only through controlled functions.

**SaveManager** — handles file I/O. Reads and writes save_data.json. Handles offline progress calculation on load. Called by GameState on milestone saves.

**AudioManager** — persistent AudioStreamPlayers. play_music(), play_sfx(), stop_music(). Prevents music restart on scene changes.

**UpgradeManager** — owns the full upgrade tree definition. Provides can_afford(), purchase(), is_purchased(). Emits signals when upgrades are purchased so other systems can react without direct coupling.

### Key Scripts
```
res://scripts/
├── autoloads/
│   ├── game_state.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   └── upgrade_manager.gd
├── carousel.gd
├── mount_base.gd          — base class all mounts extend
├── mount_horse.gd
├── mount_sweeper.gd       — line/wedge sweep: Wolf and Giraffe (data only); base for Sloth, Elephant, Panda
├── mount_sweep.gd         — the sweep hit math each sweeping mount owns
├── mount_sloth.gd
├── mount_elephant.gd
├── mount_panda.gd
├── enemy_base.gd          — base class all enemies extend
├── enemy_leaf.gd
├── enemy_stick.gd
├── enemy_rock.gd
├── enemy_boss.gd          — extends enemy_base, adds special ability system
├── enemy_rusted_king.gd   — extends enemy_boss, final boss behavior
├── enemy_data.gd          — Resource class for enemy stats
├── mount_data.gd          — Resource class for mount stats
├── upgrade_data.gd        — Resource class for upgrade definitions
├── wave_manager.gd        — controls enemy spawning and tier progression
├── ticket_booth.gd        — detects horse passes, generates Gold
├── hud.gd
└── upgrade_shop.gd
```

### Important Architecture Principles

Enemies and projectiles live in world-space nodes outside the Carousel node. Only mounts and slots are children of Carousel (rotate with it). This is the most important structural decision — everything else flows from it.

Use global_position when crossing the carousel/world boundary.

Use call_deferred() when changing scenes from physics callbacks.

Use signals for loose coupling between systems. The carousel does not need to know about the HUD. The HUD listens for signals. The UpgradeManager emits signals when upgrades are purchased and other systems react independently.

Timer nodes for recurring events (wave spawning, auto-save, offline progress tick).

Export ALL tunable values. No magic numbers in code. Every speed, damage value, cost, and duration is either an exported variable or defined in a Resource file. Balance passes happen entirely in the Inspector or by editing .tres files without touching scripts.

class_name on all major scripts for type safety and autocomplete.

Mount sweep behavior uses global_rotation to calculate the sweep line in world space — same pattern as Carousel Defender pinwheels but more sophisticated.

---

## Scope Definition — What Done Means

v1.0 is complete when a player can:
1. Start a new game from the main menu
2. Play through all 6 color tiers with all 3 base enemy types
3. Unlock and upgrade all 6 mounts
4. Purchase all upgrades in both trees
5. Defeat the Rusted King
6. See the victory and restoration screen
7. Return to main menu with their high score saved
8. Prestige after the victory and start a faster run with permanent upgrades
9. Return the next day and have offline Gold waiting for them
10. Earn Steam Achievements for milestones (via the GodotSteam addon; achievement list TBD by Garret)

Target playtime for a complete first run: 2.5 to 3.5 hours.

> **Prestige scope (resolved v1.10, Garret):** prestige ships in v1.0, after the Rusted King. See Prestige. Its details (tree nodes, currency, challenge modifiers) are designed before Phase 5.

### Explicitly NOT in v1.0
- Multiple carousel types or skins
- Free mount placement
- Mobile support
- Multiplayer
- More than 6 enemy tiers
- More than 6 mount slots
- More than 3 base enemy types
- Story or dialogue
- Animated sprites (static sprites only)
- Mana or spell mount type

---

## Post-Launch Ideas

Save these for after v1.0 ships. Do not build during v1.0 development.

- Carousel skins as prestige rewards (prestige itself is in v1.0)
- Free mount placement mode unlocked after first clear
- Mana/spell mount with AoE burst damage and long cooldown
- Second carousel — harder parallel run with different enemies
- Seasonal event skins (Halloween, winter)
- Steam Cloud saves
- Speedrun mode with leaderboard (Garret wants a run timer planned; v1.0 scope not decided. Run and split times are tracked from Phase 3.)
- Desktop overlay mode (Rusty's Retirement style)

---

*GDD Version 1.11*
*Created: June 2026*
*Status: Design complete, ready for development*
