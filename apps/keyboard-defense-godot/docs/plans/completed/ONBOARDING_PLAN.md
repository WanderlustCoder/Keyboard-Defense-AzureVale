# P0 Onboarding Plan

Roadmap IDs: P0-ONB-001

## Player outcome
New players can start a run, understand day vs night, execute core commands, and survive a first night without external guidance.

## Tutorial structure
1) Welcome + focus
   - Goal: confirm typing-first controls and command bar focus.
   - Player does: types `help` or `status`.
   - Completion: log shows command response.
2) Day actions primer
   - Goal: teach gather/build/explore.
   - Player does: `gather wood 5`, `build farm`, `explore`.
   - Completion: resources change + explore log event.
3) End day
   - Goal: explain day -> night transition.
   - Player does: `end`.
   - Completion: phase changes to night and prompt appears.
4) Night typing
   - Goal: teach per-enemy word targeting and safe Enter rules.
   - Player does: type one enemy word and press Enter; try a prefix and see incomplete hint.
   - Completion: enemy hp decreases and wave panel updates.
5) Survive to dawn
   - Goal: reinforce loop outcome and report.
   - Player does: complete a short wave or use `wait` if necessary.
   - Completion: dawn event + typing report shown.
6) Wrap-up
   - Goal: show settings/lessons panels and how to reopen tutorial.
   - Player does: `lessons`, `settings`, `tutorial` (toggle).
   - Completion: panels open/close and tutorial controls visible.

## UX constraints
- Typing-first, no mouse required.
- Steps must not alter sim balance or RNG outcomes.
- Respect safe Enter gating during night; no penalties for prefixes.

## Commands taught (order)
- `help`, `status`, `gather`, `build`, `explore`, `end`, typing enemy words, `wait`, `lessons`, `settings`, `tutorial`.

## Telemetry and metrics (existing)
- Use typing stats (hits/misses, incomplete enters) and report history to track onboarding completion trends.
- Record tutorial completion in profile onboarding state.

## Planning references
- `docs/ONBOARDING_TUTORIAL.md`
- `docs/plans/p0/ONBOARDING_COPY.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/PROJECT_MASTER_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`

## Acceptance criteria
- Tutorial auto-shows on first run and can be replayed.
- Each step advances only on the expected command or typing action.
- Players can complete a full day -> night -> dawn loop in the tutorial.
- Completion status persists in `user://profile.json`.

## Test plan
- Headless tests validate tutorial command parsing and onboarding state transitions.
- Manual smoke: run tutorial start to finish without mouse input.
