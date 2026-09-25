# Phase 2 Planning: Start Here

## Status: ✅ Phase 2 signed off (2026-09-24)
All steps done, understanding check passed, 199 tests. Next: Phase 3 (`planning/phase3/README.md`).

## Status at the Step 11 wrap-up
**Built:** Steps 1–10, 5b, 10b, and the pacing pass (GDD v1.6–1.8). Core loop: GameState, spin, Boost button with Overdrive, Horse and booth payouts, Gold/sec, leveled shop in three tabs (Carousel / Combat / Mounts), Leaves in timed waves, click damage, latch drag, the Wolf, Wolf Fang, mount slots 2–3, extra Horses (sell for 50%), Ticket Booths 2–4, even spacing, and the TEMPORARY health stall with crank and safety net.
**Extras built early:** Kenney sprites (Horse, Wolf), UI theme (Kenney UI Pack + Future font via `tools/build_ui_theme.gd`), sound effects (`AudioManager`), main menu, backgrounds, Settings + Controls (Esc in game), wave controls (Send wave / N with +50% kill Gold, Auto waves, Emergency Clear), localization (string keys, number formatter, 9 languages with per-language fonts).
**Check:** passes, **186 tests**. The Step 1 deliberate-failure check was shown on 2026-09-24 (FAIL, exit 1). The gdUnit4 editor plugin is enabled.
**Step 11 remaining:** Garret's playtest (5 min active + 5 min hands-off), full Phase 2 diff review, understanding check, then sign-off.

**Parked (Garret, 2026-09-24):**
- **Sprite orientation:** heads point outward, so the bottom mount is upside down. Parked for the Phase 6 art pass; hand-drawn art may change the answer.
- **Placeholder text:** all English text is Claude's draft or Garret's placeholder, not approved copy. That covers everything in `localization/strings.csv`: menu title/buttons, Settings/Controls labels, HUD labels ("Crank!", "Send wave", "Clear latched"), tab titles, upgrade names and descriptions, "Sell {0}", "Needs an empty slot", "Requires {0}". The 8 non-English columns are **machine-translation drafts**. Garret approves final copy before shipping, not before this milestone.

Art: Kenney packs are downloaded in `../kenney_assets/` (memo I); only used files are copied in (see `assets/PROVENANCE.md`).

**Fail rule (TEMPORARY):** the health stall only (OVERLOAD_CLEAR was removed in Step 9). Direction: **idle first, pressure when pushing** / Package A. The real fail state is still DECISION PENDING in the GDD.

## Step 11 wrap-up playtest (2026-09-24)
- Functionally everything works. Liked: crank, latching, Auto waves.
- Fixed the same day: Leaf clicks lacked feedback (now a crisper sound, click ring, squash);
  waves every 10 s (was 20); idle too slow vs clicking (base 60°/s, boost cap +40%);
  unlimited Send wave (now blocked above 30 live enemies); wanted two Wolves and to sell
  combat mounts (done for Wolves, GDD v1.11).
- Later: sound taste and background carousel music (Phase 6); Click Damage and Wolf tuning
  once Sticks and Rocks exist.
- **Jitter: solved.** Cause was Garret's setup: the MSI monitor is wired to the Radeon 780M
  while Godot rendered on the RTX 4070 (every frame copied between GPUs), and the monitor
  ran at 60 Hz. Fix: MSI at 100 Hz, and Windows Graphics → Godot → Power saving (780M).
  The laptop screen was fine all along. Code-side improvements kept: mount mipmaps, 2D MSAA
  4x + anti-aliased circles, exclusive fullscreen. Phase 6: offer Borderless as well, and a
  tip for laptop + external monitor players.

## Garret's playtest after the pacing pass (historical; pacing reassessed in Step 11)
- Fun; he bought all 4 booths. Still "a tad slow", but hold off retuning until enemies exist.
- Base speed feels too slow when idling. Fine for now (it encourages clicking); revisit after Leaves.
- Idea: an auto-clicker style option to hold boost while fighting (see NOTES).
- Residual jitter is minor and best on the laptop's 120 Hz screen. (Solved in Step 11: see above.)

## How to work with Garret (what's worked)
- He likes decisions asked one at a time as multiple-choice questions (AskUserQuestion), with a recommended option.
- Plan first, build after approval. He's fine with Claude drafting scenes; he tweaks in the editor.
- Verify visually: render frames with `--write-movie` (a window flashes briefly) and read the PNG.
- Codex for second opinions: read-only `codex exec` with docs pasted in (see CLAUDE.md). Save useful memos here.

