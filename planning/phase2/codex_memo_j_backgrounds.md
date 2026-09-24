# Codex memo J: backgrounds (2026-09-24)

> Input, not a decision. Codex compared Kenney packs for the play-field and menu backgrounds (web search).

**I’d use Top-down Tanks Remastered terrain for gameplay, with sparse Foliage Sprites leaf decoration. Background Elements Remastered suits a decorative menu backdrop, but its landscape perspective conflicts with the overhead play field.** These are design judgments based on the pack listings and previews.

**What Background Elements Remastered contains**

Kenney lists **90 assets, CC0**, released in 2019. Older listings call it “Background Elements Redux”; distinguish it from the original 110-asset Background Elements pack. Its style is smooth, flat, geometric cartoon scenery—compatible with your animal faces and yellow UI buttons in rendering style. [Kenney pack page](https://kenney.nl/assets/background-elements-remastered)

The older Redux distribution documents:

- Separate clouds, trees, orange trees and bushes, fences, houses, towers, mountains, sun and moons.
- Broad cloud, ground, hill and mountain layers for assembling landscapes.
- Ready-made square backgrounds, including an autumn composition.
- Default and approximately double-size “Retina” PNGs, spritesheets and SVG sources.

These are **side-view landscape elements suitable for parallax composition**, rather than an overhead park tileset. Parallax movement would be something you add; the artwork itself supplies the layers.

For sizes, the Redux file inventory lists finished backgrounds at **1024×1024**, most landscape strips at **1024×400**, and one ground strip at **1024×200**. Individual objects vary: `treeOrange.png` is 101×259, with a 202×518 Retina version. These dimensions are verified for that older distribution; Kenney’s current Remastered page does not expose a detailed file inventory. [Distributed file listing](https://www.construct.net/en/game-assets/construct-free-bundled-assets/background-elements-redux-4985)

At 1280×720, compose a widescreen layout from the pieces or crop a square background proportionally. Stretching the square would distort the trees.

**Fit:** poor for gameplay ground; good for a menu illustration. Upright trees, visible trunks and a horizon imply a different camera angle from your carousel.

**Other Kenney options**

All packs below are listed as CC0 on their linked sources.

| Pack | Useful material and perspective | Fit with your current artwork |
|---|---|---|
| [Top-down Tanks Remastered](https://kenney.nl/assets/top-down-tanks-remastered) | Overhead terrain, grass, connecting road/path shapes, trees and obstacles. Use the environmental pieces. | **Strongest starting point.** Smooth shapes and a consistent overhead view. Recolor suitable road pieces toward earth rather than military terrain. |
| [Top-down Shooter](https://kenney.nl/assets/top-down-shooter) | Top-down tiles and furniture; useful as a secondary source for ground and props. | Smooth non-pixel option, but much of its content serves buildings and combat. Check individual furniture silhouettes before treating them as park benches. |
| [Foliage Pack](https://kenney.nl/assets/foliage-pack) | Seasonal trees, bushes and nature objects; 100 assets. PNGs, vector sources and Retina sizes are documented. | **Good style, weaker perspective.** Many trees are upright/profile illustrations. Better for menu borders than overhead trees. [Creator’s description](https://opengameart.org/content/foliage-pack-100x) |
| [Foliage Sprites](https://kenney.nl/assets/foliage-sprites) | Leaves, grass and plant silhouettes. Originally intended for foliage billboards/model construction; 50 flat designs plus shaded versions and vector sources. | **Good selective supplement.** Flat individual leaves can become ground litter; upright grass clumps do not automatically become overhead vegetation. [Creator’s description](https://opengameart.org/content/foliage-sprites) |
| [Tiny Town](https://kenney.nl/assets/tiny-town) | 130 assets on a **16×16 pixel** grid, intended for town/overworld scenes. | Charming, but visibly pixel-based. Its RPG-style view also differs from strict overhead artwork. |
| [Roguelike/RPG pack](https://kenney.nl/assets/roguelike-rpg-pack) | 1,700 **16×16 pixel** assets covering town, terrain and furniture needs. | Broad selection, but small pixel detail and RPG perspective make it a poor visual match. |
| [RPG pack: base set](https://opengameart.org/content/rpg-pack-base-set) | Kenney’s older vector-backed RPG set: grass, dirt, water, buildings and crates; 230 PNG sprites plus vector source. | A better ground alternative than pixel RPG packs. Flat terrain is useful; upright buildings still introduce perspective differences. |

**Vector style and top-down perspective are separate requirements.** Foliage Pack satisfies the former more readily than the latter. Tiny Town supports overhead map layouts, but its pixel edges will stand apart from your smooth mounts. Enlarging pixel assets preserves blockiness; smoothing them introduces blur.

I did not verify a complete matching set of overhead park benches and fences across these packs. Those are gaps to inspect before committing, rather than reasons to mix several incompatible styles.

**Keeping the play field readable**

Your orange enemies already carry the autumn accent. Let the background communicate autumn through muted olive grass, brown earth and restrained ochre decoration.

- Keep a broad, quiet clearing around the carousel, including the rim where enemies latch.
- Make background detail lower contrast than mounts, enemies and the booth. Start with desaturation, then darken only enough to preserve separation.
- Avoid grass close to `#4A7A3D`; it could merge with the disc. A brown-grey clearing would separate it better.
- Confine fallen leaves to sparse edge clusters. Make them duller and visually different from enemy leaves; avoid repeating `#E07B39`.
- Use a gentle vignette on the scenery only. Excessive edge darkness could conceal incoming enemies.
- Avoid dense grass marks, checkerboard tiling, heavy prop outlines, animated background leaves and large foreground canopies crossing approach routes.

**My recommended compositions**

**Gameplay:** use [Top-down Tanks Remastered](https://kenney.nl/assets/top-down-tanks-remastered) grass and terrain pieces around a broad earth clearing, with a subdued approach path toward the booth. Put overhead tree crowns near the outer corners. Add a few flat leaf shapes from [Foliage Sprites](https://kenney.nl/assets/foliage-sprites), tinted dusty brown. Let uneven vegetation suggest neglect without filling the center with debris.

**Main menu:** use [Background Elements Remastered](https://kenney.nl/assets/background-elements-remastered) orange trees, bushes and low hill layers as a quiet illustrated border. Preserve a large warm-grey central area for the title, buttons and spinning carousel. Present that carousel as a menu emblem; placing it directly into a side-view landscape would expose the perspective mismatch.

No code or files were changed. The environment blocked reading `CLAUDE.md`; this comparison follows the rules and art direction supplied in your request.