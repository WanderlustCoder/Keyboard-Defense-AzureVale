# Localization and Keyboard Layout Strategy

Typing instruction is tightly coupled to keyboard layout and locale. This plan
prevents early rework.

---
## Landmark: Scope decision (recommended MVP)
- Full UI localization: optional in MVP (English UI acceptable).
- Typing content localization: supported via content packs, at least `en-US`.
- Keyboard layout support: start with QWERTY in MVP; keep architecture layout-aware.

---
## Landmark: Key concepts
### Locale
A language/region tag like `en-US`, used for:
- wordpack selection
- punctuation conventions
- pluralization (if UI localization exists)

### Keyboard layout
A layout label like `QWERTY`, `AZERTY`, `DVORAK`, used for:
- curriculum ordering (home row, etc.)
- difficulty modeling (finger travel)
- allowed character sets

---
## Landmark: Implementation approach
1. Store all prompts as characters, not key codes.
2. The game accepts text input from the OS, so it respects different layouts.
3. Teaching curriculum (wordpacks) must be layout-specific:
   - `data/wordpacks/en-US/home_row_1.qwerty.json`
   - `data/wordpacks/fr-FR/home_row_1.azerty.json`

---
## Landmark: Layout modules
Create a layout data module with:
- `layout_id`
- home row characters
- row definitions
- optional finger groupings

Example shape (JSON):
```json
{
  "layout_id": "QWERTY",
  "display_name": "QWERTY",
  "rows": {
    "top": ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
    "home": ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";"],
    "bottom": ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
  }
}
```

---
## Landmark: Detect vs choose
- Do not attempt automatic layout detection in MVP (unreliable).
- Provide a simple settings option:
  - Layout: QWERTY (default)
  - AZERTY (experimental)
  - DVORAK (experimental)

---
## Landmark: Localization-ready UI (lightweight)
Even without full translation, keep UI strings centralized:
- `apps/keyboard-defense-godot/data/locale/en-US.json`
- use a small localization helper in GDScript

This prevents painful refactors later.

---
## Landmark: Non-English input considerations
- Avoid requiring IME composition during timed prompts in MVP.
- If supporting diacritics later:
  - include them in `allowed_chars`
  - avoid timed prompts that require dead keys unless user opts in

---
## Landmark: QA checklist (layouts)
- Switching layouts changes recommended packs but does not break input.
- Command words remain valid across layouts (commands are strings, not key positions).
- Visual hints (if any) update to match the selected layout.
