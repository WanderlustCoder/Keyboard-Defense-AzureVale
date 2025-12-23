# Wave Config Schema – Slice 1 (2025-12-02)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## What shipped
- Added `schemas/wave-config.schema.json` covering waves, spawns, hazards, dynamic events, evacuation events, boss markers, feature toggles, and turret slot references.
- Vitest coverage ensures valid configs with hazards/dynamic/evacuation/boss flags pass and malformed configs fail (`tests/waveConfigSchema.test.js`).

## How to use
- Validate designer-authored configs via Ajv: `node -e "import Ajv from 'ajv'; import schema from './schemas/wave-config.schema.json' assert { type: 'json' }; const ajv=new Ajv({strict:false}); console.log(ajv.validate(schema, JSON.parse(require('fs').readFileSync('wave.json'))));"`.
- Use `schema` to drive future CLI/editor tooling (slice 2+ in backlog).

## Next slices
- Build authoring CLI (`scripts/waves/editConfig.mjs`) with load/validate/pretty-print. ✅ now available via `npm run wave:edit`.
- Add live preview hook in dev server to render upcoming waves/hazards/affixes/evac markers.