## What's in this folder
| File | What it is |
|---|---|
| `step2_plan.md` | Step 2 plan (done) |
| `step3_plan.md` | Step 3 plan (done) |
| `step6_8_plan.md` | Steps 6–8 plan: Leaf, latch/stall, waves (done) |
| `step9_plan.md` | Step 9 plan: Wolf + health/stall tuning (done) |
| `step10_plan.md` | Step 10 plan: Mounts tab, slots, Horses, selling, first sprites (done) |
| `step10b_plan.md` | Step 10b: wave controls: Send wave, early bonus, Auto waves, Emergency Clear (done) |
| `step11_plan.md` | Step 11: Phase 2 wrap-up and sign-off checklist (in progress) |
| `codex_memo_a_sweep_booth.md` | Codex: booth pass counting and Wolf sweep math (Steps 4 and 9) |
| `codex_memo_b_input_layout.md` | Codex: click routing, HUD and scene trees, `.tscn` format (Steps 2, 3, 6) |
| `codex_memo_c_state_speed.md` | Codex: GameState API, speed model, Gold/sec, stall, purchases (Steps 2–7, 10) |
| `codex_memo_d_economy.md` | Codex: idle-game stacking, starting prices |
| `codex_memo_e_playtest_feedback.md` | Codex: first-playtest feedback (Boost button, shop, booths/Horses) |
| `codex_memo_f_jitter.md` | Codex: residual jitter diagnosis and 5-minute checklist |
| `codex_memo_g_fail_state.md` | Codex: is health needed? Fail-state options, idle/offline fit |
| `codex_memo_h_health_offline.md` | Codex: keeping health: stall timing math, drag curves, crank meter, offline packages |
| `codex_memo_i_kenney_assets.md` | Codex: which Kenney packs to use (animals, UI, foliage, fonts, icons) |
| `codex_memo_j_backgrounds.md` | Codex: play-field vs menu backgrounds (top-down tanks terrain; side-view fall scene for the menu) |
| `reference_hud_format.tscn.txt` | The exact `.tscn` text Godot 4.7.2 writes for a HUD, generated by Godot itself |

The memos are **input, not decisions.** Each step plan lists what it takes from them. Anything that needs your call is under "Questions" in that step's plan.

## How the memos fit together (reconciled)
- **Simulation order:** Game's `_physics_process` is the single driver. It calls `GameState.advance_simulation(delta)`, then `Carousel.advance_rotation(delta, speed)`. Carousel emits `rotation_advanced(previous_angle, delta_angle)`, which mounts use for booth passes and sweeps. (Memo A had Carousel drive itself and memo C had Game drive; this combines them so the order is explicit and there's a single rotation signal.)
- **Clicks:** a central router using nearest-enemy-by-distance (memo B). Memo A's carousel `HitZone` Area2D isn't needed.
- **Enemies:** `Area2D` root on an `EnemyHurtbox` physics layer, with separate `click_radius` and `hitbox_radius` fields added to `EnemyData` (memos A and B agree).
- **Prices:** Wolf's cost moves from `MountData.unlock_cost_gold` into its `UpgradeData` (memo C). That happens at Step 10.

## Decided 2026-09-23 (Garret)
- Spin upgrades **add up** (+20% then +30% = +50%). Pick whatever reads most intuitively in the UI.
- Boost: +10% per click, cap +50%, fades over 2 s. Base speed 45°/s. All tunable.
- Wolf damage per hit is **fixed** (frequency only), like booth Gold. GDD updated.
- Zero health with nothing latched → refill right away.
- Stopped Wolf deals no damage; placing a Wolf on an enemy gives no free hit.
- Overlapping enemies: the one nearest the click takes it.

## Decided 2026-09-24 (Garret)
- Build Steps 6, 7, 8 together (three commits).
- Click Damage: base 1, +0.5 per level, 10 levels, 25 Gold first level (×1.5).
- Leaf: 2 Gold per kill, 1 damage/sec latched, health bar hidden until hit.
- Waves: first at 10 s, then every 20 s; 3–5 Leaves clustered from one direction.
- TEMPORARY stall refills to 25% once all latches clear.
- After Codex's memo G: build both fail rules, switchable, and compare in playtest.
- Core feel: idle first, pressure when pushing.

## Decided 2026-09-24, after the Steps 6-8 playtest (Garret; memos G and H)
- **Keep health; HEALTH_STALL is the rule.** OVERLOAD_CLEAR stays switchable for now but isn't the direction.
- **Direction: Package A, "safe farm, risky push"** (memo H §4). A stall costs the current attempt (boss or pushed tier) and earning time. Gold and unlocks are never lost. Offline: no fights, booth-only income, return to a healthy carousel. Still TEMPORARY in code; the GDD fail state stays DECISION PENDING until Garret updates it.
- **Build with the Wolf (Step 9):**
  - Softer drag curve: speed x 1 / (1 + drag). Boost always helps; only a stall fully stops the carousel.
  - Regen when clear: about 2 health/s after the rim has been latch-free for 2 s.
  - Leaf damage 0.5/s (was 1).
  - 2 s latch grace: no damage for a new latch's first 2 s (drag applies right away).
  - Crank it back: at 0 health, Boost fills a restart meter (about 10 presses, or hold 4 s). A crank restart gives 15% health with Leaves still attached; clearing every latch still gives 25%.
  - Safety net: 60 s stalled, then enemies are cleared (no Gold) and the carousel restarts at 25%; waves keep coming.
- Garret's playtest: stalls came too fast (no time to react), and he wants Boost to still move the carousel with many Leaves attached. He liked that only a little health comes back.

## Design questions collected for later steps (originally asked; answers above)
- **Step 4:** fixed booth payout confirmed. Gold/sec uses a 10-second window that starts at 0 and fills up (memo C §5).
- **Step 6:** when enemies overlap, the one nearest the click wins (memo B).
- **Step 7:** if health hits 0 with nothing latched, it refills immediately (memo C §6). OK?
- **Step 9:** the GDD says faster spin = harder Wolf hits, but there's no formula yet. Needs your call before Step 9.
- **Step 9:** a stopped Wolf deals no damage, and placing a Wolf on top of an enemy doesn't give a free hit (memo A §6).
- **Step 10:** Click Damage 1 amount and upgrade prices: your numbers.
