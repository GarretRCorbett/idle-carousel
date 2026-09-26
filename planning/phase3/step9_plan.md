# Phase 3 Step 9: Playtest, Codex review, sign-off

Phase 3 is built: four new mounts, Sticks and Rocks, six color tiers, six bosses, slots 4–6,
the look pass, theming foundation, and the playtest-3 fixes (2026-09-26). Step 9 checks it all.

> **BLOCKED (2026-09-26):** Codex is out of usage. Don't run the review until Garret says it's
> back. Phase 4 started meanwhile; the playtest below can happen any time.

## 1. Codex review (waiting: Codex is out of usage until Garret says go)
Base: `b7267ac` (the last Step 8 commit; Step 8 went straight to main, no merge). That covers
34+ commits: the look pass, theming, Debug tab, Purple Garden, outlines, and the playtest-3
fixes. A Codex review already ran partway through (fixes in `332932b`), so expect few repeats.

Following CLAUDE.md → "Working with Codex":
1. Commit everything, then snapshot:
   `{ git status --porcelain; git diff; git rev-parse HEAD; } > <scratch>/pre_codex.txt`
2. Run in the background:
   `codex review --base b7267ac -c 'sandbox_mode="danger-full-access"' -c 'model_reasoning_effort="high"' > <scratch>/codex_review.txt 2>&1`
3. Snapshot again and `diff` against `pre_codex.txt`. Anything changed → tell Garret first.
4. Show Garret the findings, say which Claude agrees with, fix only what he approves. Save
   them as `codex_memo_w_phase3_review.md`.

## 2. Playtest for sign-off (Garret)
Play a fresh run (Esc menu → Debug tab to skip ahead). Notes on anything that feels off.

**Today's fixes (playtest 3)**
- [ ] The Boost panel: does it read as part of the HUD and stay out of the way of the map?
- [ ] Mount outlines: every animal easy to see on both canopy colors, and in Overdrive's glow?
- [ ] Buy Boost Power while in Overdrive: Overdrive keeps going and the bar doesn't jump.
- [ ] Latch drain: with 1–2 latches you can out-press it; with many, Overdrive slips away
  over a few seconds, never instantly. Too gentle or too strong? (5% of the bar per second
  per latch, 30% max; `run_config.tres`.)
- [ ] Faster idle (90°/s base, from 70): does idle feel alive now? Prices and boss health
  rose about 30% to keep the pace (step 8 table below).
- [ ] Gold pops: one "+X" per booth about twice a second, readable at max Carousel Speed and
  in Overdrive; the Panda's "+X" each turn. Too many, too few, or in the way?

**Phase 3 as a whole**
- [ ] Pace: first clears near 0:15 / 0:35 / 1:00 / 1:30 / 2:05 / 2:40 (write down your times;
  the sim is a slightly slow, never-boosting player).
- [ ] Each boss's mechanic reads clearly: Leaf Storm (click-only, then 4 Leaves), Stick Giant
  (zigzag), Boulder (3 latch points), Gilded Gale (trickle of Leaves), Ancient Log (first 3
  hits reduced, immune to slow), Obsidian Boulder (splits into 2 Red Rocks).
- [ ] Losing a fight: timer runs out, boss resets, nothing else lost; Give up (two-step);
  re-challenge a beaten boss for the smaller reward.
- [ ] Tier switching from the strip pips; kill gate counts; switching blocked during a fight.
- [ ] Each mount earns its place: Giraffe (far field), Sloth (slow + Zzz), Elephant (rim
  wedge), Panda (Gold per turn, heal on its kills; unlocks at 3 types at Tier 2).
- [ ] Sell a mount (two-step Confirm?) and rebuy; slots 4–6.
- [ ] Emergency Clear and the stall/crank still feel fair with Sticks and Rocks.
- [ ] Charcoal tier enemies visible (ivory outline) against the park.
- [ ] Busy late tiers: any slowdown? (Performance target is still open, question 25.)
- [ ] F4 themes (Winter/Halloween) still load (debug builds).
- [ ] Optional: pseudolocalization pass (CLAUDE.md) for any missed or cut-off text.

**Sign-off:** Garret's go → move Phase 3's checklist to `completed_phases/`, update the
roadmap, and open Phase 4 (shop redesign, mount levels and stars, auto-boost, Park Guide,
tutorial, music).
