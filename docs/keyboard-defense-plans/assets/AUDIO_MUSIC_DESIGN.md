# Procedural music design (optional)

Music is optional for MVP. If included, keep it simple and loop-based.

## Design goals
- reinforce day/night mode shift
- avoid distracting the player during typing
- low CPU

## Approach
- generate short 8-16 bar loops into buffers
- crossfade between loops for transitions

## Musical constraints
- use a limited scale (major for day, natural minor for night)
- sparse instrumentation:
  - day: pad + light pluck
  - night: bass pulse + tight percussion

## Implementation notes
- use deterministic PRNG for note selection
- ensure seamless looping:
  - align loop length to sample rate
  - fade out/in over last 5-10ms to avoid clicks

## Acceptance checks
- mode switch is smooth
- music does not mask typing SFX
