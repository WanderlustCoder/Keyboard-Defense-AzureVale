# Threat Cards (Battle Modifiers)

Threat cards modify battle waves. They add variety and strategic planning hooks.

## Goals
- Make battles feel different without changing the core loop.
- Give the player clear counterplay with typing-driven interventions.

## Template
```json
{
  "id": "threat_smoke_winds",
  "name": "Smoke Winds",
  "description": "Visibility is reduced. Ranged units are less effective.",
  "tags": ["visibility", "ranged_nerf"],
  "difficulty_delta": 1,
  "counters": ["signal flares", "torchline"]
}
```

## Example threats (seed set)
1. Smoke Winds - ranged nerf, counter: "signal flares"
2. Thin Ice - movement hazard, counter: "lay planks"
3. False Quiet - delayed spawn, counter: "scout ahead"
4. Heavy Rain - fire effects weaker, counter: "oil pots"
5. Scree Rush - faster enemies, counter: "spike trench"
6. Sapper Signs - wall damage risk, counter: "patrol wall"
7. Moonbright - enemies see paths, counter: "break lanterns"
8. Hungry Night - morale drain, counter: "ring bell"
9. Fogbanks - random approach lanes, counter: "signal flags"
10. Bitter Cold - repairs slower, counter: "heated pitch"

## Typing integration
- Each threat should introduce 1 to 2 battle interventions with short prompts.
- Prompts must be tier-tagged and can be disabled in accessibility settings.
