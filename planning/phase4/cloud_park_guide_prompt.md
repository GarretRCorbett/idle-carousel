# Prompt for a Claude Code cloud session: build the Park Guide

Copy everything below the line into a new Claude Code session on the web (claude.ai/code) with this
repo (GarretRCorbett/idle-carousel).

---

You're working on Idle Carousel, a Godot 4.7 idle game. Please build **Phase 4 Step 8, the Park
Guide**, on a new branch `claude/park-guide`, then open a pull request to `main`. Don't push to `main`.

1. **Read first:** `CLAUDE.md` (all of it: engine rules, localization, controller support, hard
   limits), then `planning/phase4/README.md` → "Step 8 plan: Park Guide". That plan is approved by
   Garret; follow it. If something in it is unclear or impossible, stop and write the question in
   the PR description instead of guessing.
2. **Set up Godot** (this machine has none): `bash tools/setup_godot_linux.sh`, then
   `export GODOT="$HOME/godot/godot"` and run `bash tools/check.sh` once **before changing anything**.
   Report whether it passed as-is (that tells us if headless Godot works here). If the download
   fails, try the other versions it suggests and report what happened.
3. **Build** the plan in small commits (one feature per commit, messages that explain why). Run
   `bash tools/check.sh` after each change; don't commit on a failure.
4. **Strings:** every player-facing string is a key in `localization/strings.csv`. For new rows put
   the **English text in every language column** (the Chinese/Japanese/Korean fonts can't be rebuilt
   here; don't run `tools/subset_fonts.py`). All new text is a draft for Garret.
5. **Renders (optional experiment):** try `RENDER=1 bash tools/setup_godot_linux.sh` and a
   `--write-movie` render of the Guide tab (see the script's output for the command). If it works,
   commit one or two PNGs to `planning/phase4/guide/` and describe what they show. If it doesn't,
   say what failed; that's useful too.
6. **Don't:** edit `.godot/`, add assets without logging them in `assets/PROVENANCE.md`, use any
   AI-generated art or audio, or touch anything Nintendo-related.
7. **PR description:** what you built, the check.sh result, whether headless Godot and renders
   worked here, every new string for Garret to approve, and any open questions.
