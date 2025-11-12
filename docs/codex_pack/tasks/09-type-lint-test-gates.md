---
id: type-lint-test
title: "Tighten type/lint/test gates"
priority: P1
effort: S
depends_on: []
produces:
  - tsc --noEmit CI step
  - ESLint step on scripts/tests
  - Vitest coverage
status_note: docs/status/2025-11-15_tooling_baseline.md
backlog_refs:
  - "#73"
---

**Steps (sketch)**

- Add `tsc --noEmit` validating against `public/dist/src` declarations (per tooling baseline).
- ESLint profile for `scripts/**/*.mjs` and tests; Prettier via lint-staged.
- `vitest run --coverage` in the Build/Test job.
## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run lint && npm run test -- --coverage (CI gate)

