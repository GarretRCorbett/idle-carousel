# Codex Memo T: A carousel-at-the-park palette (research + three options)
**Asked:** 2026-09-25. Garret wants the feel of the carousel at Walt Disney World's Magic Kingdom
(his daughter's favorite) and a "Disney park" feel (blues for menus/UI), without copying Disney
trademarks. Codex researched with web search (read-only); answer verbatim, then Claude's read.
**Input, not a decision.** Renders of all three options in the real game: `palette/*.png`
(throwaway preview code; nothing in the game changed).

---

**My recommendation: use “Lantern Hour” for the UI and park, with ivory, lavender, and gold carousel details borrowed from “Gilded Garden.”** That combination best supports Garret’s memory of an evening ride while giving Idle Carousel its own identity.

**Evidence labels:** “Sourced” summarizes references; “interpretation” describes visual impressions; “proposal” is my design judgment. All hex values below are approximate design translations, **not Disney specifications or sampled brand colors**.

**The real carousel is richly multicolored.**

- **Canopy — visual interpretation:** Exterior references show a blue-violet/purple, tentlike roof with gold banding and a repeating scalloped edge. Think violet `#74638C`, muted blue `#647DA3`, and ochre-gold `#D5B568`. Distinguish this outer roof from the elaborate painted band underneath. Broad alternating canopy wedges would be a useful simplification; I would not describe ordinary red-and-white circus stripes as an accurate match. [WDWMAGIC exterior gallery](https://www.wdwmagic.com/attractions/prince-charming-regal-carrousel/gallery/10aug2020-prince-charming-regal-carrousel-overview.htm)
- **Carving and rounding boards — sourced:** Restoration reporting documents pink, purple, blue, silver, white, and bright metallic gold. Raised picture panels have gilded frames and surrounding filigree; sculpted figures and eagles survive from the older carousel. Approximate supporting colors: rose `#DCA9BB`, lavender `#B6A3CD`, ivory `#F5EBDD`, silver `#C4C9CD`. The pictures depict Disney’s *Cinderella*: borrow the framed-panel rhythm, not their illustrations. [Paint restoration](https://wdwnt.com/2024/03/photos-prince-charming-regal-carrousel-gets-fresh-coat-of-paint-at-magic-kingdom/), [gilded vignettes](https://wdwnt.com/2021/04/photos-vignettes-completely-refurbished-on-prince-charming-regal-carrousel-at-magic-kingdom/)
- **Horses — sourced:** White bodies carry individually colored tack, including royal-blue saddles, elaborate armor, flower garlands, feathers, and shields. Real 23-karat gold leaf and other metal leaf provide highlights. Outer horses receive more elaborate decoration. **Interpretation:** sapphire `#345D97`, ruby `#A94359`, emerald `#418873`, and lavender accents create the jewel-like effect. I did not verify the material of individual “jewels”; don’t describe them as precious stones. [MousePlanet’s account of the restoration craft](https://mouseplanet.com/the-tale-of-cinderellas-golden-carrousel/2962/)
- **Platform and poles — sourced/visual:** The floor is dark stained wood, approximately walnut `#654B3B`, with reflective golden/brass-looking vertical poles, approximately `#BE9951`. The center also has mirrors and blue diamonds with gold borders over red panels. A green platform is therefore a substantial departure from this reference. [Floor restoration and photographs](https://wdwnt.com/2024/06/flooring-refurb-prince-charming-regal-carrousel/)
- **Lighting and surroundings — sourced/interpretation:** AllEars reports 2,325 lights. Their visual effect is warm cream cores `#FFF1CC` with amber glow `#FFC77C`. Daylight emphasizes pastel ornament, paving, flowerbeds, and the surrounding Fantasyland buildings. At night, dark surroundings and cooler architectural illumination make the carousel read as a warm, luminous centerpiece. Its immediate setting is a paved courtyard; Idle Carousel’s grassy park is an adaptation. [AllEars night photography](https://allears.net/blogs/photoblog/2014/02/ready_214_photographing_the_pr.html), [day/night attraction guide](https://www.mousehacking.com/rides/guide-to-prince-charming-regal-carrousel-at-magic-kingdom)

**A storybook park feeling can come from shared visual conventions.** My judgment: dark blue supplies calm structure; cream softens it; restrained gold suggests craftsmanship; pastel ornament and warm lights add celebration. Keep most surfaces quiet so the animals and moving threats remain prominent.

Useful precedents, without claiming their developers intended Disney imitation:

| Reference | Sourced observation → proposed lesson |
|---|---|
| [Parkitect](https://www.texelraptor.com/blog/announcing-parkitect-multiplayer) | Its developer screenshot includes a purple-and-white carousel, green landscaping, and sandy paths. Simple geometry and repeated color blocks can carry the atmosphere. |
| [Planet Coaster](https://www.thesixthaxis.com/2020/11/10/planet-coaster-console-edition-review-ps5-ps4-xbox-one-series-x/) | Colorful scenery combines multiple park themes. Build an original park vocabulary rather than reproducing one location. |
| [Theme Park Studio](https://steamcommunity.com/app/254590/announcements) | Developer announcements describe an animated photobook menu and emissive night lighting. Borrow the warmth and framing at a much smaller implementation scale. |
| [Rusty’s Retirement](https://store.steampowered.com/app/2666510/Rustys_Retirement/) | Its compact idle presentation includes a less distracting focus mode. Let the carousel provide gentle motion while the UI stays steady. |

**General U.S. legal context—not legal advice:** Colors are often ornamental, but color alone can become a protected mark when it identifies a source, acquires distinctiveness, and meets other requirements. Overall appearance can also matter; changing a hex value does not establish safety. Confusion includes sponsorship or affiliation. [USPTO color guidance](https://tmep.uspto.gov/RDMS/TMEP/print?href=TMEP-1200d1e1975.html&version=current), [USPTO infringement overview](https://www.uspto.gov/page/about-trademark-infringement)

For this project, avoid Disney/Magic Kingdom/Cinderella references in game and store copy, Disney character imagery, castle icons, mouse-ear emblems, and Disney-like script paired with recognizable blue branding. Treat these as deliberate project boundaries, not assertions that every generic castle or fairy-tale name is forbidden. “Inspired by” is not a clearance mechanism. Use original typography, animal motifs, and ornament placement.

**Three proposed palettes follow, each with 14 reusable colors.** Enemy tier colors remain separate and unchanged.

| Token / role | A — Gilded Garden | B — Lantern Hour | C — Morning Picnic |
|---|---|---|---|
| Grass | `#82A88D` | `#405D60` | `#A9CBB0` |
| Trees | `#3F6C61` | `#273F49` | `#537D70` |
| Path / clearing | `#CCC4B5` | `#827F8B` | `#DDD5C5` |
| Platform deck | `#765642` | `#847281` | `#B99D7B` |
| Canopy accent / rim | `#70568B` | `#5266A8` | `#A995BF` |
| Ivory: canopy base / light text | `#FFF4DC` | `#FFF1D6` | `#FFF4E4` |
| Gold: trim / poles / primary button | `#DDB96A` | `#E7BA66` | `#D9B56E` |
| Warm bulb glow | `#FFD18A` | `#FFD08A` | `#FFD697` |
| Ink / dark UI surface | `#243955` | `#15243D` | `#25415B` |
| Secondary button / booth roof | `#405D83` | `#344E80` | `#446687` |
| Muted text | `#C0CAD7` | `#BAC5DA` | `#526879` |
| Highlight / progress fill | `#91CDE2` | `#8DCDE8` | `#94C8D6` |
| Health fill | `#79C9AE` | `#74C9AE` | `#7DBBA4` |
| Danger button / boss-health fill | `#A43749` | `#AE3C50` | `#A83C55` |

**Shared assignments:** Alternate ivory and canopy accent; use gold poles and trim, ivory bulb centers, and translucent glow. Ticket booths use ivory walls, the secondary-blue roof, and gold edging. Primary buttons take ink labels; secondary and danger buttons take ivory labels. Bars use an ink track, with labels outside the fill.

**A — Gilded Garden:** Closest to the material reference: walnut deck, violet ornament, ivory, and gilding. Panels use ink, ivory text, and gold borders. Calculated main-text contrast is **10.7:1**; muted text is **7.1:1**. The warm gray clearing helps separate combat from green landscaping, but gray enemies still need outlines. Keep panel illustrations original and simplify the ornament into flowers or animal medallions.

**B — Lantern Hour:** My preferred overall direction. Midnight panels and royal-blue accents surround a warm illuminated ride; the slate-mauve clearing avoids muddy brown. Panels use ink, ivory text, and gold borders: **13.9:1** main text, **8.9:1** muted. Charcoal enemies are the main visibility risk against the dark park. Keep the Kenney animals brightly readable rather than applying the full night tint to them. Use plain rounded lettering and original geometry to distinguish the branding.

**C — Morning Picnic:** Mint grass, lavender, warm wood, and ivory suit the round cartoon animals. Panels use **ivory**, ink text, secondary-blue borders, and small gold accents: **9.7:1** main text, **5.3:1** muted. Yellow enemies and pale animals need dark edging against the lighter setting. Keep blue secondary to the mint/lavender world and avoid princess or castle decoration.

Across all three, calculated button-label contrast exceeds **5.2:1** at full opacity. These are swatch calculations, not rendered-game validation; WCAG’s **4.5:1** normal-text criterion is a useful benchmark. [W3C contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)

**Boss strip and tier readability:** Use an opaque ink boss strip in every palette, ivory labels, a gold frame, and a danger-colored health fill over a secondary-blue track. Give tier pips an ivory inner outline and ink outer outline. Preserve their fixed gray/green/yellow/orange/red/charcoal fills; add numerals or distinct marks so red–green and yellow–orange differences never carry meaning alone. Apply comparable contrasting silhouettes to enemies. Exact enemy contrast remains unverified because their hex values were not supplied.

**Three inexpensive shape-based touches:**

1. **Canopy rhythm:** Radial wedges plus repeated semicircular scallops and a thin trim line; keep the silhouette readable at game scale.
2. **Bulb necklace:** Evenly spaced ivory circles around the rim, each with a larger translucent amber circle. Steady illumination will feel calmer than flashing.
3. **Poles and bobbing:** Gold shafts with diagonal highlight strokes suggesting a twist, plus gently offset mount bobbing. Reserve detail for a few visible poles.

These require no generated artwork. Any later implementation should expose dimensions, colors, and animation timing as tunables.

Selected source list for continued reference:

- [WDWMAGIC exterior photographs](https://www.wdwmagic.com/attractions/prince-charming-regal-carrousel/gallery/10aug2020-prince-charming-regal-carrousel-overview.htm)
- [WDWNT completed 2024 refurbishment](https://wdwnt.com/2024/07/prince-charming-regal-carrousel-refurb-complete/)
- [MousePlanet restoration history](https://mouseplanet.com/the-tale-of-cinderellas-golden-carrousel/2962/)
- [AllEars carousel details and lighting](https://allears.net/2012/04/09/carousel-or-carrousel-disney-style/)
- [USPTO color marks](https://tmep.uspto.gov/RDMS/TMEP/print?href=TMEP-1200d1e1975.html&version=current)
- [W3C avoiding color-only information](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)

Workspace unchanged. Shell policy blocked reading `CLAUDE.md`; this memo follows the constraints supplied in your prompt.
---

## Claude's read
**Sources spot-checked:** several fan sites (MickeyBlog, Disney Fanatic, AllEars) agree on 2,325
lights, white horses, and 23-karat gold leaf; the pink/purple/blue/silver/gold repaint is in
WDWNT's 2024 refurbishment coverage.

**The canopy touch does most of the work.** In the renders, alternating ivory and colored wedges
with a gold scalloped trim and a ring of warm bulbs read as "carousel" instantly, far more than any
color change to the panels. It's code-drawn, cheap, and ours.

**Tying the carousel and the UI together: yes, and B does it best.** The UI's midnight navy, the
canopy's royal-blue wedges, the booth roof, and gold trim everywhere are one family, so the menus
feel like part of the ride rather than a separate layer. That's the "evening at the park" feel.
The real carousel's canopy is blue-violet, so an easy variant is **B with A's violet canopy**
(Codex's own recommendation): navy UI, violet-and-ivory canopy, gold trim.

**Things the renders show that palettes alone don't fix:**
- The **trees** are Kenney's autumn-brown sprites; they clash with every option. Swap for green
  trees (Kenney has them) or tint them.
- **Grey and charcoal enemies** are the hardest to see on B's dark grass and slate clearing; the
  clearing may want to be a little lighter/warmer. Charcoal already has its light outline.
- Buttons are Kenney yellow textures: they already fit the gold. A blue secondary button (Kenney UI
  Pack has one) would complete B.
- C (daytime pastel) is cheerful but low-contrast: grey Leaves nearly vanish on the pale path.

**Staying clear of Disney's trademarks** (not legal advice; Codex's list is the right shape):
never use Disney, Magic Kingdom, Cinderella or Prince Charming in the game or store page; no
castles, mouse ears, characters, or Disney-style script lettering. Colors and a general storybook
carousel look are fine to evoke; the combination of names + logos + castle imagery is what signals
affiliation. Original animals (Kenney), our own fonts and ornament keep it ours.

**Suggestion:** B "Lantern Hour" (navy UI, gold trim, warm bulbs), with the canopy in B's royal
blue or A's violet (Garret's pick), green trees, and a slightly lighter clearing. Build it as a
Phase 6-style art pass, or sooner as one small "theme" step: the UI theme builder, carousel,
booth, and park already take their colors from exports.
