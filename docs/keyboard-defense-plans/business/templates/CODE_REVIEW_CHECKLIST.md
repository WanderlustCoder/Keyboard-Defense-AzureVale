# Code Review Checklist

## Correctness
- Does behavior match the spec / acceptance criteria?
- Are edge cases covered?

## Typing-first UX
- Can the feature be used without mouse?
- Are errors and help messages clear?

## Determinism
- Is RNG seeded and routed through the sim context?
- Are results reproducible given the same inputs?

## Tests
- Are tests present and meaningful (not just snapshots)?
- Do tests avoid timing flakiness?

## Performance
- Any per-frame allocations or heavy loops?
- Any large JSON parsing on hot path?

## Accessibility
- Does it respect time pressure and reduced motion?
- Is contrast and font size readable?

## Security/Privacy
- If telemetry exists, is it opt-in and schema-bound?
- No secrets committed?


