# MonoGame Campaign Milestone M8 Plan

Status: Completed  
Last Updated: 2026-02-20  
Predecessor: `docs/MONOGAME_CAMPAIGN_M7_PLAN.md`

## Objective

Deliver final pre-release campaign polish and launch-readiness workflow alignment after M7 release-hardening completion.

## Scope

- Resolve remaining high-impact campaign UX polish items found during final sanity checks.
- Consolidate release notes inputs for campaign systems and telemetry-backed confidence.
- Lock repeatable RC verification workflow for pre-release and post-fix revalidation.

## Planned Workstreams

## M8-01 Final campaign UX polish pass

Status: Implemented in this slice

- Execute a focused campaign map usability pass (readability, cue timing, edge-case clarity).
- Apply only high-value, low-risk polish fixes.
- Re-run campaign-focused sanity checks after each accepted polish fix.
- Added launch-confirmation clarity banner with explicit countdown and controls.
- Added `Esc` behavior to cancel pending launch confirmation before leaving campaign map.

## M8-02 Release notes + evidence packaging

Status: Implemented in this slice

- Summarize campaign milestone outcomes (M1-M7) for release notes.
- Capture telemetry/checklist/test evidence references in one release-facing summary.
- Ensure artifact references remain current for RC and release handoff.
- Added initial release notes draft: `docs/CAMPAIGN_RELEASE_NOTES_M1_M8_DRAFT.md`.
- Added versioned RC release notes: `docs/RELEASE_NOTES_v0.1.0-rc1_2026-02-20.md`.

## M8-03 RC verification loop hardening

Status: Implemented in this slice

- Define a short repeatable RC verification loop:
- package builds
- run campaign-focused sanity sweep
- confirm readiness checklist remains PASS
- Keep go/no-go criteria explicit and easy to re-run after any late fix.
- Verified campaign-focused sanity sweep command:
- `dotnet test apps/keyboard-defense-monogame/KeyboardDefense.sln --configuration Release --filter "FullyQualifiedName~Campaign|FullyQualifiedName~Screens"`
- Latest result: `67 passed, 0 failed`.

Milestone completion note:

- M8 objectives are satisfied with final campaign-map UX polish, release-notes draft consolidation, and RC verification loop execution evidence.

## Out of Scope (M8)

- New gameplay system additions.
- Large campaign progression redesigns.
- Engine-level migrations or platform pipeline rewrites.
