# Asset QA checklist

## Art QA
- [ ] All MVP ids exist (see `docs/keyboard-defense-plans/assets/ART_ASSET_LIST.md`)
- [ ] Tiles connect cleanly (roads and walls align on grid)
- [ ] Structures have distinct silhouettes (castle vs towers)
- [ ] Enemies readable at speed; runner and brute are distinguishable
- [ ] UI icons are legible at base size
- [ ] No high-frequency flicker in animations
- [ ] High-contrast mode works (if implemented)

## Audio QA
- [ ] No clipping (peaks are controlled)
- [ ] Mistake sound is informative but not harsh
- [ ] Correct sound rewards without being too loud
- [ ] Wave start/end are distinct
- [ ] Volume sliders work and persist
- [ ] Audio does not stutter when waves get busy

## Determinism and build QA
- [ ] Art generation with seed produces identical hashes (if pipeline used)
- [ ] Offline audio render (if used) is deterministic
- [ ] `apps/keyboard-defense-godot/scripts/run_tests.ps1` passes
- [ ] `apps/keyboard-defense-godot/data/assets_manifest.json` updated

## Human QA
- [ ] Play a full battle session and confirm typing comfort
- [ ] Check UI readability at 1280x720 and 1920x1080
