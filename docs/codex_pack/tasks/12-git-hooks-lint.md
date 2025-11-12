---
id: git-hooks-lint
title: "Git hook automation for lint/test/docs consistency"
priority: P2
effort: M
depends_on: [type-lint-test]
produces:
  - scripts/hooks/installHooks.mjs
  - .husky/pre-commit or `.git/hooks/pre-commit` template
  - README updates describing local hook usage
status_note: docs/status/2025-11-15_tooling_baseline.md
backlog_refs:
  - "#80"
---

**Context**  
Tooling baseline restored lint/test/format coverage, but we still rely on developers
manually running the commands. Codex needs a deterministic pre-commit hook that runs
lint/tests/docs validators before code ever lands.

## Steps

1. **Install hook runner**
   - Add `scripts/hooks/installHooks.mjs` that writes `.git/hooks/pre-commit` (or configure Husky)
     to run our verification commands.
   - Ensure the script is invoked automatically after `npm install` (e.g., via `postinstall`) or via
     a documented `npm run hooks:install`.
2. **Define hook commands**
   - Pre-commit should run, in order:
     1. `npm run lint`
     2. `npm run test`
     3. `npm run codex:validate-pack`
     4. `npm run codex:validate-links`
     5. `npm run codex:status`
   - Fail fast on any non-zero exit.
3. **Documentation**
   - Update `apps/keyboard-defense/README.md` with a short "Git hooks" section describing how Codex
     (and contributors) install/run the hooks.
   - Reference this task from backlog item #80 (already marked) so the plan stays discoverable.
4. **Safety**
   - Provide an escape hatch for CI (e.g., skip hook when `SKIP_HOOKS=1`), documented in README.

## Acceptance criteria

- Running `npm run hooks:install` (or `npm install`) creates the hook script on any platform.
- Commits are blocked locally if lint/test/docs validation fails.
- README explains installation, commands run, and how CI bypasses the hook.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run the installer (`npm run hooks:install`) and manually execute `.git/hooks/pre-commit` to confirm
  the command chain runs successfully.
