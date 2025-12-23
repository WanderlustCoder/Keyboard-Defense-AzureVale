# Remote Visual Testing Quickstart - 2025-12-09
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Summary
- Documented a minimal workflow for capturing Playwright visual baselines from another device on the same network using the new host/port overrides in `serve:open` and `test:visual:auto`.

## How-To
1) From your dev machine (apps/keyboard-defense/):
   ```bash
   npm run serve:open -- --host 0.0.0.0 --port 4200 --force-restart
   ```
   - Starts/reuses the dev server bound to all interfaces on port 4200 and opens the browser locally.
2) From the same machine, run visual tests targeting that bind:
   ```bash
   npm run test:visual:auto -- --host 0.0.0.0 --port 4200 --grep hud-main
   ```
   - Adds `--update` to refresh baselines intentionally.
3) On the remote device, browse to `http://<dev-machine-ip>:4200/` to review the UI live if needed.

Notes:
- Both commands skip rebuilds (`--no-build`) for speed; run `npm run build` first if assets changed.
- Use `--keep-alive` on the visual runner if you want the server to stay up after tests.

## Related Work
- `apps/keyboard-defense/scripts/runVisualTests.mjs`
- `apps/keyboard-defense/scripts/openDevServer.mjs`
- `apps/keyboard-defense/docs/DEVELOPMENT.md`

