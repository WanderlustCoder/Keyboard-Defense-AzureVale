# Git Hook Automation - 2025-12-06

## Summary
- Pre-commit hook now delegates to a cross-platform Node runner (`scripts/hooks/runChecks.mjs`) that executes lint, test, Codex pack validation, status link validation, and Codex status generation from repo root.
- `npm run hooks:install` installs a generated `.git/hooks/pre-commit` that respects `SKIP_HOOKS=1`, verifies the runner exists, and works on Windows via `node` instead of bash-specific tooling.
- `HOOKS_FAST=1` (or `--fast` when invoking `runChecks.mjs`) now runs a reduced set (lint, format:check, Codex pack/link validation) for quick iterations; still honors `SKIP_HOOKS=1`.
- Added vitest coverage for the hook runner to ensure sequences stop on failures, honor dry-run, short-circuit when hooks are skipped, and respect fast mode.
- Backlog statuses updated to reflect existing engine benchmark and wave simulation harnesses.

## Verification
- `cd apps/keyboard-defense && npx vitest run hooks.test.js`
- `npm run hooks:install` (writes `.git/hooks/pre-commit` with the Node runner)

## Related Work
- `apps/keyboard-defense/scripts/hooks/runChecks.mjs`
- `apps/keyboard-defense/scripts/hooks/installHooks.mjs`
- `apps/keyboard-defense/tests/hooks.test.js`
- Backlog #80 (git hook automation)
