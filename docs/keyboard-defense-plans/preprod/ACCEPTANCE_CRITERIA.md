# Acceptance Criteria and Definition of Done

This document defines what "done" means for the first playable, Vertical Slice,
and MVP so Codex has unambiguous targets.

---
## Landmark: Core product goal
Ship a typing-first kingdom defense experience where the player grows a realm
through typed choices and survives battles with typed interventions. The loop is
edutainment: it teaches typing skills without blocking progress.

---
## Landmark: Non-goals (explicit)
- No art or audio derived from third-party copyrighted assets.
- No requirement for mouse-driven micro; keyboard-only remains viable.
- No competitive multiplayer in MVP.

---
## Landmark: Vertical Slice (VS) - must-have acceptance criteria

### Gameplay loop
- One complete Map -> Battle -> Results -> Kingdom loop playable in ~5-8 minutes.
- Map/kingdom phase includes:
  - At least 3 upgrade options (kingdom or units).
  - At least 3 map nodes with unlock requirements.
- Battle phase includes:
  - A timed wave with at least 2 threat archetypes.
  - At least 2 typed interventions that materially affect survival
    (e.g., slow threat, heal castle, buff typing power).
- Run ends with a clear outcome: success, failure, or retreat.

### Typing-first control
- 90%+ of gameplay actions achievable via keyboard only.
- A discoverable help system:
  - `help` lists commands and examples.
  - Optional autocomplete or suggestions for commands.
- At least one tutorial segment that teaches:
  - prompt format and cadence
  - how accuracy affects outcomes

### Difficulty and adaptivity
- Difficulty adapts using:
  - rolling WPM estimate
  - accuracy estimate
  - time pressure tolerance setting
- Adaptive system must not hard-lock a run immediately:
  - allow assist toggles for extra time, reduced penalties, or simplified prompts.

### Data-driven design
- Lessons, drills, map nodes, and upgrades are JSON data validated by schemas.
- New content packs can be added without code changes when data schema is met.

### Determinism and save
- A run is reproducible from:
  - seed
  - content pack version
  - player settings
- At minimum: a mid-run save and resume for the current run.

### QA / test
- Automated tests cover:
  - data integrity and schema validation
  - command parsing and validation
  - typing score calculations
- Headless smoke test simulates a battle loop and asserts invariants.

### Performance baseline
- Target: stable 60 FPS at 1080p on a typical desktop.
- No visible hitches during battle waves or reward screens.

---
## Landmark: MVP - must-have acceptance criteria

### Content breadth
- 6-10 upgrades, 4-6 enemy archetypes, 3-5 biome or backdrop variants.
- 20-40 map nodes or events with short text outcomes.

### Progression
- Meta progression unlocks:
  - new upgrades
  - new wordpacks
  - new interventions
- First unlocks should be achievable within 10-20 minutes.

### Typing curriculum
- Wordpacks arranged by:
  - home row -> top row -> bottom row
  - common bigrams/trigrams
  - punctuation/numbers (optional module)
- In-game feedback:
  - per-run report (WPM, accuracy, common errors)
  - suggestions for next pack/module

### Accessibility
- Settings for:
  - reduced time pressure (global multiplier)
  - high-contrast UI mode
  - reduced motion
  - font choices (include a dyslexia-friendly option if licensed)
  - audio cue toggles
  - one-handed mode (optional module)

### Distribution
- Godot export preset for Windows builds.
- Versioning visible in UI (app + content version).
- A reproducible release process documented.

---
## Landmark: Definition of Done checklist (per milestone)
A milestone is "Done" only if:
- Implementation matches the acceptance criteria in its milestone doc.
- Tests exist and pass locally (and in CI if present).
- No new TODOs without linked issues.
- A short changelog entry exists, including:
  - what changed
  - how to test
  - known limitations
