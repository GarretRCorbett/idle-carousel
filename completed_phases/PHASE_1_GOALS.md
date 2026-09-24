# 🎯 Idle Carousel — Phase 1 Goals (Project Setup)
### Version 1.4 — AI-First Build

> Finish the foundation and get Claude Code working on the repo with clear rules.
> Steps 1–5 are already done. Steps 6–12 are one evening's work.
> Estimated time: 1 session (~2 hours)

---

## Changelog
- **v1.4** — Switched to an AI-first build. Claude Code now writes scripts and data from Phase 1 onward (previously it started in Phase 3). Added the working model, guardrails, and CLAUDE.md rules. Fixed `.gitignore` (`.uid` and `.import` files must be committed in Godot 4.4+). Picked one save filename. Restructured the remaining steps around Claude Code.
- **v1.3** — Rewrite with tooling (CLAUDE.md, check scripts, settings.json) and DECISION PENDING blocks.
- **v1.2** — Removed Sparks; Gold only.

---

## The Working Model

**Garret = director and reviewer.** Decides what to build, reviews every plan, builds scene layouts in the editor, playtests, and owns every design decision.

**Claude Code = implementer.** Writes GDScript, Resource scripts, `.tres` data, tests, and tooling. Explains each change.

### Guardrails (why Carousel Crusade stalled, and how this time is different)
1. **Plan before build.** Any feature larger than a small tweak starts in plan mode. Garret reads and adjusts the plan before code is written.
2. **Small commits.** One feature or fix per commit, with a message covering *what changed and why*.
3. **Walkthrough before merge.** After each feature, ask Claude Code to walk through the diff. If Garret can't explain it back, it isn't done.
4. **Verify every change.** `tools/check.sh` (or `check.bat`) runs after every change. Once GdUnit4 is in, tests run too.
5. **Scenes in the editor.** Scene layout (`.tscn`) is built by hand in Godot. Claude Code writes the scripts those scenes use. Generated `.tscn` files are fragile, and building the node tree yourself is how you keep a mental model of the game.
6. **Design stays human.** Claude Code never resolves a DECISION PENDING item. It flags the question and stops.
7. **No AI art, audio, or player-facing text.** Code only.

---

## ✅ Steps 1–5 — Complete (not yet committed)

- [x] Step 1 — GitHub repo `idle-carousel` created
- [x] Step 2 — Godot 4.7 project configured (1280×720, `canvas_items`, default `keep` aspect)
- [x] Step 3 — Folder structure created
- [x] Step 4 — Four autoload shells created
- [x] Step 5 — Autoloads registered (**order needs fixing, see Step 6**)
- [x] `.gitignore` fixed (`.uid` and `.import` no longer excluded)
- [x] Tooling added: `CLAUDE.md`, `AGENTS.md`, `tools/check.sh`, `tools/check.bat`, `.claude/settings.json`

> Only the initial commit is on GitHub. Scripts, docs, and the settings above are local changes until Step 7.

---

## Step 6 — Open the project in Godot (10 min, by hand)

Open Godot 4.7 → Import → `idle-carousel/project.godot`. This does three things:

1. **Regenerates missing `.uid` files.** `project.godot` references the autoloads by UID, but the `.gd.uid` files next to the scripts are missing (they were gitignored before). Godot recreates them on scan. Check that `scripts/autoloads/` now has four `.gd.uid` files.
2. **Fix autoload order.** Project → Project Settings → Globals → Autoload. They're currently alphabetical (AudioManager first). Drag them into this order:
   `GameState → SaveManager → AudioManager → UpgradeManager`
   Autoloads initialize top to bottom, so anything that reads GameState has to come after it. If any row shows a broken path, remove it and re-add the script.
3. **Confirm a clean Output panel.** No red errors.

Then set the check script's Godot path once. In Git Bash:
```bash
export GODOT="/c/path/to/Godot_v4.7-stable_win64_console.exe"
bash tools/check.sh
```
Use the **_console** executable so output shows in the terminal. Expect `== PASS`. (Add the export line to `~/.bashrc` so it sticks.)

---

## Step 7 — First real commit + connect (10 min, by hand)

```bash
git add -A
git status   # confirm scripts/*.gd.uid and icon.svg.import are listed, .godot/ is not
git commit -m "Phase 1 setup: autoloads, docs, agent rules, check scripts, gitignore fix"
git push
```

- [ ] Grant the Claude GitHub app access to `idle-carousel`: github.com/settings/installations → **Claude** → Configure → add the repo
- [ ] Upload the current docs (this file, GDD, Notes, Roadmap) to the Claude project knowledge
- [ ] Open the `idle-carousel` folder in VS Code and start Claude Code there (not the parent folder)

---

## Step 8 — Review CLAUDE.md with Claude Code (10 min)

