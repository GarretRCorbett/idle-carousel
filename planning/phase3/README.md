# Phase 3 Planning: Start Here

## Status (2026-09-24)
**Step 1 approved and done** (`step1_plan.md`, incl. Codex memo O): contracts and scene trees for Steps 2–3.
Next: Step 2 (foundations). Step 1 and Step 3 questions are answered (below). Mounts renamed to
Kenney animals (GDD v1.12).

Phase 3 roadmap scope: Sloth, Giraffe, Elephant, Panda; Stick and Rock; six color tiers;
the six tier bosses; mount slots 4–6. (The Rusted King is Phase 5.)

## Step 2 performance (stress test, Radeon 780M, 1 Wolf + 1 Horse, 2026-09-25)
Before = commit cdbead7 (with sound). After = end of Step 2 (silent, `--audio-driver Dummy`).
**Compare tick times**; FPS isn't comparable because the silent run skips audio work.

| Leaves | Tick avg before → after | Tick max before → after | FPS before → after |
|---|---|---|---|
| 0 | 0.18 → 0.19 ms | 0.97 → 0.93 | 782 → 1107 |
| 100 | 1.00 → 1.00 ms | 2.14 → 1.80 | 668 → 997 |
| 300 | 1.76 → 1.86 ms | 2.79 → 2.75 | 474 → 712 |
| 500 | 2.43 → 2.50 ms | 4.73 → 3.35 | 313 → 424 |
| 1,000 | 3.98 → 4.33 ms | 5.51 → 5.07 | 133 → 156 |
| 2,000 | 7.21 → 7.62 ms | 9.84 → 9.31 | 50 → 56 |

- With **one** sweeping mount, ticks cost 5–9% more at 1,000+ enemies: the snapshot adds a
  bearing update and array writes per enemy, and one Wolf alone doesn't share it. The saving
  is meant to show with several sweeping mounts (Giraffe, Elephant, Panda); re-measure at Step 5.
- Spawns now join at the next tick, so the stress tool admits a whole stage in one tick. That
  tick is setup, and the tool no longer samples it (it showed as fake 27–64 ms spikes).
