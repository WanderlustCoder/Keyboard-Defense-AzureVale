# MonoGame Vertical Slice Plan

## Milestone Objective

Deliver a first playable MonoGame loop for Keyboard Defense:

- Start run from title/menu.
- Play one complete battle wave driven by typing input.
- Resolve to victory or defeat.
- Return to menu and replay.

## Definition of Done

1. Core gameplay loop is fully playable in `apps/keyboard-defense-monogame`.
2. Deterministic battle logic lives in `src/KeyboardDefense.Core` with tests.
3. MonoGame layer in `src/KeyboardDefense.Game` handles rendering, input, and orchestration only.
4. Existing Pixel Lab active runtime manifest remains the runtime art contract.
5. Vertical-slice data is JSON-driven under `apps/keyboard-defense-monogame/data`.
6. CI passes with MonoGame tests and Pixel Lab pipeline gates.

## Out of Scope (for this milestone)

- Campaign map and multi-node progression.
- Full economy/research/building systems.
- Advanced narrative systems and localization.
- New high-volume asset generation beyond current active runtime set.

## Ordered Task Backlog

1. `VS-001` Boot and scene flow
   - Implement title/menu -> battle -> result screen flow in MonoGame.
   - Add explicit restart-to-menu behavior after run completion.
2. `VS-002` Vertical-slice data contract
   - Add JSON for one wave profile (spawn cadence, enemy templates, hp, speed, rewards).
   - Add schema validation for the new data files.
3. `VS-003` Core wave simulation
   - Implement deterministic wave timer, spawn queue, enemy lane progression, and run clock.
   - Expose intent/event API consumed by the game layer.
4. `VS-004` Typing resolution core
   - Implement target selection and prefix matching for active words.
   - Emit typed-hit, miss, and word-complete events to the sim.
5. `VS-005` Combat and outcome rules
   - Apply damage, enemy defeat, castle/life damage, and win/lose conditions.
   - Add score summary payload for result screen.
6. `VS-006` MonoGame battle presentation
   - Render battlefield, enemies, active word prompts, HUD values, and result panel.
   - Bind rendering to current Pixel Lab runtime textures.
7. `VS-007` Input and UX pass
   - Route keyboard text input and control keys (pause/restart/confirm).
   - Ensure state transitions are stable under rapid input.
8. `VS-008` Persistence baseline
   - Save and load minimal profile fields needed by the slice (last score, runs played).
   - Add versioned save structure for future expansion.
9. `VS-009` Test coverage for slice systems
   - Add unit tests for typing resolution and wave/combat transitions.
   - Add one flow test covering full wave to victory and one to defeat.
10. `VS-010` Slice balancing pass
    - Tune default values for a 3-5 minute run with clear difficulty ramp.
    - Record baseline constants and assumptions in docs.

## Acceptance Checklist

- [ ] A run can be started, completed, and replayed without restart.
- [ ] Victory and defeat both reachable through normal play.
- [ ] Core sim behavior is deterministic under fixed seed inputs.
- [ ] Test suite covers critical state transitions for slice loop.
- [ ] No Godot project dependency in MonoGame runtime path.
- [ ] Pixel Lab manifest pipeline remains green in CI.

## Execution Notes

- Implement in the backlog order unless a blocking dependency forces resequencing.
- Keep each task shippable in small increments with tests at task completion.
- Treat Godot implementation as archived reference only for parity lookup.
