# Audio Plan

Roadmap ID: P2-AUDIO-001 (Status: Not started)

## Audio event taxonomy
- UI: open/close panels, toggles, errors.
- Typing: hit, miss, streak, completion.
- Build: build placed, upgrade, demolish.
- Combat: tower fire, enemy spawn, base hit, dawn.
- Win/Loss: victory, defeat, report shown.

## Hook points (plan-only)
- Sim events emitted from reducers.
- UI layer maps events to SFX without changing sim state.

## Style goals
- Original, readable SFX inspired by fantasy tactics (no direct copying).
- Short, non-fatiguing cues that do not mask typing rhythm.

## Implementation phasing
Phase 1: UI and typing cues.
Phase 2: Combat and build cues.
Phase 3: Win/loss and ambient loops.

## Acceptance criteria
- Audio events map to key gameplay actions.
- Asset audit rules respected; manifest kept up to date.
- Headless tests remain green (no audio dependency).

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/AUDIO_EVENT_MAP.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/SOUND_STYLE_GUIDE.md`
