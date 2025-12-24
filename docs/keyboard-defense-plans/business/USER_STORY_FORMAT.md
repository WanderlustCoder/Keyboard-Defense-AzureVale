# User Story Format

Use this format to keep stories implementable by Codex without ambiguity.

## Template
**Title:**  
Short verb phrase describing user-visible capability.

**As a** <player / playtester / content author>  
**I want** <capability>  
**So that** <benefit>

### Controls (Typing-First)
- Primary command(s):
  - Example: `build tower`
- Prompt interactions:
  - Example: timed typing prompt to repair a wall

### Rules / Design Notes
- Bullets of gameplay rules and constraints.
- Determinism requirements (seeded RNG, no frame-time dependencies).

### Data
- New/updated schema fields (JSON).
- Default values and validation rules.

### Acceptance Criteria
- Observable behaviors.
- Test expectations (unit/integration/e2e harness).
- Performance constraints if relevant.

### Out of Scope
- Explicitly list what the story will *not* include.

## Example Story
**Title:** Add "repair wall" emergency action during night

As a player, I want to type `repair <segment>` during the night so that I can recover from damage spikes.

Controls:
- Command: `repair A3` where `A3` is a wall segment label.
- Prompt: short 6-12 character repair prompt; success restores HP; failure wastes time.

Acceptance:
- Repair consumes 1 action token; cannot exceed max wall HP.
- Deterministic: given seed and inputs, results are reproducible.
- Tests: sim unit tests + UI command parsing tests.



