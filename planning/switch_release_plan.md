# Nintendo Switch Release Plan

_Garret, 2026-09-26 (worked out in a separate GPT chat). A plan, not a commitment of scope: the Switch
port is a post-Steam expansion, not part of the critical path for finishing and shipping Idle Carousel._

**Goal:** release Idle Carousel on Nintendo Switch after the Steam version has shipped and stabilized.
The Switch port must not delay or distract from the Steam release.

## Plan

1. **Apply to Nintendo during development.**
   - Create the Nintendo Developer Portal account before Steam launch.
   - Developer registration is free.
   - Request Switch development access when appropriate.
   - This is administrative preparation only; do not begin the actual port yet.

2. **Ship Steam first.**
   - Complete the existing PC roadmap.
   - Release Idle Carousel on Steam.
   - Fix launch bugs, gather player feedback, and stabilize the game.
   - Only after the Steam version is in good shape should active Switch-port development begin.

3. **Controller support is already part of the main game.**
   - Continue building full controller navigation/support as currently planned.
   - This is part of the normal Steam version, not separate Switch work.
   - Continue making reasonable platform-friendly decisions where they naturally fit, but do not add
     Nintendo-specific scope before Steam ships.

4. **After Steam, attempt an in-house Switch port first.**
   - Obtain Nintendo-authorized development hardware.
   - Use an available Godot console solution, likely RAWRLAB or W4.
   - Prefer the lowest-cost viable option.
   - Garret + Claude Code/Codex should attempt the engineering work before hiring a full porting studio.
   - Bring in specialist consulting only if specific porting or certification problems cannot reasonably
     be solved internally.

5. **Target Switch without waiting for a native Switch 2 release.**
   - A compatible Switch release can also be played by Switch 2 owners through backward compatibility.
   - Do not delay the Nintendo release solely to obtain native Switch 2 development access.
   - A native Switch 2 version can be evaluated later if access and benefits justify it.

6. **Keep costs proportional to a $4.99 indie game.**
   - Nintendo developer registration: $0.
   - Nintendo SDK/tools: generally $0.
   - Digital IARC rating: $0.
   - Nintendo development hardware: paid; exact current price is disclosed after approval.
   - Godot console tooling may be free through RAWRLAB or paid through a supported option such as W4.
   - Avoid paying for a full external port unless necessary and justified by the game's performance.

7. **Retail Switch hardware is not development hardware.**
   - Garret owns a Switch and Switch 2, which can be useful for testing released/consumer builds.
   - Development builds require Nintendo-authorized development hardware.

8. **Nintendo confidentiality rule.**
   - Nintendo SDKs, documentation, certification requirements, APIs, and other developer materials may
     be under NDA.
   - Do not send Nintendo-confidential material to Claude Code, Codex, or another external AI service
     unless Nintendo's applicable agreements explicitly permit it. (Also in CLAUDE.md and AGENTS.md.)

## Intended release sequence

Finish Idle Carousel → Steam launch → Steam stabilization → begin Switch port → Nintendo certification →
Nintendo eShop launch → optional native Switch 2 version later.

## What this means for the current build (Claude's notes)
- Keep doing what's already planned for Steam: controller navigation (the Phase 4 shop is
  controller-ready), named Input Map actions instead of hard-coded keys, no hover-only information.
- Nothing Nintendo-specific gets built before Steam ships.
