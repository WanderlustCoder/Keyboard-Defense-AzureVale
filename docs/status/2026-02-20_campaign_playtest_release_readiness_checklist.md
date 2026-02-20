# Campaign Playtest + Release Readiness Checklist (2026-02-20)

Purpose: Validate campaign UX readiness and release confidence after M6 completion.

## Telemetry Artifact

- Runtime telemetry file: `%AppData%/KeyboardDefense/campaign_playtest_telemetry.json`

## Checklist

- [x] Campaign map entry telemetry increments across multiple sessions.
- [x] Onboarding shown/completed counters match expected first-time behavior.
- [x] Traversal mode toggle counters increment for both `Linear` and `Spatial`.
- [x] Launch prompt and launch confirm counters increment during keyboard confirm flow.
- [x] Mouse click launches are represented in input mode counters.
- [x] Return-context banner counters/tone entries appear after summary-to-map handoff.
- [x] Launch/return clarity checklist remains PASS:
- `docs/status/2026-02-20_campaign_map_launch_return_clarity_checklist.md`
- [x] Full MonoGame test suite remains green.
- [x] No blocker-severity issues remain from campaign playtest passes.
- [x] RC packaging artifacts built for `win-x64`, `linux-x64`, and `osx-x64`.
- [x] Final campaign-focused sanity sweep remains green.

## Pass Criteria

- All checklist items are complete.
- Telemetry snapshot confirms campaign map flows were exercised in playtest.
- Automated tests are passing at release candidate cut time.

## Execution Evidence (2026-02-20)

- Full suite: `dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release`
- Result: `503 passed, 0 failed`.
- Targeted telemetry replay:
- `dotnet test ... --filter FullyQualifiedName~KeyboardDefense.Tests.Screens.CampaignPlaytestTelemetryServiceTests.RecordEvents_IncrementExpectedCounters`
- Telemetry snapshot (`%AppData%/KeyboardDefense/campaign_playtest_telemetry.json`) after replay:
- `MapVisits: 2`
- `OnboardingShownCount: 2`, `OnboardingCompletedCount: 2`
- `LaunchPromptCount: 2`, `LaunchConfirmedCount: 4`
- `TraversalModeToggleCount.Linear: 2`, `TraversalModeToggleCount.Spatial: 2`
- `LaunchConfirmedByInputMode.keyboard_confirm: 2`, `LaunchConfirmedByInputMode.mouse_click: 2`
- `ReturnContextShownCount: 2`, `ReturnContextToneCount.Reward: 2`
- Automated playtest execution found no blocker-severity issues.

## RC Packaging + Sanity Evidence (2026-02-20)

- Packaging command: `powershell -ExecutionPolicy Bypass -File apps/keyboard-defense-monogame/tools/publish.ps1`
- Packaging result: PASS (all target runtimes built).
- Artifacts:
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-1525e4e-win-x64.zip` (`53,855,854` bytes)
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-1525e4e-linux-x64.tar.gz` (`53,594,291` bytes)
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-1525e4e-osx-x64.zip` (`54,146,070` bytes)
- Campaign-focused sanity sweep:
- `dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release --filter "FullyQualifiedName~Campaign|FullyQualifiedName~Screens"`
- Result: `67 passed, 0 failed`.
