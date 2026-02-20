# MonoGame Campaign Milestone M7 Plan

Status: Completed  
Last Updated: 2026-02-20  
Predecessor: `docs/MONOGAME_CAMPAIGN_M6_PLAN.md`
Successor: `docs/MONOGAME_CAMPAIGN_M8_PLAN.md`

## Objective

Finalize campaign release hardening with runtime playtest instrumentation, a concrete readiness checklist, and execution-ready validation gates.

## Scope

- Add lightweight runtime telemetry for campaign-map interaction flows.
- Define release-readiness checklist criteria tied to campaign UX outcomes.
- Prepare M7 validation slices for manual playtest passes and release candidate gating.

## Planned Workstreams

## M7-01 Runtime playtest instrumentation and readiness checklist

Status: Implemented in this slice

- Added `CampaignPlaytestTelemetryService` for runtime counters and persisted telemetry snapshots.
- Instrumented campaign-map flows:
- map entry count
- onboarding show/completion
- traversal mode toggles
- launch confirmation prompts and confirms
- summary-return context banner display
- Added release-readiness checklist:
- `docs/status/2026-02-20_campaign_playtest_release_readiness_checklist.md`

Acceptance criteria:

- Telemetry file is persisted in `%AppData%/KeyboardDefense/campaign_playtest_telemetry.json`.
- Campaign flow interactions increment expected counters during runtime.
- Checklist defines explicit pass/fail gates for playtest/release confidence.

## M7-02 Campaign playtest execution and triage

Status: Implemented in this slice

- Execute focused campaign playtest passes using M7 checklist.
- Capture issues with severity/impact and triage decisions.
- Apply high-impact UX fixes discovered in playtest results.
- Executed automated playtest pass with telemetry regression coverage and persisted snapshot verification.
- No blocker-severity issues identified in current campaign-map flow.

## M7-03 Release candidate gate preparation

Status: Implemented in this slice

- Align campaign readiness artifacts with CI test state and packaging scripts.
- Lock release notes inputs for campaign UX and telemetry-backed confidence.
- Establish RC go/no-go checkpoint based on checklist outcomes.
- Readiness checklist now marked PASS in `docs/status/2026-02-20_campaign_playtest_release_readiness_checklist.md`.
- Full MonoGame suite baseline at `503 passed`.
- RC packaging artifacts generated via `apps/keyboard-defense-monogame/tools/publish.ps1` for win/linux/osx targets.
- Final campaign-focused sanity sweep baseline at `67 passed`.

Milestone completion note:

- M7 objectives are satisfied with runtime telemetry instrumentation, playtest/readiness evidence, and RC packaging + sanity gate outcomes documented.

## Out of Scope (M7)

- Rewriting campaign progression systems.
- Non-campaign feature expansion.
- New content authoring unrelated to campaign release hardening.
