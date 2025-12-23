> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-16 — Sticker Book Achievements

- Added a Sticker Book overlay reachable from the pause/options menu. It renders a pixel-art sticker grid with progress bars and status pills.
- Progress auto-derives from session stats (breaches, combo peak, shields broken, gold held, perfect words, accuracy, drills) and summarizes unlocked/in-progress counts.
- Overlay is fully keyboard/focus-trapped and inherits the HUD reduced-motion/ARIA conventions; tests cover toggling and rendering with custom entries.

