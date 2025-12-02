# Wave Authoring & Preview Quickstart

This guide is for designers and engineers who need to edit wave configs, validate them, and visualize upcoming spawns/hazards/evacuation events.

## Generate or edit a designer config
- Export from core data with toggles:  
  `npm run wave:edit -- --create-from-core --force`
- Validate + summarize an existing file without writing:  
  `npm run wave:edit -- --input config/waves.designer.json --summarize --no-write`
- Flip feature toggles (e.g., disable evacuation events):  
  `npm run wave:edit -- --set-toggle evacuationEvents=false`

## Live preview
- Launch the preview server (opens browser):  
  `npm run wave:preview -- --config config/waves.designer.json --open`  
  or `npm run wave:preview:open` for the shorthand
- Features:
  - Timeline bars per wave with lane/event filters (spawns, hazards, dynamic, evac, boss).
  - Search for tiers/affixes/lanes/evac words; live-reloads on config/schema changes (SSE).
  - Inline validation errors so fixes refresh immediately.
  - Evacuation scheduling avoids lanes already booked by hazards or dynamic events; if all lanes are occupied, the evacuation skips that wave.

## Tests & checks
- Run the focused wave tooling tests:  
  `npx vitest run waveConfigEditor waveConfigPreviewRender evacuationEvent`
- Full suite (lint + format + build + coverage):  
  `npm run test`

## Tips
- Keep `config/waves.designer.json` checked in when intentionally changed so validation/previews stay aligned with CI.
- For quick iteration, keep `npm run wave:preview` running; save the config and the page will auto-refresh.
