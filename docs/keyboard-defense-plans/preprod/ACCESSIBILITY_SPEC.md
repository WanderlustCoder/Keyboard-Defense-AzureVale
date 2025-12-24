# Accessibility and Comfort Specification (Typing-First)

This is a typing-first game; accessibility is not optional if you want broad reach.

---
## Landmark: Accessibility pillars
1. Time pressure is adjustable.
2. Visual clarity supports fast reading during typing.
3. Audio cues are helpful but never mandatory.
4. Input flexibility: keyboard-only, low dexterity options, alternate layouts.

---
## Landmark: Required settings (MVP)
### Typing and time pressure
- Global time multiplier: 0.5x to 2.0x (default 1.0x)
- Practice mode toggle:
  - prompts still score, but do not cause instant loss
- Backspace behavior:
  - allow corrections (default)
  - optional "no backspace penalty" mode
- Prompt complexity:
  - token length cap (e.g., max 12/16/20 chars)
  - punctuation/numbers module toggle

### Visual
- Font size slider
- High-contrast mode
- Reduced motion mode (disable shake, reduce particles)
- Optional dyslexia-friendly font (if licensed)
- Colorblind-safe patterns for key UI states (not just color)

### Audio
- Master volume + SFX volume + music volume
- Audio cues toggle (important for success/failure feedback)
- Typing click toggle (optional; can be annoying)

### Input
- One-handed mode (optional but recommended):
  - prefer prompts constrained to one side of the keyboard
- Rebind submit/confirm (Enter vs Space)
- Ignore long key repeats in command entry

---
## Landmark: UX rules for accessibility
- Never hide critical info behind color alone.
- Battle UI should have:
  - readable threat indicators
  - optional pause between waves
- Provide a calm mode:
  - reduced enemy speed
  - fewer simultaneous prompts
  - longer timers

---
## Landmark: Assistive compatibility (Godot)
- Keep UI focus states visible and keyboard navigable.
- Provide a text-only summary screen for results.
- If adding narration later, keep it optional and off by default.

---
## Landmark: Acceptance tests
- Keyboard-only playthrough (no mouse) from menu to end-of-run screen.
- High-contrast mode makes UI readable at 100% scale.
- Reduced motion eliminates camera shake and heavy particles.
- Calm mode allows a new typist to survive at least one battle.
