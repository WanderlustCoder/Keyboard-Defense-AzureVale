## Audio Intensity Slider - 2025-11-16

**Summary**
- Added an `Audio Intensity` slider to the pause/options overlay (backlog #54). Players can now scale battle SFX output between 50% and 150% without muting the stream entirely, and the control stays disabled when the master mute is active to avoid confusing states.
- The slider feeds a new `audioIntensity` field in player settings (version bumped to 11). The value persists across sessions, flows through the HUD bindings, and updates the deterministic `AudioContext` gain nodes by multiplying per-sound amplitudes before they hit the master bus.
- Extended the debug APIs/tests (`HudView` harness + Vitest coverage) to exercise the new control, ensuring the slider emits callbacks, reflects state changes, and mirrors the live percent labels.
- Debug sound controls now mirror the overlay: the developer toolbar exposes a matching `Audio intensity` slider plus readout, wired into the same `setAudioIntensity` flow so manual QA can tweak master volume and intensity without opening the pause menu.
- Analytics snapshots, telemetry exports, and the `analytics:aggregate` CSV now record `settings.soundIntensity`, so dashboards and automation can track both volume and intensity preferences per run.

**Next Steps**
1. Consider exposing intensity metrics in smoke artifacts/telemetry so we can correlate comfort settings with combo retention or session length. *(Codex: `docs/codex_pack/tasks/23-audio-intensity-telemetry.md`)*
