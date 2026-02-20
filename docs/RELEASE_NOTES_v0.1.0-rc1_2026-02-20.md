# Keyboard Defense (MonoGame) Release Notes

Tag: `v0.1.0-rc1`  
Date: `2026-02-20`  
Status: Release Candidate

## Summary

This release candidate consolidates campaign milestones `M1` through `M8`, including onboarding, keyboard traversal/accessibility, launch/return clarity, runtime telemetry, and RC packaging/readiness workflows.

## Changelog

## Added

- Campaign onboarding overlay with one-time persistence.
- Keyboard traversal modes (`Linear`/`Spatial`) and compact-keyboard bindings.
- Launch confirmation flow with countdown-based second-press confirm.
- Summary-to-map return context banner with tone-based messaging.
- Runtime campaign playtest telemetry and persisted snapshot output.
- Release-readiness and campaign UX checklist artifacts.

## Improved

- Campaign map readability cues, inspection parity, and selection-summary clarity.
- Focus visibility and keyboard-first campaign map navigation behavior.
- Campaign retry and run-summary handoff consistency.
- RC verification workflow with repeatable packaging and sanity sweep steps.

## Fixed

- PowerShell release script path construction in `apps/keyboard-defense-monogame/tools/publish.ps1`.

## Validation Baseline

- Full suite baseline: `dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release`
- Full suite result: `503 passed, 0 failed`
- Campaign/screen sanity baseline:
- `dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release --filter "FullyQualifiedName~Campaign|FullyQualifiedName~Screens"`
- Sanity result: `67 passed, 0 failed`

## RC Artifacts

- `apps/keyboard-defense-monogame/dist/KeyboardDefense-v0.1.0-rc1-win-x64.zip`
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-v0.1.0-rc1-linux-x64.tar.gz`
- `apps/keyboard-defense-monogame/dist/KeyboardDefense-v0.1.0-rc1-osx-x64.zip`
- `apps/keyboard-defense-monogame/dist/SHA256SUMS-v0.1.0-rc1.txt`

## Checksums

- `baa7da9f54cc0f6ce9cb59a7ac612a51e645320cb7839a59bd4068d1ae1d1c54`  `KeyboardDefense-v0.1.0-rc1-linux-x64.tar.gz`
- `aab6cd5314102cc581bfe2262eaf73c38544e340394fe7780a2c4ad95d6ef542`  `KeyboardDefense-v0.1.0-rc1-osx-x64.zip`
- `955a021bc1413bfc667eabd86f28c0842123f81ff6170811103c51ac661365c9`  `KeyboardDefense-v0.1.0-rc1-win-x64.zip`

## Artifact Sizes

- `KeyboardDefense-v0.1.0-rc1-win-x64.zip` - `53,856,252` bytes
- `KeyboardDefense-v0.1.0-rc1-linux-x64.tar.gz` - `53,594,716` bytes
- `KeyboardDefense-v0.1.0-rc1-osx-x64.zip` - `54,146,472` bytes

## Notes

- Draft notes source: `docs/CAMPAIGN_RELEASE_NOTES_M1_M8_DRAFT.md`.
- This document is the versioned RC notes artifact for `v0.1.0-rc1`.
