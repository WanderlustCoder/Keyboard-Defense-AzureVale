# Changelog
## Milestone 102 (2026-02-05)
- Milestone 102: day_07 enemy_armored_hp_bonus increased to 4.
## Milestone 101 (2026-02-04)
- Milestone 101: day_07 enemy_armored_speed increased to 2.
## Milestone 100 (2026-02-03)
- Milestone 100: day_07 enemy_raider_speed increased to 2.
## Milestone 99 (2026-02-02)
- Milestone 99: day_07 enemy_scout_speed increased to 3.
## Milestone 98 (2026-02-01)
- Milestone 98: day_07 enemy_scout_armor increased to 1.
## Milestone 97 (2026-01-31)
- Milestone 97: day_07 enemy_raider_armor increased to 1.
## Milestone 96 (2026-01-30)
- Milestone 96: day_07 enemy_armored_armor increased to 2.
## Milestone 95 (2026-01-29)
- Milestone 95: day_07 enemy_scout_hp_bonus increased to 1.
## Milestone 94 (2026-01-28)
- Milestone 94: day_07 enemy_raider_hp_bonus increased to 2.
## Milestone 93 (2026-01-27)
- Milestone 93: day_07 enemy_armored_hp_bonus increased to 3.
## Milestone 92 (2026-01-26)
- Milestone 92: day_07 night wave totals increased to 7/9/11.
## Milestone 91 (2026-01-25)
- Milestone 91: tower build wood cost reduced to 4.
## Milestone 90 (2026-01-24)
- Milestone 90: wall wood cost reduced to 4.
## Milestone 89 (2026-01-23)
- Milestone 89: wall stone cost reduced to 4.
## Milestone 88 (2026-01-22)
- Milestone 88: tower build stone cost reduced to 8.
## Milestone 87 (2026-01-21)
- Milestone 87: farm food production increased to 3.
## Milestone 86 (2026-01-20)
- Milestone 86: lumber wood production increased to 3.
## Milestone 85 (2026-01-19)
- Milestone 85: quarry stone production increased to 3.
## Milestone 84 (2026-01-18)
- Increased midgame_caps_food on day 7 to 35.
- Added balance verify guardrail and tests for the day 7 food cap floor.
## Milestone 83 (2026-01-17)
- Moved midgame_food_bonus_day earlier to day 4.
- Added balance verify guardrail and tests for the updated bonus boundary.

## Milestone 82 (2026-01-16)
- Increased midgame_stone_catchup_min to 10.
- Added balance verify guardrail and tests for the stone catch-up minimum.

## Milestone 81 (2026-01-15)
- Increased midgame_caps_stone on day 7 to 35.
- Added balance verify guardrail and tests for the day 7 stone cap floor.

## Milestone 80 (2026-01-14)
- Added balance summary group outputs for wave, buildings, and midgame.
- Documented and tested the new summary variants.

## Milestone 79 (2026-01-13)
- Reduced tower upgrade costs to make midgame upgrades more accessible.

## Milestone 78 (2026-01-12)
- Buffed tower upgrade damage for levels 2 and 3 to offset earlier pacing ramps.
- Added balance verify guardrails for tower damage floors and shot progression.

## Milestone 77 (2026-01-11)
- Added balance summary group views for enemies and towers with deterministic output.
- Documented balance summary groups and unknown-group behavior.

## Milestone 76 (2026-01-10)
- Tuned day-based enemy hp_bonus ramp for armored/raider/scout across days.
- Added balance verify guardrails for hp_bonus monotonicity and day 7 minimums.

## Milestone 75 (2026-01-09)
- Added balance diff command for comparing current exports to saved baselines.
- Expanded balance diagnostics tests and command reference documentation.

## Milestone 74 (2026-01-08)
- Tuned day-based night wave totals for a steeper, consistent ramp across days.
- Added balance verify guardrails for wave offsets and day 7 minimum.

## Milestone 73 (2026-01-07)
- Added balance export metric groups with deterministic filtering and group-specific save files.
- Added balance summary command for compact pacing signals across days.
- Expanded balance diagnostics tests and command reference documentation.

