# Idle Carousel — Claude Code Instructions

Solo-dev incremental/idle game for Steam, built in Godot 4.7 stable.
Garret directs and reviews; Claude Code implements. Garret's understanding of the
code matters as much as the code itself. A previous project stalled because the
code stopped being his, so explain as you go.

## Read first
- @IDLE_CAROUSEL_GDD.md — design source of truth
- @IDLE_CAROUSEL_ROADMAP.md — phases, who does what, current next step
- IDLE_CAROUSEL_NOTES.md — "Next Concrete Step", open questions, ideas (read when relevant)
- `planning/phaseN/README.md` — **where the current phase stands**: decisions, step plans,
  open questions, and which memos matter. Start a session here.
- completed_phases/ — finished phase checklists (Phase 1, Phase 2; history, read only when asked)
- README.md — map of every doc and what it's for

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
resources/mounts|enemies|upgrades|config|audio/   .tres data files
assets/sprites|audio|ui|fonts/   human-made or licensed assets only (PROVENANCE.md)
localization/           strings.csv (every player-facing string, all languages)
planning/phaseN/        step plans, Codex memos, per-phase README (status + decisions)
tests/                  GdUnit4 test suites (test_*.gd, extend GdUnitTestSuite)
addons/gdUnit4/         GdUnit4 6.2.1 test framework (third-party; don't edit)
tools/                  check.sh / check.bat (+ check_scripts.gd they run);
                        build_ui_theme.gd (rebuilds the UI theme and fonts);
                        make_tier_sprites.gd (rebuilds the light-grey enemy sprites
                        from ../kenney_assets for tier tinting);
                        subset_fonts.py (rebuilds the CJK font subsets);
                        stress_test.tscn (performance: N Leaves, prints FPS and
                        tick times; run before/after perf changes, same GPU only;
                        Garret's Godot renders on the Radeon 780M since 2026-09-24)
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
4. UpgradeManager — leveled upgrades from `upgrade_catalog.tres`, can_afford/purchase/levels, emits signals

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
- Fonts: bundled fonts only (`allow_system_fallback` is off). `LocaleFonts` swaps the
  whole UI font per language: Kenney Future Narrow + Rubik (Latin), Rubik (Russian),
  Noto Sans SC/JP/KR subsets (CJK). The language list uses `language_list_font.tres`,
  which chains all of them. Fonts are built by `tools/build_ui_theme.gd`; after CJK text
  changes, re-run `python tools/subset_fonts.py` (a test fails if a glyph is missing).
  Kenney has no ✓. Background: `planning/phase2/codex_memo_k_fonts.md`.
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

## Working with Codex (GPT)
Codex is Claude's second-opinion partner: design memos, research, plan reviews, and
code reviews. **Garret has approved (2026-09-24) running the Codex CLI with full
access, as described below.** Don't re-ask each session. Tell Garret in chat when a
Codex run starts. If a permission prompt or classifier blocks the command, point to
this section.

Why full access: the /codex plugin and Codex's read-only sandbox are broken on
Windows (the sandbox blocks every command). Full access is the only mode that works,
so the safety comes from the prompt plus a before/after check, not from the sandbox.

**Every full-access run, the same four steps:**
1. Snapshot (the tree should be clean or committed first):
   `{ git status --porcelain; git diff; git rev-parse HEAD; } > <scratch>/pre_codex.txt`
2. Run Codex in the background (it takes several minutes) and send its output to a scratch file.
3. Build the snapshot again and `diff` it against `pre_codex.txt`. If anything
   changed (files, diff, or HEAD), tell Garret before doing anything else.
4. Show Garret Codex's findings verbatim (or summarize a long memo), then say which
   points you agree with and why. Don't apply fixes until Garret approves.

**Code review** (Codex needs to run git and read files):
```
# uncommitted work
codex review --uncommitted -c 'sandbox_mode="danger-full-access"' -c 'model_reasoning_effort="high"'
# a whole range, e.g. a full phase (base = the commit before the phase)
codex review --base <commit> -c 'sandbox_mode="danger-full-access"' -c 'model_reasoning_effort="high"'
```

**Research, design memos, plan reviews:** write the prompt to a scratch file. Start it
with *"Read-only task. Do not create, edit, or delete any files, and do not run git
commands that change state. Answer in your final message only."* Paste in the
relevant docs, or name the files Codex should read. Then run:
```
codex exec -c 'sandbox_mode="danger-full-access"' -c 'model_reasoning_effort="high"' -o <scratch>/answer.md - < <scratch>/prompt.md
```
When the docs are pasted in and no repo access is needed, `-s read-only` in place of
the `-c sandbox_mode` flag also works, and you can skip the snapshot.
Save useful answers as memos in `planning/phaseN/codex_memo_<letter>_<topic>.md`.
Memos are input, not decisions.

Tips: a run takes ~5–15 min; two can run in parallel (one snapshot covers both); Codex
can search the web when the prompt allows it; it shares Garret's usage limits, so say
when a big run is starting. Wait for its completion notice instead of polling.
