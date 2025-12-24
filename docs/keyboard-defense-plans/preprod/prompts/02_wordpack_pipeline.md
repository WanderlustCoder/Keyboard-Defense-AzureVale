# Codex Milestone: Wordpack Pipeline and Layout-Aware Selection

## Landmark: Objective
Implement the runtime wordpack pipeline described in
`docs/keyboard-defense-plans/preprod/CONTENT_PIPELINE_WORDPACKS.md`:
- load packs from JSON
- validate against schema
- provide selection APIs for map/battle prompts
- track mastery and error stats

## Landmark: Tasks
1) Define types
   - `Wordpack`, `WordToken`, `PackKind`, `LayoutId`, and related structs
2) Implement loader and validator
   - `apps/keyboard-defense-godot/scripts/content/wordpacks.gd`
   - Validate with schema at load time (dev) and via tests
3) Implement selection logic
   - `select_pack_for_phase(phase, typing_profile, settings)`
   - Use simple heuristics first:
     - prefer packs matching locale and layout
     - if accuracy is low, select easier or prior pack
     - if a character error spikes, schedule a pack containing that character
4) Implement typing profile updates
   - Update rolling WPM and accuracy
   - Update per-char error map
   - Update per-pack mastery counters
5) Tests
   - Loads all packs
   - Selection is deterministic with a fixed profile and seed
   - Mastery thresholds behave as expected

## Landmark: Verification steps
- `.\apps\keyboard-defense-godot\scripts\run_tests.ps1`

## Landmark: Deliverables
- Content pipeline modules
- Deterministic selection logic
- Tests

Summarize with LANDMARKS:
- A: New modules and types
- B: Selection rules
- C: Tests added
