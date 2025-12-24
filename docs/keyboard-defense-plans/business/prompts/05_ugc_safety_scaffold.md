# Codex Milestone - UGC Safety Scaffolding (Only If UGC Enabled)

## Objective
Prepare scaffolding for UGC moderation and validation.

## Tasks
1) Add `docs/keyboard-defense-plans/business/UGC_POLICY.md` and `docs/keyboard-defense-plans/business/MODERATION_WORKFLOW.md` into repo.
2) If the game supports importing content packs:
   - enforce schema validation and safe defaults
   - add a `content-lint` CLI script that validates packs
3) Add a `Report content` stub UI that outputs a local report file (no network).

## Constraints
- No online community integrations.
- No upload features unless explicitly requested later.

## Acceptance
- Content packs cannot crash the game; invalid packs show actionable errors.
- Report file is created locally with minimal metadata.



