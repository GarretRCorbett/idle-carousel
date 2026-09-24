# Idle Carousel — Claude Code Instructions

Solo-dev incremental/idle game for Steam, built in Godot 4.7 stable.
Garret directs and reviews; Claude Code implements. Garret's understanding of the
code matters as much as the code itself. A previous project stalled because the
code stopped being his, so explain as you go.

## Read first
- @IDLE_CAROUSEL_GDD.md — design source of truth
- @IDLE_CAROUSEL_ROADMAP.md — phases, who does what, current next step
- IDLE_CAROUSEL_NOTES.md — open questions and balance notes (read when relevant)
- PHASE_2_GOALS.md — current phase detail
- completed_phases/ — finished phase docs (history; read only when asked)

## Engine
- Godot 4.7 stable. Godot 4 APIs only; never Godot 3 syntax (no `yield`, `onready var`,
  `export var`, `KinematicBody2D`, `instance()`, `connect("signal", self, "method")`).
- Use `@export`, `@onready`, `await`, `instantiate()`, `signal.connect(callable)`.
- Static typing everywhere (`var speed: float = 1.0`, typed function signatures).
- `class_name` on all non-autoload scripts. Never on autoload scripts (name collision).
- Commit `.uid` and `.import` files. Never commit `.godot/` or export builds.

## Project layout
```
scenes/                 .tscn files (drafted by Claude Code, tweaked by Garret in the editor)
scripts/autoloads/      GameState, SaveManager, AudioManager, UpgradeManager
scripts/                gameplay scripts, Resource classes (mount_data.gd, etc.)
resources/mounts|enemies|upgrades/   .tres data files
assets/sprites|audio/   human-made or licensed assets only
tests/                  GdUnit4 test suites (test_*.gd, extend GdUnitTestSuite)
addons/gdUnit4/         GdUnit4 6.2.1 test framework (third-party; don't edit)
tools/                  check.sh / check.bat (+ check_scripts.gd they run);
                        build_ui_theme.gd (rebuilds assets/ui/game_theme.tres)
```

## Assets (Kenney, CC0)
- Downloaded packs live unmodified in `../kenney_assets/` (outside the repo; zips in `_zips/`).
  Download there first, unzip, then copy only the files the game uses into `assets/`.
- Log every copied file in `assets/PROVENANCE.md` (file, source pack/URL, original name,
  license, changes, date). Keep doing this for every new asset.
- UI look: edit `tools/build_ui_theme.gd` and re-run it; don't hand-edit `game_theme.tres`.
- Sounds: add files to `assets/audio/sfx/`, list them in `resources/audio/sound_bank.tres`,
  play with `AudioManager.play_sfx(&"id")`.
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
- Sweep detection uses angle math (RotationMath.sweep_passes), not per-frame overlap, so nothing
  tunnels at high spin. Garret chose this over physics ray queries in Step 9 (simpler, exact).
- Signals for coupling between systems. HUD listens; gameplay never references HUD.
- No magic numbers: every tunable is `@export` or lives in a `.tres` Resource.
- Timer nodes for recurring events (waves, auto-save).
- `call_deferred()` when changing scenes from physics callbacks.
- Offline progress uses `Time.get_unix_time_from_system()` with an 8-hour clamp.
- Gold is the only currency.
- Localization-ready: every player-facing string is a key in `localization/strings.csv`
  (`keys,en`). Scene text holds the key (auto-translated); code uses
  `tr(KEY).format([value])` with numbered placeholders `{0}` (named ones get mangled
  by pseudolocalization) and sets `auto_translate_mode = DISABLED` on nodes whose text
  it builds, so nothing is translated twice. Tab titles: pass the key to
  `set_tab_title()`. Numbers only through `NumberFormat.gold()` / `.decimal()`.
  Upgrade names/descriptions in `.tres` are keys too. `tests/test_localization.gd`
  fails if a scene or upgrade uses text that isn't a key.
- Plurals: when text depends on a count ("1 wave" / "3 waves"), use `tr_n(key, plural_key, n)`
  (Godot 4.6+ CSV supports plural rows) and never a hand-written `if n == 1`; many
  languages have more than two plural forms.
- Fonts: bundled fonts only (`allow_system_fallback` is off). The UI font is
  `assets/fonts/ui_font.tres` (Kenney Future Narrow + Rubik fallback for accents and
  Cyrillic). Kenney has no ✓, Polish/Turkish letters, or Cyrillic. Plan when a language
  is scheduled: swap the whole UI font per locale (Rubik for Polish/Turkish/Russian;
  Noto Sans SC/JP/KR, 9-17 MB each, for CJK; download only then). See
  `planning/phase2/codex_memo_k_fonts.md`.
- Pseudolocalization check: Project Settings → Advanced Settings on →
  Internationalization → Pseudolocalization → Use Pseudolocalization, run the game,
  look for plain English (missed) or cut-off text, then turn it off again.

## Workflow
- Plan mode first for any feature bigger than a small tweak. Wait for approval.
- Scenes: Claude Code drafts `.tscn` layouts as part of an approved plan; Garret
  reviews them in the editor and tweaks. Rules for scene files:
  - Show the planned node tree (types, names, parents, key properties) in the plan
    before writing the file.
  - UI uses containers (MarginContainer, VBox/HBox, anchors/presets, size flags)
    instead of hand-placed positions, so Garret's tweaks don't break the layout.
  - Re-read a `.tscn` right before editing it; Garret may have changed it in the
    editor. Keep his changes. Ask him to save and close the scene in Godot first.
  - Omit `uid=` and `unique_id=` on new files and nodes; Godot assigns them on save.
  - After writing, run the check and ask Garret to open the scene and save it once.
  - When a change is small or feel-related (positions, colors, tuning), give Garret
    the steps instead of editing the file.
- Run `tools/check.sh` (Windows: `tools\check.bat`) after every change. Don't report
  done until it passes. It compiles every script, loads every scene, and runs the tests.
- New logic comes with tests in `tests/` (math, money, counting, state changes). Keep
  test fixture numbers in the test; real balance values stay in exports or `.tres`.
- One feature per commit. Commit messages explain what changed and why.
- Don't push unless asked.
- After finishing a feature, offer a short walkthrough of the diff: what each piece
  does and why it's built that way.
- Never resolve items marked DECISION PENDING in the GDD. Flag them and stop.
- If the GDD is ambiguous, ask instead of guessing.

## Hard limits
- No AI-generated art, audio, or voice. Placeholder shapes drawn in code are fine.
- Text (Garret, 2026-09-24): Claude may draft player-facing text (UI labels, tooltips,
  upgrade names and descriptions) and machine-translation drafts. Garret reviews and
  approves all of it before it ships. Store page copy, trailer text, and credits stay
  Garret's.
- Don't add features outside the GDD's v1.0 scope. Put ideas in IDLE_CAROUSEL_NOTES.md.

## Second opinions from Codex (GPT)
The /codex plugin's review is broken on Windows right now (its read-only sandbox
blocks all commands). Call the Codex CLI directly instead, and only when Garret
asks for a Codex review or a second opinion.

**Ideas and planning (no code access needed):** put the relevant docs straight into
the prompt so Codex never has to run a command, and keep it read-only:
```
codex exec -s read-only -o <scratch>/answer.md - < <scratch>/prompt.md
```
Summarize the answer for Garret, then say what you agree and disagree with.

**Code reviews:** Codex needs to run commands, so it needs full access.

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
