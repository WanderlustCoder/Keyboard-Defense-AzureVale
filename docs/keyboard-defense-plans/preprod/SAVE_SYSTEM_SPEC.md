# Save System Specification (Deterministic Runs + Meta Progression)

---
## Landmark: Goals
- Allow players to resume a run after closing the game.
- Preserve meta progression across runs.
- Maintain determinism (replayable from seed + inputs) where feasible.
- Support schema migrations as the game evolves.

---
## Landmark: Save objects
### 1) Profile save (meta)
Stores long-lived progression:
- unlocked upgrades
- unlocked wordpacks
- currency (if used)
- settings (layout, accessibility, audio)
- typing profile stats (WPM/accuracy history; error map)

### 2) Run save (mid-run)
Stores the current run state:
- seed and RNG state
- current day index and phase (map/battle/results)
- map state (nodes, unlocks, POIs)
- placed defenses or upgrades
- resource inventory
- active wave state (if saved during battle)
- queued prompts (optional; or re-generated deterministically)

---
## Landmark: Determinism requirements
- Sim must not depend on:
  - real time clocks
  - non-seeded randomness
  - frame rate drift
- RNG:
  - use a seedable PRNG
  - store either:
    - current PRNG internal state, or
    - a random call counter and stable generator

Recommendation:
- Store PRNG internal state to avoid subtle drift.

---
## Landmark: Versioning and migrations
Every save includes:
- `save_version` (integer)
- `app_version` (string)
- `content_version` (hash or semver)

Migration strategy:
- `migrate_save(raw) -> SaveCurrent` function that:
  - detects old versions
  - transforms to current schema
  - fills defaults
- Old fields are ignored and never crash load.

---
## Landmark: Storage targets (Godot)
- Store saves under `user://` using JSON.
- Recommended path: `user://keyboard_defense_save.json`.
- Provide Export and Import options to support backup.

---
## Landmark: Failure modes
- Corrupted save:
  - fall back to last known good snapshot
  - otherwise reset run only (never wipe profile without explicit user action)
- Content mismatch:
  - if a run references missing content packs, display warning and offer:
    - attempt load anyway (best-effort)
    - abandon run (keep profile)

---
## Landmark: Minimal schema shapes
See `docs/keyboard-defense-plans/preprod/schemas/savegame.schema.json` for the
authoritative structure.
