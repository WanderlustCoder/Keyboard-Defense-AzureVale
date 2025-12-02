# QA Checklist - Typing Edge Cases

Use this checklist when testing typing input, especially after buffer, tutorial, or HUD changes. Audience: ages 8–16, Edge/Chrome laptops.

## Inputs & Modifiers
- Caps Lock on/off: buffer should stay lowercase, warning visible, no shifted characters sneaking in.
- Shift usage: shifted punctuation (.,?!;:'"-) and number row via Shift; ensure accuracy tracking is correct.
- Held keys/key-repeat: holding a letter should not flood the buffer; repeat events should be ignored or throttled.
- Backspace: single delete vs. Ctrl/Cmd+Backspace purge; confirm purge trims buffer and resets combo rules.
- Non-letter keys: ignore function keys, media keys, Windows key, Alt/Meta combos; no crashes or stray characters.
- IME/compose: compose events should not inject partial sequences; buffer remains stable.
- Paste/drag-and-drop: blocked/ignored for the typing field; buffer should not change.
- Focus trap: typing input should regain focus after overlays close; Esc/Enter UI controls should not steal focus permanently.

## Accuracy & Buffer Rules
- Buffer reset on word completion; clears active word highlight and combo updates correctly.
- Error handling: wrong key increments error count; per-letter highlight stays in sync.
- Purge hotkey clears buffer and applies the intended combo penalty (if any).
- Tutorial flow: continue/skip/replay keys (Enter/Esc) do not leave stray characters in the buffer.

## Accessibility & Feedback
- Aria-live updates for combo/accuracy remain polite; no spam when holding keys.
- Reduced-motion mode: no flashing/shaking on errors; warnings appear without animation.
- Caps-lock warning: appears/disappears immediately on modifier change; aria-live polite.

## Smoke Commands
- Run typing fuzz tests: `npm run test -- --runInBand --filter typingFuzz` (or full `npm test`).
- Manual: `npm run serve:open`, focus typing input, walk through the scenarios above in both tutorial and main waves.