- Open, minor: the tool sometimes prints "4 resources still in use at exit" since Step 2 (not
  sound-related; the game itself doesn't show it). Look at it with `--verbose` when convenient.

## Decided 2026-09-24 (Garret)
- **Boss access:** a minimal per-tier kill gate plus a manual "Challenge boss" button, built
  in Phase 3. HUD polish and the full shop visibility system stay in Phase 4. (Q1)
- **Run target** (2.5–3.5 h) means online play, checking in now and then. Faster expert
  runs are fine. (Q3)
- **Tier select:** players can go back and farm any unlocked tier. (Q4)
- **Boss rule (TEMPORARY for playtests; the real fail state stays DECISION PENDING in the
  GDD).** After memo N (Clicker Heroes and other idle games):
  - **Timed fight.** Kill the boss (and any required split children) before the timer
    runs out. Starting timers from memo N: Leaf Storm 90 s, Stick Giant 120, Boulder 120,
    Gilded Gale 150, Ancient Log 150, Obsidian Boulder 180. Stored in boss data.
  - **Failure costs time only.** Timeout ends the attempt, the boss resets, you go back
    to farming. No Gold cost, no mount loss. Gold, mounts, unlocks, and kill-gate
    progress are kept.
  - **Health still matters, with unlimited crank rescues.** Latches still drag and
    damage; a stall doesn't end the attempt, you crank back as many times as needed while
    the timer keeps running. The fight is a balance of dealing damage and not stalling.
    (A one-rescue limit can be tried later.) The 60 s safety net must never remove the
    boss or count as a win during a fight.
  - **Bosses need active play at first.** Near-idle wins only when truly maxed. Garret:
    "maybe after a prestige or two." Prestige is now in v1.0 (GDD v1.10, Phase 5).
  - **Retries are manual and free:** press Challenge again whenever you like.
- **Prestige ships in v1.0** (GDD v1.10), built in Phase 5. For Phase 3 that means: keep run
  state separate from anything permanent, keep numbers in data with multipliers (future
  challenge modifiers), and track run times.
- **Mounts can be doubled and sold** (GDD v1.11, after the wrap-up playtest): any type can be
  bought more than once and sold for 50%, to swap builds (e.g. sell a Horse for a second
  Wolf before a boss). Built for Horse and Wolf in Phase 2; new mounts follow the rule.
  Question 9 answered: **per-type tiers** (Garret). Affects question 10 (count *types*, so
  duplicates can't unlock the Panda).
- **Send wave limit:** blocked while more than 30 enemies are alive (Phase 2 wrap-up).
  Revisit once Sticks and Rocks exist; Garret might prefer one early wave at a time then.
  This answers question 24 for now and part of question 26.
- **Tuning from the wrap-up playtest:** base 70°/s (60, then 70 after a second playtest), max boost +40%, waves every 10 s. So
  question 22 is answered (70°/s).
- **Phase 3 start (Garret, 2026-09-24):** tier colors = light greyscale enemy sprites + tint (Q13);
  Stick/Rock latch damage 0.9 / 1.5 (Q14); waves = **random with caps** per tier (odds per type
  plus a max per wave), per-tier interval in data, Grey at 10 s (Q15); Claude drafts the six tier
  shades, Garret tweaks; debug-only dev keys switch tiers until Step 6; performance target decided
  after content (Q25), stress test still run each step; Send limit stays 30 until the first
  Grey + Green playtest (Q26); Step 1 contracts cover Steps 2–3 only.
- **Mounts renamed** to match Kenney's Animal Pack (Garret; GDD v1.12): **Turtle → Sloth,
  Eagle → Giraffe, Lion → Elephant, Unicorn → Panda.** Abilities unchanged. Q12 answered.
  Upgrade names drafted by Claude, approved by Garret. **The memos in this folder still use the
  old names.**
- **Speedrun-friendly** (Garret, see NOTES): track active run time and each boss's first-clear time in GameState; seed wave randomness per run.

## What's in this folder
| File | What it is |
|---|---|
| `claude_audit.md` | What Phase 2 code already supports, what's hard-wired to Horse/Wolf/Leaf, stale data, art inventory |
| `codex_memo_l_mounts_enemies_bosses.md` | Codex: architecture for new mounts, statuses, tiers, bosses, multi-latch, removal safety, tests, 11-step plan, 18 questions |
| `claude_memo_performance.md` | Claude: stress test of today's build (FPS at 0–4,000 Leaves), where the time goes, Phase 3 recommendations and guardrails |
| `tools/stress_test.tscn` | (in tools/) The stress test as a permanent dev tool; run it before/after performance changes |
| `claude_memo_prestige.md` | Claude: prestige research (first-prestige timing, rewards players like, Slay the Spire / Wildfrost challenges), a possible shape, questions for before Phase 5 |
| `codex_memo_n_boss_timers.md` | Codex: how Clicker Heroes, Tap Titans 2, Idle Slayer, and Melvor handle boss failure; player reactions; timed-boss proposal |
| `step1_plan.md` | Step 1: decisions, contracts, and scene trees for Steps 2–3 |
| `codex_memo_o_step1_review.md` | Codex: review of the Step 1 plan (spawn queue vs Send limit, removal order, line-tip formula, wave validation, tests) |
| `codex_memo_m_tiers_pacing.md` | Codex: tier loop, kill gate, wave recipes, stat scaling, 3-hour economy model, prices, simulator, boss tuning, 12 questions |

The memos are **input, not decisions.**

## Claude's read of the memos

### Agree (adopt when planning steps)
- **Foundations before content.** The roadmap calls Phase 3 "pattern replication", but
  that's only true after a few shared pieces exist: every mount emits the same signals
  (no more `if mount is MountWolf` in `game.gd`), a shared `MountSweep` helper that
  Wolf/Giraffe/Elephant/Sloth/Panda each own (composition, not a superclass), per-mount
  damage lookup, and kill attribution (which mount landed the lethal hit, for Panda heals).
- **Removal is a state, not just `queue_free()`.** An enemy being removed can't move,
  latch, be hit, spawn children, or complete a boss. Phase 2's last bug was exactly this;
  splits, spawners, and knockback add more ways to hit it. Children spawned mid-tick
  join at the next tick.
- **Tiers as data:** one `TierData` `.tres` per color with separate multipliers
  (health, speed, drag, Gold, damage). Each enemy snapshots its effective stats at spawn;
  nothing reads `enemy.data` directly for tiered stats after that.
- **Modest scaling** (memo M §3): health ×1.40 per tier, Gold ×1.45, latch damage ×1.10,
  drag unchanged. Retune Stick/Rock latch damage to about 0.9 and 1.5 before tiers
  multiply them (they're 4× and 8× the Leaf today).
- **Tint needs light art.** Modulate darkens colored sprites. Also: the tint must live on
  a different node than the hit flash (`_flash()` resets modulate to white today), and
  enemies have no `Sprite2D` yet, so setting `EnemyData.texture` would make them vanish.
- **Multi-latch as `(enemy, point)`**, keeping today's one-latch calls working for
  ordinary enemies. `get_latched_count()` keeps meaning enemies, not points.
- **Boss victory is separate from body death** (`BossEncounter`): the big Gold bonus and
  unlocks are paid once, when every required piece (split children too) is dead.
- **Mount tiers are separate from upgrade levels.** Today `horse` level = number of
  Horses bought, so it can't also mean Horse Tier 2.
- **Prices:** booths 2–4 as separate milestones (≈500 / 2,500 / 8,000), not one ×1.5
  curve. Today's booths total only 2,375 Gold, which late tiers make trivial.
- **Gilded Gale** at "2 Leaves per second" is far too much. Start at 2 every 4 s, with
  no Gold or kill credit for summons.
- **A small balance simulator is worth it**, but a small first version (below).

### Simplify or disagree
1. **Memo L's moving-target solver and event-ordered tick (its Steps 2–3, both "L").**
   Physics runs at a fixed 60 ticks/s. At the fastest possible spin the carousel turns
   ~11° per tick, which `sweep_passes` already covers exactly; a Leaf moves ~1.5 px per
   tick. Checking the enemy's end-of-tick position is off by at most one tick, which
   you'd never see. The two real problems are smaller: **bearings wrap at ±180°** for
   enemies that move sideways (Stick Giant's zigzag) and **zigzag re-entry** must not
   earn a second hit. Fix those (track each enemy's unwrapped bearing; per-encounter hit
   memory) with tests, keep today's tick order, and revisit only if a playtest shows misses.
   This saves roughly a session.
2. **Memo L's finite-segment window math** (§4) is a real but tiny correction for the
   tips of the sweep line. Worth doing when `MountSweep` is extracted, with tests.
3. **Kill gate: the memos disagree.** M pulls a minimal gate into Phase 3 (a kill counter
   plus a "Challenge boss" button), so bosses are tested through the real path. L keeps
   the gate in Phase 4 and spawns bosses with dev shortcuts. **Claude sides with M**: the
   minimal version is small, and Garret can't judge boss pacing from a dev button. The
   HUD polish and full shop visibility stay in Phase 4. (Question 1.)
4. **Simulator scope.** M wants discrete sweep timing, fail policies, and five player
   policies. Start smaller: a headless GDScript tool that loads the real `.tres` files and
   plays the *economy* forward (purchases, booth income, kill income from cleared waves)
   and prints time-to-each-purchase and time-to-each-tier. Combat safety stays a
   playtest question until the economy numbers look right.
5. **Knockback (Trunk Toss)** is an Elephant upgrade, not the Elephant. Build the Elephant's arc
   in Phase 3; knockback with the other named upgrades in Phase 4 unless Garret wants it early.

### Carries into Phase 3 from elsewhere
- **Fail state is still DECISION PENDING.** Bosses make it pressing: what does a stall do
  to a boss attempt? Phase 3 can keep encounter code replaceable, but a boss playtest will
  need at least a TEMPORARY rule (Question 5).
- **Offline pacing** (memo M §8): at late-game income, 8 h offline at 50% ≈ 288,000 Gold,
  more than the whole planned run. A Phase 4 problem, but it shapes prices now.
- **Sprite orientation** is still parked for Phase 6.

## Proposed Phase 3 steps (draft)
Ordered so the risky, shared pieces come first. Rough sizes: S ≈ under 1 h, M ≈ 1–2 h, L ≈ 2–3 h.

| Step | Work | Size |
|---|---|---|
| 1 | Garret's decisions; resource contracts (`TierData`, `WaveProfile`, mount/enemy fields); scene trees for the new enemies and mounts | S (plan) |
| 2 | **Foundations:** generic mount signals, `MountSweep` extracted from the Wolf (all Wolf tests still pass), per-mount damage, kill attribution, enemy removal state, queued spawns, unwrapped bearings. **Performance** (memo): one shared enemy snapshot per tick, health bar drawn in the enemy, drop the unused `Area2D`, `tools/stress_test.tscn` | L |
| 3 | **Tiers and enemies:** `TierData` × 6, effective stats, Stick/Rock retune and scenes, mixed waves, `Sprite2D` + tint separate from hit flash | M–L |
| 4 | **Giraffe and Sloth:** long-range sweep on approaching enemies; `EnemyStatusEffects` (slow, freeze-ready) | M |
| 5 | **Elephant and mount tiers:** arc sweep; type-wide mount tiers with a few real Tier 2 purchases; **Panda** (Gold per turn, damage, heal on its own kills) | M–L |
| 6 | **Boss framework + first boss:** tier/kill/boss state in GameState (save-ready), minimal kill gate + Challenge button, `EnemyBoss`, `BossEncounter`, slots 4–6, **Leaf Storm** | L |
| 7 | **Remaining five bosses:** Stick Giant (zigzag), Boulder (3 latch points), Gilded Gale (spawner), Ancient Log (immune + resist), Obsidian Boulder (split) | L (maybe 2 sessions) |
| 8 | **Balance simulator v1 + pricing pass:** new prices, test 60°/s base speed | M |
| 9 | Playtest across tiers, fixes, Codex review, understanding check, sign-off | M |

About 8–10 sessions. Grey + Green with Stick, Rock, Sloth/Giraffe, and Leaf Storm
(end of Step 6) is the first slice worth a real playtest.

## Questions for Garret
Grouped by when they're needed. Recommendations marked ★. Full reasoning is in the memos
(L = memo L question number, M = memo M question number).

**Before Step 1 (shape of the phase)** — all answered. Q2 (Garret): **any enemy kill in the tier counts** toward its gate (Leaf, Stick, Rock; boss summons only exist after the gate is met, so they can't be farmed for it).
1. Boss access: ★ minimal kill gate + a manual "Challenge" button in Phase 3 / auto-summon when the gate is met / dev shortcuts only, gate in Phase 4. (M2, L17)
2. What counts toward the gate: ★ kills of ordinary enemies in that tier, kept through failures / every kill incl. summons / waves completed. (M3)
3. What does the 2.5–3.5 h target measure? ★ someone playing online, checking in now and then / constant active play / total time incl. offline. (M1)
4. Can players go back to farm a lower tier? ★ yes, pick any unlocked tier / no, always the newest. (M §1)
5. TEMPORARY boss-failure rule for playtests (the real fail state stays DECISION PENDING): ★ a stall ends the attempt after a short rescue window; Gold and unlocks kept / the attempt only ends if you leave / decide after the first boss playtest. (M4)

**Before Steps 4–5 (mounts)**
6. Sloth trigger: ★ slows each approaching enemy once as it rotates past it / one pulse at a fixed point each turn. (L1)
7. Panda Gold: ★ once per full turn / per enemy hit / per turn that hits something. (L2)
8. Panda heal: ★ only on its own kills / any kill while it's on the carousel. (L3)
9. ~~Mount tiers~~ **Decided: per type** (all Wolves share Wolf Tier 2). (L4)
10. Panda unlock: ★ 3 different mount types at Tier 2 (duplicate Horses don't count) / any 3 mounts at Tier 2. (L5)
11. Elephant shape: ★ a wedge centered on the carousel / a cone from the Elephant. (L6) Also confirm the Elephant's job: the Wolf already hits every enemy on its line, so a wider arc mostly hits clusters *sooner*, not more often. Is that enough, or should the Elephant hit harder too?
12. ~~Mount art~~ **Decided:** repicked to Kenney animals (Sloth, Giraffe, Elephant, Panda).

**Before Step 3 (tiers and enemies)** — all answered (see Decided).
13. Tier colors on colored art: ★ light/greyscale enemy sprites + tint / a color-swap shader / tint only an accent. (L15)
14. Stick/Rock retune: ★ latch damage 0.9 and 1.5 (from 2 and 4) / keep and see.
15. Waves per tier: ★ memo M's recipe table (Sticks from ~40 Grey kills, Rocks from ~40 Green kills) / random mix.

**Before Steps 6–7 (bosses)**
16. Split bosses win when: ★ every split child is dead too / the parent dies. (L12)
17. Gilded Gale: ★ 2 Leaves every 4 s, no Gold or kill credit / 2 every second as written. (M9, L13)
18. Ancient Log "resists the first 3 hits": ★ reduced damage on those hits / fully blocked. And immune to freeze as well as slow? ★ yes. (L10, L11)
19. Boulder's 3 latch points: ★ each has its own health; drag drops as each is cleared / full drag until all are cleared / shared health. (L9)
20. Obsidian Boulder "must kill twice": ★ body dies, then 2 Purple Rocks must die (two stages) / something else.
21. Trunk Toss knockback: ★ Phase 4 with the other named upgrades / build with the Elephant now. (L7, L8)

**Before Step 8 (pricing)**
22. Idle speed: ★ test 60°/s base (from 45) / keep 45 and cheapen early upgrades / wait for hold-to-boost. (M6)
23. Booth prices: ★ milestones ≈500 / 2,500 / 8,000 / keep ×1.5 / lock booths to tiers. This changes the GDD's booth rule. (M7)
24. Manual wave stacking: ★ leave it unlimited, restrict it if a playtest shows abuse / one unresolved manual wave at a time now. (M8)

**Performance (before Step 2; see `claude_memo_performance.md`)**
25. Target: ★ 60 fps on a Steam Deck–class machine with 300 live enemies and all 6 mounts / higher / decide after Phase 3 content.
26. Live-enemy cap: ★ block Send wave above a live-enemy limit and cap summoner adds / no cap, just optimize / decide after measuring.

**Later (GDD clean-up before the full upgrade tree, Phase 4)**
- Several GDD upgrades describe the same effect twice (Giraffe Tier 3 vs Double Take, Elephant Tier 3 vs Trunk Toss, Sloth Tier 3 vs Deep Sleep), and Bamboo Feast is both +50% and ×2. ★ same unlock, doesn't stack. (L16)
- Horse Tier 3 "Gold on every sweep" needs a definition. ★ booth passes plus one extra payment per turn. (M10)
- Mount-tier colors vs the six enemy colors. ★ keep them separate. (L18)
