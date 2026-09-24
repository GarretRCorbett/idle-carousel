# Codex memo I: Kenney asset packs (2026-09-24)

> Input, not a decision. Codex browsed kenney.nl with web search. Packs are downloaded to ../kenney_assets/ (outside the project); only used files are copied into assets/.

**I recommend Animal Pack Remastered + the current UI Pack + Foliage Sprites/Foliage Pack**, with a small human-made art pass for missing mounts, the carousel, and the booth. This gives Idle Carousel a coherent, smooth cartoon style while keeping the asset workload manageable.

The main limitation: **Animal Pack Remastered directly covers only Horse from your six mounts.** Its animals are face icons, so using them on the carousel means embracing a stylized token-like presentation.

[Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) contains **30 animals, each in eight styles**, producing 240 variants. The species are:

Bear, buffalo, chick, chicken, cow, crocodile, dog, duck, elephant, frog, giraffe, goat, gorilla, hippo, horse, monkey, moose, narwhal, owl, panda, parrot, penguin, pig, rabbit, rhino, sloth, snake, walrus, whale, and zebra. Kenney’s own [OpenGameArt listing](https://opengameart.org/content/animal-pack-redux) supplies the inventory; “Redux” became “Remastered” in a [2026 naming update](https://itch.io/devlog/1526460/update-version-35.amp).

These are **flat, predominantly front-facing animal faces**, with round or square foundations, optional outlines, and optional extra details. They are neither overhead animal bodies nor animated riding mounts. PNGs, spritesheets, and vector sources are available.

Sizes vary with ears, horns, and outlines. The [Construct bundle’s file inventory](https://www.construct.net/en/game-assets/construct-free-bundled-assets/animal-pack-redux-4996), under the former Redux name, gives these examples:

| Variant | Horse | Dog | Owl |
|---|---:|---:|---:|
| Round | 129×141 | 129×157 | 128×128 |
| Round, outlined | 137×149 | 137×165 | 136×136 |
| Round without details | 129×128 | 129×128 | 128×128 |

These are source dimensions, not intended display sizes. At approximately 32 pixels, normalize their apparent head sizes rather than applying one scale factor to every file.

| Required mount | Coverage | Best practical approach |
|---|---|---|
| Horse | Included | Use directly. |
| Wolf | Missing | Dog is the closest stand-in; a human edit to ears and muzzle would distinguish it. |
| Turtle | Missing | Frog is only a temporary placeholder. A shell silhouette needs custom work. |
| Eagle | Missing | Parrot offers a beak; owl offers a recognizable bird face. Either needs editing to read as eagle. |
| Lion | Missing | Bear could supply a face foundation, but needs a human-drawn mane. |
| Unicorn | Missing | Horse plus a human-drawn horn is the easiest adaptation. |

I did not verify another Kenney 2D pack that supplies those five animals in this same style. Game-icons.net has alternatives such as [Wolf Head](https://game-icons.net/1x1/lorc/wolf-head.html) and [Turtle](https://game-icons.net/1x1/lorc/turtle.html), but their silhouette treatment differs substantially.

For the carousel, these faces can work as charming animal emblems mounted on seats. They will not communicate physical riding animals from above. I would test the round variants at actual size before committing; preserving identifying ears and beaks matters more than removing every detail.

For UI, **choose [UI Pack](https://kenney.nl/assets/ui-pack)**. Its simple shapes leave room for your autumn palette and are the strongest match for the animal faces.

| Pack | Contents and character | Fit for Idle Carousel |
|---|---|---|
| [UI Pack](https://kenney.nl/assets/ui-pack) | Current remade version lists 430 files; panels, buttons, sliders, checkboxes, and interface symbols. | **Best overall:** clean, friendly, easy to recolor. |
| [UI Pack – Adventure](https://kenney.nl/assets/ui-pack-adventure) | 130 files; framed panels, banners, circular elements, bars, and sliders. PNG and vector sources. | Strong runner-up: cream panels and warm red banners suit park signage, though decoration adds visual weight. |
| [UI Pack – RPG Expansion](https://kenney.nl/assets/ui-pack-rpg-expansion) | 85 files; fantasy panels, buttons, bars, cursors, and symbols. | Warmer out of the box, but its heavier framing suggests a fantasy inventory. |
| [Pixel UI Pack](https://kenney.nl/assets/pixel-ui-pack) | 750 files of pixel-style interface pieces. | Useful breadth, but introduces a pixel grid absent from the animals. |
| [UI Pack – Pixel Adventure](https://kenney.nl/assets/ui-pack-pixel-adventure) | Newer 2024 collection with 500 files; pixel frames, buttons, bars, and decorations. | Attractive for a fully pixel-art game; inconsistent here. |
| [UI Pack – Sci-Fi](https://kenney.nl/assets/ui-pack-sci-fi) | Remade collection of 130 interface assets. | Its technological styling contributes little to the autumn-park theme. |

UI Pack’s [creator-posted mockup](https://mastodon.gamedev.place/@kenney/112604228055851654) also demonstrates tabs. Use that visual family for Carousel / Combat / Mounts, rectangular buttons for purchases, a larger button for Boost, and matching bar components for health, boost, and shop progress. These are graphic ingredients; the shop arrangement still needs design.

For fonts, download [Kenney Fonts](https://kenney.nl/assets/kenney-fonts) separately rather than depending on a particular UI archive’s extras. It contains 11 fonts. I would trial Kenney Future for short labels and numbers, avoiding the pixel faces for this direction. Check long prices and small descriptions at 1280×720; its geometric styling may feel too mechanical for extended reading.

The remaining art can come from a compact selection:

| Need | Recommended source | What to use or adapt |
|---|---|---|
| Leaf | [Foliage Sprites](https://kenney.nl/assets/foliage-sprites) | White plant and leaf silhouettes are particularly convenient for tinting. Select one broad, unmistakable leaf and color it `#E07B39`. |
| Stick | [Wood Stick, game-icons.net](https://game-icons.net/1x1/delapouite/wood-stick.html) | A more direct match than the Kenney previews I found. Simplify fine details and color it `#8B5E3C`. |
| Rock | [Foliage Pack](https://kenney.nl/assets/foliage-pack) | Contains rocks alongside trees, bushes, and stumps. Choose a compact shape, reduce shading, and recolor to `#7A7A8C`. |
| Carousel | Custom human-made vector art | I found no suitable ready-made playground carousel. A disc, rim, spokes, and hub are a small, distinctive art task. |
| Ticket booth | [Medieval RTS](https://kenney.nl/assets/medieval-rts) | Small buildings provide a possible foundation, but roof/front perspective and medieval details need adaptation. No verified ready-made ticket booth. |
| Gold coin | [New Platformer Pack](https://kenney.nl/assets/new-platformer-pack) | Its visible coin collectible suits a floating reward icon despite the pack’s platformer setting. Recolor to `#F2C94C`. |
| Small UI symbols | [Game Icons](https://kenney.nl/assets/game-icons) and [Game Icons Expansion](https://kenney.nl/assets/game-icons-expansion) | Good sources for navigation and interface symbols. Use the UI pack’s checkmark; fill specific combat-symbol gaps from game-icons.net. |
| Effects | [Particle Pack](https://kenney.nl/assets/particle-pack) | 80 textures at 512×512: useful ingredients for flashes, sparks, and bursts. Treat a sweep slash as an effect to assemble, not a verified finished animation. |

For speed, health, and damage, choose simple boot/lightning, heart, and sword silhouettes from game-icons.net, keeping their visual weight consistent. Credit each selected artist and the CC BY 3.0 license, and identify modifications; its [FAQ](https://game-icons.net/faq.html) explains attribution.

The rusted carousel-horse boss deserves dedicated human art. Enlarging the horse face can establish a placeholder, but it will not supply the full mechanical horse silhouette or rust treatment.

For later audio, audition [Interface Sounds](https://kenney.nl/assets/interface-sounds) or [UI Audio](https://kenney.nl/assets/ui-audio) for clicks and short pop-like feedback, and [Casino Audio](https://kenney.nl/assets/casino-audio) for reward-related sounds. These are audition candidates, not clips I listened to during this research.

Keep the final combination **smooth, flat, and lightly shaded**, with one consistent outline treatment. Use `#3D3530` for the quiet background, forest green for the carousel, and warm red/cream for the booth and UI accents.

Prepare tier-tinted sprites in white and light neutral greys first. Godot’s `modulate` multiplies existing colors, so a brown animal will not become a clean blue simply by applying blue modulation. Preserve dark facial details and test every tier against both background and carousel. [Godot’s color documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html)

My priority shopping list is:

| Priority | Pack | Use |
|---:|---|---|
| 1 | [Animal Pack Remastered](https://kenney.nl/assets/animal-pack-remastered) | Horse and foundations for mount adaptations |
| 2 | [UI Pack](https://kenney.nl/assets/ui-pack) | Main interface, Boost, tabs, and bars |
| 3 | [Foliage Sprites](https://kenney.nl/assets/foliage-sprites) | Leaf enemy and plant silhouettes |
| 4 | [Foliage Pack](https://kenney.nl/assets/foliage-pack) | Rock enemy and restrained park dressing |
| 5 | [Kenney Fonts](https://kenney.nl/assets/kenney-fonts) | Font trials |
| 6 | [New Platformer Pack](https://kenney.nl/assets/new-platformer-pack) | Coin |
| 7 | [Game Icons Expansion](https://kenney.nl/assets/game-icons-expansion) | Additional interface symbols |
| 8 | [Particle Pack](https://kenney.nl/assets/particle-pack) | Combat and reward effects |

No code or files were changed.