# Agent Instructions

This repo's full rules live in CLAUDE.md. Read it and follow every rule there.
They apply to any coding agent (Codex included), not just Claude Code.

Key points, in case you read nothing else:
- Godot 4.7 stable, Godot 4 APIs only, static typing.
- `.tscn` scene files: only as part of an approved plan, following CLAUDE.md's scene rules.
- Never resolve items marked DECISION PENDING in IDLE_CAROUSEL_GDD.md.
- No magic numbers: tunables go in `@export` vars or `.tres` Resources.
- Run tools/check.sh (Windows: tools\check.bat) after every change.
- No AI-generated art or audio. Player-facing text may be drafted, but Garret approves it
  (CLAUDE.md → Hard limits).
- When reviewing, focus on bugs, Godot 3 vs 4 API mistakes, and GDD architecture
  violations (e.g., enemies parented under Carousel).

## When Claude Code calls you (Codex)
Claude Code is the implementer; you're its second opinion (reviews, research, design
memos). It runs you with full access only because the Windows sandbox is broken, so:
- **Read-only unless the prompt explicitly says otherwise.** Don't create, edit, or
  delete files. Don't run git commands that change state (commit, checkout, reset,
  stash, branch), and don't run the game or tools that write files. Reading files,
  `git log`/`diff`/`show`, and searching are fine.
- Put everything in your final message. Claude saves it and snapshots the repo before
  and after to confirm nothing changed.
- Never ask for or process Nintendo-confidential material (SDKs, docs, certification
  requirements, APIs) unless Nintendo's agreements explicitly permit it
  (`planning/switch_release_plan.md`).
- Recommendations are input, not decisions: Garret decides. Flag DECISION PENDING
  items rather than resolving them.
- Full workflow (commands, snapshot check): CLAUDE.md → "Working with Codex (GPT)".

## Worktree tasks (style exploration, renders, experiments)
When the prompt says you're in a **worktree task**, you work in your own git worktree
(e.g. `../ic-codex`, branch `codex/<topic>`), never in `idle-carousel/`:
- You may create and edit files, run Godot (`$GODOT`, headless or `--write-movie`
  renders), run tools/check.bat, and commit **on your branch only**. Never push, merge,
  rebase, or touch `main` or other worktrees.
- Put renders in `planning/<phase>/<topic>/` in your worktree; explain them in a memo.
- No AI image/audio models. Draw with Godot code or Kenney CC0 assets only. Garret makes
  the design decisions; you build options and record what each is.
- Claude reviews your branch and merges only what Garret approves.
