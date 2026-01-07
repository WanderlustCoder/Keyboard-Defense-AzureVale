# Planpack Triage

## Scope and rules
- The planpack is reference-only until items are promoted into authoritative docs.
- Authoritative docs are:
  - `docs/PROJECT_STATUS.md`
  - `docs/ROADMAP.md`
  - `docs/COMMAND_REFERENCE.md`
  - `docs/RESEARCH_SFK_SUMMARY.md`
  - `docs/CHANGELOG.md`

## Top planpack documents (actionable shortlist)
| Planpack path | Topic | Summary | Recommendation | Promote to target doc |
| --- | --- | --- | --- | --- |
| `planpack_2025-12-27_tempPlans/generated/PROJECT_MASTER_PLAN.md` | Roadmap alignment | Consolidates baseline features and milestone priorities with deterministic test expectations. | Adopt Now | `docs/ROADMAP.md` (P0-ONB-001, P0-BAL-001, P0-ACC-001, P0-EXP-001) |
| `planpack_2025-12-27_tempPlans/generated/CORE_SIM_GAMEPLAY_PLAN.md` | Core loop | Details day/night sim boundaries, typing feedback, and balance levers for the core loop. | Adopt Now | `docs/plans/p0/BALANCE_PLAN.md` and `docs/ROADMAP.md` (P0-BAL-001) |
| `planpack_2025-12-27_tempPlans/generated/TESTING_QA_PLAN.md` | QA strategy | Defines headless tests, data validation, and smoke boot expectations. | Adopt Now | `docs/ROADMAP.md` (P1-QA-001) |
| `planpack_2025-12-27_tempPlans/generated/UI_UX_ACCESSIBILITY_PLAN.md` | UI/UX + accessibility | Focuses on readability, keyboard-first navigation, and accessibility toggles. | Adopt Now | `docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md` and `docs/ROADMAP.md` (P0-ACC-001) |
| `planpack_2025-12-27_tempPlans/generated/CONTENT_DATA_PIPELINE_PLAN.md` | Content pipeline | Outlines lesson expansion, data schemas, and asset audit requirements. | Adopt Later | `docs/ROADMAP.md` (P1-CNT-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/ARCHITECTURE.md` | Architecture | High-level structure and system responsibilities; partly pre-Godot. | Reference Only | `docs/PROJECT_STATUS.md` (architecture snapshot) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/BALANCING_MODEL.md` | Balance model | Provides baseline combat numbers and tuning levers for pacing. | Adopt Now | `docs/plans/p0/BALANCE_PLAN.md` |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/TYPING_PEDAGOGY.md` | Learning design | Defines curriculum stages and prompt rules for accuracy-first progression. | Adopt Later | `docs/ROADMAP.md` (P1-CNT-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md` | Input UX | Documents keyboard-first principles and accessibility notes. | Adopt Now | `docs/plans/p0/ONBOARDING_PLAN.md` and `docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md` |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/GDD.md` | Game design | Full GDD with campaign map and battle loop concepts; partly pre-Godot. | Adopt Later | `docs/ROADMAP.md` (P1-MAP-001, P2-META-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/TECH_STACK.md` | Tech stack | Confirms Godot + data-driven content + headless tests stack. | Reference Only | `docs/PROJECT_STATUS.md` (tech stack note if needed) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/RESEARCH_SUPER_FANTASY_KINGDOM.md` | Research | SFK feature takeaways and inspiration notes. | Adopt Later | `docs/RESEARCH_SFK_SUMMARY.md` (already mapped) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/DATA_SCHEMAS.md` | Data contracts | Example schemas for lessons and drills; useful for future validation. | Adopt Later | `docs/ROADMAP.md` (P1-CNT-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/PROJECT_ROADMAP.md` | Long-term roadmap | Phase-based roadmap with content and UI refit highlights. | Reference Only | `docs/ROADMAP.md` (merge only) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/checklists/QA_CHECKLIST.md` | QA checklist | Practical manual QA steps and regression checks. | Adopt Later | `docs/ROADMAP.md` (P1-QA-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/PLAYTEST_PLAN.md` | Playtesting | Structured playtest objectives and participant profiles. | Adopt Later | `docs/plans/p0/BALANCE_PLAN.md` (test plan) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md` | Quality gates | Release readiness gates across repo hygiene, slice stability, and MVP content. | Adopt Now | `docs/ROADMAP.md` (P1-QA-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/ART_STYLE_GUIDE.md` | Art direction | Visual goals and palette constraints for readability-first UI. | Adopt Later | `docs/ROADMAP.md` (P1-ACC-001) |
| `planpack_2025-12-27_tempPlans/keyboard-defense-plans/assets/AUDIO_EVENT_MAP.md` | Audio map | Defines consistent SFX naming and triggers to avoid regressions. | Adopt Later | `docs/ROADMAP.md` (P2-AUDIO-001) |
| `planpack_2025-12-27_tempPlans/status/2025-12-27_ui_navigation_plan.md` | UI navigation | Archived pre-Godot note; mainly a pointer to older docs. | Outdated | None (reference only) |

## Key gaps uncovered
- Many planpack docs reference a pre-Godot structure; mappings to current `sim/` and `game/` split need care.
- No single place ties onboarding steps directly to current tutorial panel triggers.
- Balance targets lack explicit, testable scenario scripts for the day 1-7 curve.
- Asset and audio plans exist, but no current implementation plan for procedural placeholders in Godot.
- Data schemas are referenced but not yet aligned to the current JSON files under `apps/keyboard-defense-godot/data/`.
- Roadmap acceptance criteria need stable IDs and traceable refs (addressed in this milestone).
- QA notes mention different save filenames and pre-Godot flows.

## Promotions completed in this milestone
- `docs/ROADMAP.md` updated with P0/P1/P2 IDs, statuses, acceptance criteria, and planpack references.
- New P0 action plans created under `docs/plans/p0/` and linked from the roadmap:
  - `docs/plans/p0/ONBOARDING_PLAN.md`
  - `docs/plans/p0/BALANCE_PLAN.md`
  - `docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md`
  - `docs/plans/p0/EXPORT_PIPELINE_PLAN.md`
- New P1 action plans informed by planpack sources:
  - `docs/plans/p1/CONTENT_EXPANSION_PLAN.md` (from `generated/CONTENT_DATA_PIPELINE_PLAN.md`, `TYPING_PEDAGOGY.md`, `DATA_SCHEMAS.md`)
  - `docs/plans/p1/MAP_EXPLORATION_PLAN.md` (from `COMPARATIVE_MECHANICS_MAPPING.md`, `RESEARCH_SUPER_FANTASY_KINGDOM.md`, `extended/EVENT_POI_SYSTEM_SPEC.md`)
  - `docs/plans/p1/QA_AUTOMATION_PLAN.md` (from `generated/TESTING_QA_PLAN.md`, `GODOT_TESTING_PLAN.md`, `checklists/QA_CHECKLIST.md`)
  - `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md` (from `generated/CORE_SIM_GAMEPLAY_PLAN.md`, `preprod/PLAYTEST_PLAN.md`)
- New P2 action plans informed by planpack sources:
  - `docs/plans/p2/META_PROGRESSION_PLAN.md` (from `GDD.md`, `PROJECT_ROADMAP.md`)
  - `docs/plans/p2/HERO_SYSTEM_PLAN.md` (from `GDD.md`, `COMPARATIVE_MECHANICS_MAPPING.md`)
  - `docs/plans/p2/LOCALIZATION_PLAN.md` (from `preprod/LOCALIZATION_AND_LAYOUTS.md`)
  - `docs/plans/p2/AUDIO_PLAN.md` (from `assets/AUDIO_EVENT_MAP.md`, `assets/SOUND_STYLE_GUIDE.md`)
- Cross-cutting mappings added:
  - `docs/plans/ARCHITECTURE_MAPPING.md` (from `ARCHITECTURE.md`, `TECH_STACK.md`, `CORE_SIM_GAMEPLAY_PLAN.md`)
  - `docs/plans/SCHEMA_ALIGNMENT_PLAN.md` (from `DATA_SCHEMAS.md`, `CONTENT_DATA_PIPELINE_PLAN.md`)
- Execution-ready planning added:
  - `docs/QUALITY_GATES.md` (from `business/QUALITY_GATES.md`, `checklists/QA_CHECKLIST.md`)
  - `docs/PLAYTEST_PROTOCOL.md` (from `preprod/PLAYTEST_PLAN.md`, `checklists/BALANCE_PLAYTEST_SCRIPT.md`)
  - `docs/plans/p1/SCENARIO_CATALOG.md` (from `BALANCING_MODEL.md`, `CORE_SIM_GAMEPLAY_PLAN.md`)
  - `docs/plans/p0/P0_IMPLEMENTATION_BACKLOG.md` (from P0 action plans and planpack references)
- Implementation specs added:
  - `docs/plans/p1/SCENARIO_HARNESS_IMPLEMENTATION_SPEC.md` (from `generated/TESTING_QA_PLAN.md`, `keyboard-defense-plans/checklists/QA_CHECKLIST.md`)
  - `docs/plans/p1/CI_AUTOMATION_SPEC.md` (from `keyboard-defense-plans/preprod/CI_CD_AND_RELEASE.md`, `generated/TESTING_QA_PLAN.md`)
  - `docs/plans/p1/GDSCRIPT_QUALITY_PLAN.md` (from `generated/TESTING_QA_PLAN.md`, `keyboard-defense-plans/TECH_STACK.md`)
  - `docs/plans/p0/ONBOARDING_IMPLEMENTATION_SPEC.md` (from `keyboard-defense-plans/UX_CONTROLS.md`, `generated/PROJECT_MASTER_PLAN.md`)
