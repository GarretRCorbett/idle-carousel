# Phase 4 Step 9: Tutorial (draft for Garret)

**Status:** script and behavior drafted by Claude (2026-09-26), **waiting for Garret's approval**.
Build after the Park Guide PR is merged (they touch the same files). Every line below is a draft;
Garret approves all player-facing text before it ships (CLAUDE.md "Hard limits").

## How it behaves (Garret's answers, 2026-09-26)
- **Learn by doing:** each step waits for the action ("knock a Leaf off" finishes when you do).
  Info-only steps have a **Next** button (controller: the confirm button).
- **The game keeps running, gently:** no waves until the clicking step, then one small wave at a
  time; the carousel **can't stall** until the tutorial ends (latches still slow it and show the
  red drain, so the lesson is visible).
- **Highlight + bubble:** the thing being taught gets a glowing outline and the rest of the screen
  dims a little; a speech bubble sits next to it, one or two short lines.
- **A carousel keeper** talks you through it (drawn in code for now, a portrait later). Name TBD:
  shown as **{keeper}** below.
- **When:** starts on the first New run when there's no save. Settings gets **Tutorial: on/off**
  and **Replay tutorial**. A **Skip** button on every bubble (asks once, like Sell).
- **Controller:** every step names the action through `ControllerPrompt` (the real binding), and
  the text has a controller version where it differs.

## The script (draft)
Each step: what's highlighted · what the keeper says · when it's done.

1. **Welcome** · the carousel · "Welcome to the carousel! I'm {keeper}. Leaves, sticks and stones
   keep blowing in and grabbing the ride, and every one slows it down." · **Next**
2. **Knock one off** · the first Leaf (one small wave arrives now) · "Click a Leaf to knock it away.
   Every one you clear pays a little Gold." Controller: "Press [strike] to hit the nearest one." ·
   done when you clear a Leaf.
3. **Latching** · the rim, when the first enemy grabs on · "Uh-oh, that one grabbed the rim! Grabbers
   drag the ride slower and wear it down. Knock it off!" · done when nothing is latched.
4. **Gold from the Horse** · the Horse and the ticket booth · "Your Horse earns Gold every time it
   passes the ticket booth. Faster spinning means more passes." · **Next**
5. **Boost** · the Boost panel · "Press Boost ([boost]) to spin faster for a moment. Keep the bar
   full for a few seconds and you'll hit Overdrive!" · done when the bar passes half.
6. **The shop** · the Upgrades tab · "Spend your Gold in the shop. Carousel Speed is a great first
   buy." · done when you buy Carousel Speed (the bubble waits while you save up).
7. **A helper** · the Mounts tab, then Mount Slot and the Wolf · "Mounts fight for you. Buy a Mount
   Slot, then a Wolf to fill it." · done when you own a Wolf.
8. **Level it up** · the Wolf's Up button · "Press Up to level your Wolf. Every Wolf you own shares
   its levels, and after three it can earn a star." · done when the Wolf is level 1.
9. **Waves** · Send wave and Auto waves · "Waves come on their own. Send one early for bonus Gold,
   or switch Auto waves off to take a breather." · **Next**
10. **The first boss** · the boss strip · "Clear 60 debris in this tier to challenge the Leaf Storm.
    Beat it and new mounts and tiers open up." · **Next**
11. **Goodbye** · the pause menu hint · "Everything you meet goes in your Ticket Book (Esc / [pause]). Have
    fun, and keep the ride spinning!" · **Next** (the tutorial ends; stalls are possible again)

About 3–5 minutes for a new player, most of it playing, not reading.

## Build notes (for later)
- A `TutorialStep` resource per step (target, text key, completion condition), so steps are data
  and a theme or a later character can reuse them. A `Tutorial` node in Game listens to existing
  signals (enemy died by click, latch count, boost fraction, upgrade_applied) to finish steps.
- Highlight: a dim overlay with a cut-out and a glowing outline around the target Control or world
  point; the bubble positions itself beside it and stays on screen.
- Tutorial progress (done / skipped) goes in the save's `permanent` section.
- Step 3 only runs if something latches during the tutorial; otherwise it's skipped.

## Garret's answers (2026-09-26)
- **The keeper:** a mascot-style character that doesn't lock us into an art asset (like Wildfrost's
  small guides). Garret likes the **ticket** most (light bulb as backup); see `planning/theme_ticket.md`.
  A name would be nice but isn't required; it waits for the theme to be defined.
- **Controller striking:** build **"strike nearest"** now (a button that hits the enemy closest to the rim).
- **Lines:** mostly good; final pass once the theme is settled and Codex has weighed in.

## Open questions for Garret (original)
1. **The keeper's name** (and are they a person, or an animal like the mounts?).
2. **Controller striking (step 2):** controllers can't hit enemies yet (the "strike nearest" idea
   is in NOTES for the full controller pass). Build a simple strike-nearest button together with
   the tutorial, or give controller players a different step 2 for now?
3. **Approve or edit the lines above.** Short and friendly is the aim; say if the tone is off.
