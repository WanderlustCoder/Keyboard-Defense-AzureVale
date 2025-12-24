# Data schemas and examples

Schemas live in `apps/keyboard-defense-godot/data/schemas/` and are mirrored
here for planning. Automated tests validate game data against these schemas.

## Example: Lesson
```json
{
  "id": "home-row-1",
  "order": 1,
  "label": "Home Row Foundations",
  "words": ["as", "sad", "dad", "lad"]
}
```

## Example: Drill template
```json
{
  "id": "forest-gate",
  "label": "Forest Gate Drill",
  "plan": [
    {
      "mode": "lesson",
      "label": "Warmup",
      "word_count": 5,
      "shuffle": false,
      "hint": "Anchor fingers on home row."
    },
    {
      "mode": "intermission",
      "label": "Reset",
      "duration": 2.0,
      "message": "Breathe and reset."
    }
  ]
}
```

## Example: Map node
```json
{
  "id": "forest-gate",
  "label": "Forest Gate",
  "lesson_id": "home-row-1",
  "requires": [],
  "reward_gold": 10,
  "drill_template": "forest-gate"
}
```

## Example: Upgrade
```json
{
  "id": "scribe-hall",
  "label": "Scribe Hall",
  "cost": 20,
  "description": "Letters strike with greater force.",
  "effects": {
    "typing_power": 0.15
  }
}
```

## Example: Asset manifest entry
```json
{
  "id": "typing_power",
  "path": "res://assets/icons/typing_power.png",
  "expected_width": 16,
  "expected_height": 16,
  "max_kb": 8,
  "pixel_art": true
}
```
