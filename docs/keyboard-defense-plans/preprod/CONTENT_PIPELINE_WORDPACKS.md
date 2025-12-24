# Wordpacks and Content Pipeline (Typing Curriculum)

This document defines how the game's typing content is authored, validated,
and consumed.

---
## Landmark: Design principles
1. Gameplay first, pedagogy integrated: typing drills feel like actions in the loop.
2. Data-driven: wordpacks are content files; code changes should not be required.
3. Layout-aware: packs declare intended keyboard layouts.
4. Safe licensing: use public domain or in-house generated lists; avoid copying proprietary lessons.

---
## Landmark: Wordpack types
### 1) Command vocabulary pack
Words and tokens used in the command UI:
- commands (`build`, `scout`, `repair`)
- building names (`wall`, `library`)
- abbreviations (`b`, `sc`)

Purpose: teach the game's interface and reduce friction.

### 2) Lesson pack (skill-building)
Structured sets by character groups:
- home row
- common bigrams/trigrams
- punctuation / numbers (optional)

Purpose: progressive typing instruction.

### 3) Combat prompt pack (stress inoculation)
Short phrases and mixed tokens used during battles:
- "seal breach"
- "reinforce gate"
- "frost rune"

Purpose: timed, higher pressure, adaptively scaled.

### 4) Exploration/event pack (low pressure)
Longer narrative snippets with fill-in tokens:
- "You find a {adjective} shrine..."

Purpose: varied typing without time pressure.

---
## Landmark: Wordpack JSON format (proposal)

File naming:
- `apps/keyboard-defense-godot/data/wordpacks/<locale>/<pack_id>.json`

Example (abridged):
```json
{
  "id": "home_row_1",
  "version": 1,
  "locale": "en-US",
  "layouts": ["QWERTY"],
  "kind": "lesson",
  "difficulty": {
    "target_wpm": 20,
    "max_time_multiplier": 1.4,
    "min_time_multiplier": 0.8
  },
  "allowed_chars": "asdfjkl; ",
  "tokens": [
    {"text": "as", "weight": 3},
    {"text": "dad", "weight": 2},
    {"text": "lass", "weight": 1}
  ],
  "tags": ["home-row", "intro"],
  "notes": "Introduce a/s/d/f and j/k/l/; slowly."
}
```

Key rules:
- `allowed_chars` defines what can appear in the pack (except `kind=command` where punctuation is allowed).
- `weight` is relative frequency.
- `difficulty.target_wpm` helps the adaptivity engine pick next packs.

---
## Landmark: Selection logic and progression
### Run-time selection
- Map and exploration phases primarily use:
  - `kind=command` + `kind=exploration`
- Battle phases primarily use:
  - `kind=combat`

### Player progression
- Track a typing profile:
  - WPM estimate
  - accuracy estimate
  - per-character error rates
  - common digraph errors
- Choose wordpacks using:
  - mastery threshold per pack
  - spaced repetition for weak characters
  - novelty budget (avoid too many new characters at once)

### Mastery thresholds (suggested)
- Learned: accuracy >= 92% across 3 sessions
- Mastered: accuracy >= 96% with stable WPM improvement across 5 sessions
- Revisit mastered packs periodically to prevent decay.

---
## Landmark: Scoring and feedback model
For each typed prompt:
- `accuracy = correct_chars / total_chars`
- `raw_wpm = (total_chars / 5) / elapsed_minutes`
- Optional correction penalty (configurable)
- Immediate feedback:
  - highlight error positions
  - show common mistake hints

Run report should include:
- WPM and accuracy
- top 5 problematic characters
- one recommended next pack

---
## Landmark: Content generation (safe approach)
Codex can create initial packs by:
1. generating synthetic word lists constrained by character sets
2. importing from a local text file the user provides
3. using public-domain sources the user explicitly provides

Avoid:
- copying proprietary typing lesson lists or scripts.

---
## Landmark: Validation and testing
- Validate wordpacks against a schema stored in this pack:
  - `docs/keyboard-defense-plans/preprod/schemas/wordpacks.schema.json` (to be created when implementing)
- Add a test that loads every pack and asserts:
  - tokens contain only allowed chars (unless pack overrides)
  - no empty tokens
  - weights are positive
  - locale and layout fields exist

Notes:
- Current lesson data lives in `apps/keyboard-defense-godot/data/lessons.json` and can be migrated into the wordpack format later.
