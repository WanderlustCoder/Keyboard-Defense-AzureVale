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
