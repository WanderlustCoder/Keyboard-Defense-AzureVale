---
id: tutorial-passive-messaging
title: "Tutorial messaging for passive unlocks"
priority: P2
effort: M
depends_on: [passive-analytics-export]
produces:
  - tutorial script updates announcing passive unlocks
  - localization/telemetry entries for the new messages
  - tests ensuring messaging appears during onboarding
status_note: docs/status/2025-11-06_castle_passives.md
backlog_refs:
  - "#1"
  - "#30"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Castle passives are introduced later, but the tutorial still doesn't explicitly
call them out when the player upgrades the castle. We need tutorial cues +
telemetry so onboarding captures passive unlock awareness.

## Steps

1. **Tutorial script**
   - Update `tutorialManager` to insert a step after the relevant castle upgrade
     explaining the passive (regen, armor, gold).
   - Provide separate messaging for each passive unlock (text + optional voice).
2. **HUD highlight**
   - During the tutorial message, highlight the passive entry in the HUD so the
     player sees the new icon/text.
3. **Telemetry**
   - Emit tutorial events (`tutorial:passive-announced`) when the message runs,
     captured in analytics.
4. **Tests**
   - Add unit/tutorial tests verifying the message appears and analytics event fires.
5. **Docs**
   - Update tutorial docs/status to mention the new messaging (once implemented).

## Implementation Notes

- **Script orchestration**
  - Insert a scripted checkpoint after the castle upgrade step (where passive unlocks) so the tutorial pauses combat, focuses the castle panel, and injects narration text (support plural passives when multiple unlock simultaneously).
  - Use the existing tutorial dialogue system to add localized strings (`tutorial.passive.regen`, etc.) and include short + long variants (short for HUD toast, long for narration modal).
  - When the step triggers, set `body.dataset.highlightPassive="<passiveId>"` and pulse the HUD passive entry with CSS class `is-highlighted`.
  - Ensure the tutorial resumes automatically once the player acknowledges the message or after a timeout (≈3 seconds) to avoid stalls.
- **HUD/UX hooks**
  - Add a `PassiveHighlightController` that can be reused by non-tutorial flows; it should:
    - Scroll the castle passive list into view on small devices.
    - Provide reduced-motion variants (no flashing, just color change).
    - Fall back gracefully if the passive panel is condensed (tie into task #37 audit).
- **Telemetry + analytics**
  - Emit `tutorial.passiveAnnounced` via the analytics dispatcher with payload `{passiveId, waveIndex, upgradeLevel, messageVariant}`.
  - Record the timestamp difference between unlock and announcement (`announcementLagMs`) and include it in analytics snapshots for dashboards.
  - Update `scripts/analyticsAggregate.mjs` fixtures to include the new event so smoke runs confirm the telemetry fired.
- **Testing**
  - Unit tests covering:
    - Tutorial step insertion order (ensuring announcements happen only once per passive).
    - Highlight controller toggling classes and respecting reduced-motion prefs.
    - Analytics payload content.
  - Tutorial integration test (Vitest/Playwright) simulating the upgrade, verifying the message text, highlight, and telemetry emission.
- **Docs & localization**
  - Add string entries to the localization catalog and document them in `apps/keyboard-defense/docs/HUD_NOTES.md`.
  - Update `docs/status/2025-11-06_castle_passives.md` follow-up plus `docs/CODEX_PLAYBOOKS.md` tutorial section with instructions for refreshing the messages when passives change.

## Deliverables & Artifacts

- Tutorial script updates + localization strings (JSON/TS).
- HUD highlight helper + CSS tokens.
- Analytics fixtures reflecting new event.
- Documentation/status updates describing the new onboarding cues.

## Acceptance criteria

- Tutorial orchestrator announces each passive as it unlocks.
- HUD highlight appears during the tutorial message.
- Analytics captures the event.
- Tests cover the flow.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run tutorial smoke (`node scripts/smokeTutorialFull.mjs` when available) to confirm messaging triggers.






