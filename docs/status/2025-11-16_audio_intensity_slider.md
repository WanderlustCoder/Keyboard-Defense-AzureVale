> Note: This document targets the retired web version (`apps/keyboard-defense`). The current Godot project lives at `apps/keyboard-defense-godot`; see `docs/GODOT_PROJECT.md` and `apps/keyboard-defense-godot/README.md` for active workflows.

## Audio Intensity Slider - 2025-11-16

**Summary**
- Added an `Audio Intensity` slider to the pause/options overlay (backlog #54). Players can now scale battle SFX output between 50% and 150% without muting the stream entirely, and the control stays disabled when the master mute is active to avoid confusing states.
- The slider feeds a new `audioIntensity` field in player settings (version bumped to 11). The value persists across sessions, flows through the HUD bindings, and updates the deterministic `AudioContext` gain nodes by multiplying per-sound amplitudes before they hit the master bus.
- Extended the debug APIs/tests (`HudView` harness + Vitest coverage) to exercise the new control, ensuring the slider emits callbacks, reflects state changes, and mirrors the live percent labels.
- Debug sound controls now mirror the overlay: the developer toolbar exposes a matching `Audio intensity` slider plus readout, wired into the same `setAudioIntensity` flow so manual QA can tweak master volume and intensity without opening the pause menu.
- Analytics snapshots, telemetry exports, and the `analytics:aggregate` CSV now record `settings.soundIntensity`, so dashboards and automation can track both volume and intensity preferences per run.

**Telemetry Refresh (2025-11-21)**
- `scripts/smoke.mjs` accepts `--audio-intensity` (percent or multiplier) and emits `artifacts/summaries/audio-intensity.(json|csv)` alongside gold summaries. Drift > `--audio-intensity-threshold` automatically flags the smoke summary.
- CI publishes the audio summary Markdown via `node scripts/ci/audioIntensitySummary.mjs`; Codex Portal links to the JSON/CSV fixtures plus the Markdown table.
- `analyticsAggregate.mjs` surfaces `audioIntensitySamples`, `audioIntensityAvg`, `audioIntensityDelta`, and correlation columns so dashboards can plot intensity vs combo/accuracy over time.
- Codex dashboard now includes an “Audio Intensity Summary” card populated from the latest `artifacts/summaries/audio-intensity.(json|csv)`, so reviewers can track requested vs recorded values, drift, and correlations without opening raw artifacts.
- The build/test job in `ci-e2e-azure-vale.yml` now appends the audio telemetry Markdown (via `node scripts/ci/audioIntensitySummary.mjs --file artifacts/summaries/audio-intensity.json`) to `$GITHUB_STEP_SUMMARY`, so reviewers see drift/correlation stats directly in GitHub even when they skip the Codex dashboard.

**Next Steps**
1. Extend `combo-accuracy-analytics` (#26) to consume `audioIntensity*` columns, surfacing at-risk ranges directly inside the analytics board.