## Milestone 72 (2026-01-06)
- Added balance diagnostics commands for verify/export with deterministic JSON output and save support.
- Implemented balance export payloads from existing pacing constants plus invariant checks.
- Added tests and docs covering balance export schema, determinism, and saved output.

## Milestone 71 (2026-01-05)
- Added repo-root verification scripts for tests and scenarios.
- Added app-local wrappers that delegate to the root scripts from the app folder.
- Documented and tested the dual-path verification workflow.

## Milestone 70 (2026-01-04)
- Updated bump_version scripts to align product/file versions across all export presets.
- Enforced file_version consistency checks in Windows export scripts with dry-run warnings and apply/package errors.
- Added tests/docs to cover preset-wide version consistency and new export script markers.

## Milestone 69 (2026-01-03)
- Added patch/minor/major increment modes to the version bump scripts.
- Added apply support for increment modes with strict current version validation.
- Documented increment usage and added tests for new bump script markers.

## Milestone 68 (2026-01-02)
- Added deterministic bump_version helper scripts with dry-run and apply modes.
- Scripts update VERSION.txt plus Windows export preset product/file versions.
- Documented version bump workflow and added script marker tests.

## Milestone 67 (2026-01-02)
- Added VERSION.txt as the single source of truth plus a version command.
- Bumped settings export to schema v4 with game version data.
- Added export script version consistency checks with docs/tests.

## Milestone 66 (2026-01-01)
- Added versioned Windows export packaging with manifest metadata inside the zip.
- Added export manifest generation and robust preset parsing for product metadata.
- Updated Windows export docs and tests for versioned outputs and manifest checks.

## Milestone 65 (2026-01-01)
- Added repo-root export wrappers plus PCK validation and packaging options.
- Hardened Windows export scripts to detect embed_pck and validate sidecar outputs.
- Documented packaging commands and deterministic output paths.

## Milestone 64 (2026-01-01)
- Added a Windows Desktop export preset with a deterministic build path.
- Added dry-run/apply export scripts for Windows builds.
- Documented Windows export prerequisites and commands.

## Milestone 63 (2026-01-01)
- Bumped settings export to schema v3 with engine, window, and panel visibility sections.
- Kept export deterministic and read-only while preserving existing keybind/conflict/resolve data.
- Updated command reference example to include the new export fields.

## Milestone 62 (2026-01-01)
- Added help topics/play/accessibility outputs with dynamic hotkey inserts and fixed topic listing.
- Expanded quick-start help tips to point to available topics alongside hotkeys.
- Documented the new onboarding help topics.

## Milestone 61 (2026-01-01)
- Added help hotkeys topic for a full rebindable hotkey listing with conflict summary.
- Updated settings verify hint gating to show onboarding guidance whenever conflicts are clear.
- Documented the new help hotkeys output.

## Milestone 60 (2026-01-01)
- Added help and help settings quick-start outputs with current hotkey summaries.
- Added a settings verify success hint when no conflicts are detected.

## Milestone 59 (2026-01-01)
- Added UI scale/compact preferences to settings export and bumped schema to v2.
- Kept export deterministic while preserving existing keybind/conflict/resolve sections.

## Milestone 58 (2026-01-01)
- Added settings export and settings export save for deterministic keybind diagnostics JSON output.
- Added structured export payload generation with conflict/resolve plan inclusion and tests for determinism.
- Documented settings export usage and example output.

## Milestone 57 (2026-01-01)
- Centralized control alias normalization in ControlsAliases and moved keybind parsing/formatting to ControlsFormatter.
- Removed keybind conflict parsing ownership to prevent circular dependencies.
- Added tests to enforce dependency direction while keeping alias behavior unchanged.

## Milestone 56 (2025-12-31)
- Hardened keybind parsing with deterministic alias normalization for safe keys and modifier synonyms.
- Added unit tests for alias parsing, round-trip consistency, and parse error handling.
- Documented key string alias handling in the command reference.

