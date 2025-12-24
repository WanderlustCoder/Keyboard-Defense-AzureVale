# Audio event map

This map keeps audio consistent and prevents missing SFX regressions.

## Typing engine -> SFX
- keydown (rate limited) -> `ui_keytap`
- confirm/enter -> `ui_confirm`
- cancel/escape -> `ui_cancel`
- correct char or word -> `type_correct`
- mistake -> `type_mistake`
- combo threshold reached -> `combo_up`
- combo broken -> `combo_break`

## World and sim -> SFX
- build placed -> `build_place`
- build finished -> `build_complete`
- resource collected -> `resource_pickup`
- unit spawned -> `unit_spawn`
- enemy spawned -> `enemy_spawn`
- player hit -> `hit_player`
- enemy hit -> `hit_enemy`
- wave start -> `wave_start`
- wave end -> `wave_end`

## Rate limiting and ducking
To avoid audio overload during intense typing:
- rate limit `ui_keytap` to 10-15 per second max
- when a typing prompt is active:
  - duck non-typing SFX by about 30 percent
  - optionally duck music slightly
- when wave starts, briefly duck music to emphasize the cue

## Loudness normalization (simple)
- each preset includes `gain`
- add a test that checks peak amplitude and reduces gain if clipping is detected

## Acceptance checks
- in a 60-second stress test (continuous typing + wave), audio remains clear and not fatiguing
