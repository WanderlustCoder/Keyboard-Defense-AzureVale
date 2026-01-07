# Definition of Done (DoD)

A feature is "done" only when it meets **all** applicable criteria below.

## Functional Correctness
- Feature matches the specification and acceptance criteria.
- Edge cases are handled (invalid commands, empty inputs, paused states, etc.).
- Deterministic simulation rules are respected (no hidden entropy).

## Typing-First UX
- Feature is operable using typing-only controls.
- If optional mouse/UI affordances exist, they must not be required.
- Error feedback is actionable ("unknown command", "missing argument", "not available at night").

## Tests
- Unit tests exist for core logic (parser, sim rules, selection weights).
- Integration tests exist for end-to-end flows where practical (command -> sim -> render state).
- Tests are stable and deterministic.

## Accessibility
- Feature respects global settings:
  - time pressure scaling
  - reduced motion
  - high contrast
  - alternative prompt modes (strict/lenient)
- No flashing or excessive audio spam.

## Performance
- No significant regressions in baseline scenes.
- Avoid per-frame allocations in hot loops; cache when possible.

## Documentation
- Spec updated if behavior differs.
- Player-facing help updated (`help` command, tutorial steps).

## Telemetry/Privacy (If enabled)
- Telemetry is **opt-in** and clearly explained.
- Collected fields match documented schema.
- Works without network access.



