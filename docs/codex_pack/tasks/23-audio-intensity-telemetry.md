---
id: audio-intensity-telemetry
title: "Expose audio intensity metrics in smoke/telemetry"
priority: P2
effort: S
depends_on: []
produces:
  - updates to smoke artifacts capturing audio intensity
  - analytics summary fields correlating intensity with combo/session metrics
status_note: docs/status/2025-11-16_audio_intensity_slider.md
backlog_refs:
  - "#54"
  - "#79"
---

**Context**  
Players can now adjust audio intensity, but our smoke artifacts/telemetry don’t
record the setting. We want to correlate comfort settings with combo retention
and session length.

## Steps

1. **Smoke artifact enrichment**
   - Update `scripts/smoke.mjs` (and other relevant scripts) to log the current
     `audioIntensity` value into `artifacts/smoke/devserver-smoke-summary.json`.
   - Include history if the slider changes mid-run.
2. **Analytics**
   - Ensure `analyticsSnapshot` and `analytics:aggregate` output a field for
     audio intensity, plus computed correlations (e.g., average intensity vs combo).
3. **CI summary**
   - Extend `scripts/ci/emit-summary.mjs` to display the captured intensity data.
4. **Docs**
   - Update the audio slider status note once the metrics are exposed and mention
     how to interpret them.

## Acceptance criteria

- Smoke artifacts include audio intensity settings.
- Analytics exports include intensity stats for dashboards.
- CI summary highlights the intensity value for each run.

## Verification

- npm run lint
- npm run test
- npm run codex:validate-pack
- npm run codex:validate-links
- npm run codex:status
- Run `npm run serve:smoke -- --ci --json` and check the JSON contains intensity data.