## Milestone 55 (2025-12-31)
- Canonicalized keybind persistence so modifier binds round-trip with stable ordering.
- Added tests for modifier save/load, legacy load compatibility, and deterministic keybind serialization.
- Documented modifier bind persistence in the command reference.

## Milestone 54 (2025-12-31)
- Enforced exact-match runtime handling for rebindable hotkeys so modifier binds remain distinct.
- Added tests covering Ctrl+key vs unmodified key matching and conflict isolation.
- Documented modifier bind runtime behavior in the command reference.

## Milestone 53 (2025-12-31)
- Added Ctrl+safe key fallback tier for keybind auto-resolve when the safe pool is exhausted.
- Synced conflict suggestions and resolution planning on the same tiered candidate list.
- Expanded tests/docs to cover modifier-safe fallback behavior.

## Milestone 52 (2025-12-31)
- Expanded keybind auto-resolve to use a safe key pool beyond F-keys, with deterministic fallback behavior.
- Synced conflict suggestions and resolver planning on the same safe key pool.
- Added tests and docs for fallback resolution scenarios when F-keys are saturated.

## Milestone 51 (2025-12-30)
- Added settings resolve (dry-run/apply) to auto-plan and apply keybind conflict fixes.
- Added deterministic resolve planning helpers with tests for apply and unresolvable cases.
- Updated command reference with resolve usage and examples.

## Milestone 50 (2025-12-30)
- Added unused function-key suggestions for keybind conflicts, plus a new settings conflicts command.
- Extended conflict diagnostics output and command reference documentation.
- Added tests for conflict suggestions and settings conflicts parsing.

## Milestone 49 (2025-12-30)
- Added keybind conflict detection with warnings on bind operations and startup.
- Extended settings verify diagnostics to report keybind conflicts with friendly names.
- Updated accessibility/quality docs and tests for conflict checks.

## Milestone 48 (2025-12-30)
- Added ACCESSIBILITY_VERIFICATION checklist for 1280x720 readability + keyboard-only flows, with settings verify diagnostics.
- Added rebindable hotkeys for settings/lessons/report, refreshed default function-key map, and documented new controls.
- Added early/mid enforced scenario wrapper scripts and updated QA guidance/tests.

## Milestone 47 (2025-12-30)
- Added `settings font` alias and updated settings/hotkey guidance for scale and keybinds.
- Added rebindable compact panels hotkey (F4), shifted history default to F5, and enabled typed keybind commands.
- Clarified compact mode effects in Settings and refreshed accessibility/QA documentation notes.

## Milestone 46 (2025-12-29)
- Added UI scale and compact panels settings with profile persistence and Settings panel cues.
- Applied compact rendering to lessons, trend/history, and wave panels for small screens.
- Added economy guardrails hint to help output and updated command reference.
- Updated tests for new settings commands and profile prefs, plus gitignore for scenario artifacts.

## Milestone 45 (2025-12-29)
- Added a one-time economy guardrails note and Settings Economy guidance.
- Added `docs/BALANCE_CONSTANTS.md` and linked it from balance planning docs.
- Added day7_defense_smoke scenario and updated catalog/tag references.
- Added scenario `--out-dir` artifacts with updated wrappers and CI/gate docs.
- Expanded tests for scenario CLI parsing and balance constants doc presence.

## Milestone 44 (2025-12-29)
- Added midgame balance levers (resource caps, low-food bonus, stone catch-up) to stabilize day 5/7 pacing.
- Updated midgame scenario baselines after tuning and kept early targets green.
- Expanded balance tuning notes with midgame iteration evidence and target deltas.
- Updated balance/quality docs with midgame tuning workflow and enforced target commands.

## Milestone 43 (2025-12-29)
- Added Day 5/7 midgame scenarios with tags and baseline/target expectations.
- Adjusted midgame scenario scripts (tower upgrades) and tightened day 5/7 baselines.
- Added tag exclusion filtering plus targets/metrics flags in the scenario CLI.
- Wrote scenario last_summary artifact and simplified wrapper output.
- Updated scenario catalog and quality gates to reflect mid/long suites.

