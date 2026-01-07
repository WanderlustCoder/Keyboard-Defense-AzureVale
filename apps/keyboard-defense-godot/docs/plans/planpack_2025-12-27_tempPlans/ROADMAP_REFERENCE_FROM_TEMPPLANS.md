# Roadmap

## Next Milestones (P0/P1)
1) Onboarding and first-run guidance (P0)
   - Add a guided first night tutorial and a short command primer.
   - Provide a minimal in-game checklist for day/night flow.
2) Balance pass for core loop (P0)
   - Tune enemy stats, tower costs/upgrades, and word length ranges.
   - Validate difficulty curve across days 1-7 with deterministic seeds.
3) Accessibility and readability polish (P1)
   - Improve panel readability, font sizes, and contrast in HUD/panels.
   - Add optional reduced motion and extra legibility toggles.
4) Content expansion (P1)
- Add more lessons and enemy variants.
- Expand building roster and adjacency effects in a controlled way.
- Add exploration events and road-based map expansion inspired by research.
5) Packaging and export pipeline (P1)
   - Document export presets and produce a Windows build workflow.
   - Add a smoke-test checklist for release builds.

## Inspiration / Research
- Summary: `docs/RESEARCH_SFK_SUMMARY.md`

## Backlog (P2)
- Meta progression (lightweight unlocks tied to lesson mastery).
- Hero/guardian layer with simple synergies and typing-linked buffs.
- Faction selection as a long-term unlock (non-gameplay-impacting initially).
- Audio cues for hits/misses and phase changes (procedural or licensed).
- More map variety and exploration events.
- Localization scaffolding for UI strings.

## Non-goals (For Now)
- Real-time combat (night loop remains turn-based and typing-driven).
- Networked features or online leaderboards.
- Third-party asset packs or licensed IP.

## Testing and Quality Gates
- Headless tests must pass: `res://tests/run_tests.gd`.
- Smoke boot main scene headless without rendering.
- No sim regressions: deterministic outcomes remain identical for same seed/actions.
- README and help text updated for new commands or panels.
