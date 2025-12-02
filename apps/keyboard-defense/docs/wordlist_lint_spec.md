# Wordlist & Lesson Content Lint Specification

Guardrails for validating lesson/wordlist content before it reaches builds or CI. Audience: ages 8–16; target platforms Edge/Chrome.

## Scope
- Lesson JSON/CSV wordlists per unit (home row, top row, bottom row, numbers, punctuation, mixed words).
- Wave bank vocabulary and themed lists (enemies, events) that surface in typing gameplay.
- Tutorial prompts and drills that introduce letters/punctuation.

## Required Checks
- **Character set:** only ASCII letters a–z plus allowed punctuation per lesson; block symbols/emoji; no control characters.
- **Age safety:** reject profane/inappropriate words; maintain a denylist checked case-insensitively.
- **Length bounds:** words min 1 char, max 16 chars for lessons; phrases max 32 chars; configurable per list type.
- **Lesson gating:** each list may only include letters introduced up to that lesson index; number/punctuation lists gated by their unit flags.
- **Case rules:** lowercase only for lessons; allow capitalized proper nouns only in advanced lists flagged `allowProper`.
- **Uniqueness:** no duplicates within a list; optional cross-list uniqueness per unit to reduce repetition.
- **Sorting/stability:** enforce deterministic ordering (e.g., alpha) to keep diffs stable in Git and baselines.
- **Frequency weights (optional):** weights must sum to 1 (±0.01) when present; weights must be positive.
- **Themed banks:** enforce theme tags (e.g., `theme: "castle" | "weather" | "enemy"`); words must match allowed characters for the unit.

## JSON Schema Hints
- Fields: `id`, `lesson`, `words: string[]`, optional `weights: number[]`, optional `allowProper: boolean`, optional `theme: string`.
- Add `introducedLetters: string` or array to each lesson to validate gating.
- For wave banks, include `allowedCharacters` and `difficulty` so lints can tailor bounds per bucket.

## CLI Expectations
- Command: `npm run lint:wordlists` validates all lesson/word bank files; `npm run lint:wordlists:strict` runs with `--strict --out artifacts/summaries/wordlist-lint.json` and is invoked by `npm run lint`/CI/pre-commit.
- Flags: `--fix-sort` to auto-sort, `--strict` to treat warnings as errors, `--out <file>` to emit a JSON report (CI writes `artifacts/summaries/wordlist-lint.json`).
- Integrated into `npm run lint` (and therefore `npm run test`) so CI and hooks gate on content quality; keep the standalone command for focused edits or auto-sorting.

## Test Ideas
- Fixtures covering: forbidden character rejection, profanity denylist hit, lesson gating failure, duplicates, bad weights, out-of-range lengths, proper nouns blocked unless allowed, and theme validation.
- Golden-path fixtures for each unit to keep expected behavior stable as rules evolve.

## Integration Notes
- Keep denylist centralized (e.g., `data/wordlists/denylist.txt`) and versioned.
- Match the existing analytics/lint pattern: emit Markdown + JSON summaries, mirror other validators in `scripts/validate*.mjs`.
- Reduce churn: normalize whitespace, trim words, and downcase during lint processing before comparison.
