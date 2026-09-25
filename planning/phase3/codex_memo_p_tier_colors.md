# Codex Memo P: Tier color order (research)
**Asked:** 2026-09-25, after Garret felt Grey → Green → Blue → Purple → Gold → Red is "off" and
suggested Grey → Green → Yellow → Orange → Red → Black. Codex with web search; answer verbatim
below, then Claude's read. **Input, not a decision.** Candidate render:
`tier_color_candidates.png` (real sprites on the grass, each order also shown with an
approximate deuteranopia simulation).

---

**I recommend Garret’s Grey → Green → Yellow → Orange → Red → Black order, provided Black gets a readable treatment.** His instinct has a particularly strong precedent: the first five colors exactly match WoW’s traditional **enemy-difficulty** sequence. [WoW difficulty colors](https://warcraft.wiki.gg/wiki/Mob_difficulty_colors)

Players learn several overlapping color languages:

| Context | Familiar progression or meaning |
|---|---|
| **WoW loot** | Grey → White → Green → Blue → Purple → Orange: poor through legendary. [Item quality](https://wowpedia.fandom.com/wiki/Quality) |
| **Borderlands** | White → Green → Blue → Purple → Orange, with additional special rarities depending on installment. [Player explanations](https://www.reddit.com/r/Borderlands2/comments/1dawd4z) |
| **Destiny** | Traditionally White → Green → Blue → Purple → Gold; purple means legendary, gold exotic. [Engram colors](https://www.destinypedia.com/Engram) |
| **Diablo III loot** | White → Blue → Yellow → Orange; green identifies sets, so green is not necessarily weak. [Item colors](https://di.diablowiki.net/Items) |
| **Diablo III enemies** | Blue champions, yellow rares, purple unique names distinguish elite categories—not a universal linear strength ladder. [Elite guide](https://blizzardwatch.com/2015/07/11/combat-elite-monster-affixes-diablo-3/) |

The rarity sequence works largely through familiarity and repeated rewards. A [Reddit discussion](https://www.reddit.com/r/Songsofconquest/comments/utfcgm) explicitly explains another game’s colors through WoW; a [Borderlands discussion](https://www.reddit.com/r/Borderlands2/comments/1uaw42z/rarity_scale_origin/) recognizes the same sequence across games. These illustrate expectations, not representative survey results.

**Idle games offer mixed precedents:**

- **Clicker Heroes:** progression centers on numbered zones and recurring bosses; its documented system supplies no comparable universal enemy-color ladder. [Monsters](https://clickerheroes.fandom.com/wiki/Monsters)
- **Tap Titans 2:** equipment uses white common, blue rare, gold legendary, orange mythic; purple denotes event equipment. [Rarity](https://tap-titans-2.fandom.com/wiki/Rarity)
- **Realm Grinder:** faction hues identify affiliations; bronze → silver → gold identifies upgrade tiers. [Factions](https://realm-grinder.fandom.com/wiki/Factions)
- **Idle Slayer:** evolutions include Green → Red → Blue Jellies and progressively darker hornets, with greater rewards. This supports recoloring as progression without establishing one universal order. [Enemies](https://idleslayer.fandom.com/wiki/Enemies)

Real-world conventions reinforce different parts of Garret’s order. Traffic lights supply green/go, yellow/caution, red/stop; orange naturally bridges caution and danger. Skiing supplies an especially strong black endpoint: North America uses green → blue → black, while European systems commonly include blue → red → black, sometimes preceded by green. Shapes reinforce the North American colors. [Ski Club guide](https://www.skiclub.co.uk/discover-snowsports/staying-safe/piste-maps/)

Martial arts supply white/beginner and black/advanced associations, but intermediate belts vary; black is not universally the highest rank. Judo also has senior red-and-white and red belts. [International Judo Federation](https://www.ijf.org/history/judo-culture/2250) Medal metals supply bronze → silver → gold prestige, making **Gold before Red** potentially feel like passing the finish line and continuing.

Research supports particular associations, rather than an innate six-color ranking:

- **Danger:** controlled experiments found implicit red–danger associations; green–safety evidence was weaker. [Pravossoudovitch et al., 2014](https://pubmed.ncbi.nlm.nih.gov/24588355/)
- **Aggression/dominance:** men pictured wearing red received higher aggression ratings than those wearing blue or grey; the dominance effect depended on the observer’s sex. [Wiedemann et al., 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4455742/)
- **Weight:** experimental packaging research found dark colors increased perceived visual heaviness. That supports a possible “heavy/powerful” reading, not proof that black enemies universally seem strongest. [Study, 2019](https://www.jstage.jst.go.jp/article/marketing/38/4/38_2019.015/_article/-char/en)

My interpretation: Garret’s order reads **ordinary → manageable → caution → escalating danger → danger → exceptional final threat**. Its middle resembles a warning/heat-map ramp. It is not literal heating: increasingly hot incandescent objects progress toward white/blue, and black is no thermal climax. [NASA](https://www.nasa.gov/space-science-and-astrobiology-at-ames/interesting-fact-of-the-month-current/interesting-fact-of-the-month-2020/)

The current order instead combines loot prestige through Gold with a danger-colored finale. Both are learnable; Garret’s proposal communicates enemy threat more consistently. It does sacrifice familiar blue/purple loot milestones.

For the actual sprites:

- **Grey:** keep it light. **Green:** use a bright, lighter green to separate it from grass. **Yellow/Gold:** likely strong visibility, but flat gold can simply read as yellow. **Orange/Red:** separate their brightness as well as hue. **Blue/Purple:** avoid deep shades that disappear against dark grass. These are starting judgments requiring actual sprite tests.
- Multiplication darkens the source: black removes all RGB shading, while near-black compresses it. Use charcoal with an **independently colored light outline**, preserved highlights, or restrained glow. Dark violet/crimson still needs sufficient brightness; changing hue alone cannot solve contrast. [Godot tint behavior](https://docs.godotengine.org/en/latest/tutorials/shaders/shader_reference/canvas_item_shader.html)
- Add tier numerals and distinctive marks/patterns. Red/green and neighboring warm colors can become confusable. Check rendered sprites at gameplay size in motion, grayscale, and color-vision simulations, then with affected players. [Microsoft accessibility guidance](https://learn.microsoft.com/en-us/windows/uwp/gaming/accessibility-for-games)

| Candidate | Advantages | Drawbacks |
|---|---|---|
| **Grey → Green → Yellow → Orange → Red → Black** | Strong difficulty precedent; distinct finale | Black needs additional rendering; warm-color confusion |
| **Grey → Green → Yellow → Orange → Red → Deep Violet** | Preserves warning ramp; retains more visible shading | Violet-after-red needs teaching; still needs contrast |
| **Grey → Green → Blue → Purple → Orange → Gold** | Familiar loot prestige; bright finale; suits mount upgrades | Less threatening; orange/gold can look similar |

Prototype the first candidate with charcoal and a light edge. If mounts reuse tier colors, preserve their ordinal meaning across both systems.

*No files changed. Local read commands were policy-blocked, so I could not read CLAUDE.md or inspect the artwork.*
---

## Claude's read
- **Agree with Garret's direction.** These colors mark *enemy threat*, not loot, and the closest
  precedent Codex found is exactly that: WoW's enemy-difficulty colors (grey, green, yellow,
  orange, red). It also matches traffic lights and "red = danger", the one link with real
  experimental support. Loot orders (green/blue/purple/orange) mean "better reward", which is
  the wrong message for "this enemy is tougher".
- **The render shows the real cost: colorblind players.** In the deuteranopia rows, Green,
  Yellow, Orange and Red become pale yellow, bright yellow, mustard and dark olive. They stay
  apart only by **brightness**. So if we adopt the warm ramp, make it a brightness ramp too
  (light → dark as tiers rise) and add a second cue: a tier number or pips in the Step 6 tier
  picker and on bosses. The loot order has its own collisions (Blue = Purple, Orange ≈ Gold).
- **Black:** charcoal reads as a dark silhouette on the grass but loses all shading. It needs a
  light outline, and that's doable: `make_tier_sprites.gd` can also bake an outline copy for the
  last tier. **Deep violet** (candidate B) is the easy alternative: it keeps its shading and is
  the most distinct color in the colorblind rows, but "violet after red" isn't a known ladder.
- **Knock-on changes if the order changes:** GDD tier table and mount accent colors;
  `resources/tiers/*.tres` (`tier_id`, tint, `name_key`; a few minutes); boss flavor: the
  Gilded Gale spawns "Gold Leaves" and the Obsidian Boulder splits into "Purple Rocks". With
  order A, Obsidian (black) fits the last tier well, and the Gale could move to the Yellow tier
  or be renamed.
- **Suggestion:** Grey → Green → Yellow → Orange → Red → Charcoal-with-outline, as a light-to-dark
  ramp, with tier numbers in the UI. Garret decides; I'd look at `tier_color_candidates.png` first.
