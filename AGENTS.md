# Agent Instructions

This repo's full rules live in CLAUDE.md. Read it and follow every rule there.
They apply to any coding agent (Codex included), not just Claude Code.

Key points, in case you read nothing else:
- Godot 4.7 stable, Godot 4 APIs only, static typing.
- Don't create or edit `.tscn` scene files unless explicitly asked.
- Never resolve items marked DECISION PENDING in IDLE_CAROUSEL_GDD.md.
- No magic numbers: tunables go in `@export` vars or `.tres` Resources.
- Run tools/check.sh (Windows: tools\check.bat) after every change.
- No AI-generated art, audio, or player-facing text.
- When reviewing, focus on bugs, Godot 3 vs 4 API mistakes, and GDD architecture
  violations (e.g., enemies parented under Carousel).