## Milestone 42 (2025-12-29)
- Tuned explore rewards and updated P0 balance scenario scripts to resolve denied-command cases.
- Rebaselined P0 balance expectations and restored a green baseline suite with targets met.
- Added balance tuning notes and improved scenario wrapper output for targets/report paths.

## Milestone 41 (2025-12-29)
- Added baseline vs target expectations to scenario schema and reporting.
- Tightened P0 balance scenario baselines and introduced target ranges for tracking.
- Updated harness evaluation/CLI, docs, and tests for baseline/target handling.

## Milestone 40 (2025-12-29)
- Expanded scenario catalog to 12 scenarios with tags/priorities and P0 balance coverage.
- Added stop condition support, enriched metrics extraction, and tag/priority filtering in the harness.
- Updated scenario docs, roadmap/status, and QA gates to reflect Phase 2 coverage.

## Milestone 39 (2025-12-29)
- Added a headless scenario harness (loader, runner, evaluator, reporter) with CLI entrypoint.
- Added machine-readable scenarios plus wrapper scripts for CI-friendly runs.
- Updated QA docs, roadmap/status, and tests to reflect harness availability.


## Milestone 38 (2025-12-27)
- Added onboarding flow module with copy-based steps and snapshot-driven advancement.
- Wired tutorial panel auto-show, progression tracking, and profile persistence helpers.
- Added onboarding flow tests and synced command reference/roadmap/status docs.

## Milestone 37 (2025-12-27)
- Added implementation specs for scenario harness, onboarding, CI automation, and GDScript quality.
- Linked new specs into the roadmap, plans index, and planpack triage promotions.
- Added doc presence checks for the new specs.

## Milestone 36 (2025-12-27)
- Added BALANCE_TARGETS and linked it through balance planning and backlog tasks.
- Expanded Scenario Catalog with exact scripts, stop conditions, and CI selection guidance.
- Added ONBOARDING_COPY and a Visual Style Guide plan, with plan index and tests updated.

## Milestone 35 (2025-12-27)
- Added Quality Gates and Playtest Protocol docs for execution-ready QA and review.
- Added Scenario Catalog and P0 implementation backlog for balance/QA planning.
- Linked new planning docs in ROADMAP, plan index, and doc presence tests.

## Milestone 34 (2025-12-27)
- Added P1/P2 action plans plus cross-cutting architecture/schema plans.
- Updated ROADMAP planning refs and planpack triage promotions.
- Added doc presence checks for the new plan docs.

## Milestone 33 (2025-12-27)
- Added planpack triage doc and P0 action plans for onboarding, balance, accessibility, and exports.
- Rebuilt ROADMAP with stable IDs, statuses, acceptance criteria, and planpack references.
- Updated planning links in README/PROJECT_STATUS and added doc-presence tests.

## Milestone 32 (2025-12-27)
- Imported tempPlans planpack into docs/plans with preserved structure and notes.
- Added plan library index and linked it from README and PROJECT_STATUS.
- Added lightweight tests for plan library doc presence.
- Removed tempPlans staging folder after import.

## Milestone 31 (2025-12-26)
- Added onboarding tutorial panel with step tracking and replay commands.
- Persisted onboarding state in profile with first-run auto-show.
- Added onboarding tutorial doc and referenced it in roadmap/status.
- Updated help/command reference and tests for tutorial commands + doc presence.

## Milestone 30 (2025-12-26)
- Added command reference and research summary docs for onboarding and review.
- Integrated Super Fantasy Kingdom research files into docs with a curated mapping.
- Added a Codex summary template and linked doc set in README.
- Updated ROADMAP and PROJECT_STATUS to reference research influence.
- Added doc presence checks to headless tests.

## Milestone 29 (2025-12-26)
- Added explicit settings show/hide commands and help text.
- Added planning docs (PROJECT_STATUS and ROADMAP) and linked them in README.
- Added doc presence checks for planning docs.

