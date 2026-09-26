# Devlog #1: Why a carousel?

*Draft by Claude for Garret to edit. Private until published.*

My daughters love carousels. Every fair, every mall, every park: if there's a carousel, we're riding it. So it's no surprise I've been trying to make a carousel game for a while now.

The first attempt wasn't an idle game at all. It was a strategy game in the spirit of Slay the Spire and Wildfrost, built around a carousel. I learned a ton working on it in Godot, but the scope was way too big for one person learning as he went.

So I took a step back and entered a game jam to get better at finishing things. I made a little game about a spinning plate of biscuits, and I fell in love with the spin mechanic. A few months later another jam's theme was literally "spin to win." It felt like fate. I didn't finish that one in time, but I loved designing it so much that I decided to try again for real. This time I'd aim for something I could actually finish and put on Steam.

An idle game fit. The carousel spins on its own, and the question became: what if the carousel itself was the thing you're protecting, and everything you do is about keeping it spinning? A couple of months of planning later, **Idle Carousel** was born.

![The carousel in the middle of the park](../images/2026-09-25_19_purple_garden_final.png)

## Keep it spinning
The carousel sits in the middle of a park. Every turn, your Horse passes the ticket booth and earns Gold. Faster spin means more passes, and more passes mean more Gold. Simple.

But debris blows in from every side: Leaves first, then Sticks, then heavy Rocks. When something latches onto the carousel, it drags. Enough of it, and your carousel grinds to a halt.

You fight back two ways:
- **Click** debris to knock it away.
- **Put mounts on the carousel** that do the work for you. The Wolf sweeps everything in its line. The Sloth makes enemies drowsy and slow. The Elephant clears a wide arc. The Panda earns Gold and patches the carousel up.

Early on you're clicking a lot. Later your mounts carry you, and you're making choices about the build instead. Another Horse for income, or a second Wolf before a boss?

## Tiers and bosses
Debris comes in six color tiers, from Grey up through Green, Yellow, Orange and Red to Charcoal. Each is tougher than the last, and each tier ends with a boss:
- The **Leaf Storm** swirls around the park flinging packs of leaves.
- The **Stick Giant** zigzags its way in.
- The **Boulder** grabs on with three separate grips.
- …and three more after those.

![A Leaf Storm fight](../images/2026-09-24_04_leaf_storm_fight.png)

Beating a boss unlocks the next tier, new mounts and new upgrades. A first full run is meant to take a few relaxed hours.

## How I'm making it
I'm a solo dev building this in Godot, one of my favorite engines. I use AI coding assistants (Claude Code and Codex) to help write and test the code. Everything you see is either free Kenney art or simple shapes drawn in code from my own designs. No AI-generated art, music, or voice.

## What's next
If this one makes it to Steam and even a handful of people enjoy it, I'd love to go back to that first, bigger carousel game someday.

Right now I'm polishing the six bosses and the park's look. Next post: how the park went from a forest to a theme-park plaza, including a couple of wrong turns.

Thanks for reading!
