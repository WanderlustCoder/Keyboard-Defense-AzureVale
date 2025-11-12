---
id: schema-contracts
title: "Snapshot schema contracts as code"
priority: P2
effort: M
depends_on: []
produces:
  - analytics JSON Schema
  - CI validator step
status_note: docs/status/2025-11-08_gold_summary_cli.md
backlog_refs:
  - "#76"
---

**Steps (sketch)**

- Author a JSON Schema for `analytics_schema.md` (root fields + arrays).
- Validate CI artifacts with Ajv; assert `exportVersion` bumps when structure changes.
