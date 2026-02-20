# Project Documentation Index

## Current Project (MonoGame)

- `docs/MONOGAME_PROJECT.md` - Active project workflow, commands, and structure.
- `docs/MONOGAME_VERTICAL_SLICE_PLAN.md` - Completed first-playable milestone scope and acceptance checklist.
- `docs/MONOGAME_CAMPAIGN_M1_PLAN.md` - Completed campaign progression milestone backlog after vertical-slice completion.
- `docs/MONOGAME_CAMPAIGN_M2_PLAN.md` - Completed campaign hardening milestone for summary safety and retry consistency.
- `docs/MONOGAME_CAMPAIGN_M3_PLAN.md` - Completed campaign map readability and node-inspection milestone.
- `docs/MONOGAME_CAMPAIGN_M4_PLAN.md` - Completed campaign map selection-summary and inspection-parity milestone.
- `docs/MONOGAME_CAMPAIGN_M5_PLAN.md` - Completed campaign traversal and keyboard accessibility consistency milestone.
- `docs/MONOGAME_CAMPAIGN_M6_PLAN.md` - Completed campaign onboarding and launch/return-flow clarity milestone.
- `docs/MONOGAME_CAMPAIGN_M7_PLAN.md` - Completed campaign release-hardening and playtest-readiness milestone.
- `docs/MONOGAME_CAMPAIGN_M8_PLAN.md` - Completed campaign pre-release polish and launch-readiness milestone.
- `docs/CAMPAIGN_RELEASE_NOTES_M1_M8_DRAFT.md` - Draft release notes summary covering campaign milestones, validation baselines, and RC artifacts.
- `apps/keyboard-defense-monogame/KeyboardDefense.sln` - MonoGame solution entrypoint.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Core/` - Deterministic simulation/domain logic.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/` - Runtime game/render/input layer.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/` - Unit and integration/e2e-style tests.
- `apps/keyboard-defense-monogame/data/` - Game data and manifests.
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.catalog.json` - Full Pixel Lab catalog manifest.
- `apps/keyboard-defense-monogame/data/pixel_lab_manifest.active_runtime.json` - Runtime-shippable asset subset.
- `apps/keyboard-defense-monogame/data/schemas/pixel_lab_manifest.schema.json` - Pixel Lab manifest schema.
- `apps/keyboard-defense-monogame/docs/PIXEL_LAB_CONTRACT.md` - Pixel Lab integration contract.
- `apps/keyboard-defense-monogame/docs/VERTICAL_SLICE_BALANCE.md` - Single-wave baseline constants and scoring assumptions.
- `apps/keyboard-defense-monogame/data/vertical_slice_wave_profiles.json` - Node-specific single-wave profile overrides.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Core/VerticalSliceWaveDataTests.cs` - Node-profile resolution and fallback coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Core/VerticalSliceWaveProfileCatalogTests.cs` - Real-data profile catalog and node-mapping regression coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Progression/CampaignProgressionServiceTests.cs` - Campaign summary handoff, reward-once behavior, and outcome messaging coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapInputPolicy.cs` - Campaign map inspect-mode arbitration and compact-keyboard binding resolution policy.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapLaunchFlow.cs` - Campaign map keyboard launch confirmation flow and timeout handling.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapOnboardingPolicy.cs` - Campaign map first-time onboarding visibility and completion policy.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/RunSummaryNavigationPolicy.cs` - Run-summary return routing policy for campaign map vs main menu transitions.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Screens/CampaignMapTraversal.cs` - Deterministic campaign-map keyboard traversal and focus-visibility helper logic.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Services/CampaignMapReturnContextService.cs` - Summary-to-map return context handoff for campaign outcome reinforcement.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Game/Services/CampaignPlaytestTelemetryService.cs` - Runtime campaign-map playtest telemetry capture and persisted snapshot service.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapInputPolicyTests.cs` - Campaign map input policy coverage for mouse/keyboard arbitration and compact binding behavior.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapLaunchFlowTests.cs` - Campaign map launch confirmation flow coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapOnboardingPolicyTests.cs` - Campaign map onboarding policy coverage for first-show, step progression, and completion conditions.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignPlaytestTelemetryServiceTests.cs` - Campaign playtest telemetry counter persistence/regression coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapReturnContextServiceTests.cs` - Campaign summary handoff messaging/tone regression coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapScreenFlowIntegrationTests.cs` - Integrated campaign-map flow coverage combining input policy, launch confirmation, onboarding, and summary return context.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/RunSummaryNavigationPolicyTests.cs` - Run-summary campaign-map return policy and context publishing regression coverage.
- `apps/keyboard-defense-monogame/src/KeyboardDefense.Tests/Screens/CampaignMapTraversalTests.cs` - Traversal candidate, focus visibility, and scroll-clamp coverage for campaign-map input flow behavior.
- `docs/status/2026-02-20_campaign_map_reward_cues_checklist.md` - Focused UI checklist for first-clear reward cue rendering on campaign map nodes.
- `docs/status/2026-02-20_campaign_map_inspection_checklist.md` - Focused UI checklist for legend, hover details, and keyboard-only node inspection.
- `docs/status/2026-02-20_campaign_map_launch_return_clarity_checklist.md` - Focused UI checklist for keyboard launch confirmation and summary return-context reinforcement.
- `docs/status/2026-02-20_campaign_map_selection_strip_checklist.md` - Focused UI checklist for selection strip correctness and keyboard traversal behavior.
- `docs/status/2026-02-20_campaign_map_traversal_mode_checklist.md` - Focused UI checklist for linear/spatial traversal mode toggle behavior and runtime hinting.
- `docs/status/2026-02-20_campaign_map_onboarding_hints_checklist.md` - Focused UI checklist for first-time campaign onboarding hints and persistence behavior.
- `docs/status/2026-02-20_campaign_playtest_release_readiness_checklist.md` - Campaign playtest telemetry and release-readiness gate checklist.
- `apps/keyboard-defense-monogame/tools/pixel_lab/validate_manifest.py` - Manifest validation.
- `apps/keyboard-defense-monogame/tools/pixel_lab/build_texture_manifest.py` - Runtime manifest generation.
- `apps/keyboard-defense-monogame/tools/pixel_lab/split_runtime_subset.py` - Catalog/runtime subset split.
- `apps/keyboard-defense-monogame/tools/pixel_lab/curate_active_runtime.py` - Runtime-usage-based active subset curation.
- `apps/keyboard-defense-monogame/tools/pixel_lab/verify_active_in_catalog.py` - CI subset gate for active vs catalog.

## Archived Project (Godot)

- `docs/GODOT_PROJECT.md` - Archived Godot reference and migration boundary.
- `apps/keyboard-defense-godot/` - Archived Godot project retained for parity/reference only.

## Notes

- New features should target MonoGame.
- Godot remains in-repo and is not deleted, but is not the active implementation target.
