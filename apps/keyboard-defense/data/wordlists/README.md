# Wordlists & Lesson Banks

Lesson wordlists live here and are validated by `npm run lint:wordlists` (strict mode runs inside `npm run lint` and pre-commit). Guardrails:

- **Fields:** `id`, `lesson`, `words`, optional `weights`, `allowProper`, `introducedLetters`, `allowedCharacters`.
- **Gating:** `introducedLetters` limits which letters appear; `allowedCharacters` lists extra safe symbols (digits, punctuation). Keep lessons ASCII-only for ages 8-16.
- **Safety:** curate `denylist.txt` for forbidden terms; keep words lowercase unless `allowProper` is true.
- **Sorting:** keep `words` case-insensitively sorted to avoid noisy diffs (`--fix-sort` can auto-sort).
- **Lengths:** max 16 chars for single words, 32 for phrases (with spaces).

Add new lists alongside the lesson progression (home row → top row → bottom row → numbers → punctuation/mixed) and run `npm run lint:wordlists:strict` before committing.