`CLAUDE.md` holds the engine, architecture, and workflow rules. `AGENTS.md` points Codex (and any other agent) at the same rules.

Prompt:
```
Read CLAUDE.md and summarize the rules back to me in 5 bullets. Then read the
GDD and tell me anything in CLAUDE.md that conflicts with it or is missing.
Don't change files yet.
```

This checks that Claude Code is picking up the file, and it gets you familiar with the rules.

**Optional — Codex plugin (5 min):** uses your ChatGPT plan for code reviews.
```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/reload-plugins
/codex:setup
```

---

## Step 9 — Resource scripts + data files (20 min, Claude Code)

Prompt:
```
Create the MountData and EnemyData Resource scripts in res://scripts/ as specified
in PHASE_1_GOALS.md Step 9. Then create the 6 mount and 3 enemy .tres files using
the placeholder values below, with stats based on the GDD's relative descriptions
(Leaf fast/low HP, Rock slow/high HP, etc.). Run the check script, then commit.
```

**Spec — MountData** (`class_name MountData`, extends Resource):
`mount_name`, `is_stationary`, `sweep_range`, `sweep_arc`, `base_damage`, `base_gold_bonus`, `unlock_cost_gold`, `placeholder_color`, `placeholder_points`, `placeholder_size`, `texture`

**Spec — EnemyData** (`class_name EnemyData`, extends Resource):
`enemy_name`, `move_speed`, `base_health`, `damage_per_second`, `latch_drag`, `gold_drop`, `placeholder_color`, `placeholder_points`, `placeholder_size`, `texture`

**Placeholder values:**

| File | Color | Points | Size | Notes |
|---|---|---|---|---|
| `mounts/horse.tres` | chestnut brown | 8 | 18 | stationary |
| `mounts/wolf.tres` | dark grey | 6 | 14 | |
| `mounts/turtle.tres` | olive green | 8 | 12 | stationary |
| `mounts/eagle.tres` | tan brown | 6 | 20 | long range |
| `mounts/lion.tres` | sandy gold | 8 | 20 | wide arc |
| `mounts/unicorn.tres` | white/silver | 8 | 18 | |
| `enemies/leaf.tres` | orange | 5 | 10 | gold_drop 1.0 |
| `enemies/stick.tres` | brown | 4 | 14 | gold_drop 3.0 |
| `enemies/rock.tres` | medium grey | 7 | 16 | gold_drop 8.0 |

**Your review:** Open two of the `.tres` files in the Inspector. Change a value, save, and look at the diff in git. That's the whole idea behind data-driven design: balance changes are data edits, not code edits.

---

## Step 10 — Placeholder scenes (5 min, by hand in the editor)

- [ ] `res://scenes/MainMenu.tscn` → root: Control
- [ ] `res://scenes/Game.tscn` → root: Node2D
- [ ] `res://scenes/GameOver.tscn` → root: CanvasLayer
- [ ] Project Settings → Application → Run → Main Scene: `MainMenu.tscn`
- [ ] Press F5. An empty window should open with no errors.

---

## Step 11 — Test harness (20 min, Claude Code, optional tonight)

- [ ] Read through `Randroids-Dojo/Godot-Claude-Skills` before installing anything
- [ ] Install via `/plugin marketplace add Randroids-Dojo/Godot-Claude-Skills`
- [ ] Prompt: `Set up GdUnit4 with one test that loads leaf.tres and asserts its gold_drop is 1.0. Add a headless test command to tools/check.sh.`

Tests are what let you trust code you didn't write line by line. Worth doing before Phase 2 gets going.

---

## Step 12 — Commit, walkthrough, and plan Phase 2 (15 min)

- [ ] Ask Claude Code: `Walk me through everything we changed tonight.`
- [ ] Confirm on GitHub: no `.godot/` folder or exports committed, and `.uid` files are present
- [ ] **Plan only, don't build:** In plan mode, ask for a Phase 2 plan (see `IDLE_CAROUSEL_ROADMAP.md`). Review it, adjust it, and save it for next session.
- [ ] Write the next concrete step at the top of `IDLE_CAROUSEL_NOTES.md`

---

## ✅ Phase 1 Complete When:

- [ ] Autoload order fixed; `.uid`/`.import` files committed
- [ ] Claude GitHub app has access to the repo
- [ ] Project knowledge updated to current docs
- [ ] CLAUDE.md reviewed with Claude Code
- [ ] MountData + EnemyData scripts created
- [ ] 6 mount and 3 enemy `.tres` files created
- [ ] 3 placeholder scenes created, main scene set, F5 runs clean
- [ ] `tools/check.sh` passes with GODOT set
- [ ] Walkthrough done: you can explain every file in the repo
- [ ] (Optional) GdUnit4 running with one passing test
- [ ] Phase 2 plan drafted and reviewed

**Then move to Phase 2: Core Loop.**