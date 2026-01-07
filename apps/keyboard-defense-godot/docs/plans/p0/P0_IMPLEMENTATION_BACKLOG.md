# P0 Implementation Backlog

## P0-ONB-001 Onboarding and first-run guidance
Objective: Deliver a guided tutorial that teaches core commands, panels, and the day/night loop without mouse input. Ensure onboarding is repeatable and does not alter deterministic sim behavior.

Deliverables:
- Tutorial panel copy and step logic wired to typing-first actions.
- First-run auto-show with profile persistence.
- Replay/skip controls and log messages.

Task breakdown:
- ONB-T01: Review onboarding docs and validate step triggers | Files: `game/main.gd`, `docs/ONBOARDING_TUTORIAL.md`, `docs/plans/p0/ONBOARDING_COPY.md` | Tests: update tutorial tests | Complexity: M | Dependencies: none
- ONB-T02: Implement step completion checks for core commands (help/status/map) | Files: `game/main.gd`, `sim/parse_command.gd` | Tests: parser + tutorial unit tests | Complexity: M | Dependencies: ONB-T01
- ONB-T03: Add tutorial step for day planning (build/explore) | Files: `game/main.gd` | Tests: tutorial progression tests | Complexity: M | Dependencies: ONB-T01
- ONB-T04: Add tutorial step for night defense (typing) | Files: `game/main.gd` | Tests: tutorial progression tests | Complexity: M | Dependencies: ONB-T03
- ONB-T05: Add replay and skip flows with clear log output | Files: `game/main.gd`, `sim/parse_command.gd` | Tests: parser coverage | Complexity: S | Dependencies: ONB-T01
- ONB-T06: Add UI hints for panels and focus behavior | Files: `scenes/Main.tscn`, `game/main.gd` | Tests: smoke boot | Complexity: S | Dependencies: none
- ONB-T07: Update docs and CHANGELOG | Files: `docs/ONBOARDING_TUTORIAL.md`, `docs/CHANGELOG.md` | Tests: doc presence | Complexity: S | Dependencies: none
- ONB-T08: Manual smoke pass for first-run | Files: none | Tests: manual checklist | Complexity: S | Dependencies: ONB-T04
- ONB-T09: Apply tutorial panel copy from `ONBOARDING_COPY.md` | Files: `game/main.gd`, `scenes/Main.tscn`, `docs/plans/p0/ONBOARDING_COPY.md` | Tests: tutorial progression tests | Complexity: M | Dependencies: ONB-T01

Acceptance criteria:
- Tutorial auto-shows on first run and can be replayed on demand.
- Players complete a full day -> night -> dawn loop using typed commands.
- Completion is persisted in `user://profile.json`.

Links:
- `docs/plans/p0/ONBOARDING_PLAN.md`
- `docs/ONBOARDING_TUTORIAL.md`
- `docs/plans/p0/ONBOARDING_COPY.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/UX_CONTROLS.md`

## P0-BAL-001 Balance curve and pacing
Objective: Tune day 1-7 pacing so waves are survivable without high WPM, with tower upgrades providing meaningful relief. Keep determinism intact and measurable via fixed-seed scenarios.

Deliverables:
- Balance targets for day 1-7 (ranges and survival expectations).
- Scenario catalog entries used for regression checks.
- Updated tests covering deterministic outcomes for balance scenarios.

Task breakdown:
- BAL-T01: Define numeric balance targets and tolerances | Files: `docs/plans/p0/BALANCE_TARGETS.md` | Tests: doc presence | Complexity: S | Dependencies: none
- BAL-T02: Add scenario scripts and tolerances to catalog | Files: `docs/plans/p1/SCENARIO_CATALOG.md` | Tests: doc presence | Complexity: S | Dependencies: BAL-T01
- BAL-T03: Build a lightweight scenario runner plan | Files: `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md` | Tests: doc presence | Complexity: S | Dependencies: BAL-T02
- BAL-T04: Adjust enemy stats and tower costs (future implementation) | Files: `sim/enemies.gd`, `sim/buildings.gd` | Tests: determinism tests | Complexity: M | Dependencies: BAL-T01
- BAL-T05: Verify explore reward pacing | Files: `sim/apply_intent.gd`, `sim/map.gd` | Tests: reducer tests | Complexity: M | Dependencies: BAL-T04
- BAL-T06: Add balance regression tests (fixed seeds) | Files: `tests/run_tests.gd` | Tests: headless | Complexity: M | Dependencies: BAL-T04
- BAL-T07: Manual playtest session | Files: `docs/PLAYTEST_PROTOCOL.md` | Tests: manual | Complexity: S | Dependencies: BAL-T04
- BAL-T08: Update docs and changelog | Files: `docs/CHANGELOG.md`, `docs/PROJECT_STATUS.md` | Tests: doc presence | Complexity: S | Dependencies: none

