# Phase 2 · Step 11 Plan: wrap-up and sign-off
**Status:** Planned 2026-09-24 (Claude + Codex). Start in a fresh session.

Phase 2 needs sign-off, not another feature pass. Codex's plan, which Claude agrees with:

**Phase 2 needs sign-off, not another feature pass.** Based on the supplied status, Steps 1–10 already satisfy the implementation requirements.

Remaining checklist:

- [ ] Complete Step 11: **5 minutes actively playing and 5 minutes hands-off**. Record when the loop became satisfying, when clicking felt required, and what you wanted to buy next. Confirm the “want to keep going” criterion.
- [ ] During that run, confirm the completed core loop: boost, booth income and Gold/sec, waves, latch/drag/damage, temporary stall and recovery, click/Wolf kills with one payout, and purchases.
- [ ] Fix any acceptance-blocking bugs; expose any remaining hard-coded values identified as needing tuning. Then obtain a passing full check, including the **187 tests**.
- [ ] Complete the **full Phase 2 diff review** and walkthrough.
- [ ] Garret answers the understanding check: why enemies live outside Carousel, how Wolf sweep hits are detected, and how booth passes avoid duplicate payouts.

**Tidy before sign-off:**

- Update roadmap implementation checkboxes to reflect completed work; tick final acceptance boxes only after the wrap-up.
- Replace the obsolete “five purchases” list with the implemented leveled shop and Step 10 purchases. Verify these rather than rebuilding the original one-time upgrades.
- Update the goals document’s version header and stale descriptions: Step 4’s click Gold was removed; Auto waves already exists despite the Phase 4 note; temporary stall documentation should reflect crank/safety-net behavior.
- Consolidate README status to **187 tests**, including localization and all completed extras. Mark “revisit after Leaves” feedback as historical and reassess pacing during Step 11.
- Resolve or explicitly park sprite orientation. Inventory Garret’s placeholder text and the **nine draft languages**; distinguish drafts from approved copy. Final copy is required before shipping, not necessarily before this internal milestone.
- Close the editor-plugin checkbox as enabled or intentionally optional; confirm the Step 1 deliberate-failure check was previously demonstrated.

**Size:** Small—one focused **90–120-minute wrap-up session**, assuming the full diff review is manageable and playtesting finds no substantial bugs. Reviewing all accumulated extras could require a separate session.

**Move forward explicitly:**

- **Phase 3:** additional enemies, mounts, upgrades, and balancing around that expanded content.
- **Phase 4/backlog:** hold-to-boost automation, further idle-system work, and expanded wave controls beyond what already exists.
- Defer nonblocking jitter polish, further visual/audio polish, and translation finalization to their appropriate later milestones.
- Keep the **real fail state DECISION PENDING**; Phase 2 requires only the working temporary stall.