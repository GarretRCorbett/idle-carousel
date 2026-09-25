# Performance: first pass (Claude, 2026-09-24)

Garret's concern: other Steam incrementals lock up when too much is on screen, and a
playtest with a fast carousel and lots of Leaves felt close to that. No performance work
existed yet. This memo measures today's build and lists what Phase 3 should do about it.

## How it was measured
A temporary stress scene (since replaced by the permanent `tools/stress_test.tscn`,
which fixes the sampling issues Codex found) loads the real `Game.tscn` with max Carousel Speed, the Wolf, and a second
Horse, then holds N Leaves on screen at random distances. The Leaves can't die (huge health,
no damage, no drag) so N stays fixed, but the Wolf keeps hitting them, so hit flashes and
health bars are included. Vsync off; 1 s warm-up, then 3 s of samples per stage.

**Machine: Ryzen 9 8945HS + RTX 4070 Laptop (high end).** A typical laptop or a Steam Deck
may be 3–5× slower; divide the enemy counts below accordingly.

## Results
| Leaves | FPS | Avg frame | Worst 1% | Physics per tick | Draw calls |
|---|---|---|---|---|---|
| 0 | 1282 | 0.8 ms | 1.6 ms | 1.0 ms | 59 |
| 50 | 1287 | 0.8 ms | 1.9 ms | 2.0 ms | 195 |
| 200 | 1320 | 0.8 ms | 2.9 ms | 4.8 ms | 631 |
| 500 | 626 | 1.6 ms | 6.3 ms | 6.9 ms | 1,499 |
| 1,000 | 130 | 7.7 ms | 20 ms | 14 ms | 2,989 |
| 2,000 | 17 | 59 ms | 149 ms | 26 ms | 5,871 |
| 4,000 | 3 | 304 ms | 336 ms | 42 ms | 9,169 |

What breaks: once a frame takes longer than a physics tick (16.7 ms), Godot runs several
physics ticks per frame to catch up, which makes the frame even slower. That spiral is the
"lock-up" Garret has seen in other games. Here it starts between 1,000 and 2,000 Leaves.

## Where the time goes (1,000 / 2,000 Leaves)
| Variant | FPS at 1,000 | FPS at 2,000 | Meaning |
|---|---|---|---|
| Normal | 135 | 17 | |
| No Wolf (nothing gets hit) | 608 | 176 | **Hits are the main cost**: health bars become visible, a flash tween per hit, and the Wolf checks every enemy every tick (~6 ms per 1,000 enemies, per Wolf). |
| No drawing (enemies and bars hidden) | 685 | 113 | **Drawing is the other main cost.** A hit Leaf is 3 draw items (its shape + a UI `ProgressBar` with 2 style boxes). |
| No physics body (`Area2D` shape off) | 142 | 22 | The unused `Area2D` costs little. |
| Physics interpolation off | 148 | 21 | Smoothing costs little. |

## How many enemies will the game really have?
- Normal play (memo M's waves): about 4–10 enemies every 15–20 s, cleared by mounts, so
  **tens on screen**. That's far below any problem.
- What can pile up: **Send wave has no limit** (stacking waves), long stalls, and **Gilded
  Gale's summons**. Garret's playtest pile-up was probably this. A few hundred is realistic
  with stacking; thousands only with deliberate abuse or a bug.
- Phase 3 adds **4 more sweeping mounts**. If each checks every enemy like the Wolf does,
  the mount cost is ~5× today's.
- Phase 6 "juice" (particles, coin pops, tweens) adds per-hit cost on top.

## Recommendations
**Set a budget (Garret's call):** e.g. *60 fps on a Steam Deck–class machine with 300 live
enemies and all 6 mounts*, tested at 2× that. Add a guardrail so play can't exceed it
(below).

**Phase 3, cheap now (build into Step 2 foundations, measure after each step):**
1. **One shared enemy snapshot per tick.** Game builds one list of live enemies (bearing,
   distance, radius) each tick; every sweeping mount reads it instead of re-scanning. Skip
   enemies outside a mount's reach with a quick distance check before any angle math.
   Memo L suggested the snapshot for correctness; it's also the biggest mount-cost saving.
2. **Draw the health bar inside the enemy's own drawing** (two `draw_rect` calls on
   `Visual`) instead of a `ProgressBar` control. Fewer nodes and draw items per enemy, and
   it matches the "tint layer separate from flash" change memo L asks for anyway.
3. **Drop the unused `Area2D`/`CollisionShape2D`** from enemies (clicks and sweeps use
   distance and angle math). Small gain, fewer nodes, less confusion. Make the enemy root a
   `Node2D`.
4. **Make the stress test a real tool** (`tools/stress_test.tscn`) with the stage table
   printed, and run it at the end of each Phase 3 step. Timing tests in the normal check
   would be flaky, so this stays a manual tool with a written target.

**Guardrails (design; Garret decides, Phase 3):**
5. **Live-enemy cap.** E.g. Send wave is disabled while more than N enemies are alive,
   and summoners (Gilded Gale) stop at M live adds. This also answers memo M's worry
   that stacking sends is exploitable. Memo L said to measure before adding a cap; this memo
   is that measurement.
6. **Spawn bursts:** big waves spawn over a few ticks, not all in one frame.

**Later (only if the budget test fails):**
7. Object pooling for enemies (reuse instead of create/free), useful once spawners exist.
8. Draw all enemies from one node (`MultiMeshInstance2D` or one custom `_draw`) for
   thousands on screen. Big change; not needed at the counts above.
9. Phase 6: budget particles/juice per second; test on a Steam Deck or low-end laptop
   before the demo (Next Fest players will include low-end machines).

## Questions for Garret
1. Performance target: ★ 60 fps on a Steam Deck–class machine with 300 live enemies / higher / decide after Phase 3 content.
2. Live-enemy cap: ★ block Send wave above a live-enemy limit and cap summoner adds / no cap, just optimize / decide after measuring Phase 3.
3. Build the stress test as a permanent tool in Phase 3 Step 2? ★ yes.
