# Phase 3 Step 8: Economy Simulator + Pricing (results)

Garret's targets (2026-09-25):
- **Pace:** 15 / 20 / 25 / 30 / 35 / 35 min per boss, so the first clears land at about 0:15, 0:35, 1:00, 1:30, 2:05 and 2:40.
- **Wall:** the boss. Kill gates stay short; the bosses make you go back and farm.
- **Clicking:** tone it down; mounts carry.

## The simulator
`tools/economy_sim.tscn` plays a whole run headless with a scripted player on the real game (waves, combat, bosses, shop):

```
"$GODOT" --headless --audio-driver Dummy --path . res://tools/economy_sim.tscn -- <hours> <clicks/s> <seed> [clicks/s in fights]
```

What the scripted player does:
- **Clicking:** at a steady rate, on the boss or on the enemy nearest the carousel.
- **Cranking:** only when stalled. It never Boosts.
- **Shopping:** follows a build order, then buys the cheapest affordable upgrade.
- **Bosses:** challenges each one as soon as its gate is met; after a loss, waits 150 s before trying again.

Real players Boost and aim, so read its times as a slightly slow player. A 2.6 h run takes about 5 minutes on the laptop.

## Results (1 click/s, seeds 1–3)
| Boss | Target | Seed 1 | Seed 2 | Seed 3 | Avg |
|---|---|---|---|---|---|
| 1 Leaf Storm | 0:15 | 0:19:38 | 0:19:38 | 0:15:50 | 0:18 |
| 2 Stick Giant | 0:35 | 0:32:05 | 0:32:02 | 0:28:13 | 0:31 |
| 3 Boulder | 1:00 | 1:07:26 | 1:02:53 | 1:07:49 | 1:06 |
| 4 Gilded Gale | 1:30 | 1:26:52 | 1:32:13 | 1:32:08 | 1:30 |
| 5 Ancient Log | 2:05 | 2:06:24 | 2:06:43 | 2:01:57 | 2:05 |
| 6 Obsidian Boulder | 2:40 | 2:39:25 | 2:34:12 | 2:34:46 | 2:36 |

Each boss takes 1 to 4 tries. The run stalls for about 12–13 min in total (mostly before the first Wolf).

## What changed
- **Prices, roughly 2–6×:**
  - Starting upgrades rose least: Speed 30→60, Click Damage 25→40, Wolf 80→150.
  - Late items rose most: Elephant 400→2,500, Panda 1,500→9,000, Tier 2 rows 3–7×.
  - Level growth is a bit steeper: Speed and Click ×1.6, Wolf Fang ×1.75, slots ×2.8, booths ×1.8.
- **Click Damage** is +0.25 per level, down from +0.5 ("tone clicking down").
- **Boss health up:**

  | Boss | Old | New |
  |---|---|---|
  | Leaf Storm | 90 | 130 |
  | Stick Giant | 200 | 270 |
  | Boulder | 300 | 480 |
  | Gilded Gale | 230 | 550 |
  | Ancient Log | 220 | 400 |
  | Obsidian Boulder | 200 | 380 |

- **Gilded Gale** circles at radius 190 (was the default), so mounts can reach it. With less click damage it couldn't be beaten otherwise.
- Kill gates unchanged.
- Tests that assumed the old prices now read them from the data.

Every price, health value and growth rate is a draft. The ticket booth price (1,500, then ×1.8) differs from the ★ in open question 23 (500 / 2,500 / 8,000). That's Garret's call.

## Sensitivity (the part worth a look)
- **2 clicks/s:** the whole run takes 1:16, about half as long. Leaf Storm falls at 0:02:47 because it's click-only by design (memo S), so a fast clicker can beat it before owning anything.
- **Idle farming (0.2 clicks/s), 1.5 clicks/s in fights (seed 1):** stuck on Leaf Storm until 1:02, losing 12 times (it's click-only and early Gold comes slowly). Then the mounts carry: bosses 2–6 fall at 1:05, 1:17, 1:52, 2:06 and 2:39. The finish matches the 1 click/s player; only the first boss is a wall.
- **After all upgrades are bought (around 2:30)**, Gold has nothing left to buy. That's fine for Phase 3; Phase 4's full upgrade tree fills it.

## Open for Garret
1. Is it OK that clicking speed changes the run length this much (1 click/s = 2:36, 2 clicks/s = 1:16)? Options:
   - ★ Keep it; the playtest will tell.
   - Cap click damage per second.
   - Give Leaf Storm a mount-damageable part.
2. Booth prices (question 23): keep the draft 1,500 ×1.8, or the ★ milestones 500 / 2,500 / 8,000?
3. Questions 22 (idle speed) and 24 (manual wave stacking) are still open; Step 8 didn't need them.
