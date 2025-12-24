# Input and Remapping Requirements

## Principle
The game is typing-first. Remapping is primarily for:
- pause / resume
- accessibility toggles
- focus capture / console open

## Requirements
- Provide a way to rebind any non-text-entry hotkeys.
- Avoid using single-letter hotkeys that conflict with typing.
- When in text input mode, **do not** interpret keystrokes as hotkeys unless they are explicit (e.g., Esc to cancel).

## Suggested Control Set (minimal)
- `Esc`: cancel/close
- `Ctrl+K`: open command palette (if you use one)
- `F1`: help overlay
- `Ctrl+,`: settings

All other actions should be available through typed commands.


