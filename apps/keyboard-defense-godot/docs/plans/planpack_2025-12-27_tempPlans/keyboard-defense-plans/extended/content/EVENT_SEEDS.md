# Example Event Seeds (Original)

These are small, generic event seeds. Convert them to JSON in
`apps/keyboard-defense-godot/data/events/` as needed. Keep them short. Ensure
each has a tier and tags.

## 1) The Bent Wheel
- Tier: 1
- Tags: salvage, logistics
- Body: "A wagon sits half-sunk in the dirt. The wheel is bent, but the crates are intact."
- Choices:
  - A (phrase): "salvage crates" -> +TIMBER small, +FOOD small
  - B (phrase): "repair wheel" -> +ROAD_KNOWLEDGE buff, costs TIMBER small
  - C (code): leave -> nothing

## 2) Scribe Notes
- Tier: 2
- Tags: lore, research
- Body: "A satchel hangs from a branch. Inside: ink-smudged notes and a clean map corner."
- Choices:
  - A (prompt_burst): 2 short prompts -> +MAP_REVEAL small, +RESEARCH
  - B (phrase): "copy notes" -> +RESEARCH bigger, costs TIME
  - C (code): burn it -> +MORALE, -RESEARCH

## 3) Reedbed Crossing
- Tier: 1
- Tags: navigation, weather
- Body: "The reeds hide a narrow crossing. It will save time, but the footing is slick."
- Choices:
  - A (phrase): "take crossing" -> +MAP_REVEAL, RNG: minor injury chance
  - B (phrase): "go around" -> no risk, costs TIME

## 4) Warm Lanterns
- Tier: 0-1 (depending on prompts)
- Tags: ally, morale
- Body: "A small group waves lanterns. They offer soup and news."
- Choices:
  - A (code): accept -> +FOOD, +MORALE
  - B (phrase): "share supplies" -> +MORALE big, costs FOOD
  - C (code): decline -> nothing

## 5) The Quiet Bell
- Tier: 2
- Tags: defense, omen
- Body: "A bell hangs on a post. It has not rung in years. Tonight, the wind makes it tap once."
- Choices:
  - A (phrase): "test alarm" -> unlock intervention "raise alarm" (cheap)
  - B (phrase): "ignore bell" -> nothing
  - C (phrase): "take bell" -> +METAL small, -MORALE
