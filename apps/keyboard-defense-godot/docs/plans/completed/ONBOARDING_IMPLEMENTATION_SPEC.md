# Onboarding Implementation Spec (P0-ONB-001)

## Purpose and constraints
Implement the tutorial panel and step engine described in `ONBOARDING_PLAN` and `ONBOARDING_COPY` without changing deterministic sim rules. The tutorial must be typing-first and must not require the mouse.

References:
- `docs/plans/p0/ONBOARDING_PLAN.md`
- `docs/plans/p0/ONBOARDING_COPY.md`
- `docs/COMMAND_REFERENCE.md`
- `docs/QUALITY_GATES.md`

## Profile persistence contract
Stored in profile `ui_prefs.onboarding` (see `game/typing_profile.gd`):
- `enabled: bool`
- `completed: bool`
- `step: int`
- `ever_shown: bool`

Migration rules:
- Missing onboarding entry -> use defaults.
- Invalid values -> clamp to defaults.

## Tutorial panel UI contract
Proposed nodes (CanvasLayer):
- `TutorialPanel` (PanelContainer or ColorRect)
- `TutorialText` (RichTextLabel)
- `TutorialHint` (Label, optional)

Behavior:
- Auto-show if `enabled` and `ever_shown` is false.
- Does not steal focus from the command bar; refocus after updates.
- Visibility is controlled by commands and onboarding state.

## Step engine design
Step IDs and order must match `ONBOARDING_PLAN` and `ONBOARDING_COPY`.
Each step defines:
- Required phase (day/night/any)
- Expected commands or outcomes (e.g., `build farm` success)
- Completion rules based on state deltas (resources, buildings, phase changes)  

Suggested completion checks (tolerant, outcome-based):
- Use state fields: `phase`, `day`, `resources`, `buildings`, `night_wave_total`.
- Do not require exact text; check for intent outcomes.

## Tutorial copy source
Runtime copy is hardcoded in `game/onboarding_flow.gd` and must be kept in sync
with `docs/plans/p0/ONBOARDING_COPY.md` (source of truth).

## Commands and UX flows
Commands are UI-only (no sim changes):
- `tutorial` (toggle panel)
- `tutorial restart` (reset step to 0, `completed=false`)
- `tutorial skip` (mark completed, hide panel)
- Optional: `tutorial on|off` (toggle enabled flag)

## Edge cases
- Loading a save mid-tutorial: keep step, re-evaluate completion rules.
- If tutorial is skipped: `completed=true`, `enabled=false` optional.
- If panel overlaps UI: ensure readable at 1280x720.

## Test plan
Headless:
- Parser tests for tutorial commands.
- Step engine tests for completion rules (no scene instantiation).

Manual smoke:
- First run shows panel.
- Complete day -> night -> dawn step without mouse.
- Replay works after `tutorial restart`.