Acceptance criteria:
- Day 1-3 nights are survivable without high WPM.
- Tower upgrades provide meaningful pacing relief without trivializing waves.
- Determinism tests remain stable for the same seed/actions.

Links:
- `docs/plans/p0/BALANCE_PLAN.md`
- `docs/plans/p0/BALANCE_TARGETS.md`
- `docs/plans/p1/SCENARIO_CATALOG.md`
- `docs/plans/p1/SCENARIO_TEST_HARNESS_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/BALANCING_MODEL.md`

## P0-ACC-001 Accessibility and readability polish
Objective: Improve panel readability and keyboard-first navigation so all core panels are usable at 1280x720 without truncation. Preserve typing-first flow and accessible defaults.

Deliverables:
- Readability pass on HUD, panels, and legends.
- Keyboard-only navigation verified for all panels.
- Accessibility preferences stored in profile.

Task breakdown:
- ACC-T01: Audit panel density and font sizes | Files: `scenes/Main.tscn`, `themes/` | Tests: smoke boot | Complexity: M | Dependencies: none
- ACC-T02: Add compact/expanded UI preferences | Files: `game/typing_profile.gd`, `game/main.gd` | Tests: profile tests | Complexity: M | Dependencies: ACC-T01
- ACC-T03: Ensure focus behavior and hotkeys work on all panels | Files: `game/main.gd`, `ui/command_bar.gd` | Tests: input tests | Complexity: M | Dependencies: ACC-T01
- ACC-T04: Improve legend clarity for grid and lessons | Files: `scenes/Main.tscn`, `game/main.gd` | Tests: smoke boot | Complexity: S | Dependencies: ACC-T01
- ACC-T05: Add docs for accessibility prefs | Files: `docs/PROJECT_STATUS.md`, `README.md` | Tests: doc presence | Complexity: S | Dependencies: ACC-T02
- ACC-T06: Manual accessibility checklist pass | Files: `docs/QUALITY_GATES.md` | Tests: manual | Complexity: S | Dependencies: ACC-T01
- ACC-T07: Add/adjust tests for UI prefs | Files: `tests/run_tests.gd` | Tests: headless | Complexity: S | Dependencies: ACC-T02
- ACC-T08: Update changelog | Files: `docs/CHANGELOG.md` | Tests: doc presence | Complexity: S | Dependencies: none

Acceptance criteria:
- Panels remain readable at 1280x720 and do not truncate critical info.
- Keyboard-only navigation works across settings, lessons, trend, and report panels.
- Accessibility preferences persist in `user://profile.json`.

Links:
- `docs/plans/p0/ACCESSIBILITY_READABILITY_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/generated/UI_UX_ACCESSIBILITY_PLAN.md`

## P0-EXP-001 Export pipeline (Windows)
Objective: Document and validate a Windows export pipeline with repeatable steps and a release checklist. Keep the process documented and compatible with headless test gates.

Deliverables:
- Export preset instructions and output structure.
- Release smoke checklist with pass/fail notes.
- Versioning notes aligned to quality gates.

Task breakdown:
- EXP-T01: Document export preset creation | Files: `docs/plans/p0/EXPORT_PIPELINE_PLAN.md` | Tests: doc presence | Complexity: S | Dependencies: none
- EXP-T02: Define release checklist (smoke + tests) | Files: `docs/QUALITY_GATES.md` | Tests: manual | Complexity: S | Dependencies: EXP-T01
- EXP-T03: Validate headless tests in export workflow | Files: `scripts/test.ps1`, `scripts/test.sh` | Tests: headless | Complexity: S | Dependencies: EXP-T01
- EXP-T04: Document versioning notes | Files: `docs/QUALITY_GATES.md` | Tests: doc presence | Complexity: S | Dependencies: EXP-T01
- EXP-T05: Update README with export pointer | Files: `README.md` | Tests: doc presence | Complexity: S | Dependencies: EXP-T01
- EXP-T06: Manual export smoke run | Files: none | Tests: manual | Complexity: M | Dependencies: EXP-T01
- EXP-T07: Record results in CHANGELOG | Files: `docs/CHANGELOG.md` | Tests: doc presence | Complexity: S | Dependencies: EXP-T06
- EXP-T08: Link to planpack release guidance | Files: `docs/plans/p0/EXPORT_PIPELINE_PLAN.md` | Tests: doc presence | Complexity: S | Dependencies: none

Acceptance criteria:
- Windows export preset is documented and reproducible.
- Release smoke checklist is documented and completed once.
- Build output includes versioned folder and minimal run notes.

Links:
- `docs/plans/p0/EXPORT_PIPELINE_PLAN.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/CI_CD_AND_RELEASE.md`
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/business/QUALITY_GATES.md`
