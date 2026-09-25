# Idle Carousel

An incremental/idle game where a spinning carousel is both your engine and your weapon. Built in Godot 4.7 for Steam.

## Where things live

**Start here each session:** `IDLE_CAROUSEL_NOTES.md` → "Next Concrete Step", then the current phase's `planning/phaseN/README.md`.

| Doc | What it's for | Changes |
|---|---|---|
| `IDLE_CAROUSEL_GDD.md` | Design source of truth: what the game is. DECISION PENDING items live here. | When Garret decides something |
| `IDLE_CAROUSEL_ROADMAP.md` | Phases 1–7, checkboxes, who does what, launch timeline | When a phase's scope changes or items finish |
| `IDLE_CAROUSEL_NOTES.md` | Next Concrete Step, open to-dos, balance notes, ideas, known issues | Every session |
| `completed_phases/` | Finished phase checklists (Phase 1, Phase 2; history). Phase 3 keeps its checklist in `planning/phase3/` | Rarely |
| `planning/phaseN/README.md` | **Current phase status:** decisions, step list, open questions, which memos matter | Every session in that phase |
| `planning/phaseN/stepX_plan.md` | Approved plan for one step | Before building the step |
| `planning/phaseN/codex_memo_*.md`, `claude_*.md` | Research and second opinions. **Input, not decisions**; kept as written | Never (add a new memo instead) |
| `CLAUDE.md` / `AGENTS.md` | Rules for Claude Code / Codex: engine, architecture, workflow, Codex usage | When a rule changes |
| `assets/PROVENANCE.md` | Source and license of every asset file | Every new asset |

## Checks
Run `tools/check.sh` (Windows: `tools\check.bat`). It compiles every script, loads every scene, and runs the GdUnit4 tests.
