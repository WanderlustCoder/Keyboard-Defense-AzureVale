# UI asset spec (typing-first)

The UI must support type-only control. UI art should be minimal and functional.

## Panels and 9-slice
Prefer 9-slice scalable panels rather than many fixed-size bitmaps.
Use Godot `NinePatchRect` or `StyleBoxTexture` in a Theme.

Required UI sprites (can be generated as SVG):
- `ui_panel_bg` (9-slice)
- `ui_panel_header` (9-slice)
- `ui_button` (9-slice, normal/hover/pressed optional)
- `ui_tag` (small pill background)
- `ui_cursor` (caret)
- `ui_focus_ring` (selection outline)

Threat cards:
- `ui_threat_card_bg` (9-slice)
- `ui_threat_card_badge` (icon container)

Typing widgets:
- `ui_prompt_bg` (9-slice)
- `ui_progress_bar_bg`
- `ui_progress_bar_fill`
- `ui_mistake_underline` (small repeating segment)

## Typography
Because the game teaches typing, font choice is critical:
- use a clean monospace for prompts and command input
- provide optional dyslexia-friendly font toggle if added later

Implementation note:
- fonts are loaded via Godot resources; do not embed unlicensed fonts

## Icon behavior
Icons should never be the only signal:
- always pair with text label or help text

## Animation
UI animations should be subtle:
- focus ring pulse at low frequency
- error shake optional and disable-able

## Acceptance checks
- command bar readable at 1280x720 and 1920x1080
- prompt widget remains readable over bright tiles
