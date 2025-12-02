# Dev Server One-Command Open - 2025-12-09

## Summary
- Added `npm run serve:open` to automatically start the dev server with `--no-build` when needed, reuse a healthy running instance, and open the game in the default browser. Supports `--force-restart` to replace an existing server before opening.
- Updated `apps/keyboard-defense/docs/DEVELOPMENT.md` to document the shortcut alongside the existing serve/monitor commands.

## Verification
- `cd apps/keyboard-defense && npm run serve:open`
- `cd apps/keyboard-defense && npm run serve:open -- --force-restart`

## Related Work
- `apps/keyboard-defense/scripts/openDevServer.mjs`
- `apps/keyboard-defense/scripts/devServer.mjs`
