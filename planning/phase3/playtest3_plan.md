# Playtest 3 notes and plan (2026-09-25)

Garret played the Purple Garden build ("once I started playing, I loved it"). His notes and answers:

## Decided
1. **Boost bar gets its own purple HUD panel** (like the other sections), holding the bar and the Boost button, so it separates from the map.
2. **Tutorial:** a toggleable first-run walkthrough, planned now, built after Phase 3 sign-off. Order:
   - the main objective (debris slows your carousel; clear it);
   - click to destroy, or add powerful mounts;
   - the boost bar;
   - the wave timer and settings;
   - the shop and its tabs;
   - buying and upgrading a Wolf.

   Every line is player-facing text, which Claude drafts and Garret approves. It needs a highlight/pointer system.
3. **Idle:**
   - Speed up idle now: base spin (open question 22) and idle Gold, re-tuned with `tools/economy_sim.tscn`.
   - Keep offline progress (Phase 4, with saves).
   - Plan automation.
4. **Auto-boost, early automation.** Garret's idea: a shop upgrade with 4 levels (like Carousel Speed) that presses Boost for you.
   - It fixes touchscreens: you can't hold Boost and click enemies at once.
   - It lets players use the Boost Power they've bought.
   - Each level holds the bar higher. The top level keeps it just above 80%: enough to keep Overdrive running once started, never enough to start it alone.
   - Garret's intent: "if something latches, it still brings you out of turbo," so players still want to protect the carousel.
5. **Mounts:** add outlines now, the same way as the tier outlines; then a Codex art study (a few treatments of the same animals) for Garret to pick from.

6. **Bug: buying Boost Power ends Overdrive.** The cap rises, so the same boost reads below the 80% "still maxed" line. Fix: keep the bar's fill fraction when the cap grows. Buying must never break Overdrive.
7. **Latches drain boost gently** (Garret: "just slow down boost some, not bully reset it"). Each latched enemy drains the bar a little; more latches drain it faster. Losing all health still ends Overdrive, as now ("that felt right").
8. **Shop redesign** ("takes up too much real estate; navigating is confusing, especially mounts"):
   - The Mounts tab becomes one row per animal in a fixed order: an icon (fully greyed when locked, in color when available), the count owned ("×2") and tier (T1/T2), and compact **Buy** (gold, with the price), **Sell** and **Upgrade** buttons.
   - The other tabs get the same compact treatment (icon, level pips, one gold buy button), and the shop gets narrower.
   - Codex renders 2–3 mockups first (a worktree task); Garret picks; then build.

9. **Mount upgrades are confusing** (Wolf Fang sits in Combat, the others get a one-step Tier 2 in Mounts; "the Wolf has it right"). Claude's proposal, **awaiting Garret's OK (it's a GDD change)**:
   - Every mount gets its own leveled track on its Mounts-tab row: Wolf damage, Giraffe reach/damage, Sloth slow strength, Elephant sweep width/damage, Panda Gold/heal, Horse Gold per pass.
   - Tiers become milestones on that track (for example Tier 2 at level 5 and Tier 3 at level 10), each adding a visible ability.
   - The Combat tab keeps the player's own stats (click damage).
10. **Almanac / "Park Guide"** from the pause menu, Hades-style: pages for mounts (abilities, levels, tiers), enemies and tiers, and bosses (how each fight works), unlocking as you meet them. Phase 4 size. The tutorial can link into it.
11. **Income is invisible** ("not looking at Gold per second"; "I don't get how the Panda works"):
    - Make every mount's effect visible: a coin "+X" over the Horse at booth passes and over the Panda each turn, and a heal sparkle when the Panda heals (like the Sloth's Zzz).
    - Make Gold and Gold per second more prominent once idle matters.
    - Garret's idea, a mount with flat Gold per second: maybe the Panda becomes that. Decide together with item 9.

## Open (ask Garret when building auto-boost)
- (Answered, item 7: latches drain the bar gently.) **How Overdrive works today** (`GameState._update_boost_status`, RunConfig): it starts after the bar sits at 99% or more for 5 s, and stays on until the bar drops below 80%. Latched enemies slow the spin but do **not** lower the bar. So "a latch breaks turbo" needs a new rule. Options:
  - latched enemies drain the bar;
  - any latch ends Overdrive;
  - auto-boost pauses while something is latched.
- **Level holds:** maybe roughly 30% / 50% / 65% / 82% of the bar. Tune with the sim. Prices and position in the shop (the Carousel tab?) are open too.
- **Strings:** the upgrade's name and description need Garret's approval.

## Build order (next sessions)
1. Boost panel, mount outlines, and the Boost Power / Overdrive bug. All small.
2. Faster idle: raise the base spin, re-run the economy sim, keep the boss pace.
3. Auto-boost, once the open questions are answered. Update the GDD.
4. Codex worktree tasks: mount art study, and the shop redesign mockups.
5. Tutorial script draft for Garret's approval. Build it after Phase 3.
