# Sound style guide

## Goals
- reinforce typing correctness and rhythm without being annoying
- make day/night and threat escalation audible
- keep it lightweight: no large sample libraries required

## SFX principles
- short: 50-500ms
- low poly / retro: simple waveforms, minimal effects
- consistent loudness; avoid clipping
- mistakes must be informative but not punishing

### Required SFX events (MVP)
Typing and UI:
- `ui_keytap` (very subtle)
- `ui_confirm`
- `ui_cancel`
- `type_correct`
- `type_mistake`
- `combo_up`
- `combo_break`

World:
- `build_place`
- `build_complete`
- `resource_pickup`
- `unit_spawn`
- `enemy_spawn`
- `hit_player`
- `hit_enemy`
- `wave_start`
- `wave_end`

## Music (optional for MVP)
If included, keep it sparse:
- day: calm loop, 60-90 BPM, low density
- night: tense loop, 100-140 BPM, slightly more percussion
- threat escalation: add layers (hi-hats, bass pulse)

## Mixing targets (simple)
- master peak: keep below clipping
- SFX lower than music by default; provide sliders

## Accessibility
- separate volume controls: music, SFX, typing cues
- option to disable mistake sound
