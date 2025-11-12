## Enemy Defeat Animations - 2025-11-07

**Summary**
- Canvas renderer now tracks recent defeats and plays a brief eased burst (palette-matched radial gradient + spikes) at the impact point, honoring reduced-motion settings.
- SpriteRenderer exposes getEnemyPalette so defeat bursts match existing enemy colors.
- Backlog item #66 marked Done; adds quick polish that sells hits without needing sprite sheets yet.

**Next**
1. Consider layering sprite-based defeat frames once art lands to replace the procedural burst. *(Codex: `docs/codex_pack/tasks/24-enemy-defeat-spriteframes.md`)*
2. Pipe defeat burst counts into diagnostics overlay for quick visual-regression smoke assertions. *(Codex: `docs/codex_pack/tasks/25-defeat-burst-diagnostics.md`)*

