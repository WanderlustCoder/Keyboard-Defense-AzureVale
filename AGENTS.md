# AGENTS

Godot project root is `apps/keyboard-defense-godot` (res:// maps there).

- Deterministic sim logic in `res://sim/**` only (no Node/UI/scene dependencies)
- UI/game code calls sim via intents and renders events
- Add/maintain tests runnable headless via `godot --headless --path . --script res://tests/run_tests.gd`
- Do not add copied third-party assets; prefer procedural placeholders
- Before finalizing changes, attempt to run headless tests and a headless smoke boot
- When summarizing work, use LANDMARK sections:
  - LANDMARK A: Files changed
  - LANDMARK B: How to run
  - LANDMARK C: Tests executed (with results)
  - LANDMARK D: Next steps
- When adding art or audio, update `apps/keyboard-defense-godot/data/assets_manifest.json` so the audit stays green
- Use `apps/keyboard-defense-godot/docs/CODEX_SUMMARY_TEMPLATE.md` for required end-of-milestone headings and checklist
