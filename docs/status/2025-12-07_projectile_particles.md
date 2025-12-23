# Projectile Particle Stub (Offscreen) - 2025-12-07
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Implemented a minimal `ParticleRenderer` with optional OffscreenCanvas support to render muzzle-puff style particles and decay them over time.
- Respects reduced-motion by no-oping and skipping canvas allocation; supports forced reload of cached sprites for future upgrades.
- Added unit tests covering reduced-motion fallback, decay behavior, and particle cap enforcement.
- Backlog #65 now has a baseline offscreen-capable particle system to extend with richer effects.

## Verification
- `cd apps/keyboard-defense && npx vitest run particleRenderer.test.js`

## Related Work
- `apps/keyboard-defense/src/rendering/particleRenderer.ts`
- `apps/keyboard-defense/tests/particleRenderer.test.js`
- Backlog #65

