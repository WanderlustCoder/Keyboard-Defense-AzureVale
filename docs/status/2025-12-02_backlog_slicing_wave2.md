# Remaining Backlog Slices (Not Started Items)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

Context: Break down the remaining "Not Started" Season 1 backlog items (31, 32, 35, 36, 37, 38, 40) into shippable slices with clear outputs, toggles, and test hooks.

## #31 Elite Enemy Affixes (slow aura, shielded, armored)
- Add an affix catalog (id/label/rules/values) plus a `featureToggles.eliteAffixes` gate and debug/menu toggle.
- Decorate spawns with affixes, surface badges in wave preview/HUD, and record analytics (per-wave affix mix + active lane modifiers).
- Implement effects: slow aura reduces turret fire-rate on that lane; armored reduces turret damage taken; shielded injects bonus shield when absent. Guard stacking and provide copy for tooltips/logs.
- Tests: spawn decoration determinism by seed, aura lane throttling, armored mitigation, shield injection, HUD preview badge rendering.

## #32 Episode 1 Boss Mechanics
- Script boss phases (intro, mid-fight, finale) with bespoke mechanics: e.g., rotating shield, vulnerability window, and burst taunts.
- Add boss intro banner, health bar segments, and defeat/victory hooks; ensure countdown/analytics remain deterministic.
- Tests: scripted phase timeline, shield/vulnerability gating, intro messaging emits once per run.

## #35 Dynamic Spawn Scheduler (mini-events)
- Create a scheduler that can inject micro-events (skirmish, gold-runner, shield-carrier) based on wave time and rng seed.
- Surface scheduled injections in diagnostics/logs and allow enable/disable via feature toggle.
- Tests: deterministic queue by seed, respecting wave duration/slot limits, preview summaries for upcoming injected events.

## #36 Evacuation Event (long-form typing rescue)
- Author an event template: trigger at wave midpoint, spawn a rescue transport with long-form words and countdown timer.
- Add HUD banner + progress meter, reward bundle on success, and fail condition on countdown expiry.
- Tests: timer flow, reward grant, analytics entries (attempts/success/fail) and coexistence with normal spawns.

## #37 Lane Hazards (fog/storms)
- Define hazard types (fog: obscures words; storm: accuracy penalty + shaky HUD) with lane-scoped timers and visuals.
- Add hazard scheduler tied to waves with a toggle; render lane overlays and HUD warnings; apply accuracy/fire-rate impacts safely with reduced-motion guards.
- Tests: hazard timing, UI flags per lane, effect clamping (no negative fire-rate/accuracy), reduced-motion bypass.

## #38 Wave Config Schema/Editor
- Extend JSON schema to cover waves/affixes/hazards and add validation fixtures for design handoff.
- Build a lightweight editor (CLI or form) to author/preview wave configs with schema validation and sample export to `config.json`.
- Tests: schema validation failures/success, editor round-trip (load-edit-save), and CI hook wiring.

## #40 Practice Dummy (debug DPS target)
- Add a `practice-dummy` enemy tier with high health/no damage, spawned via debug toggle or practice mode CTA.
- Render dummy differently in HUD/wave preview; log DPS per slot against dummy and allow manual despawn/reset.
- Tests: spawn/despawn flow, DPS accumulation against dummy, and ensuring dummy does not breach or damage the castle.

## Next Action
- Implement #31 elite affixes first under the new toggle, then iterate through remaining slices.

