# Accessibility Verification (P0-ACC-001)

## Scope
P0-ACC-001 covers two goals: (1) readability of core panels at 1280x720 and (2) keyboard-only navigation of settings, lessons, trend, history, and report panels. This checklist documents the manual verification steps required for signoff.

## Test setup
- Godot editor window size: Project Settings -> Display -> Window -> Size. Set `viewport_width` to 1280 and `viewport_height` to 720, then run the project.
- Runtime window size: resize the game window to 1280x720 and run `settings verify` to confirm the reported window size.
- Recommended starting settings: `settings scale 100`, `settings compact off`, and `bind <action> reset` for any custom keybinds.

## Readability @ 1280x720 checklist (pass/fail)
- Command bar text and placeholder are fully visible; no truncation or overlap.
- Log panel lines remain readable without clipping the command bar or prompt.
- Settings panel header and command hints fit without overlapping or clipping.
- Settings Controls list entries show full action names and bindings in-frame.
- Lessons panel (non-compact) shows header, active lesson, and samples without clipped lines.
- Lessons panel (compact) shows active lesson, compact progress lines, and lesson list without overlap.
- Trend panel (non-compact) shows goal, targets line, and trend text without clipping.
- Trend panel (compact) shows goal line and trend summary without clipping.
- History panel (non-compact) shows recent entries without clipped or overlapping lines.
- History panel (compact) shows trimmed entries clearly and within bounds.
- Night wave list (non-compact) shows enemy rows and progress bars without overlap.
- Night wave list (compact) shows capped list and “(+N more)” line within the panel.
- No critical HUD elements overlap or hide (stats, command bar, prompt, typing feedback, wave panel).

## Keyboard-only navigation checklist (pass/fail)
- Toggle Settings with typed command (`settings`) and hotkey (F1); panel opens/closes.
- Toggle Lessons with typed command (`lessons`) and hotkey (F2); panel opens/closes.
- Toggle Trend with typed command (`trend`) and hotkey (F3); panel opens/closes.
- Toggle History with typed command (`history`) and hotkey (F5); panel opens/closes.
- Toggle Report with typed command (`report`) and hotkey (F6); panel opens/closes.
- Change UI scale via command (`settings scale 110`, `settings scale reset`).
- Toggle compact via command (`settings compact toggle`) and hotkey (F4).
- Rebind a key via typed command (`bind toggle_lessons F2` or `bind toggle_lessons reset`) and confirm the Controls list updates.
- Command bar stays usable after each toggle; focus returns to the command bar for typing.
- Run `settings verify` and confirm the diagnostic block reports expected window size and panel states.
- Confirm `settings verify` reports `Keybind conflicts: none` (or document intentional conflicts).

## Evidence capture guidance
- Capture `settings verify` output from the log after all checks.
- Take screenshots of each panel in both compact and non-compact modes at 1280x720.
- Note any overlap/clipping issues in an issue or milestone report.

## References
- Command reference: `docs/COMMAND_REFERENCE.md`
- Quality gates: `docs/QUALITY_GATES.md`
