# Onboarding Tutorial

Purpose
The onboarding tutorial gives first-run guidance for the typing-first loop without altering any sim rules or balance. It is UI/profile only and tracks progress from the commands you already type.

Tutorial Steps
1) Open help
   - Goal: see the command primer.
   - Player types: `help`
   - Completion signal: help command executes (help lines printed to log).
2) Move the cursor
   - Goal: learn navigation.
   - Player types: `cursor up` or `cursor 8 5`
   - Completion signal: cursor move intent processed.
3) Inspect a tile
   - Goal: learn inspection output.
   - Player types: `inspect`
   - Completion signal: inspect intent processed.
4) Gather resources
   - Goal: practice a day action.
   - Player types: `gather wood 5`
   - Completion signal: Gathered event emitted.
5) Build a structure
   - Goal: place a building.
   - Player types: `build farm`
   - Completion signal: Built event emitted.
6) End the day
   - Goal: move into night phase.
   - Player types: `end`
   - Completion signal: phase transitions to night.
7) Defend at night
   - Goal: type an enemy word to attack.
   - Player types: type an enemy word + Enter
   - Completion signal: defend input processed during night.

First Run vs Replay
- First run: the tutorial panel is auto-shown and progress is stored in `user://profile.json`.
- Completion: the panel auto-hides when all steps are complete.
- Replay: use `tutorial restart` to reset to step 1 at any time.

Tutorial Control Commands
- `tutorial` toggles the tutorial panel on/off.
- `tutorial restart` resets step progress and shows the panel.
- `tutorial skip` marks the tutorial as complete and hides the panel.

Non-goals
- The tutorial does not change sim rules, RNG, enemies, damage, or balance.
- The tutorial does not add new combat mechanics; it only highlights existing commands.
