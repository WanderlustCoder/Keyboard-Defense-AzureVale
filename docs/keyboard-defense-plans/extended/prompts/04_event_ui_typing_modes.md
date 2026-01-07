# Codex Milestone EXT-04 - Event UI and Typing Choices

## LANDMARK: Goal
Create a minimal UI component that displays an event and accepts typing input
to pick a choice.

## Requirements
- Support global typing mode:
  - code (A/B/C)
  - phrase (type exact phrase)
  - prompt_burst (type 1 to 3 prompts)
- Provide accessibility toggles:
  - allow backspace
  - autocomplete off/on
  - strict vs lenient punctuation

## Tasks
1) Add `EventPanel.tscn` and state wiring.
2) Implement input handling and validation per mode.
3) On success or failure, call sim `resolve_choice` and show a result banner.
4) Add at least 3 sample events for manual testing.

## LANDMARK: Acceptance criteria
- Player can complete an exploration event without using mouse.
- Incorrect typing gives feedback but does not lock the run.
