# Roadmap

## How to read this roadmap
This roadmap lists the next priorities for the Godot project. Items are grouped into P0 (now), P1 (next), and P2 (later). Each item has a stable ID, status, planning references, and lightweight acceptance criteria.

## P0 - Now (stabilize and ship)

### P0-ONB-001 Onboarding and first-run guidance
Status: Done

Deliver a guided tutorial that teaches core commands and the day/night loop without mouse input.

Planning refs:
- `docs/ONBOARDING_TUTORIAL.md`
- `docs/plans/p0/ONBOARDING_PLAN.md`
- `docs/plans/p0/ONBOARDING_COPY.md`
- `docs/plans/p0/ONBOARDING_IMPLEMENTATION_SPEC.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/PLAYTEST_PROTOCOL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/PROJECT_MASTER_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`

Acceptance criteria:
- Tutorial auto-shows on first run and can be replayed on demand.
- Players complete a full day -> night -> dawn loop using typed commands.
- Completion is persisted in `user://profile.json`.
- Tutorial copy is finalized and matches the step plan in `docs/plans/p0/ONBOARDING_COPY.md`.

### P0-BAL-001 Balance curve and pacing
Status: In progress

Balance enemy stats, tower upgrades, and word length ranges for days 1-7 with deterministic seeds.

Planning refs:
- `docs/plans/p0/BALANCE_PLAN.md`
- `docs/plans/p0/BALANCE_TARGETS.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/plans/p1/SCENARIO_CATALOG.md`
- `docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md`
- `docs/PLAYTEST_PROTOCOL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/BALANCING_MODEL.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/CORE_SIM_GAMEPLAY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/PLAYTEST_PLAN.md`

Acceptance criteria:
- Day 1-3 nights are survivable without high WPM.
- Tower upgrades provide meaningful pacing relief without trivializing waves.
- Determinism tests remain stable for the same seed/actions.
- Day 1-7 numeric targets are documented and tied to scenario tolerances.

### P0-ACC-001 Accessibility and readability polish
Status: In progress

Improve panel readability, keyboard navigation, and accessibility toggles while keeping typing-first flow.

Planning refs:
- `docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/ACCESSIBILITY_VERIFICATION.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/UI_UX_ACCESSIBILITY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/ACCESSIBILITY_SPEC.md`

Acceptance criteria:
- Panels remain readable at 1280x720 and do not truncate critical info.
- Keyboard-only navigation works across settings, lessons, trend, and report panels.
- Accessibility preferences persist in `user://profile.json`.

### P0-EXP-001 Export pipeline (Windows)
Status: Not started

Document and validate a Windows export pipeline with a release checklist.

Planning refs:
- `docs/plans/p0/EXPORT_PIPELINE_PLAN.md`
- `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CI_CD_AND_RELEASE.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md`

Acceptance criteria:
- Windows export preset is documented and reproducible.
- Release smoke checklist is documented and completed once.
- Build output includes versioned folder and minimal run notes.

## P1 - Next (expand depth)

### P1-CNT-001 Content expansion (lessons and drills)
Status: Not started

Expand lesson packs and word curricula with data validation and clear pedagogy stages.

Planning refs:
- `docs/plans/p1/CONTENT_EXPANSION_PLAN.md`
- `docs/plans/p1/VISUAL_STYLE_GUIDE_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/CONTENT_DATA_PIPELINE_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/TYPING_PEDAGOGY.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CONTENT_PIPELINE_WORDPACKS.md`
- `docs/plans/SCHEMA_ALIGNMENT_PLAN.md`

Acceptance criteria:
- New lessons load and validate in headless tests.
- Word ranges stay aligned to lesson intent (short/medium/long).
- No RNG consumption added to lesson word selection.

### P1-MAP-001 Map and exploration depth
Status: Not started

Add deeper exploration events and map structure while staying deterministic.

Planning refs:
- `docs/plans/p1/MAP_EXPLORATION_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/COMPARATIVE_MECHANICS_MAPPING.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/RESEARCH_SUPER_FANTASY_KINGDOM.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/extended/EVENT_POI_SYSTEM_SPEC.md`

Acceptance criteria:
- New exploration events appear in log without breaking determinism.
- Map data remains data-driven and tested.
- UI can surface event outcomes clearly in the log.

### P1-QA-001 Testing and QA hardening
Status: In progress

Increase automated coverage and formalize manual QA gates for releases.

Planning refs:
- `docs/plans/p1/QA_AUTOMATION_PLAN.md`
- `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md`
- `docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md`
- `docs/plans/p1/SCENARIO_CATALOG.md`
- `docs/plans/p1/CI_AUTOMATION_SPEC.md`
- `docs/plans/p1/GDSCRIPT_QUALITY_PLAN.md`
- `docs/QUALITY_GATES.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/TESTING_QA_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/GODOT_TESTING_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/checklists/QA_CHECKLIST.md`
- `docs/plans/ARCHITECTURE_MAPPING.md`
- `docs/plans/SCHEMA_ALIGNMENT_PLAN.md`

Acceptance criteria:
- Headless tests cover core sim, UI, and data contracts.
- A manual QA checklist is maintained and used before releases.
- Test summary output is visible in scripts and logs.
- Phase 1 scenario harness runs selected JSON scenarios headless.

## P2 - Later (strategic expansion)

### P2-META-001 Meta progression and mastery
Status: Not started

Add lightweight persistent unlocks tied to lesson mastery without changing core balance.

Planning refs:
- `docs/plans/p2/META_PROGRESSION_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`

Acceptance criteria:
- Unlocks are cosmetic or optional, not required for success.
- Progression data remains deterministic and saveable.

### P2-HERO-001 Hero or faction layer
Status: Not started

Introduce optional hero or faction choices with small typing-linked bonuses.

Planning refs:
- `docs/plans/p2/HERO_SYSTEM_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md`

Acceptance criteria:
- Choices are readable and reversible without forcing rerolls.
- Balance and determinism remain stable.

### P2-LOC-001 Localization scaffolding
Status: Not started

Add a localization pipeline for UI strings and commands.

Planning refs:
- `docs/plans/p2/LOCALIZATION_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/LOCALIZATION_AND_LAYOUTS.md`

Acceptance criteria:
- Strings are centralized and can be exported for translation.
- UI layouts handle longer text without overlap.

### P2-AUDIO-001 Audio pass
Status: Not started

Add procedural or original SFX for typing and combat feedback.

Planning refs:
- `docs/plans/p2/AUDIO_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/AUDIO_EVENT_MAP.md`

Acceptance criteria:
- Audio events map to key gameplay actions.
- Asset audit rules are respected and documented.

## Inspiration / Research
- Summary: `docs/RESEARCH_SFK_SUMMARY.md`

## Testing and Quality Gates
- Headless tests must pass: `res://tests/run_tests.gd`.
- Smoke boot main scene headless without rendering.
- No sim regressions: deterministic outcomes remain identical for same seed/actions.
- README and help text updated for new commands or panels.
