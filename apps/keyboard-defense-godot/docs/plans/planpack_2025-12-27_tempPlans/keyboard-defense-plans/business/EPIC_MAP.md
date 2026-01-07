# Epic Map

This is an epic-level decomposition for planning and tracking. It is designed to stay stable even as features iterate.

## Core Loop Epics
### E01 - Typing-First Input and Prompt System
- Command line / command palette
- Prompt rendering and timing logic
- Error tolerance modes (strict/lenient)
- Keyboard layout support (QWERTY/AZERTY/Dvorak)

### E02 - Deterministic Simulation Core
- Tick-based sim state
- RNG seeding and replayability
- State snapshots and migrations

### E03 - Day Phase: Build + Economy
- Buildings and upgrades
- Resource nodes and gather rates
- Trading / crafting (optional)

### E04 - Exploration Phase
- Map generation / fog-of-war
- Roads/outposts
- POIs + events hooks

### E05 - Night Phase: Defense
- Wave generator
- Enemy behaviors
- Towers/traps, repairs, emergency actions

### E06 - Meta Progression and Run Structure
- Unlocks, perks, and difficulty modifiers
- Run recaps and goals

## Content Epics
### E07 - Wordpacks and Curriculum
- Word lists by skill focus
- Progressive unlock rules
- Validation + lint tooling

### E08 - Events, POIs, Threat Cards
- Data-driven definitions
- Weighted selection with anti-repetition
- Deterministic selection per seed

## Presentation Epics
### E09 - Procedural Art Pipeline
- SVG-to-atlas pipeline
- UI icon library
- Auto-tiling

### E10 - Procedural Audio Pipeline
- SFX preset library
- Offline render option
- Event-to-audio mapping

## Production Epics
### E11 - Build/Release Automation
- CI checks
- Versioning + changelog
- Packaging for Windows/Desktop

### E12 - Quality & Accessibility
- Test harness scenes
- Input remapping
- Reduced motion / color contrast

### E13 - Evaluation and Metrics
- Baseline typing tests
- Skill improvement reports
- Opt-in telemetry

### E14 - Marketing Assets + Press Kit
- Store copy + screenshots
- Trailer beats
- Press kit generator (optional)



