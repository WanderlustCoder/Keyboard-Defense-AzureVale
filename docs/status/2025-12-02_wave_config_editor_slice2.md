# Wave Config Editor - Slice 2 (2025-12-02)
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## What shipped
- CLI `npm run wave:edit` (`scripts/waves/editConfig.mjs`) to validate, summarize, and generate wave configs for designers.
- Supports:
  - `--create-from-core` to export waves/turret slots/enemy tiers/feature toggles from compiled core config.
  - `--set-toggle key=value` (dynamicSpawns, eliteAffixes, evacuationEvents, bossMechanics).
  - `--summarize` to print wave stats (spawns/hazards/dynamic/evac/boss markers).
  - Schema validation against `schemas/wave-config.schema.json`; writes pretty JSON with `--output` (default `config/waves.designer.json`).
- Tests: `tests/waveConfigEditor.test.js` covers core export validity, toggle application, and summaries.

## How to use
- Generate from core: `npm run wave:edit -- --create-from-core --force`.
- Validate + summarize existing file: `npm run wave:edit -- --input config/waves.designer.json --summarize --no-write`.
- Toggle evacuation off: `npm run wave:edit -- --set-toggle evacuationEvents=false`.

## Next slice
- Add designer-friendly preview/authoring UI or dev-server hook to render upcoming waves/hazards/affixes/evac markers.

Update 2025-12-09: Preview UI shipped in `2025-12-09_wave_preview_slice3.md` (`npm run wave:preview` with filters/timelines and live reload).

