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
> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

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

## Implementation Notes

- **Runtime data flow**
  - Store the current slider value under `playerSettings.audio.intensity`.
  - Publish a `ui.audioIntensityChanged` event whenever the slider moves; include
    `{from, to, timestampMs, duringWave}` so analytics can correlate with accuracy
    drops or combo recovery.
  - Feed that value into the diagnostics overlay + pause menu so manual testing can
    confirm the setting that smoke automation applied.
- **Smoke + CI artifacts**
  - Extend the smoke harness to accept `--audio-intensity <0..100>` and default to
    the slider's midpoint. Persist both the configured target and the actual values
    observed during playback (`recordedIntensity`), plus a time series if the slider
    is exercised mid-run.
  - Emit a compact CSV (`artifacts/summaries/audio-intensity.csv`) with columns
    `scenario, intensity, avgCombo, sessionDurationMs, accuracy` so dashboards can
    plot correlations without post-processing.
  - Provide a `node scripts/ci/audioIntensitySummary.mjs` helper that renders the
    latest audio metrics (requested/recorded, averages, drift %, correlations) so
    CI and coders can embed the Markdown table in summaries without opening the raw JSON.
- **Analytics correlations**
  - Inside `analyticsAggregate`, track per-wave aggregates: average intensity,
    intensity delta vs previous wave, and derived stats (combo retention, miss rate).
  - Compute lightweight correlations (e.g., Pearson between intensity and combo) and
    include them in the JSON summary (`audioIntensityCorrelation` field).
- **CI / dashboard exposure**
  - Update the Codex dashboard to show a small card with the latest intensity,
    correlation coefficient, and combo delta so reviewers can spot regressions quickly.
  - Add a `--audio-intensity-threshold` flag that warns if the scripted intensity deviates
    from expected by more than N %, catching automation drift.
- **Docs & playbooks**
  - Document the workflow (`npm run analytics:audio`) in `CODEX_GUIDE.md` and add a
    “Audio metrics” checklist to the UI/Gameplay playbook.
  - Update `docs/status/2025-11-16_audio_intensity_slider.md` once telemetry lands,
    noting where to find the dashboards/artifacts.

## Deliverables & Artifacts

- Updated smoke artifact(s):
  - `artifacts/smoke/devserver-smoke-summary.json` (with intensity fields)
  - `artifacts/summaries/audio-intensity.csv|json`
- `scripts/ci/audioIntensitySummary.mjs` (optional helper) that renders Markdown for CI.
- Analytics fixture updates capturing the new fields (`docs/codex_pack/fixtures/audio-intensity/*.json`).
- Doc updates across `CODEX_GUIDE.md`, `CODEX_PLAYBOOKS.md`, `docs/codex_dashboard.md`, and the Nov-16 status note.

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






