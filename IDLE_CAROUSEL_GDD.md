# 🎠 Idle Carousel — Game Design Document
### Version 1.5 | Working Title: Idle Carousel
> Solo dev project. Built in Godot 4.7 stable. Target: Steam release, anonymous, $4.99 (sale target ~$3.49–$3.75), with a free demo.
> Personal motivation: daughters love carousels.
> Influences: Cookie Clicker, Clicker Heroes, A Game About Feeding a Black Hole, Rusty's Retirement.

---

## Changelog
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
9. Progression & Tier System
10. Final Boss
11. UI & HUD
12. Save System
13. Audio
14. Art Direction
15. Technical Architecture
16. Scope Definition
17. Post-Launch Ideas

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

### Health
The carousel has a health bar. Enemies that successfully latch deal damage over time until removed.

> **⚠️ DECISION PENDING — Death / fail state.** Current draft: at zero health the carousel stops (Game Over), and the player respawns at the start of the current tier with a Gold penalty. Open questions: Is a hard Game Over right for an idle game, especially while offline? Should zero health instead stall the carousel until repaired? How big is the penalty? **Resolve before Phase 4.** Agents: do not implement or change this without Garret's decision.
>
> **Temporary Phase 2 behavior (Garret's call, placeholder only):** at zero health the carousel stalls (stops spinning) until the latched enemies are cleared, then health refills a little. Mark it TEMPORARY in code; it is replaced once the real fail state is decided.

### Latch Mechanic
When an enemy reaches the carousel edge it latches on. Visually the enemy grabs the rim and a drag effect slows the carousel. The slowdown is immediately visible and tactile.

- **Latched enemies hold their world position.** The carousel grinds past underneath them, so every mount sweeps past each latched enemy once per rotation.
- **Drag adds up with no floor.** Each enemy's `latch_drag` is a fraction of spin speed (Leaf 0.05 = 5% slower); three Leaves = 15% slower. Enough latched enemies can stop the carousel completely.

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
- **Extra Horses (v1.5):** more Horses can be bought into empty mount slots, each costing more than the last. A Horse can be sold back for a partial refund to free its slot. Every slot is a choice: another Horse for income, or a combat mount for defense.
- **Art:** Classic carousel horse. Brown/chestnut. Simple side silhouette from top-down. Coin icon appears on booth pass.
- **Color tier:** Saddle color changes per tier (grey → green → blue → purple → gold → red)
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

### Turtle — The Defender
- **Type:** Stationary
- **Role:** Crowd control — slows approaching enemies
- **Behavior:** As it rotates past approaching enemies (before they latch), it applies a Slow debuff. Slowed enemies move at 50% speed and have a visible slow icon above their head (snowflake). Slow lasts 3 seconds.
- **Art:** Turtle top-down shell view. Green with pattern. Snowflake icon appears above affected enemies.
- **Color tier:** Shell pattern color changes per tier
- **Upgrades:** Shell 1/2/3 increases slow duration. Permafrost converts slow to a brief freeze.

---

### Eagle — The Scout
- **Type:** Sweeping, extended range
- **Role:** Long-range — hits enemies before they reach the carousel
- **Behavior:** Fires outward at significantly longer range than Wolf. Can hit enemies still approaching from a distance before they latch. Counter to fast Leaf swarms — the Eagle intercepts them mid-approach.
- **Art:** Eagle wings spread top-down. Brown with white head. Talon strike visual on distant hit.
- **Color tier:** Wing tip color changes per tier
- **Upgrades:** Eagle Eye 1/2/3 extends range further. Dive Bomb makes it fire twice per sweep.

---

### Lion — The Heavy
- **Type:** Sweeping, wide arc
- **Role:** AoE — hits multiple latched enemies simultaneously
- **Behavior:** Instead of a single line, the Lion sweep covers a wider arc. Hits all enemies within that arc. Particularly effective when multiple enemies are latched at the same section of the rim.
- **Art:** Lion top-down, mane visible as a ring. Gold color. Roar/shockwave arc visual on sweep.
- **Color tier:** Mane color changes per tier
- **Upgrades:** Lion Roar 1/2/3 increases arc width. King's Wrath adds knockback that flings latched enemies outward.

---

### Unicorn — The All-Rounder
- **Type:** Sweeping
- **Role:** Hybrid — Gold generation plus combat plus heal
- **Behavior:** Generates a small Gold amount on each sweep (less than Horse). Deals damage to enemies in sweep path (less than Wolf). On enemy kill, restores a small amount of carousel health.
- **Unlock requirement:** Must have upgraded at least 3 other mounts to Tier 2.
- **Art:** Unicorn top-down, horn prominent. White/iridescent. Sparkle trail follows sweep path.
- **Color tier:** Horn and mane color shifts through tier colors
- **Upgrades:** Prismatic Horn increases all three effects by 50%. Dream Blessing adds a chance to double Gold on sweep.

### Mount Slot Progression
Start with 1 slot (Horse only). Slots are always bought with Gold in the Upgrade Shop:
- **Slots 2 and 3:** in the shop from the start.
- **Slots 4, 5, and 6:** appear in the shop after beating the first, second, and third tier bosses.

A slot and its mount are separate purchases (e.g., buy Mount Slot 2, then buy Wolf to fill it).

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
| 3 | Blue | Challenging |
| 4 | Purple | Hard |
| 5 | Gold | Very Hard |
| 6 | Red | Pre-boss / Elite |

Implementation: Use Godot Modulate property on Sprite2D to tint the base sprite. Same sprite, different modulate color = different tier. One sprite per enemy type supports all tiers.

---

### Leaf — The Swarmer
- **Speed:** Fast
- **Health:** Low (1-2 hits)
- **Latch drag:** Small
- **Behavior:** Spawns in groups of 3-5. Approaches quickly. Easy to kill individually but overwhelming in numbers if ignored.
- **Threat type:** Quantity. Tests whether Eagle can intercept fast movers before mass-latching.
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
| Leaf Storm | Leaf | On death splits into 4 Grey Leaves |
| Stick Giant | Stick | Moves in zigzag — harder to intercept with Eagle |
| Boulder | Rock | Has 3 separate latch points, rolls faster near carousel |
| Gilded Gale | Leaf | Spawns 2 Gold Leaves per second while alive |
| Ancient Log | Stick | Immune to Turtle slow, resists first 3 hits |
| Obsidian Boulder | Rock | Splits into 2 Purple Rocks on first kill — must kill twice |
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
| Spin Speed 1 | +20% spin speed — immediate visual feedback |
| Spin Speed 2 | +30% spin speed |
| Spin Speed 3 | +50% spin speed |
| Spin Speed 4 | +75% spin speed |
| Mount Slot 2-6 | Unlocks additional mount positions (4–6 require a boss first) |
| Ticket Booths 2–4 | Extra booths, re-spaced evenly; each costs more than the last |
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
| Eagle Eye 1/2/3 | Eagle range extended |
| Lion Roar 1/2/3 | Lion arc width increased |
| Turtle Shell 1/2/3 | Slow duration extended |
| Kings Wrath | Lion knockback added |
| Dive Bomb | Eagle fires twice per sweep |
| Pack Mentality | Wolf fires offset second sweep |

---

### Mount Upgrades (Gold)

| Upgrade | Effect |
|---|---|
| Wolf Tier 2/3 | Speed and damage increase, then damage trail |
| Turtle Tier 2/3 | Slow duration doubled, then freeze added |
| Eagle Tier 2/3 | Range extended significantly, then fires twice |
| Lion Tier 2/3 | Arc doubled, then knockback added |
| Horse Tier 2/3 | Gold per pass doubled, then Gold on every sweep |
| Unicorn Unlock | Requires 3 other mounts at Tier 2 |
| Unicorn Tier 2 | All Unicorn effects plus 50% |
| Prismatic Horn | Unicorn effects doubled |

---

## Progression and Tier System

### Early Game (Grey Tier — first 15-20 minutes)
- Start: Horse only, Grey Leaves approaching
- First goal: Survive first wave by clicking
- First purchase: Spin Speed 1 (immediate satisfaction)
- Second purchase: Mount Slot 2 + Wolf (game transforms — now have auto-combat)
- Third purchase: Slot 3, add Turtle or Eagle (first strategic choice)
- Boss: Leaf Storm — splits into 4 leaves on death, tests burst enemy handling
- Reward: Green Tier unlocked, Slot 4 available to buy, new combat upgrades available

### Mid Game (Green through Purple)
- Enemies get tougher, spawn faster
- Extra ticket booths come online (major Gold surge moments)
- Eagle and Lion come online
- Click Combo upgrade changes active play feel
- Boss types introduce new behaviors

### Late Game (Gold through Red)
- All mounts in play
- Both ticket booths active
- Upgrade trees largely maxed
- Enemy combinations intense — Rocks plus Leaf swarms simultaneously
- Red tier enemies are pre-boss difficulty

### Endgame
After defeating the Red tier boss, the Rusted King appears.

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
- Auto Wave toggle button — when ON, the wave countdown always runs and sends the next wave when it hits zero, whether or not the last wave is cleared. When OFF, the countdown pauses.
- Next Wave manual button — sends next wave immediately with a bonus Gold reward for early send
- Emergency Clear button — removes all latched enemies, costs Gold, has 60 second cooldown

### Mount Info
- Clicking a mount slot shows a small popup with mount name, current tier, stats, and upgrade button
- Mount tier shown as a small colored gem on the carousel slot

### Simplicity principle
No floating damage numbers in v1.0. Enemy health shown as a simple health bar above each enemy. Slow debuff shown as snowflake icon. Latch shown as a chain visual on the carousel rim.

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

**Turtle:** Shell pattern clearly visible from top-down. Green with hexagonal segments. Round and unmistakably turtle-shaped.

**Eagle:** Wings spread wide — most distinctive silhouette from above. Brown with white head suggestion. Wings communicate large range.

**Lion:** Mane visible as a ring around the head from top-down. Gold/tan. Reads as powerful area effect.

**Unicorn:** White horse body with clearly visible horn. Iridescent shimmer. Most visually complex mount — visual reward for unlocking it.

**Leaf:** Autumn leaf shape. Orange/gold. Slightly asymmetric. Tumbles as it moves.

**Stick:** Elongated oval/branch shape. Brown. Slightly irregular edges. Clearly different silhouette from Leaf and Rock.

**Rock:** Round irregular circle. Grey. Slightly bumpy edge. Larger than Leaf.

**Rusted King:** Enormous carousel horse silhouette. Rust texture with broken edges. Red glowing eyes. Chains trailing. Dramatically larger than all other enemies.

### Color Tier Implementation
Use Godot Modulate property on Sprite2D to tint the base sprite with the tier color. Same sprite, different modulate = different tier. This keeps art to ONE sprite per enemy type while supporting all six tiers with no extra art work.

### Asset & AI Policy
- AI tools are used for code only. No AI-generated images, audio, voice, or player-facing text anywhere, including the Steam capsule, screenshots, and trailer.
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
├── mount_wolf.gd
├── mount_turtle.gd
├── mount_eagle.gd
├── mount_lion.gd
├── mount_unicorn.gd
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
8. Return the next day and have offline Gold waiting for them
9. Earn Steam Achievements for milestones (via the GodotSteam addon; achievement list TBD by Garret)

Target playtime for a complete first run: 2.5 to 3.5 hours.

> **⚠️ DECISION PENDING — Prestige loop scope.** Prestige is currently out of v1.0 scope. Open question: with a 2.5–3.5 hour first run, does the game need a light prestige/replay loop at launch to hold players (and reviews), or does it ship as a complete one-run experience? **Resolve before Phase 5.** Agents: do not implement or change this without Garret's decision.

### Explicitly NOT in v1.0
- Prestige or ascension system
- Multiple carousel types or skins
- Free mount placement
- Mount doubling or stacking (exception, v1.5: extra Horses)
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

- Prestige system with permanent multipliers and new carousel skin on prestige
- Free mount placement mode unlocked after first clear
- Mount doubling mode — stack same type for specialized builds
- Mana/spell mount with AoE burst damage and long cooldown
- Second carousel — harder parallel run with different enemies
- Seasonal event skins (Halloween, winter)
- Steam Cloud saves
- Speedrun mode with leaderboard
- Desktop overlay mode (Rusty's Retirement style)

---

*GDD Version 1.5*
*Created: June 2026*
*Status: Design complete, ready for development*
