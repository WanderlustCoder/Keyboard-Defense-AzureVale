# Backlog Slicing - Remaining Not-Started Items (2025-12-02)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

Context: Only #32, #36, and #38 remain in "Not Started". Each slice below is scoped to ship inside a single session with clear toggles, deliverables, and test hooks.

Update 2025-12-02: #32 is now implemented (see `2025-12-02_boss_archivist_mechanics.md`). Slices retained for phase follow-ups; #36 and #38 remain pending.

Update 2025-12-09: #38 slice 3 shipped (`2025-12-09_wave_preview_slice3.md`); #36 slice 3 closed with lane reservation (`2025-12-09_evacuation_events_slice3.md`).

## #32 Episode 1 Boss Mechanics (Archivist)
- **Slice 1: Boss scaffolding & gating**
  - Add `featureToggles.bossMechanics` and keep enabled by default.
  - Script a single boss wave definition (intro spawn only) plus intro banner/taunt event and deterministic seed for boss-only spawns.
  - Tests: boss wave loads without extras when toggle off; intro taunt emits once; spawn seed is deterministic.
- **Slice 2: Phase logic & defenses**
  - Implement rotating shield segments with timed vulnerability windows (e.g., 3 segments cycling every 8s) and a mid-fight break that strips shields at 50% HP.
  - Add a periodic shockwave that slows turrets on the boss lane and a vulnerability buff window after the shockwave.
  - Tests: shield rotation timers, vulnerability window damage increase, shockwave applying lane fire-rate debuff, phase transition triggers at 50%.
- **Slice 3: HUD/analytics polish**
  - Render segmented boss health bar + shield pips, surface phase labels in diagnostics, and log boss events into wave analytics (intro/phase-shift/finale).
  - Provide debug controls to skip to boss phase or despawn for fast iteration.
  - Tests: HUD/state sync for segments, analytics entries recorded, debug skip/despawn leaves state clean.

## #36 Evacuation Event (Long-form Rescue)
- **Slice 1: Event skeleton** (shipped) (see `2025-12-02_evacuation_events_slice1.md`)
  - Introduce an `evacuation` event type gated by `featureToggles.dynamicSpawns` + `evacuationEvents` sub-toggle.
  - Spawn rescue transport at wave midpoint with long-form word and countdown timer; emit start/resolve events.
  - Tests: event schedules deterministically by seed, timer ticks, and cancel respects toggle.
- **Slice 2: HUD/resolution flow** (shipped) in-engine/HUD (banner + gold resolution)
  - Add banner with timer/progress meter, reward on completion, and failure penalty (small breach or gold loss) on timeout.
  - Tests: banner state transitions, reward/penalty applied once, analytics entries for attempt/success/fail.
- **Slice 3: Coexistence & balance**
  - Ensure evacuation coexists with hazards/affixes/dynamic spawns without double-booking the lane; clamp to one active event.
  - Tests: overlapping events resolve gracefully, lane reserved flag clears on completion/reset, reduced-motion safe visuals.

## #38 Wave Config Schema/Editor
- **Slice 1: Schema expansion** (shipped) (`wave-config.schema.json`, tests)
  - Extend JSON schema to cover affixes, hazards, dynamic/evacuation events, and boss markers; ship fixtures for valid/invalid samples.
  - Tests: schema validation pass/fail cases, CI hook for schema check.
- **Slice 2: Authoring CLI**
  - Build `scripts/waves/editConfig.mjs` (or similar) to load/validate/pretty-print configs with prompts for common fields and export to `config.json`.
  - Tests: CLI round-trip (load/edit/save) in temp dir, validation errors bubble with codes, supports `--dry-run`.
- **Slice 3: Editor preview integration**
  - Add `npm run wave:preview` (or flag on existing dev server) that hot-reloads configs and renders upcoming spawns/hazards/affixes for designers.
  - Tests: preview render uses new schema fields, rejects invalid config with actionable error, respects feature toggles for hazards/affixes.

