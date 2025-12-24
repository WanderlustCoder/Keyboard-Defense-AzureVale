# Release Checklist (MVP)

## Landmark: Build and QA
- [ ] Headless tests pass: `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`
- [ ] Godot export succeeds (Windows preset)
- [ ] No error spam in a fresh run
- [ ] New profile -> first battle works (smoke test)
- [ ] Mid-run save and resume works
- [ ] Accessibility toggles verified (contrast, motion, time multiplier)

## Landmark: Content integrity
- [ ] Content validation passes for all data packs
- [ ] No missing textures or audio references (asset manifest check)
- [ ] Version strings show correctly (app + content)

## Landmark: Performance
- [ ] Stress scene meets FPS targets on dev machine
- [ ] No memory growth in 5-minute idle and stress runs

## Landmark: Packaging
- [ ] Exported build runs on a clean machine
- [ ] Reset data option works and warns the user

## Landmark: Legal
- [ ] Third-party dependency licenses acceptable
- [ ] Fonts and audio libs include attribution if required
