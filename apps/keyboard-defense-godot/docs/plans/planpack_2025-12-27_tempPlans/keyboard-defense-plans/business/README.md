# Keyboard Defense (Godot) - Optional Planning Packs (Delivery + Release + Evaluation + Community + Marketing)

This pack contains additional planning documents intended to be completed **before** major implementation work begins.

It is organized into five domains:

1. **Production backlog pack**  
   Epics, user stories, definition-of-done, quality gates, GitHub templates, and a delivery cadence.

2. **Store/release + compliance pack**  
   Build/release strategy, packaging checklists (Steam + itch.io), input remapping requirements, crash reporting stance, and privacy templates.

3. **Learning outcomes evaluation pack**  
   How to measure typing skill improvement (WPM/accuracy/consistency), evaluation protocol, consent/ethics notes, and telemetry plan (opt-in, local-first).

4. **Community/moderation pack** *(only if you accept user-generated content or run a community space)*  
   Community rules, UGC policy, reporting workflow, and incident response playbook.

5. **Branding/marketing pack**
   Key messages, store copy templates, Steam asset brief, screenshot plan, trailer beat sheet, press kit skeleton, and a devlog/content calendar.

## How to use this pack with Codex CLI

Recommended approach:
- Add `AGENTS.md` (from your earlier packs) to the repo root so Codex follows consistent constraints.
- Apply these plans in order:
  1) `docs/keyboard-defense-plans/business/BACKLOG_AND_DELIVERY.md` + `docs/keyboard-defense-plans/business/DEFINITION_OF_DONE.md`
  2) Release plans under `docs/keyboard-defense-plans/business/RELEASE_STRATEGY.md` and `docs/keyboard-defense-plans/business/release/`
  3) Evaluation docs under `docs/keyboard-defense-plans/business/LEARNING_OUTCOMES_EVALUATION.md`
  4) (Optional) Community docs under `docs/keyboard-defense-plans/business/COMMUNITY_GUIDELINES.md`
  5) Marketing docs under `docs/keyboard-defense-plans/business/BRAND_GUIDE.md` and `docs/keyboard-defense-plans/business/marketing/`

Codex prompt files are included under `docs/keyboard-defense-plans/business/prompts/` if you want Codex to implement repository plumbing (issue templates, CI skeleton, changelog conventions) before coding gameplay.

## Notes
- Platform requirements can change. These documents use durable patterns and explicitly tell you where to verify the latest platform-specific rules.
- Spreadsheet templates are represented as text specs:
  - `docs/keyboard-defense-plans/business/backlog/BACKLOG_WORKBOOK_SPEC.md`
  - `docs/keyboard-defense-plans/business/marketing/MARKETING_CALENDAR_SPEC.md`
- GitHub templates are stored under `docs/keyboard-defense-plans/business/templates/` until you decide to apply them to `.github/`.
- Nothing in this pack is legal advice.



