# Localization Plan

Roadmap ID: P2-LOC-001 (Status: Not started)

## Localization scope
- UI strings, help text, panel headings, and logs.
- Lesson content and word prompts (locale-specific charsets).
- Command keywords may remain English; explore alias support later.

## Input implications
- Non-Latin layouts require alternate lesson charsets.
- IME support and input composition must not break typing feedback.
- Consider layout-specific word banks (QWERTY vs AZERTY).

## Lesson strategy per locale
- Maintain a lesson pack per locale with charset and length ranges.
- Avoid forcing translation of enemy words unless the locale supports it.

## Fonts and rendering risks
- Ensure fonts cover target glyph ranges.
- UI layout must handle longer strings without overlap.

## Acceptance criteria
- Locale switch does not break command parsing.
- Lesson packs load per locale and pass validation tests.
- UI remains readable at 1280x720 across locales.

## Test plan
- Add unit tests for locale lesson loading.
- Manual UI smoke in at least one non-English locale.

## References (planpack)
- `docs/plans/planpack_2025-12-27_tempPlans/keyboard-defense-plans/preprod/LOCALIZATION_AND_LAYOUTS.md`
