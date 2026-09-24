# Phase 2 · Step 2 Plan: GameState Foundation + Game Scene Skeleton
**Status:** DRAFT, waiting on Garret's approval. Nothing here is built yet.
**Inputs:** PHASE_2_GOALS.md Step 2, GDD v1.4, `codex_memo_b_input_layout.md`, `codex_memo_c_state_speed.md`, `reference_hud_format.tscn.txt`.

---

## Goal
Running `Game.tscn` shows a placeholder carousel in the middle of the screen and the HUD frame: stats on the left, an empty shop panel on the right. GameState stores Gold and health, changes them only through functions, and resets cleanly. No spinning yet; that's Step 3.

## 1. Where tunables live
- **`RunConfig` Resource** at `resources/config/run_config.tres` (Codex called it CarouselConfig; "Run" fits better because it also holds Gold and click values). This is where you tune in the Inspector.
- Step 2 adds only `starting_gold` and `max_health`. Later steps add their own fields: spin and boost in Step 3, click Gold and income window in Step 4, click damage in Step 6, recovery fraction in Step 7.
- GameState `preload`s it. `reset_run(config_override)` lets tests pass their own config, so a test never edits the real `.tres`.
- Placeholder visuals (radius, GDD palette colors) are `@export` values on the Carousel and TicketBooth nodes.

## 2. GameState API added in Step 2
All state is private (`_gold`, `_health`); read it through getters and change it through functions only.
```gdscript
signal gold_changed(balance: float, delta: float)
signal health_changed(current: float, maximum: float)
signal run_reset

func reset_run(config_override: RunConfig = null) -> void
func get_gold() -> float
func add_gold(amount: float) -> void      # finite and > 0 only; this is "earned" Gold
func can_afford(cost: float) -> bool
func spend_gold(cost: float) -> bool      # all-or-nothing; rejects negative or non-finite amounts
func get_health() -> float
func get_max_health() -> float
func damage_carousel(amount: float) -> void   # clamps at 0 (the stall itself comes in Step 7)
```
- `reset_run()` sets **all** state first, then emits `run_reset` followed by the current values, so listeners never see half-reset data.
- The HUD reads current values when it starts, then listens to the signals.
- `add_gold` and `spend_gold` validate their input: no NaN, no negatives, and spending can never produce a negative balance.

## 3. Scene: `Game.tscn`
It's written in Godot 4.7.2's exact text format (see the reference file), without `uid=` or `unique_id=`. Nodes that later steps fill in are included now as empty placeholders, so the tree doesn't need restructuring.
```
Game (Node2D)                               game.gd: reset_run() on start; recenters World on resize
├── World (Node2D)                          centered on the viewport (640, 360)
│   ├── Carousel (Node2D)                   carousel.gd (rotation arrives in Step 3)
│   │   ├── Visual (Node2D)                 placeholder base, rim, and hub drawn in _draw()
│   │   └── MountSlots (Node2D)
│   │       └── Slot1..Slot6 (Marker2D)     capacity markers; mounts are spaced by count, not slot
│   ├── TicketBooth (Node2D)                fixed above the carousel
│   │   └── Visual (Node2D)                 placeholder red rectangle
│   └── EnemyLayer (Node2D)                 world space; never under Carousel
└── HUD (CanvasLayer)                       hud.gd
    └── HUDRoot (Control)                   full rect · mouse IGNORE
        └── ScreenMargin (MarginContainer)  full rect · 16px margins · IGNORE
            └── Columns (HBoxContainer)     separation 24 · IGNORE
                ├── LeftColumn (VBoxContainer)          min width 220 · IGNORE
                │   └── StatsPanel (PanelContainer)     content height · **STOP**
                │       └── StatsMargin → StatsVBox     12px margins, 8 separation · IGNORE
                │           ├── GoldLabel (Label)
                │           ├── GoldPerSecLabel (Label)
                │           ├── HealthBar (ProgressBar) min height 20 · no percentage text
                │           └── WaveCountdownLabel (Label)
                ├── WorldSpacer (Control)               expand fill · IGNORE
                └── ShopPanel (PanelContainer)          min width 260 · **STOP**
                    └── ShopMargin → UpgradeRows (VBox) rows arrive in Step 5
```
**Why IGNORE vs STOP matters:** the frame containers cover the whole screen, so they must IGNORE the mouse or every click on the carousel silently disappears. The stats and shop panels STOP clicks, so clicking the Gold label or empty shop space never counts as a carousel click. A health-bar or Gold-burst click leaking through to the game would be a real bug.

`ProjectileLayer`, `ClickLayer`, and `WaveManager` are added in the steps that use them. Label text is left empty with `# TODO(Garret): text` until you write the wording; the scripts fill in the numbers.

## 4. Files
| New / changed | What |
|---|---|
| `scripts/run_config.gd` | `class_name RunConfig extends Resource`, with validation |
| `resources/config/run_config.tres` | starting Gold 0, max health 100 (GDD value) |
| `scripts/autoloads/game_state.gd` | API above |
| `scripts/game.gd`, `scripts/carousel.gd`, `scripts/ticket_booth.gd`, `scripts/hud.gd` | `class_name` on each |
| `scenes/Game.tscn` | replaces the empty placeholder |
| `tests/test_game_state.gd` | tests below |
| `scripts/mount_data.gd` | fix the stale comment: booth Gold is **not** scaled by speed (GDD v1.4) |

## 5. Tests (`before_test()` calls `reset_run(test_config)`, `after_test()` calls `reset_run()`)
- Add 10 → Gold 10; `gold_changed(10, 10)` emitted once
- Add 0, −5, NaN → no change, no signal
- Spend 8 of 10 → true, Gold 2; spend 3 of 2 → false, Gold 2, no signal; spend exactly the balance → true, Gold 0
- Damage 150 from 100 → 0, never negative; `health_changed` emitted
- `reset_run()` restores config values and emits `run_reset` **after** the state is complete (a listener checks this)
- The production `run_config.tres` loads and validates

## 6. Your steps in the editor after it's built
1. Close `Game.tscn` if it's open, since I'm replacing the file. Reopen it and save once so Godot assigns IDs.
2. Press F6 on Game. You should see the carousel in the middle, the stats panel at top left, and the empty shop on the right.
3. Tweak margins, sizes, or colors to taste; later steps keep your changes.

## Done when
`tools/check.sh` passes with the new tests, F6 on Game shows the layout with no errors, and GameState resets cleanly.
