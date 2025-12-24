# Backlog and Delivery Plan

## Objectives
- Deliver a **Vertical Slice** that proves the typing-first loop: day planning + exploration + night defense, with adaptive typing difficulty and basic meta progression.
- Deliver an **MVP** that is content-complete enough for a demo/Early Access: multiple biomes, event variety, threat variety, balanced economies, accessibility settings, and stable saves.

## Delivery Cadence
- **Weekly cadence**: one internal playtest build per week, with changelog and a focused playtest questionnaire.
- **Two-week sprint rhythm** (optional): plan -> implement -> stabilize -> playtest.

## Milestones

### Milestone VS - Vertical Slice (Target: 4-6 weeks)
Acceptance emphasis: loop cohesion + typing feel.

Must include:
- Deterministic sim tick, day/night cycle, and one run lasting 8-12 in-game days.
- Core typing UX: command entry + prompt system + feedback.
- Exploration: at least one fog-of-war map with POIs.
- Resource gathering: at least 3 resources, 2 buildings, 1 upgrade path.
- Defense: at least 3 enemy types and 1 boss-like wave modifier.
- Accessibility: adjustable typing time pressure and practice mode.

### Milestone MVP - Demo/Early Access Ready (Target: +6-10 weeks after VS)
Acceptance emphasis: stability + content variety + retention.

Must include:
- Multiple biomes; event/threat card variety.
- Meta progression (unlocks) without paywalling mastery.
- Save/resume and run recap.
- Audio + art pipeline integrated and tested (procedural generators acceptable).
- Onboarding + tutorial + basic settings.

## Roles and Responsibilities (even for a solo dev)
- **Game designer (you)**: owns difficulty curve, content pacing, and acceptance criteria.
- **Codex**: implements per prompts; must not invent new mechanics outside the plans without explicit instruction.
- **Playtesters**: provide qualitative feedback on typing feel and frustration.

## Definition of Ready (DoR) for a Story
A story is ready for implementation when it has:
- Clear player value (what changes in the player experience).
- Input/controls explicitly described (typing-only assumption).
- Data needs specified (JSON schemas where applicable).
- Acceptance tests described (automated or manual).

## Definition of Done (DoD) Summary
See `docs/keyboard-defense-plans/business/DEFINITION_OF_DONE.md`.

## Backlog Structure
- **Epics**: large features (e.g., Event Engine, Night Defense, Wordpack Pipeline).
- **Stories**: user-visible slices that ship incrementally.
- **Tasks**: implementation steps (parser changes, UI wiring, tests).

## Risk-Driven Ordering
Implement in the following order to reduce rework:
1. Typing UX + input pipeline
2. Deterministic sim + save format
3. Day/night loop
4. Defense & exploration as data-driven systems
5. Content pipeline tooling
6. Art/audio generators
7. Telemetry (opt-in) and evaluation harness
8. Marketing build outputs (press-kit generator, etc.)



