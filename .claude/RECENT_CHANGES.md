# Recent Changes

Log of recent changes made by Claude Code. Most recent first.

---

## 2026-01-10: Schema Updates

**Fixed all outdated schemas:**
- `assets_manifest.schema.json` - Added `category`, `source_svg`, `source_svg_frames` (string or array), `description`, `duration_ms`, `frames`, `frame_width`, `frame_height` to textures; Added `nineslice` as boolean or object; Added `margin_*` at texture level; Added `music` section; Added animation `duration_ms`
- `kingdom_upgrades.schema.json` - Added `gold_income` to effects
- `unit_upgrades.schema.json` - Added `resource_multiplier`, `gold_multiplier`, `gold_income`, `wave_heal` to effects
- `lessons.schema.json` - Added `sentence` mode, `sentences` property, `graduation_paths` section

All 7 schema-validated files now pass: `./scripts/validate.sh --quick` returns 8 passed, 0 failed.

---

## 2026-01-10: Development Infrastructure Setup

**Added schema validation system:**
- `scripts/validate_schemas.py` - Python script that validates JSON data files against schemas
- `scripts/validate.sh` / `validate.ps1` - Shell wrappers
- Validates all `data/*.json` files against `data/schemas/*.schema.json`
- Also checks sim/ directory for Node imports (architecture rule)

**Added .claude/ context directory:**
- `CURRENT_TASK.md` - Active work tracking
- `RECENT_CHANGES.md` - This file
- `DECISIONS.md` - Architecture decisions log
- `KNOWN_ISSUES.md` - Known quirks and edge cases
- `BLOCKED.md` - Current blockers

**Added pre-commit validation:**
- `scripts/precommit.sh` / `precommit.ps1` - Runs all validations before commit
- Validates schemas, runs headless tests, checks architecture rules

---

<!-- Template for new entries:

## YYYY-MM-DD: Short Description

**What changed:**
- Item 1
- Item 2

**Why:**
Brief rationale

**Files:**
- `path/to/file1`
- `path/to/file2`

---
-->
