# Steam Release Plan (High-Level)

This document is a **planning checklist**. Steamworks requirements can change, so treat this as a durable baseline and verify against current Steamworks documentation before submission.

## Product Strategy
- Choose one:
  - **Demo first** (recommended): a constrained slice of the loop, with strong wishlist CTA.
  - **Early Access**: only if you can commit to regular updates and clear roadmap.
  - **1.0 launch**: only if content is already deep enough.

## Technical Plan
- Packaging:
  - Produce a clean build folder per platform with versioned output.
  - Ensure deterministic asset generation step is either committed or runs in CI.
- Save location:
  - Store saves in a predictable per-user location; consider Steam Cloud support later.
- Input:
  - The game must be playable with typing-first controls; if you add optional controller support, design it as an accessibility option, not the primary path.

## Store Page Plan
- Required materials (baseline):
  - Short description, long description
  - Capsule art (multiple sizes)
  - At least 5 screenshots
  - Trailer (optional but strongly recommended)
  - Tags and supported languages
- Messaging:
  - Lead with **typing-first strategy roguelite** and the day/night cadence.
  - Clarify that skill matters but settings prevent hard gating.

## Submission Checklist (baseline)
- Build uploaded and tested on a clean machine
- Store page assets uploaded and proofread
- Achievements (optional) deferred if not ready
- Steam Input configuration (optional) only if controller is supported
- Launch options defined (if multiple renderers)

## Post-launch Operations
- Patch cadence (e.g., weekly for first month)
- Bug triage SLA
- Community monitoring (Steam forums)

See also:
- `docs/keyboard-defense-plans/business/release/steam/DEPOT_PLAN_TEMPLATE.md`
- `docs/keyboard-defense-plans/business/release/steam/STEAM_INPUT_PLAN.md`
- `docs/keyboard-defense-plans/business/release/steam/STORE_ASSETS_SIZES.md`


