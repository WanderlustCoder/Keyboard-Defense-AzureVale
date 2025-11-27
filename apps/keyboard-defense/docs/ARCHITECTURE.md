# Keyboard Defense Architecture

## Vision
- Merge a fast-paced typing trainer with a lane-based castle defense experience.
- Keep core simulation deterministic and testable by separating logic from rendering and input.
- Expose debug hooks so automated tests and manual QA can manipulate live state.

## Core Modules
- `GameController`: Orchestrates the main loop, routes ticks to systems, exposes lifecycle controls (start, pause, step, speed).
- `GameState`: Struct-like container encapsulating castle status, turret slots, enemies, projectiles, resources, and timers. Provides immutable snapshots for UI/tests.
- `Config`: Pure data describing castle progression, turret archetypes, projectile behaviors, enemy templates, wave schedules, and economy.
- `EventBus`: Lightweight publish/subscribe utility for gameplay events (`enemySpawned`, `wordCompleted`, `castleDamaged`, etc.). Used both by systems and debug observers.
- `EnemySystem`: Spawns and updates enemies along paths, issues damage on arrival, and reacts to typing hits.
- `TurretSystem`: Manages turret placement, upgrade paths, targeting logic, and projectile trajectories.
- `TypingSystem`: Accepts character input, tracks active word focus, resolves hits/misses, and routes damage to `EnemySystem`.
- `WaveSystem`: Produces enemy spawn batches, scaling difficulty and rewards. Integrates with `Config` to unlock new turret slots.
- `UpgradeSystem`: Handles castle/turret upgrades, validates resource costs, applies stat changes, and emits relevant events.
- `SoundManager`: Lightweight Web Audio facade that preloads synthesized cues and responds to projectile/combat events with spatialized feedback.
- `DebugAPI`: Facade that exposes introspection and mutation hooks (spawn enemies, inject resources, toggle systems) for tests and tooling.

## Rendering & Input
- Rendering lives in `rendering/CanvasRenderer.ts`, consuming read-only `GameState` snapshots each frame.
- `SpriteRenderer` synthesizes lightweight gradients/patterns so enemies and turrets have distinct silhouettes without requiring external assets.
- Starfield parallax uses a shared config/controller (`utils/starfield.ts`) so the canvas background drifts/tints based on wave progress + castle health; diagnostics surface drift/tint plus severity and `reducedMotionApplied` flags for CI evidence.
- Defeat burst animations now honor optional sprite atlases defined in the asset manifest: `AssetLoader` exposes defeat animation metadata, the renderer streams frames when available, and the player's "Defeat Animations" preference (auto/sprite/procedural) controls whether sprites or the procedural fallback are used.
- UI overlays (HUD, upgrade panels, typing feedback) are DOM-driven, decoupled from simulation data.
- Input adapters translate keyboard events into `TypingSystem` calls; alternative adapters (recorded scripts, automated typing) can be swapped in tests.

## Game Flow
1. `GameController.start()` seeds the initial wave, registers input adapters, and begins the animation frame loop (fallback to manual `step()` when paused or in tests).
2. Each tick:
   - Advance timers on `WaveSystem` and `EnemySystem`.
   - Resolve turret targeting/projectiles and apply damage.
   - Process typing buffer to determine hits.
   - Apply resource rewards, unlock upgrades, push UI events.
   - Emit consolidated events and produce a new immutable state snapshot.
3. Rendering layer consumes the snapshot; debug hooks can pause/resume/step or mutate state between frames.
4. Transient projectile entities are produced for visual systems only, allowing canvases to animate shots, beams, or burn zones without mutating enemy state.

## Upgrade & Economy Model
- Castle upgrades improve max health, regen, and unlock turret slots.
- Turret upgrades follow per-archetype tracks (e.g., Arrow, Arcane, Flame) adjusting damage, fire rate, and special effects (slow, burn).
- Rewards are based on word difficulty (length, rarity) and wave multipliers.

## Testing Strategy
- Unit tests (Node `--test`) target deterministic modules: typing resolution, wave scheduling, turret targeting, and upgrade economics.
- Integration tests instantiate `GameController` with a manual ticker to simulate discrete frames, verifying enemy spawn/kill loops.
- Debug hooks allow tests to inject words, advance frames, and assert against immutable state snapshots without DOM dependencies.
- Difficulty scaling tests validate how wave progress adjusts enemy templates, word bank buckets, and reward multipliers.

## Real-Time Hooks
- Global `window.keyboardDefense` object (guarded for non-browser tests) exposes:
  - `pause()`, `resume()`, `step(frames)`, `setSpeed(multiplier)`.
  - `spawnEnemy(opts)`, `grantResources(amount)`, `simulateTyping(text|sequence)`.
  - `setCastleLevel(level)`, `upgradeTurret(slot, archetype?)`, `damageCastle(amount)`.
  - `getState()` returning the latest snapshot.
- Diagnostics overlay is toggleable via debug API to surface wave band data, projectile counts, combo streaks, typing accuracy, and gold totals; it now summarizes completed waves and session stats without leaving the game view.
- HUD includes an “Upcoming Enemies” panel fed by `WaveSystem.getUpcomingSpawns`, indicating lane, wave, and ETA for the next few spawns (including early lookahead into the following wave). This keeps typing plans visible without opening dev tools.
- Audio hooks play synthesized cues for projectile launch, impact, breaches, and upgrades; they can be toggled or muted via debug controls.
- Forthcoming inspector widgets consume batched event logs to visualize combo streaks and wave pacing without DevTools.
- Hooks internally route through `DebugAPI`, ensuring validation and event emission stay consistent with production flow.

## Build & Tooling
- Pure TypeScript sources under `apps/keyboard-defense/src`, compiled to `dist/` via `tsc`.
- Static assets (HTML/CSS) under `apps/keyboard-defense/public`, referencing the built ES module bundle.
- Development server: `npm run start` triggers `scripts/devServer.mjs`, which builds the project, launches a detached `http-server`, and writes readiness details (`DEV_SERVER_READY`, `.devserver/state.json`, `.devserver/server.log`). Companion scripts (`npm run serve:status|serve:check|serve:logs|serve:stop`) interact with the running instance.
- Tests compiled alongside code (`dist/tests/**`) and executed with `node --test`.

