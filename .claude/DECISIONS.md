# Architecture Decisions

Record of design and architecture decisions made during development. Reference this before making changes that might conflict with established patterns.

---

## Decision Format

Each entry should include:
- **Date:** When the decision was made
- **Decision:** What was decided
- **Rationale:** Why this approach was chosen
- **Alternatives Considered:** What else was evaluated
- **Consequences:** What this means for future development

---

## Decisions Log

### 2026-01-10: Context Directory Location

**Decision:** Place `.claude/` at repository root, not inside `apps/keyboard-defense-godot/`

**Rationale:**
- Repository-level concerns (like task tracking) apply across the whole project
- AGENTS.md is at repo root, so related files should be nearby
- Keeps Godot project directory focused on game code

**Consequences:** Claude Code should look for context files at repo root

---

### 2026-01-10: Schema Validation in Python

**Decision:** Use Python + jsonschema library for schema validation, not GDScript

**Rationale:**
- jsonschema is a mature, standards-compliant validator
- Python already used for other build scripts (svg_to_png.py, synth_audio.py)
- Can run without Godot engine
- Better error messages than a custom GDScript implementation

**Alternatives Considered:**
- GDScript validator: Would require Godot, harder to get good error messages
- Node.js (ajv): Would add another runtime dependency

**Consequences:** Requires `pip install jsonschema` for full validation

---

### Pre-existing: Sim/Game Separation

**Decision:** All game logic in `sim/` must be Node-free and deterministic

**Rationale:**
- Enables headless testing
- Ensures deterministic replay
- Separates concerns cleanly

**Consequences:**
- No `extends Node` in sim/
- No signals, no scenes, no UI references
- All state changes through intents

---

### Pre-existing: Intent-Based State Mutation

**Decision:** All state changes go through the intent system

**Rationale:**
- Single point for state validation
- Enables replay and undo
- Clear audit trail of changes

**Consequences:**
- Never modify GameState directly from game layer
- Create intents in parse_command.gd
- Apply intents in apply_intent.gd

---

<!-- Add new decisions above this line -->
