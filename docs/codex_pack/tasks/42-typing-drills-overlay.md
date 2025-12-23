---
id: typing-drills-overlay
title: "Typing drills overlay and analytics export"
priority: P2
effort: M
depends_on: []
produces:
  - apps/keyboard-defense/public/index.html
  - apps/keyboard-defense/src/ui/typingDrills.ts
  - docs/analytics_schema.md
status_note: docs/status/2025-12-01_typing_drills.md
backlog_refs:
  - "#19"
---
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

**Context**  
Players need a warm-up lane that doesn't risk the castle. We want a dedicated drills overlay (Burst/Endurance/Shield Breaker) that pauses the run, resumes cleanly, and emits analytics so dashboards can show drill usage and outcomes.

## Steps

1. Add the typing drills overlay UI/CTA (HUD, options overlay, main menu) with pause-safe open/close and a restart affordance.
2. Record drill completions to `analytics.typingDrills` (mode, source, elapsed, accuracy, best combo, words, errors, WPM, timestamp) and surface a concise HUD log + debug analytics pills.
3. Extend the analytics schema/docs + `analyticsAggregate` CSV output with typing drill fields, including history string + last drill rollup, and cover with tests.

## Acceptance criteria

- Overlay opens from the HUD CTA, options overlay, and main menu; it pauses the run safely, respects menu/scorecard/toggle guards, and resumes or reopens options as appropriate.
- Each finished drill appends a normalized entry to `analytics.typingDrills`, shows a HUD log line, and populates the analytics viewer pills/history.
- Analytics schema/docs include typing drill fields and `analyticsAggregate` exports columns for count/last/history with passing tests.

## Verification

- `npm run build`
- `npx vitest tests/analyticsAggregate.test.js`
- `npm run test`






