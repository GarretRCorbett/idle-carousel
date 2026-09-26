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

## Open (ask Garret when building auto-boost)
- **How Overdrive works today** (`GameState._update_boost_status`, RunConfig): it starts after the bar sits at 99% or more for 5 s, and stays on until the bar drops below 80%. Latched enemies slow the spin but do **not** lower the bar. So "a latch breaks turbo" needs a new rule. Options:
  - latched enemies drain the bar;
  - any latch ends Overdrive;
  - auto-boost pauses while something is latched.
- **Level holds:** maybe roughly 30% / 50% / 65% / 82% of the bar. Tune with the sim. Prices and position in the shop (the Carousel tab?) are open too.
- **Strings:** the upgrade's name and description need Garret's approval.

## Build order (next sessions)
1. Boost panel, then mount outlines. Both small.
2. Faster idle: raise the base spin, re-run the economy sim, keep the boss pace.
3. Auto-boost, once the open questions are answered. Update the GDD.
4. Codex worktree task: mount art study.
5. Tutorial script draft for Garret's approval. Build it after Phase 3.
