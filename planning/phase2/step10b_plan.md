# Phase 2 · Step 10b: Wave controls (pulled forward from Phase 4)
**Status:** BUILT 2026-09-24.

## Decisions (Garret, 2026-09-24)
| Topic | Decision |
|---|---|
| Placement | Stats panel: the "Next wave" line became a **Send wave (12)** button, with the Auto waves toggle and Emergency Clear under it. |
| Early bonus | Leaves in an early-sent wave drop **+50% Gold**, paid only on kills (`WaveManager.early_send_gold_multiplier`). |
| Timer | Sending early **restarts the countdown** at a full interval; waves can't pile up by accident. N does the same as the button. |
| Auto waves | Toggle pauses the countdown when off; sending still works. Saved as the `auto_wave` setting (default on). |
| Emergency Clear | Removes every latched enemy (no Gold) and ends a stall. Price: 20 s of normal booth income (unboosted, no drag), min 25 Gold. 60 s cooldown. Only while something is latched. All in RunConfig. |

## Your steps
- Open Game.tscn and save once.
- Playtest: send waves early for the bonus; turn auto waves off and back on; get latched and use Emergency Clear.
- Placeholder text: "Send wave (%d)", "Send wave", "Auto waves", "Clear latched (%d)", "Clear ready in %ds".
