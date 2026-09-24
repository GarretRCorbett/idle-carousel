# Idle Carousel — Claude Code Instructions

Solo-dev incremental/idle game for Steam, built in Godot 4.7 stable.
Garret directs and reviews; Claude Code implements. Garret's understanding of the
code matters as much as the code itself. A previous project stalled because the
code stopped being his, so explain as you go.

## Read first
- @IDLE_CAROUSEL_GDD.md — design source of truth
- @IDLE_CAROUSEL_ROADMAP.md — phases, who does what, current next step
- IDLE_CAROUSEL_NOTES.md — open questions and balance notes (read when relevant)
- PHASE_1_GOALS.md — Phase 1 detail (read only while Phase 1 is open)

## Engine
- Godot 4.7 stable. Godot 4 APIs only; never Godot 3 syntax (no `yield`, `onready var`,
  `export var`, `KinematicBody2D`, `instance()`, `connect("signal", self, "method")`).
- Use `@export`, `@onready`, `await`, `instantiate()`, `signal.connect(callable)`.
- Static typing everywhere (`var speed: float = 1.0`, typed function signatures).
- `class_name` on all non-autoload scripts. Never on autoload scripts (name collision).
- Commit `.uid` and `.import` files. Never commit `.godot/` or export builds.

## Project layout
```
scenes/                 .tscn files (built by hand in the editor)
scripts/autoloads/      GameState, SaveManager, AudioManager, UpgradeManager
scripts/                gameplay scripts, Resource classes (mount_data.gd, etc.)
resources/mounts|enemies|upgrades/   .tres data files
assets/sprites|audio/   human-made or licensed assets only
tools/                  check.sh / check.bat (+ check_scripts.gd they run)
```
File names snake_case; class names PascalCase; scenes PascalCase.tscn.

## Autoloads (load order matters)
1. GameState — single source of truth for runtime data; written only through its functions
2. SaveManager — file I/O, offline progress. Save file: `user://save_data.json`
3. AudioManager — persistent music/SFX players
4. UpgradeManager — upgrade tree, can_afford/purchase/is_purchased, emits signals

## Architecture rules (from the GDD)
- Enemies and projectiles live in world-space layers (EnemyLayer, ProjectileLayer),
  never as children of Carousel. Only mounts and slots rotate with the carousel.
  Use global_position / global_rotation when crossing that boundary.
- Sweep detection uses physics space-state ray queries (avoids tunneling at high spin).
- Signals for coupling between systems. HUD listens; gameplay never references HUD.
- No magic numbers: every tunable is `@export` or lives in a `.tres` Resource.
- Timer nodes for recurring events (waves, auto-save).
- `call_deferred()` when changing scenes from physics callbacks.
- Offline progress uses `Time.get_unix_time_from_system()` with an 8-hour clamp.
- Gold is the only currency.

## Workflow
- Plan mode first for any feature bigger than a small tweak. Wait for approval.
- Don't create or edit `.tscn` files unless Garret explicitly asks. When a script needs
  scene nodes, end with a "Manual steps in Godot" list: node type, name, parent,
  and properties to set.
- Run `tools/check.sh` (Windows: `tools\check.bat`) after every change. Don't report
  done until it passes.
- One feature per commit. Commit messages explain what changed and why.
- Don't push unless asked.
- After finishing a feature, offer a short walkthrough of the diff: what each piece
  does and why it's built that way.
- Never resolve items marked DECISION PENDING in the GDD. Flag them and stop.
- If the GDD is ambiguous, ask instead of guessing.

## Hard limits
- No AI-generated art, audio, voice, or player-facing text (UI copy, store page,
  dialogue). Placeholder shapes drawn in code are fine.
- Don't add features outside the GDD's v1.0 scope. Put ideas in IDLE_CAROUSEL_NOTES.md.

## Second opinions from Codex (GPT)
The /codex plugin's review is broken on Windows right now (its read-only sandbox
blocks all commands). Call the Codex CLI directly instead, and only when Garret
asks for a Codex review or a second opinion.

Full access is the only sandbox mode that works on Windows, so check afterward that
Codex changed nothing. Before running it, save a snapshot with
`git status --porcelain > /tmp/pre_codex.txt; git diff >> /tmp/pre_codex.txt`.
```
codex review --uncommitted -c 'sandbox_mode="danger-full-access"' -c 'model_reasoning_effort="high"'
```
Afterward, rebuild the same snapshot and compare it to /tmp/pre_codex.txt. If anything
changed, tell Garret before doing anything else.
Show Garret Codex's findings verbatim, then say which ones you agree with and why.
Don't apply fixes from a Codex review until Garret approves.
