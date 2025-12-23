> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## 2025-12-16 - Castle Skin Themes

- Pause/options overlay adds a Castle Skin selector (Classic, Dusk, Aurora, Ember) tied to streak unlocks and applies themes instantly.
- HUD + options castle panels now read skin-specific CSS variables for health bars, passives, gold events, and castle surfaces via `data-castle-skin` on root/body/HUD.
- Selection persists through the new `castleSkin` player setting; loading restores the skin before syncing the overlay, and tests cover persistence plus control wiring.

