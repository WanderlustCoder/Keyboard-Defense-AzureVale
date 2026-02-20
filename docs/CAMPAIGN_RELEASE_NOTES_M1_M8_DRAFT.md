# Campaign Release Notes Draft (M1-M8)

Status: Draft  
Last Updated: 2026-02-20

Superseded by:

- `docs/RELEASE_NOTES_v0.1.0-rc1_2026-02-20.md`

## Release Summary

Campaign feature work progressed from baseline map/progression support through release-hardening and pre-release polish.

## Milestone Highlights

## M1 - Campaign progression baseline

- Established campaign node progression and map traversal baseline.
- Added initial reward and completion tracking hooks.

## M2 - Campaign hardening and retry consistency

- Stabilized summary handoff and retry flow consistency.
- Reduced outcome/return mismatches across run summary paths.

## M3 - Campaign map readability and inspection

- Improved node inspection clarity and map readability cues.
- Added first wave-profile visibility into map inspection context.

## M4 - Selection summary and inspection parity

- Added selection summary strip to keep inspected-node context visible.
- Improved parity between mouse and keyboard inspection flows.

## M5 - Traversal and keyboard accessibility consistency

- Added traversal mode support (`Linear`/`Spatial`) and runtime toggle cues.
- Added focus visibility retention and compact-keyboard traversal bindings.
- Expanded campaign map traversal/input regression coverage.

## M6 - Onboarding and launch/return clarity

- Added first-time campaign onboarding overlay with persistence.
- Added keyboard launch confirmation gating and summary return-context banner.
- Expanded regression coverage for summary handoff messaging and flow integration.

## M7 - Release hardening and playtest readiness

- Added runtime campaign playtest telemetry and persisted snapshot output.
- Completed campaign readiness checklist with PASS status and evidence.
- Produced RC packaging artifacts for `win-x64`, `linux-x64`, and `osx-x64`.

## M8 (Current) - Final pre-release polish

- Added launch-confirmation clarity banner with explicit countdown guidance.
- Added `Esc` cancel behavior for pending launch confirmations.
- M8-02 release notes/evidence packaging now in progress.

## Validation Snapshot

- Full MonoGame suite baseline: `503 passed, 0 failed`.
- Campaign/screen-focused sanity baseline: `67 passed, 0 failed`.
- Readiness checklist:
- `docs/status/2026-02-20_campaign_playtest_release_readiness_checklist.md` (PASS)

## RC Artifact Snapshot

- `apps/keyboard-defense-monogame/dist/KeyboardDefense-1525e4e-win-x64.zip`
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-1525e4e-linux-x64.tar.gz`
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-1525e4e-osx-x64.zip`

## Open Items Before Final Release Notes

- Confirm any M8 polish follow-up changes and lock final scope.
- Freeze final version label/tag for release bundles.
- Convert this draft to final release notes with version/date header.
