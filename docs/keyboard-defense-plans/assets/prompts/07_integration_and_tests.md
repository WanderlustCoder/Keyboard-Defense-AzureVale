TASK: Integrate generated assets and add QA hooks.

DELIVERABLES:
1) Godot boot or preload:
   - load `apps/keyboard-defense-godot/assets/art/generated` textures or atlas
   - validate `data/assets_manifest.json` in dev builds
2) Add fallback texture generation for missing frames.
3) Wire AudioManager to key gameplay events:
   - typing engine, build placement, wave start/end, damage
4) Add a debug overlay command:
   - `assets audit` prints missing textures or missing SFX ids
5) Add docs:
   - `docs/keyboard-defense-plans/assets/GODOT_ASSET_INTEGRATION.md`
   - `docs/keyboard-defense-plans/assets/checklists/ASSET_QA_CHECKLIST.md` (if missing)

TESTS:
- a smoke test that boots the preload scene in headless mode, or validate loader config and manifest

LANDMARKS in final response (mandatory).
