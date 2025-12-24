# Release Checklist (Generic)

Use this checklist for any public build (demo, Early Access, 1.0).

## Build
- [ ] Version bumped and tagged
- [ ] `.\apps\keyboard-defense-godot\scripts\run_tests.ps1` passes
- [ ] Deterministic asset generation ran successfully
- [ ] Build outputs created for target platforms
- [ ] `version.json` generated and included (e.g., `apps/keyboard-defense-godot/data/version.json`)

## Smoke Test (10 minutes)
- [ ] Launch game
- [ ] Start new run
- [ ] Typing input works immediately (no focus issues)
- [ ] Complete Day 1 actions
- [ ] Survive Night 1
- [ ] Save and quit
- [ ] Load save and continue
- [ ] Open settings and adjust time pressure
- [ ] Run recap shows typing stats

## Accessibility
- [ ] High contrast mode readable
- [ ] Reduced motion works
- [ ] Audio sliders work

## Store/Page
- [ ] Updated changelog / patch notes
- [ ] Screenshots updated if UI changed
- [ ] Known issues listed

## Post-release
- [ ] Monitor crash reports (local-first)
- [ ] Triage top issues
- [ ] Schedule hotfix if needed


