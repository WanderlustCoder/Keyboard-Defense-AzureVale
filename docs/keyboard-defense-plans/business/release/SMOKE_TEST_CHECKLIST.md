# Smoke Test Checklist (Detailed)

## Typing Input
- Command entry accepts text and backspace correctly
- Enter submits; Esc cancels
- Help command returns valid list
- Invalid command yields a helpful error + suggestion

## Day Phase
- Resources change as expected
- Build command consumes resources and updates map/state
- Exploration reveals new tile/POI deterministically

## Night Phase
- Wave spawns
- Walls take damage
- Repair command triggers prompt and outcome

## Save/Load
- Save exists after quitting
- Load resumes same day/time and state matches

## Performance
- No major stutter during wave start
- Audio levels stable (no clipping)


