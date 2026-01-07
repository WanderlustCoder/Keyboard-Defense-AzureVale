# Architecture sketch (Keyboard Defense)

## High-level structure
- scenes/ - UI scenes (MainMenu, CampaignMap, Battlefield, KingdomHub).
- scripts/ - gameplay logic and scene controllers.
- scripts/tests/ - headless GDScript tests.
- data/ - JSON content (lessons, drills, map, upgrades, assets manifest).
- assets/ - art and audio; audited by the asset integrity test.
- themes/ - global UI theme and style resources.

## Core systems
- ProgressionState.gd: data loading, save state, rewards, upgrades.
- TypingSystem.gd: word tracking, accuracy/WPM, input validation.
- Battlefield.gd: drill scheduling, threat, buffs, battle results.
- BattleStage.gd: visual threat lane and hit feedback.
- GameController.gd: scene navigation and handoff state.

## Determinism and testing
- Keep drill scheduling and reward math deterministic for tests.
- Use data-driven JSON for content so tests can validate integrity.
- Add tests in scripts/tests/ for new systems and UI layout invariants.

## Data and asset validation
- data/assets_manifest.json defines expected size, dimensions, and rules.
- test_asset_integrity.gd enforces manifest completeness and budgets.
