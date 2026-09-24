# Phase 2 · Step 3 Plan: Spin + Click Boost
**Status:** DRAFT, waiting on Garret's approval (after Step 2 is done).
**Inputs:** PHASE_2_GOALS.md Step 3, GDD v1.4, `codex_memo_c_state_speed.md` §3–4, `codex_memo_b_input_layout.md` §1.

---

## Goal
The carousel spins at a base speed. Clicking the play area (not the HUD) gives a stacking speed boost that fades back to base, and the speed feels the same at any frame rate.

## 1. Speed model (one formula, one place)
```
effective speed = base × spin_upgrade_multiplier × (1 + click_boost) × max(0, 1 − total_drag)
                  (0 while the TEMPORARY stall is active: Step 7)
```
- **Units:** you tune in **degrees/second** (`base_spin_speed_deg_s` in `run_config.tres`); code runs in radians/second, which is what Godot's `rotation` uses.
- **Upgrade multiplier** is 1.0 until Step 5. **Drag** is 0 until Step 7. Both are built into the formula now, so later steps only add their inputs.
- **Drag is stored unclamped** (1.10 stays 1.10). Only the speed factor stops at 0, so removing one Leaf from a 1.10 total still leaves the carousel stopped, as it should.
- There's no separate writable "spin speed" variable anywhere; it's always calculated.

## 2. Click boost (needs your OK: see "Questions")
- Each play-area click adds `click_boost_increment` (proposed 0.10 = +10%), capped at `click_boost_cap` (proposed 0.50 = +50%).
- After the **latest** click, the current boost fades linearly to 0 over `click_boost_decay_seconds` (proposed 2.0 s). A small boost and a capped boost both end about 2 s after your last click, and clicking at the cap refreshes the timer.
- It's frame-rate independent: the boost is computed from elapsed time, so one 1-second step equals sixty 1/60-second steps (a test checks this).

## 3. Who moves what, in what order
Game drives the simulation from one place, so nothing competes:
```gdscript
# game.gd
func _physics_process(delta: float) -> void:
	GameState.advance_simulation(delta)                                   # boost decay (later: income, latch damage)
	_carousel.advance_rotation(delta, GameState.get_effective_spin_speed_rad_s())
```
Carousel also keeps an **unwrapped travelled angle** (it never wraps at 360°). Step 4's booth-pass counting and Step 9's Wolf sweep depend on it.

## 4. Clicks: `ClickLayer` with `click_router.gd`
- One central `_unhandled_input()` handler. Godot gives UI the first chance at every click, so clicks on the stats or shop panels never reach it; this relies on Step 2's STOP/IGNORE setup.
- Left-button presses only; releases, right-clicks, and the wheel are ignored.
- In Step 3 every play-area click goes to `play_area_click_requested` → `GameState.add_click_boost()`. The enemy path (nearest enemy within its click radius wins) and the Gold burst arrive in Steps 4 and 6; the router has a spot for them.
- The click position is converted to world coordinates with the canvas transform, so it stays correct if the window is resized.

## 5. New API (GameState)
```gdscript
signal spin_speed_changed(speed_rad_s: float)
func advance_simulation(delta: float) -> void
func add_click_boost() -> void
func get_click_boost() -> float
func get_spin_upgrade_multiplier() -> float   # 1.0 for now
func get_total_drag() -> float                # 0.0 for now
func get_effective_spin_speed_rad_s() -> float
```
New `RunConfig` fields: `base_spin_speed_deg_s`, `click_boost_increment`, `click_boost_cap`, `click_boost_decay_seconds`.

## 6. Tests
- **Formula:** deg→rad conversion is correct; each factor applies; drag of 1.0 and 1.25 → speed 0; drag stays 1.25 (unclamped)
- **Boost:** one click = increment; three clicks cap at 0.5; half-way through the decay = half the boost; after the decay = 0; clicking during decay adds to what's left; clicking at the cap refreshes
- **Frame-rate independence:** one 1.0 s step = sixty 1/60 s steps (approximately equal)
- **Router:** a play-area click → one boost request; a right-click or a release → nothing
- **Integration** (headless SubViewport, clicks injected): clicking the Gold label or empty shop space → no boost; clicking the spacer → one boost. This proves the HUD blocks clicks properly.

## 7. Your steps
- F6 on Game: it spins; click the empty area, it speeds up and settles back.
- Tune `base_spin_speed_deg_s`, increment, cap, and decay in `run_config.tres` until it feels right.

## Done when
It spins smoothly. Clicking speeds it up and it settles back, while clicking the HUD does nothing to it. Tests pass.

## Questions for Garret (from Codex's memo; short answers are fine)
1. **Spin upgrades add up** (Spin 1 + Spin 2 = +50%, not ×1.2×1.3 = +56%)? Codex recommends adding; it's easier to reason about.
2. **Boost numbers** to start: +10% per click, cap +50%, fades over 2 s after your last click?
3. **Starting base speed:** about 45°/s (one turn every 8 s) as a first guess, tuned by feel?
